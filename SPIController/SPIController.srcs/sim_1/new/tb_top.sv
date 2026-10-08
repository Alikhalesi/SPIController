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
      // ----------------------------------------------------
    // Parameters
    // ----------------------------------------------------
    parameter CLK_PERIOD = 10; // 10ns for 100MHz clock
    parameter [7:0] READ_REGISTER = 8'h0B; // Example instruction opcode

    // ----------------------------------------------------
    // Testbench Wires & Regs
    // ----------------------------------------------------
    logic clk;
    logic synced_rst;
    
    // SPI Physical Interface
    logic sclk;
    logic mosi;
    logic miso;
    logic csn;

    // FIFO Interface
    logic read_enable;
    logic write_enable;
    logic [7:0] fifo_read;
    logic [7:0] fifo_write;
    logic fifo_empty;
    logic fifo_full;

    // SPI Master Internal Controls
    logic spi_master_ready;
    logic spi_master_finished;
    logic [7:0] spi_master_din;
    logic spi_master_start_transfer;
    logic data_phase;

    // Driver Controls
    logic driver_start;
    logic driver_ready;
    logic driver_finished;
    logic [7:0] instruction;
    logic [7:0] addr;

    // Mock Device Variables
    logic [7:0] mock_device_data = 8'hA5; // Data the sensor will return
    int bit_count = 0;

    // ----------------------------------------------------
    // Glue Logic & Interconnects (from your design)
    // ----------------------------------------------------
    assign instruction = READ_REGISTER;
    assign addr        = 8'd0;
    assign write_enable = spi_master_finished && data_phase;

    // ----------------------------------------------------
    // DUT Instances
    // ----------------------------------------------------
    fifo #(.DATA_WIDTH(8)) fifo_instance (
        .clk(clk),
        .nrst(synced_rst),
        .w_en(write_enable),
        .r_en(read_enable),
        .r_data(fifo_read),
        .w_data(fifo_write),
        .empty(fifo_empty),
        .full(fifo_full)
    );

    spi_master master (
        .clk(clk),
        .nrst(synced_rst),
        .sclk(sclk),
        .mosi(mosi),
        .ready(spi_master_ready),
        .miso(miso),
        .start(spi_master_start_transfer),
        .din(spi_master_din),
        .dout(fifo_write),
        .finished(spi_master_finished)
    );

    adxl_driver driver (
        .clk(clk),
        .nrst(synced_rst),
        .spi_master_ready(spi_master_ready),
        .spi_master_finished(spi_master_finished),
        .csn(csn),
        .spi_master_din(spi_master_din),
        .spi_master_start_transfer(spi_master_start_transfer),
        .start(driver_start),
        .ready(driver_ready),
        .instruction(instruction),
        .addr(addr),
        .finish(driver_finished),
        .data_phase(data_phase)
    );

    // ----------------------------------------------------
    // Clock Generation (100MHz)
    // ----------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    // ----------------------------------------------------
    // Behavioral Model of External SPI Slave (CPOL=0, CPHA=0)
    // ----------------------------------------------------
    // For Mode 0: Data is launched by the slave on SCLK falling edge 
    // and sampled by the master on SCLK rising edge.
    always @(negedBySclkOrCsn) begin
        if (csn) begin
            miso <= 1'b0;
            bit_count <= 0;
        end else begin
            // Drive MISO bit-by-bit MSB first on falling edges of sclk
            // Note: In a true driver sequence, the sensor only returns data during the data phase
            miso <= mock_device_data[7 - (bit_count % 8)];
        end
    end

    // Increment bit tracking on rising edge of sclk (sampling edge)
    always @(posedge sclk or posedge csn) begin
        if (csn) begin
            bit_count <= 0;
        end else begin
            bit_count <= bit_count + 1;
        end
    end

    // Helper macro logic to handle clean clocking triggers
    wire negedBySclkOrCsn = sclk || csn;

    // ----------------------------------------------------
    // Test Vector Sequence
    // ----------------------------------------------------
    initial begin
        // Initialize signals
        clk = 0;
        synced_rst = 0;
        driver_start = 0;
        read_enable = 0;
        miso = 0;

        // 1. Reset Phase
        #(CLK_PERIOD * 10);
        synced_rst = 1; // De-assert active-low reset
        #(CLK_PERIOD * 5);

        // Wait for system to be completely ready
        wait(driver_ready && spi_master_ready);
        #(CLK_PERIOD);

        $display("[TB INFO] Starting ADXL Driver Read Operation...");

        // 2. Trigger Driver Transaction
        driver_start = 1;
        #(CLK_PERIOD);
        driver_start = 0;

        // 3. Monitor Transaction Progress
        // Wait for driver to finish executing its state machine
        wait(driver_finished);
        $display("[TB INFO] Driver transaction completed!");

        // Give a few buffer cycles for the FIFO to settle
        #(CLK_PERIOD * 5);

        // 4. Verify FIFO Data Insertion
        if (!fifo_empty) begin
            $display("[TB SUCCESS] FIFO is not empty. Reading data from FIFO...");
            read_enable = 1; // Pop data out asynchronously
            #(CLK_PERIOD);
            $display("[TB RESULT] Data read from FIFO: 8'h%h (Expected: 8'h%h)", fifo_read, mock_device_data);
            read_enable = 0;
        end else begin
            $display("[TB ERROR] Transaction finished but FIFO is empty! Data phase write failed.");
        end

        // Finish simulation
        #(CLK_PERIOD * 20);
        $display("[TB INFO] Simulation finished cleanly.");
        $finish;
    end
endmodule
