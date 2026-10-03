`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/03/2026 01:44:38 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top(

    );
  // =========================================================================
    // 1. Clock & Interface Signals
    // =========================================================================
    logic clk;
    logic nrst;
    logic miso;
    
    logic mosi;
    logic sclk;
    logic csn;
    logic [7:0] sseg_data;
    logic [7:0] sseg_ctrl;
    logic btn;
    logic led;

    // =========================================================================
    // 2. Unit Under Test (UUT) Instantiation
    // =========================================================================
    top uut (
        .clk(clk),
        .nrst(nrst),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .csn(csn),
        .sseg_data(sseg_data),
        .sseg_ctrl(sseg_ctrl),
        .btn(btn),
        .led(led)
    );

    // =========================================================================
    // 3. Clock Generation (100 MHz)
    // =========================================================================
    always begin
        #5 clk = ~clk; 
    end

    // =========================================================================
    // 4. Mock SPI Peripheral Model (Strict CPOL=0, CPHA=0 Mode)
    // =========================================================================
    logic [7:0] mock_device_reg = 8'hA5; // Data the master will read
    logic [2:0] miso_bit_cnt;

    // Mode 0 requires combinatorial drive or instant driving on CSN falling edge
    always_comb begin
        if (csn) begin
            miso = 1'b0;
        end else begin
            miso = mock_device_reg[miso_bit_cnt];
        end
    end

    // Manage the bit pointer tracking
    always_ff @(negedge sclk or posedge csn) begin
        if (csn) begin
            miso_bit_cnt <= 3'd7; // Reset index to the MSB
        end else begin
            if (miso_bit_cnt > 0)
                miso_bit_cnt <= miso_bit_cnt - 1'b1;
            else
                miso_bit_cnt <= 3'd7; // Roll over for next byte if multi-byte
        end
    end

    // =========================================================================
    // 5. MOSI Protocol Monitor (CPOL=0, CPHA=0 samples on RISING edge)
    // =========================================================================
    logic [7:0] captured_mosi_byte;
    logic [2:0] mosi_bit_cnt = 3'd7;

    always_ff @(posedge sclk or posedge csn) begin
        if (csn) begin
            mosi_bit_cnt <= 3'd7;
        end else begin
            captured_mosi_byte[mosi_bit_cnt] <= mosi;
            if (mosi_bit_cnt == 0) begin
                $display("[TB INFO] @ %0t ns | SPI Master Sent: 8'h%h", $time, captured_mosi_byte);
                mosi_bit_cnt <= 3'd7;
            end 
            else begin
                mosi_bit_cnt <= mosi_bit_cnt - 1'b1;
            end
        end
    end

    // =========================================================================
    // 6. Test Stimulus Flow
    // =========================================================================
    initial begin
        clk  = 0;
        nrst = 1;
        btn  = 0;

        #40;
        nrst = 0;
        #40;
        nrst=1;
        #40;

        // Trigger transaction
        @(posedge clk);
        btn = 1;
        
        repeat (5) @(posedge clk);
        btn = 0;

        // Wait for implementation completion
        wait(led == 1);
        $display("[TB SUCCESS] SPI Mode 0 Transaction Finished Successfully!");
        
        #200;
        $finish;
    end
endmodule
