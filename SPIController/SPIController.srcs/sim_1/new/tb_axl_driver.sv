`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 09:06:20 AM
// Design Name: 
// Module Name: tb_axl_driver
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


module tb_axl_driver(

    );
    
    // ----------------------------------------------------
    // Parameters & Constants
    // ----------------------------------------------------
    parameter CLK_PERIOD = 10; // 10ns for 100MHz clock
    localparam [7:0] MOCK_OPCODE = 8'h0B;
    localparam [7:0] MOCK_ADDR   = 8'h2D;

    // ----------------------------------------------------
    // Testbench Signals
    // ----------------------------------------------------
    logic clk;
    logic nrst;
    
    // Inputs to the Driver (Controlled by TB)
    logic spi_master_ready;
    logic spi_master_finished;
    logic driver_start;
    logic [7:0] instruction;
    logic [7:0] addr;
    
    // Outputs from the Driver (Monitored by TB)
    logic csn;
    logic [7:0] spi_master_din;
    logic spi_master_start_transfer;
    logic driver_ready;
    logic driver_finished;
    logic data_phase;

    // ----------------------------------------------------
    // Device Under Test (DUT)
    // ----------------------------------------------------
    adxl_driver uut (
        .clk(clk),
        .nrst(nrst),
        .spi_master_ready(spi_master_ready),
        .spi_master_finished(spi_master_finished),
        .csn(csn),
        .spi_master_din(spi_master_din),
        .spi_master_start_transfer(spi_master_start_transfer),
        .start(driver_start),
        .ready(driver_ready),
        .instruction(instruction),
        .addr(addr),
        .finish(driver_finished), // mapped to 'finish' in your port list
        .data_phase(data_phase)
    );

    // ----------------------------------------------------
    // Clock Generation (100MHz)
    // ----------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    // ----------------------------------------------------
    // SPI Master Emulation Logic (Behavioral Model)
    // ----------------------------------------------------
    // This block listens for the driver's start commands and simulates 
    // the delay of an actual 2MHz SPI master byte transaction.
    // 2MHz SPI Clock = 500ns per bit * 8 bits = 4000ns per byte transfer.
    localparam SPI_BYTE_DELAY = 4000; 

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            spi_master_ready    <= 1'b1;
            spi_master_finished <= 1'b0;
        end else begin
            // When driver requests a transfer, the master becomes busy
            if (spi_master_start_transfer && spi_master_ready) begin
                spi_master_ready    <= 1'b0;
                spi_master_finished <= 1'b0;
                
                // Simulate the time it takes to shift out 8 bits at 2MHz
                #(SPI_BYTE_DELAY); 
                
                // Complete the transfer on the next clock edge
                @(posedge clk);
                spi_master_finished <= 1'b1;
                spi_master_ready    <= 1'b1;
                
                // Clear the finished flag on the subsequent cycle
                @(posedge clk);
                spi_master_finished <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------
    // Test Sequence
    // ----------------------------------------------------
    initial begin
        // Initialize inputs
        clk          = 0;
        nrst         = 1;
        driver_start = 0;
        instruction  = MOCK_OPCODE;
        addr         = MOCK_ADDR;

        // 1. Reset Phase
        #(CLK_PERIOD * 10);
        nrst = 0; // Release reset
        #(CLK_PERIOD * 5);
        nrst = 1; // Release reset
        #(CLK_PERIOD * 5);
        // Check if driver initializes to ready state
        if (!driver_ready) begin
            $display("[TB ERROR] Driver did not enter ready state after reset.");
        end

        // 2. Start a Read/Write Sequence
        $display("[TB] Triggering driver transaction. Opcode: 0x%h, Addr: 0x%h", instruction, addr);
        @(posedge clk);
        driver_start = 1;
        @(posedge clk);
        driver_start = 0;

        // 3. Monitor and Assert Correct Behavior
        // Verification Item A: CSN should drop low immediately during a transaction
        @(posedge clk);
        if (csn !== 1'b0) begin
            $display("[TB ERROR] CSN did not drop low when transaction started.");
        end

        // Verification Item B: Monitor the driver's phase sequences
        // Usually, an ADXL driver will send: Instruction -> Address -> Data Phase
        
        // Wait for Instruction byte transfer
        @ (posedge spi_master_start_transfer);
        $display("[TB] Master transferring Instruction Byte. Data: 0x%h", spi_master_din);
        
        // Wait for Address byte transfer
        @ (posedge spi_master_start_transfer);
        $display("[TB] Master transferring Address Byte. Data: 0x%h", spi_master_din);
        
        // Wait for Data phase transfer
        @ (posedge spi_master_start_transfer);
        if (data_phase !== 1'b1) begin
            $display("[TB ERROR] data_phase signal did not go high during data transaction.");
        end else begin
            $display("[TB] Master entered Data Phase successfully.");
        end

        // 4. Wait for Sequence Completion
        wait(driver_finished);
        $display("[TB SUCCESS] Driver successfully asserted finish flag.");
        
        // Final sanity check on CSN release
        #(CLK_PERIOD * 2);
        if (csn !== 1'b1) begin
            $display("[TB ERROR] CSN stayed low after driver finished transaction.");
        end

        // End Simulation
        #(CLK_PERIOD * 20);
        $display("[TB] Isolated driver simulation complete.");
        $finish;
    end

endmodule
