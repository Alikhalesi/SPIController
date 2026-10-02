`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2026 11:16:27 AM
// Design Name: 
// Module Name: 16b_to_d
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


module binary_to_decimal_16bit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [15:0] binary_in,
    output logic [19:0] bcd_out,    // 5 digits * 4 bits = 20 bits
    output logic        ready
);

    // State Encoding
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        CHECK = 2'b01,
        SHIFT = 2'b10,
        DONE  = 2'b11
    } state_t;

    state_t state, next_state;

    // Internal Registers
    logic [15:0] binary_reg;
    logic [19:0] bcd_reg;
    logic [4:0]  bit_counter; // Counts up to 16 shifts

    // Split BCD register into separate 4-bit aliases for easy addition logic
    logic [3:0] bcd_ones, bcd_tens, bcd_hundreds, bcd_thousands, bcd_tenthousands;
    
    assign bcd_ones          = bcd_reg[3:0];
    assign bcd_tens          = bcd_reg[7:4];
    assign bcd_hundreds      = bcd_reg[11:8];
    assign bcd_thousands     = bcd_reg[15:12];
    assign bcd_tenthousands  = bcd_reg[19:16];

    // State Machine Register Block
       // 1. Clean State Register Block (Sequential)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // 2. NEW: Combinational Next-State Logic (Blocking assignments)
    always_comb begin
        next_state = state; // Default hold state
        case (state)
            IDLE:  if (start) next_state = CHECK;
                   else       next_state = IDLE;
            CHECK: next_state = SHIFT;
            SHIFT: if (bit_counter == 5'd15) next_state = DONE;
                   else                      next_state = CHECK;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 3. Clean Datapath Block (Sequential - remove next_state updates from here)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_reg      <= '0;
            binary_reg   <= '0;
            bit_counter  <= '0;
            ready        <= 1'b1;
            bcd_out      <= '0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (start) begin
                        binary_reg  <= binary_in;
                        bcd_reg     <= '0;
                        bit_counter <= '0;
                        ready       <= 1'b0;
                    end
                end
                CHECK: begin
                    if (bcd_ones >= 5)         bcd_reg[3:0]   <= bcd_ones + 3;
                    if (bcd_tens >= 5)         bcd_reg[7:4]   <= bcd_tens + 3;
                    if (bcd_hundreds >= 5)     bcd_reg[11:8]  <= bcd_hundreds + 3;
                    if (bcd_thousands >= 5)    bcd_reg[15:12] <= bcd_thousands + 3;
                    if (bcd_tenthousands >= 5) bcd_reg[19:16] <= bcd_tenthousands + 3;
                end
                SHIFT: begin
                    bcd_reg     <= {bcd_reg[18:0], binary_reg[15]};
                    binary_reg  <= {binary_reg[14:0], 1'b0};
                    bit_counter <= bit_counter + 1;
                end
                DONE: begin
                    bcd_out <= bcd_reg;
                    ready   <= 1'b1;
                end
            endcase
        end
    end


endmodule
