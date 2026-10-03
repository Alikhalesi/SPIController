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
    // 4. Mock SPI Peripheral Behavioral Model
    // =========================================================================
    // This blocks mirrors a physical device. It shifts out a predefined response 
    // register value (e.g., 0xA5) on falling edges of sclk whenever csn is low.
    logic [7:0] mock_device_reg = 8'hA5; // Data expected to be read by the UUT
    logic [2:0] miso_bit_cnt = 3'd7;

    always_ff @(negedge sclk or posedge csn) begin
        if (csn) begin
            miso        <= 1'b0;
            miso_bit_cnt <= 3'd7; // Reset index when unselected
        end else begin
            miso        <= mock_device_reg[miso_bit_cnt];
            miso_bit_cnt <= miso_bit_cnt - 1'b1;
        end
    end

    // Monitor SPI MOSI transactions in the console window
    logic [7:0] captured_mosi_byte;
    logic [2:0] mosi_bit_cnt = 3'd7;

    always_ff @(posedge sclk) begin
        if (!csn) begin
            captured_mosi_byte[mosi_bit_cnt] <= mosi;
            if (mosi_bit_cnt == 0) begin
                $display("[TB INFO] @ %0t ns | SPI Byte Sent out from Master: 8'h%h", $time, captured_mosi_byte);
                mosi_bit_cnt <= 3'd7;
            end
             else begin
                mosi_bit_cnt <= mosi_bit_cnt - 1'b1;
            end
        end
    end

    // Reset bit counter when chip select goes high
    always_ff @(posedge csn) begin
        mosi_bit_cnt <= 3'd7;
    end

    // =========================================================================
    // 5. Test Stimulus Flow
    // =========================================================================
    initial begin
        // Initialize Inputs
        clk  = 0;
        nrst = 1;
        btn  = 0;

        // Apply Reset
        #40;
        nrst = 0;
        #20
        nrst=1;
        $display("[TB STATUS] Global Asynchronous Reset Released.");
        
        // Wait for system synchronization settle down
        #40;

        // Trigger the FSM transaction via button press
        @(posedge clk);
        btn = 1;
        $display("[TB STATUS] Pressing Trigger Button (btn=1)...");
        
        // Keep button pressed for a few cycles then release
        repeat (5) @(posedge clk);
        btn = 0;
        $display("[TB STATUS] Releasing Trigger Button (btn=0).");

        // Wait for the Master sequence to process and complete
        // The LED goes high when entering WAIT_FOR_FINISH -> TEAR_DOWN states
        wait(led == 1);
        $display("[TB SUCCESS] LED detected High! Transaction finished.");
        
        // Give it a brief tail execution window before shutting down simulation
        #200;
        $display("[TB STATUS] Simulation ended cleanly.");
        $finish;
    end

endmodule
