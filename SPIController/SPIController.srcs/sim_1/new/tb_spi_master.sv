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
    localparam int SPI_FREQ = 2_000_000;   // 2 MHz SPI Clock

    // Divisor mapping: (100M / (2 * 2M)) - 1 = 24
    localparam int TARGET_DVSR = (CLK_FREQ / (2 * SPI_FREQ)) - 1;
    localparam int CYCLES_PER_HALF_PERIOD = TARGET_DVSR + 1; // 25 cycles

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

    // =================================================================
    // SIMULATION-SAFE SLAVE & CHECKER (Driven purely by System Clock)
    // =================================================================
    logic [7:0] slave_rom [0:1] = '{8'hA5, 8'h5A}; 
    int byte_idx;
    int bit_cnt;
    logic miso_reg;
    
    // Tracking registers for edge detection
    logic sclk_delayed;
    wire sclk_falling_edge = (sclk_delayed == 1'b1 && sclk == 1'b0);
    int sys_clk_counter = 0;
    logic last_sclk;

    // Continuous assignment handles High-Z state cleanly when CS is inactive
    assign miso = (cs_n) ? 1'bz : miso_reg;

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            sclk_delayed    <= 1'b0;
            bit_cnt         <= 0;
            byte_idx        <= 0;
            miso_reg        <= slave_rom[0][7]; // Align to MSB immediately
            sys_clk_counter <= 0;
            last_sclk       <= 1'b0;
        end else begin
            // 1. Maintain history for edge detection
            sclk_delayed <= sclk;

            if (cs_n) begin
                // Reset internal stream pointers instantly when CS is high
                bit_cnt         <= 0;
                byte_idx        <= 0;
                miso_reg        <= slave_rom[0][7];
                sys_clk_counter <= 0;
                last_sclk       <= sclk;
            end else begin
                // 2. Frequency Divisor Checker Logic
                sys_clk_counter++;
                if (sclk != last_sclk) begin
                    if (sys_clk_counter != CYCLES_PER_HALF_PERIOD) begin
                        $display("[FREQ ERROR] SPI Clock frequency drift! Expected: %0d sys clks. Measured: %0d", 
                                 CYCLES_PER_HALF_PERIOD, sys_clk_counter);
                    end else begin
                        $display("[FREQ CHECK] SCLK edge verified at exactly %0d system clocks (2 MHz).", sys_clk_counter);
                    end
                    sys_clk_counter <= 0;
                    last_sclk       <= sclk;
                end

                // 3. Slave Shifting Logic (Triggered synchronously by the falling edge detection)
                if (sclk_falling_edge) begin
                    if (bit_cnt < 7) begin
                        bit_cnt  <= bit_cnt + 1;
                        miso_reg <= slave_rom[byte_idx][6 - bit_cnt];
                    end else begin
                        bit_cnt  <= 0;
                        if (byte_idx < 1) begin
                            byte_idx <= byte_idx + 1;
                            miso_reg <= slave_rom[byte_idx + 1][7]; // Load next byte's MSB
                        end else begin
                            byte_idx <= 0;
                            miso_reg <= 1'b0; 
                        end
                    end
                end
            end
        end
    end

    // Stimulus Process (Simulating Outer Module Driving Sequence)
    initial begin
        nrst  = 1'b1;
        start = 1'b0;
        din   = 8'h00;
        cs_n  = 1'b1;

        #40;
        nrst = 1'b0;
        #20;
        nrst = 1'b1;
        #20;
        wait(ready == 1'b1);
        @(posedge clk);

        $display("[TB] Starting Multi-Byte Write. Tracking system clock edges...");
        
        cs_n = 1'b0; 
        #250; // Front setup delay

        // Byte 1
        din   = 8'hA5;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge ready);
        #1;
        $display("[TB] Byte 1 Completed. Master dout = 8'h%h (Expected: 8'hA5)", dout);

        // Byte 2
        din   = 8'hAD;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge ready);
        #1;
        $display("[TB] Byte 2 Completed. Master dout = 8'h%h (Expected: 8'h5A)", dout);

        #250; // Back hold delay
        cs_n = 1'b1; 
        
        #2000;
        $finish;
    end

    
endmodule
