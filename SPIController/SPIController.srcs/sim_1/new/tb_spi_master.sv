`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2026 11:50:52 AM
// Design Name: 
// Module Name: tb_spi_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_spi_master(

    );
    // Parameters
    localparam int CLK_FREQ = 100_000_000; // 100 MHz Master System Clock
    localparam int SPI_FREQ = 2_000_000;   // 2 MHz SPI Clock (Requested)

    // Testbench Signals
    logic clk;
    logic nrst;
    logic sclk;
    logic mosi;
    logic ready;
    logic miso;
    logic start;
    logic [7:0] din;
    logic [7:0] dout;
    // Outer-module controlled signal
    logic cs_n; 

    // Instantiate UUT
    spi_master #(
        .freq(SPI_FREQ)
    ) uut (
        .clk(clk),
        .nrst(nrst),
        .sclk(sclk),
        .mosi(mosi),
        .ready(ready),
        .miso(miso),
        .start(start),
        .din(din),
        .dout(dout)

    );

    // 100 MHz System Clock (10ns period)
    always begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end

    // Emulated Multi-byte Slave (CPOL=0, CPHA=0)
       logic [7:0] slave_rom [0:1] = '{8'hA5, 8'h5A}; 
    int byte_idx;
    int bit_cnt;
    logic miso_reg;

    assign miso = (cs_n) ? 1'bz : miso_reg;

    always @(negedge sclk or negedge nrst or posedge cs_n) begin
        if (!nrst) begin
            bit_cnt  <= 0;
            byte_idx <= 0;
            miso_reg <= slave_rom[0][7]; // Force MSB of first byte
        end else if (cs_n) begin
          //  bit_cnt  <= 0;
           // byte_idx <= 0;
           // miso_reg <= slave_rom[0][7]; 
        end else begin
            // For CPHA=0, advance the bit counter and track byte boundaries
            if (bit_cnt < 7) begin
                bit_cnt  <= bit_cnt + 1;
                miso_reg <= slave_rom[byte_idx][6 - bit_cnt];
            end else begin
                bit_cnt  <= 0;
                // Safely boundary-check before incrementing to avoid out-of-bounds 'X'
                if (byte_idx < 1) begin
                    byte_idx <= byte_idx + 1;
                    miso_reg <= slave_rom[byte_idx + 1][7]; // Load next byte's MSB safely
                end else begin
                    byte_idx <= 0; // Wrap around or hold idle
                    miso_reg <= 1'b0; 
                end
            end
        end
    end
    // Stimulus Process (Simulating the "Outer Module" logic)
    initial begin
        // Init
        nrst  = 1'b1;
        start = 1'b0;
        din   = 8'h00;
        cs_n  = 1'b1; // Idle high

        #40;
        nrst = 1'b0;
        #20;
        nrst = 1'b1;
        #20;
        wait(ready == 1'b1);
        @(posedge clk);

        // =================================================================
        // MULTI-BYTE TRANSACTION: Send 2 Bytes consecutively [8'hDE, 8'hAD]
        // =================================================================
        $display("[TB] --- Starting 2-Byte Transaction @ 2MHz SPI Clock ---");
        
        // 1. Assert CS to kick off the frame
        cs_n = 1'b0; 
        #250; // Dynamic setup time relative to the slower 2MHz clock (500ns period)

        // --- Byte 1 ---
        din   = 8'hDE;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // Wait for the master to finish shifting the first byte
        wait(ready == 1'b1);
        @(posedge ready);
        #1;
        $display("[TB] Byte 1 Sent: 8'hDE | Received: 8'h%h", dout);

        // --- Byte 2 (Streamed immediately without dropping CS) ---
        din   = 8'hAD;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // Wait for the master to finish shifting the second byte
        wait(ready == 1'b1);
        @(posedge ready);
        #1;
        $display("[TB] Byte 2 Sent: 8'hAD | Received: 8'h%h", dout);

        // 2. De-assert CS after transaction completion
        #250; // Hold time for the slower 2MHz clock
        cs_n = 1'b1; 
        
        $display("[TB] --- Multi-byte Transaction Finished ---");

        #2000;
        $finish;
    end

    // Timeout watchdog (increased since 2MHz clock takes longer to shift bits)
    initial begin
        #200000;
        $display("[TIMEOUT] Simulation hung!");
        $finish;
    end
    
endmodule
