`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2026 06:36:27 PM
// Design Name: 
// Module Name: top
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


module top(
input logic clk,
input logic nrst,
 input logic miso,
output logic mosi,
 output logic sclk,
output logic csn,
output logic[7:0] sseg_data,
output logic[7:0] sseg_ctrl,
input logic btn,
input logic btnr,
output logic led

    );
    

      
  typedef enum logic[7:0] {WRITE_REGISTER=8'h0A,READ_REGISTER=8'h0B,READ_FIFO=8'h0D} AXL_INSTRUCTION;
  
    logic synced_rst;
    reset_synchronizer rst_synchronizer(.nrst(nrst),.clk(clk),.sync_nrst(synced_rst));
    
        logic btn_debounced;
debouncer btn_debouncer(.d(btn),.q(btn_debounced),.clk(clk),.nrst(synced_rst));
    
    logic btn_delayed;
     delay_signal btn_delay(.clk(clk),.nrst(nrst),.d(btn_debounced),.q(btn_delayed));
    
        logic btnr_debounced;
debouncer btnr_debouncer(.d(btnr),.q(btnr_debounced),.clk(clk),.nrst(synced_rst));
    
    logic btnr_delayed;
     delay_signal btnr_delay(.clk(clk),.nrst(nrst),.d(btnr_debounced),.q(btnr_delayed));

    
    logic transmit_finished;
    
    logic[7:0] fifo_read;
    logic[7:0] fifo_write;
    logic fifo_empty;
    logic fifo_full;
    logic spi_master_ready;
    logic spi_master_finished;
    logic [7:0] spi_master_din;
    logic spi_master_start_transfer;
    logic data_phase;
    
    //driver
     logic driver_start;
    logic driver_ready;
    logic driver_finished;
    logic [7:0] instruction;
    logic [7:0] addr;
    logic [7:0] spi_write_data;
    logic spi_transaction_type;
    assign spi_transaction_type=0;
    assign instruction=READ_REGISTER;
    assign addr=8'h0;
    
    assign write_enable=spi_master_finished && data_phase;
    logic read_enable= (!fifo_empty) && btnr_delayed;// read operation is asynchronous, this signal just pop the data from FIFO.
    logic fifo_top_updated;    
    fifo  #(.DATA_WIDTH(8)) fifo_instance
    (.clk(clk),.nrst(synced_rst),.w_en(write_enable),.r_en(read_enable),.r_data(fifo_read),.w_data(fifo_write),.empty(fifo_empty),.full(fifo_full),.top_updated(fifo_top_updated));
    
    
  spi_master master(
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

  adxl_driver driver
(
    .clk(clk),
.nrst(synced_rst),
.spi_master_ready(spi_master_ready),
  .spi_master_finished(spi_master_finished),
.csn(csn),
.spi_master_din(spi_master_din),
.spi_master_start_transfer(spi_master_start_transfer),
.start(btn_delayed),
.ready(driver_ready),
.instruction(instruction),
.addr(addr),
.finish(driver_finished),
.data_phase(data_phase),
.transaction_type(spi_transaction_type),
.write_data(spi_write_data)
    );
  
 
acc_subscriber seven_seg_subscriber(.clk(clk),
        .nrst(synced_rst),
        .fifo_empy(fifo_empty),
        .fifo_full(fifo_full),
        .fifo_top(fifo_read),
        .fifo_updated(fifo_top_updated),
         .sseg_data(sseg_data),
.sseg_ctrl(sseg_ctrl)
    );


 assign led= fifo_full; 
    
    
endmodule
