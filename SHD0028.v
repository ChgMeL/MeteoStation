/*
PIN-OUTS:
-------------------------------------------		
		SHD0028								-				MAX10
-------------------------------------------
		GND									|		J4 (PIN #7)	- GND
		POWER									|		J4	(PIN #1) - 3.3V
		INPUT	(SHD0028_DATA)	 			|		J4	(PIN #5) - AA15
		CLOCK (SHD0028_CLK)				|		J4 (PIN #6) - Y16
		LATCH	(SHD0028_LATCH)			|		J5	(PIN #1)	- B2
		ENABLE_n (SHD0028_ENABLE_n)	|		J5	(PIN #2)	- B1

TABLE_DIGITS:
-------------------------------------------
	 76543210; 			BITS (0-th BIT - POINT)
-------------------------------------------
0 : 11111100;
1 : 01100000;
2 : 11011010;
3 : 11110010;
4 : 01100110;
5 : 10110110;
6 : 10111110;
7 : 11100000;
8 : 11111110;
9 : 11110110;
* : 11000110;
C : 10011100;
R : 11101110;
H : 01101100;
- : 00000010;

*C : 11000110_10011100;
RH : 11101110_01101100;


//--------------SERIAL_IN:------------//

[47:40]	- Minus/Plus sector
[39:32]	- Tens sector
[31:24]	- Units	sector
[23:16]	- Tenths	sector
[15:8]	- Sign_measurment_1 degree or humidity sector
[7:0]		- Sign_measurment_2 degree or humidity sector

*/
module SHD0028 (

input 						CLK,
input			[23:0]		DATA,
//input			[23:0]		DATA_RTC,		// 02.07.2019
input							TEMP_OR_RTC,
input							DATA_RTC,
						
output reg					SHD0028_DATA,
output						SHD0028_CLK,														// 25 Mhz
output reg					SHD0028_LATCH_n,
output reg					SHD0028_ENABLE_n
//output reg					CLK_25MHz,
//output reg	[31:0]		SERIAL_IN,			
);


reg			[6:0]			CNT;																	// General Counter
reg			[47:0]		SERIAL_IN;
reg			[6:0]			CNT_BITS;															// All time scale devided to CNT_BITS ~
reg 							SHD0028_ENABLE;													// Enable clock for SHD0028
reg							CLK_25MHz;

/*==============================================================================================*/
/*========================================= ALWAYS =============================================*/
/*==============================================================================================*/

/*====================================== Counter for 25MHz =====================================*/

always @ (posedge CLK)
	begin
				if (CLK_25MHz == 1 )
					CLK_25MHz <= 1'b0;
				else
					CLK_25MHz <= CLK_25MHz + 1'b1;
	end

/*====================================== GENERAL LOGIC ========================================*/
	
always @ (posedge CLK)
	begin
		if (CLK_25MHz == 1'b1)
			begin
				if (CNT_BITS <= 47)			// 31		/47
					begin
						SHD0028_LATCH_n <= 1'b0;
						SHD0028_ENABLE_n <= 1'b0;
						SHD0028_DATA <= SERIAL_IN[0];
						SHD0028_ENABLE <= 1'b1;
						CNT_BITS <= CNT_BITS + 1'b1;
					end
				else if (CNT_BITS == 48)				// 32		48
					begin
						SHD0028_LATCH_n <= 1'b1;
						SHD0028_ENABLE <= 1'b0;
//						SHD0028_ENABLE_n <= 1'b0;
						SHD0028_DATA <= 1'b0;
						CNT_BITS <= CNT_BITS + 1'b1;
					end
				else if (CNT_BITS >= 49 && CNT_BITS <= 51)		// 33	35 // 49 51
					begin
						SHD0028_LATCH_n <= 1'b0;
//						SHD0028_ENABLE_n <= 1'b0;
						CNT_BITS <= CNT_BITS + 1'b1;
					end
				else if (CNT_BITS >= 52 && CNT_BITS <= 57)			// 36 41 // 52 57
					begin
//						SHD0028_ENABLE_n <= 1'b0;
						CNT_BITS <= CNT_BITS + 1'b1;
					end
				else
					CNT_BITS <= 0;
			end
	end
/*====================================== SHIFT REGISTER ========================================*/
/*============================================ & ===============================================*/
/*========================================= DECODER ============================================*/	// Decode DATA from DS18B20 to LED indicators	
//always @ (negedge CLK)
//	begin
//		if (CLK_25MHz == 1'b1)
//			begin
//				if (CNT_BITS > 0 && CNT_BITS <= 48)	// 32 // 48													// SHIFT REGISTER
//					begin
//						SERIAL_IN[47:0] <= {SERIAL_IN[0],SERIAL_IN[47:1]};	//31 // 47
//					end
//					
//				else if (CNT_BITS == 0)																					// DECODER
//					begin
//						case (DATA[15:4])
//							12'd1: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd2: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd3: SERIAL_IN [47:24] <= 24'b00000000_00000000_11011011;
//							12'd4: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd5: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd6: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd7: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd8: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd9: SERIAL_IN [47:24] <= 24'b00000000_00000000_01100001;
//							12'd10: SERIAL_IN [47:24] <= 24'b00000000_01100000_11111101;
//							12'd11: SERIAL_IN [47:24] <= 24'b00000000_01100000_01100001;
//							12'd12: SERIAL_IN [47:24] <= 24'b00000000_01100000_11011011;
//							12'd13: SERIAL_IN [47:24] <= 24'b00000000_01100000_11110011;
//							12'd14: SERIAL_IN [47:24] <= 24'b00000000_01100000_01100111;
//							12'd15: SERIAL_IN [47:24] <= 24'b00000000_01100000_10110111;
//							12'd16: SERIAL_IN [47:24] <= 24'b00000000_01100000_10111111;
//							12'd17: SERIAL_IN [47:24] <= 24'b00000000_01100000_11100001;
//							12'd18: SERIAL_IN [47:24] <= 24'b00000000_01100000_11111111;
//							12'd19: SERIAL_IN [47:24] <= 24'b00000000_01100000_11110111;
//							12'd20: SERIAL_IN [47:24] <= 24'b00000000_11011010_11111101;
//							12'd21: SERIAL_IN [47:24] <= 24'b00000000_11011010_01100001;
//							12'd22: SERIAL_IN [47:24] <= 24'b00000000_11011010_11011011;
//							12'd23: SERIAL_IN [47:24] <= 24'b00000000_11011010_11110011;
//							12'd24: SERIAL_IN [47:24] <= 24'b00000000_11011010_01100111;
//							12'd25: SERIAL_IN [47:24] <= 24'b00000000_11011010_10110111;
//							12'd26: SERIAL_IN [47:24] <= 24'b00000000_11011010_10111111;
//							12'd27: SERIAL_IN [47:24] <= 24'b00000000_11011010_11100001;
//							12'd28: SERIAL_IN [47:24] <= 24'b00000000_11011010_11111111;
//							12'd29: SERIAL_IN [47:24] <= 24'b00000000_11011010_11110111;
//							12'd30: SERIAL_IN [47:24] <= 24'b00000000_11110010_11111101;
//							12'd31: SERIAL_IN [47:24] <= 24'b00000000_11110010_01100001;
//							12'd32: SERIAL_IN [47:24] <= 24'b00000000_11110010_11011011;
//							12'd33: SERIAL_IN [47:24] <= 24'b00000000_11110010_11110011;
//							12'd34: SERIAL_IN [47:24] <= 24'b00000000_11110010_01100111;
//							12'd35: SERIAL_IN [47:24] <= 24'b00000000_11110010_10110111;
//							12'd36: SERIAL_IN [47:24] <= 24'b00000000_11110010_10111111;
//							12'd37: SERIAL_IN [47:24] <= 24'b00000000_11110010_11100001;
//							12'd38: SERIAL_IN [47:24] <= 24'b00000000_11110010_11111111;
//							12'd39: SERIAL_IN [47:24] <= 24'b00000000_11110010_11110111;
//							12'd40: SERIAL_IN [47:24] <= 24'b00000000_01100110_11111101;
//						endcase
//						case (DATA[3:0])
//							4'd0: SERIAL_IN[23:16] <= 8'b11111100;			//	0
//							4'd1: SERIAL_IN[23:16] <= 8'b01100000;			//	1
//							4'd2: SERIAL_IN[23:16] <= 8'b01100000;			//	1
//							4'd3: SERIAL_IN[23:16] <= 8'b11011010;			//	2
//							4'd4: SERIAL_IN[23:16] <= 8'b11011010;			// 2
//							4'd5: SERIAL_IN[23:16] <= 8'b11110010;			// 3
//							4'd6: SERIAL_IN[23:16] <= 8'b01100110;			// 4
//							4'd7: SERIAL_IN[23:16] <= 8'b01100110;			// 4
//							4'd8: SERIAL_IN[23:16] <= 8'b10110110;			// 5
//							4'd9: SERIAL_IN[23:16] <= 8'b10111110;			// 6
//							4'd10: SERIAL_IN[23:16] <= 8'b10111110;		// 6
//							4'd11: SERIAL_IN[23:16] <= 8'b11100000;		// 7
//							4'd12: SERIAL_IN[23:16] <= 8'b11100000;		// 7
//							4'd13: SERIAL_IN[23:16] <= 8'b11111110;		//	8
//							4'd14: SERIAL_IN[23:16] <= 8'b11111110;		// 8
//							4'd15: SERIAL_IN[23:16] <= 8'b11110110;		// 9
//						endcase
//							SERIAL_IN[15:0] <= 16'b11000110_10011100;		// *C
//					end
//			end
//	end
/*========================================= DECODER_v2 (BCD_to__SHD0028) ============================================*/	// Decode DATA from DS18B20 to LED indicators	
always @ (negedge CLK)
	begin
		if (CLK_25MHz == 1'b1)
			begin
				if (CNT_BITS > 0 && CNT_BITS <= 48)	// 32 // 48													// SHIFT REGISTER
					begin
						SERIAL_IN[47:0] <= {SERIAL_IN[0],SERIAL_IN[47:1]};	//31 // 47
					end
					
				else if (CNT_BITS == 0 && TEMP_OR_RTC == 1)																					// DECODER
					begin
						case (DATA[11:8])
							4'd0 : SERIAL_IN[39:32] <= 8'b00000000;
							4'd1 : SERIAL_IN[39:32] <= 8'b01100000;
							4'd2 : SERIAL_IN[39:32] <= 8'b11011010;
							4'd3 : SERIAL_IN[39:32] <= 8'b11110010;
							4'd4 : SERIAL_IN[39:32] <= 8'b01100110;
							4'd5 : SERIAL_IN[39:32] <= 8'b10110110;
							4'd6 : SERIAL_IN[39:32] <= 8'b10111110;
							4'd7 : SERIAL_IN[39:32] <= 8'b11100000;
							4'd8 : SERIAL_IN[39:32] <= 8'b11111110;
							4'd9 : SERIAL_IN[39:32] <= 8'b11110110;
						endcase
						
						case (DATA[7:4])
							4'd0 : SERIAL_IN[31:24] <= 8'b11111101;
							4'd1 : SERIAL_IN[31:24] <= 8'b01100001;
							4'd2 : SERIAL_IN[31:24] <= 8'b11011011;
							4'd3 : SERIAL_IN[31:24] <= 8'b11110011;
							4'd4 : SERIAL_IN[31:24] <= 8'b01100111;
							4'd5 : SERIAL_IN[31:24] <= 8'b10110111;
							4'd6 : SERIAL_IN[31:24] <= 8'b10111111;
							4'd7 : SERIAL_IN[31:24] <= 8'b11100001;
							4'd8 : SERIAL_IN[31:24] <= 8'b11111111;
							4'd9 : SERIAL_IN[31:24] <= 8'b11110111;
						endcase
						
						case (DATA[3:0])
							4'd0 : SERIAL_IN[23:16] <= 8'b11111100;
							4'd1 : SERIAL_IN[23:16] <= 8'b01100000;
							4'd2 : SERIAL_IN[23:16] <= 8'b11011010;
							4'd3 : SERIAL_IN[23:16] <= 8'b11110010;
							4'd4 : SERIAL_IN[23:16] <= 8'b01100110;
							4'd5 : SERIAL_IN[23:16] <= 8'b10110110;
							4'd6 : SERIAL_IN[23:16] <= 8'b10111110;
							4'd7 : SERIAL_IN[23:16] <= 8'b11100000;
							4'd8 : SERIAL_IN[23:16] <= 8'b11111110;
							4'd9 : SERIAL_IN[23:16] <= 8'b11110110;
						endcase
						
						case (DATA[12])
							4'd0 : SERIAL_IN[15:0] <= 16'b00001010_01101110;	// rH
							//4'd0 : SERIAL_IN[15:0] <= 16'b11000110_00111010;	// %
							4'd1 : SERIAL_IN[15:0] <= 16'b11000110_10011100;	// *C
						endcase
						
						case (DATA[13])
							4'd0 : SERIAL_IN[47:40] <= 8'b00000000;					// Empty
							4'd1 : SERIAL_IN[47:40] <= 8'b00000010;					// "-"	
						endcase
//							SERIAL_IN[15:0] <= 16'b11000110_10011100;		// *C
							//SERIAL_IN[15:0] <= 16'b11101110_01101110;		// RH
							//SERIAL_IN[15:0] <= 16'b11000110_00111010;	// %
							//SERIAL_IN[15:0] <= 16'b00001010_01101110;		// rH
					 end
					else if (CNT_BITS == 0 && TEMP_OR_RTC == 0)
						begin
							case (DATA[3:0])								// SEC
								4'd0 : SERIAL_IN[7:0] <= 8'b11111100;
								4'd1 : SERIAL_IN[7:0] <= 8'b01100000;
								4'd2 : SERIAL_IN[7:0] <= 8'b11011010;
								4'd3 : SERIAL_IN[7:0] <= 8'b11110010;
								4'd4 : SERIAL_IN[7:0] <= 8'b01100110;
								4'd5 : SERIAL_IN[7:0] <= 8'b10110110;
								4'd6 : SERIAL_IN[7:0] <= 8'b10111110;
								4'd7 : SERIAL_IN[7:0] <= 8'b11100000;
								4'd8 : SERIAL_IN[7:0] <= 8'b11111110;
								4'd9 : SERIAL_IN[7:0] <= 8'b11110110;		
							endcase
							
							case (DATA[7:4])								// DEC SEC
								4'd0 : SERIAL_IN[15:8] <= 8'b11111100;
								4'd1 : SERIAL_IN[15:8] <= 8'b01100000;
								4'd2 : SERIAL_IN[15:8] <= 8'b11011010;
								4'd3 : SERIAL_IN[15:8] <= 8'b11110010;
								4'd4 : SERIAL_IN[15:8] <= 8'b01100110;
								4'd5 : SERIAL_IN[15:8] <= 8'b10110110;
								4'd6 : SERIAL_IN[15:8] <= 8'b10111110;
								4'd7 : SERIAL_IN[15:8] <= 8'b11100000;
								4'd8 : SERIAL_IN[15:8] <= 8'b11111110;
								4'd9 : SERIAL_IN[15:8] <= 8'b11110110;		
							endcase
							
							case (DATA[11:8])							// MIN
								4'd0 : SERIAL_IN[23:17] <= 7'b1111110;
								4'd1 : SERIAL_IN[23:17] <= 7'b0110000;
								4'd2 : SERIAL_IN[23:17] <= 7'b1101101;
								4'd3 : SERIAL_IN[23:17] <= 7'b1111001;
								4'd4 : SERIAL_IN[23:17] <= 7'b0110011;
								4'd5 : SERIAL_IN[23:17] <= 7'b1011011;
								4'd6 : SERIAL_IN[23:17] <= 7'b1011111;
								4'd7 : SERIAL_IN[23:17] <= 7'b1110000;
								4'd8 : SERIAL_IN[23:17] <= 7'b1111111;
								4'd9 : SERIAL_IN[23:17] <= 7'b1111011;		
							endcase
							
							case (DATA[15:12])							// DEC MIN
								4'd0 : SERIAL_IN[31:24] <= 8'b11111100;
								4'd1 : SERIAL_IN[31:24] <= 8'b01100000;
								4'd2 : SERIAL_IN[31:24] <= 8'b11011010;
								4'd3 : SERIAL_IN[31:24] <= 8'b11110010;
								4'd4 : SERIAL_IN[31:24] <= 8'b01100110;
								4'd5 : SERIAL_IN[31:24] <= 8'b10110110;
								4'd6 : SERIAL_IN[31:24] <= 8'b10111110;
								4'd7 : SERIAL_IN[31:24] <= 8'b11100000;
								4'd8 : SERIAL_IN[31:24] <= 8'b11111110;
								4'd9 : SERIAL_IN[31:24] <= 8'b11110110;		
							endcase
							
							case (DATA[19:16])							//  HOURS
								4'd0 : SERIAL_IN[39:33] <= 7'b1111110;
								4'd1 : SERIAL_IN[39:33] <= 7'b0110000;
								4'd2 : SERIAL_IN[39:33] <= 7'b1101101;
								4'd3 : SERIAL_IN[39:33] <= 7'b1111001;
								4'd4 : SERIAL_IN[39:33] <= 7'b0110011;
								4'd5 : SERIAL_IN[39:33] <= 7'b1011011;
								4'd6 : SERIAL_IN[39:33] <= 7'b1011111;
								4'd7 : SERIAL_IN[39:33] <= 7'b1110000;
								4'd8 : SERIAL_IN[39:33] <= 7'b1111111;
								4'd9 : SERIAL_IN[39:33] <= 7'b1111011;		
							endcase
							
							case (DATA[23:20])							// DEC HOURS
								4'd0 : SERIAL_IN[47:40] <= 8'b11111100;
								4'd1 : SERIAL_IN[47:40] <= 8'b01100000;
								4'd2 : SERIAL_IN[47:40] <= 8'b11011010;
								4'd3 : SERIAL_IN[47:40] <= 8'b11110010;
								4'd4 : SERIAL_IN[47:40] <= 8'b01100110;
								4'd5 : SERIAL_IN[47:40] <= 8'b10110110;
								4'd6 : SERIAL_IN[47:40] <= 8'b10111110;
								4'd7 : SERIAL_IN[47:40] <= 8'b11100000;
								4'd8 : SERIAL_IN[47:40] <= 8'b11111110;
								4'd9 : SERIAL_IN[47:40] <= 8'b11110110;		
							endcase
							
							if (DATA_RTC == 0)
								begin
									SERIAL_IN[16] <= 0;
									SERIAL_IN[32] <= 0;
								end
							else
								begin
									SERIAL_IN[16] <= 1;
									SERIAL_IN[32] <= 1;
								end
							
							
						end
			end
	end
assign	SHD0028_CLK = (SHD0028_ENABLE) ? CLK_25MHz : 1'b0;
	
endmodule