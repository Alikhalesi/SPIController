`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2026 05:19:09 PM
// Design Name: 
// Module Name: sseg
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

(* DONT_TOUCH = "TRUE" *) 
module sseg
 import common::*;
(
input logic[3:0] number,
output SSEG_NUM segments
    );
   
//        (* parallel_case, full_case *)
//    always_comb  
//    begin
//    case (number)
//    4'b0000:segments=ZERO;
//    4'b0001:segments=ONE;
//    4'b0010:segments=TWO;
//    4'b0011:segments=THREE;
//    4'b0100:segments=FOUR;
//    4'b0101:segments=FIVE;
//    4'b0110:segments=SIX;
//    4'b0111:segments=SEVEN;
//    4'b1000:segments=EIGHT;
//    4'b1001:segments=NINE;
//    default:segments=SSEG_NUM'('x);
//    endcase
//    end

    // This attribute tells Vivado: DO NOT turn this into a ROM block! [3]
    (* rom_style = "mux" *)
    SSEG_NUM temp_seg;

    always_comb begin
        // Using a dynamic ternary tree forces literal multiplexer logic
        temp_seg = (number == 4'b0000) ? ZERO  :
                   (number == 4'b0001) ? ONE   :
                   (number == 4'b0010) ? TWO   :
                   (number == 4'b0011) ? THREE :
                   (number == 4'b0100) ? FOUR  :
                   (number == 4'b0101) ? FIVE  :
                   (number == 4'b0110) ? SIX   :
                   (number == 4'b0111) ? SEVEN :
                   (number == 4'b1000) ? EIGHT :
                   (number == 4'b1001) ? NINE  : SSEG_NUM'('x);
                   
        segments = temp_seg;

// case (number)
//            4'h0: temp_seg = 8'b0000_0011; // 0
//            4'h1: temp_seg = 8'b1001_1111; // 1
//            4'h2: temp_seg = 8'b0010_0101; // 2
//            4'h3: temp_seg = 8'b0000_1101; // 3
//            4'h4: temp_seg = 8'b1001_1001; // 4
//            4'h5: temp_seg = 8'b0100_1101; // 5
//            4'h6: temp_seg = 8'b0100_0001; // 6
//            4'h7: temp_seg = 8'b0001_1111; // 7
//            4'h8: temp_seg = 8'b0000_0001; // 8
//            4'h9: temp_seg = 8'b0000_1101; // 9
//            default: temp_seg = 8'b1111_1111; // Blank
//        endcase
//        segments = temp_seg;


    end
    
//       logic [6:0] raw_seg;
//    logic w, x, y, z;
//    assign {w, x, y, z} = number;

//    // Insert either the Active-High or Active-Low continuous assignments here
//    always_comb begin
//        raw_seg[0] = w | y | (x & z) | (~x & ~z); 
//        raw_seg[1] = ~x | (~y & ~z) | (y & z);    
//        raw_seg[2] = x | ~y | z;                  
//        raw_seg[3] = w | (~x & ~z) | (y & ~z) | (x & ~y & z) | (~x & y); 
//        raw_seg[4] = w | (~x & ~z) | (y & ~z);        
//        raw_seg[5] = w | (~y & ~z) | (x & ~y) | (x & ~z); 
//        raw_seg[6] = w | (x ^ y) | (y & ~z);      
        
//        // Cast the optimized flat bits back to your user-defined type
//        segments = SSEG_NUM'(~raw_seg);
//    end
    
    
endmodule
