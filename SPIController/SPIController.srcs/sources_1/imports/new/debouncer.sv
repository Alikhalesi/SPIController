module debouncer #(
    parameter int N = 1,
    parameter int STABLE = 1_000_000
)(
    input  logic [N-1:0] d,
    output logic [N-1:0] q,
    input  logic         clk,
    input  logic         nrst 
);
    
    localparam int LENGTH = $clog2(STABLE);
    
    logic [LENGTH-1:0] stable;
    logic [N-1:0]      last_value;
    logic [N-1:0]      d_reg; // Pipeline register to detect changes/bounces
    
    assign q = last_value;
    
    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            stable     <= 0;
            last_value <= 0;
            d_reg      <= 0;
        end else begin
            d_reg <= d; // Sample the input
            
            // If the input changed this cycle, a bounce occurred! Reset the timer.
            if (d != d_reg) begin
                stable <= 0;
            end 
            // If stable reaches the target, lock in the new stable value
            else if (stable == STABLE - 1) begin
                last_value <= d_reg;
            end 
            // If input is steady but timer hasn't expired, keep counting
            else begin
                stable <= stable + 1'b1;
            end
        end
    end
    
endmodule