`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2026 05:28:04 PM
// Design Name: 
// Module Name: common
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


package common;

typedef logic [6:0] SEVEN_SEGEMNT_DATA_BUS;

typedef enum logic [6:0] {
    ZERO  = ~7'b0111111,
    ONE   = ~7'b0000110,
    TWO   = ~7'b1011011,
    THREE = ~7'b1001111,
    FOUR  = ~7'b1100110,
    FIVE  = ~7'b1101101,
    SIX   = ~7'b1111101,
    SEVEN = ~7'b0000111,
    EIGHT = ~7'b1111111,
    NINE  = ~7'b1101111,
    A     = ~7'b1110111, // Upper 'A' (Segments a,b,c,e,f,g)
    B     = ~7'b1111100, // Lower 'b' (Segments c,d,e,f,g)
    C     = ~7'b0111001, // Upper 'C' (Segments a,d,e,f)
    D     = ~7'b1011110, // Lower 'd' (Segments b,c,d,e,g)
    E     = ~7'b1111001, // Upper 'E' (Segments a,d,e,f,g)
    F     = ~7'b1110001  // Upper 'F' (Segments a,e,f,g)
} SSEG_NUM;
                         
typedef enum logic [3:0] {IDLE=4'b0000,UPCOUNTINUE_PRESSING_CHECK_1=4'b0001,UPCOUNTINUE_PRESSING_CHECK_2=4'b0010,UPCOUNTINUE_PRESSING_CHECK_3=4'b0100,UPCOUNTINUE_PRESSING_CHECK_4=4'b0101,
                          UPPRESSED=4'b0111,
                          
                          DOWNCOUNTINUE_PRESSING_CHECK_1=4'b1001,DOWNCOUNTINUE_PRESSING_CHECK_2=4'b1010,DOWNCOUNTINUE_PRESSING_CHECK_3=4'b1100,DOWNCOUNTINUE_PRESSING_CHECK_4=4'b1101,
                          DOWNPRESSED=4'b1111
} FSMD_STATE ;    


endpackage : common
