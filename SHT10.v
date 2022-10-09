/*
//////////////////////////////////////////////////////////////////////////////////////////////////
// Name: 					SHT10																							//
// Author: 					Konstantin M.																				//
// Creation Date:			20.04.2018																					//
//	Date of change:		02.07.2018																					//
//	Version:					1.0																							//
//																																//
//	0.1 Mhz = 500 Tacts ( 50 MHz) 																					//
//	50 MHz = = 0.02 us																									//						//
//																																//
//																																//
//////////////////////////////////////////////////////////////////////////////////////////////////

PIN-OUTS:
-------------------------------------------		
		SHT10								   -				 MAX10 
-------------------------------------------
1:		GND									|		J5 (PIN #30)	- GND
2:		I2C_DATA (I/O)						|		J4	(PIN #3) 	- AA14 	(INPUT/OUTPUT)
3:		I2C_CLK	(I)						|		J5	(PIN #3) 	- C3		(OUTPUT)
4:    VDD									|		J5 (PIN #11)	- 5.0V


*/

module SHT10 (

//DEBUG
output reg						strobe,																					// FOR DEBUG , FOR SIGNAL TAP II

output reg	[3:0]				STATE,
	
output							CLK_2MHZ,

input 							CLK,																						// CLK 50 Mhz (20 ns)
input								SHT10_START,
inout 							I2C_DATA,

output 	 						I2C_CLK,
output reg 	[11:0]			DATA_HUMIDITY,
output 		[9:0]				HUMIDITY_VALUE,
output 		[12:0]			HUMIDITY_BCD
);

/*========================================= GENERAL LOGIC ======================================*/

assign I2C_CLK = Value_CLK;
assign I2C_DATA  = (I2C_DATA_ENABLE) ? 1'bz : 1'b0;
assign HUMIDITY_BCD[12] = 1'b0;
/*========================================= REGISTERS ==========================================*/
reg							Value_CLK;
reg 							I2C_CLK_ENABLE;																			//
reg							I2C_DATA_ENABLE; 
reg	[5:0]					MHz_2;																						// 
reg							TS;																							// 
//reg	[22:0]				STATE;																						// 
reg	[15:0]				Counter_2MHz;																				// 
reg	[28:0]				CounterGeneral;																			// 
reg							CLK_CONTROL;																				//
reg	[7:0]					COMMAND;																						//
reg	[4:0]					CNT_BITS_COMMAND;																			//
reg	[11:0]				HUMIDITY_CACHE;																			//
reg							BCD_CONTROL;
//reg	[4:0]					;																								// 
//reg							;																								// 
//reg	[4:0]					;																								//

/*========================================= WIRES ==============================================*/

wire 							CLK2MHZ;
/*========================================= STATES =============================================*/

localparam START												= 0;
localparam DELAY_11ms_POWER_UP							= 1;
localparam TRANSMISSION_START								= 2;
localparam COMMAND_EQYALS_MEASURE_HUMIDITY			= 3;
localparam SEND_ADDRESS_MEASUREMENT						= 4;
localparam MEASUREMENT_80ms								= 5;
localparam GET_ACK											= 6;
localparam IDLE_BITS_AND_BITS_4_MSB_HUMIDITY			= 7;
localparam BITS_8_LSB										= 8;
localparam GET_ACK_2											= 9;
localparam SLEEP												= 10;
localparam READSTATUSREGISTERS							= 11;
localparam COMMAND_EQYALS_READ_REGISTERS				= 12;
localparam BCD													= 13;
localparam DELAY												= 15;




/*====================================== CONSTANTS (us) ========================================*/

localparam MHz_2_Value										= 24;
localparam ms_11												= 11000000;
localparam ms_80												= 16000000;
localparam measureRH											= 8'b000_00101; // 8'b000_00101;
localparam measureT											= 8'b000_00011;
localparam MHz_0_1											= 499;
localparam DELAY_TEST										= 1999;
localparam DELAY_6sec										= 300_000_000;
localparam FINISH_TIME										= 999;
//localparam us_70												= ;
//localparam us_960												= ;
//localparam s_5													= ;

/*====================================== ROM COMMANDS ==========================================*/

localparam MEASURE_TEMPErATURE							= 8'b000_00011;												// 
localparam MEASURE_HUMIDITY								= 8'b000_00101;												//
localparam READ_STATUS_REGISTERS						= 8'b000_00111;	 
//


initial 
	begin
		STATE <= 15;
	end
/*==============================================================================================*/
/*========================================= ALWAYS =============================================*/
/*==============================================================================================*/

/*=================================== Counter for 2MHz (500ns) =================================*/

//always @ (posedge CLK)
//	 if (Counter == MHz_2)																									// 24 = 2MHz (500ns)
//		begin
//			Counter <= 1'b0;
//			strobe <= 1'b1;
//		end
//	 else
//		begin
//			Counter <= Counter + 1'b1;
//		strobe <= 1'b0;
//		end
/*=================================== Counter General ==========================================*/

always @ (posedge CLK)
		begin
				if (STATE == DELAY_11ms_POWER_UP)
					begin
						if (CounterGeneral == 550000)
							CounterGeneral <= 0;
						else
							CounterGeneral <= CounterGeneral + 1'b1;
					end
		   else if (STATE == TRANSMISSION_START)
					begin
						if (CounterGeneral == 999)	// 750
							CounterGeneral <= 0;
						else
							CounterGeneral <= CounterGeneral + 1'b1;
					end
			else if (STATE == SEND_ADDRESS_MEASUREMENT || STATE == IDLE_BITS_AND_BITS_4_MSB_HUMIDITY || STATE == READSTATUSREGISTERS)
					begin
						if (CounterGeneral == 499)
							CounterGeneral <= 0;
						else
							CounterGeneral <= CounterGeneral + 1'b1;
					end
			else if (STATE == MEASUREMENT_80ms)
					begin
						if (CounterGeneral == ms_80)
							CounterGeneral <= 0;
						else
							CounterGeneral <= CounterGeneral + 1'b1;
					end
			else if (STATE == DELAY)
					begin
						if (CounterGeneral == DELAY_6sec)
							CounterGeneral <= 0;
						else
							CounterGeneral <= CounterGeneral + 1'b1;
					end
			
			else if (STATE == BCD)
					begin
						if (CounterGeneral == 76)
							CounterGeneral <= 0;
						else
							CounterGeneral <= CounterGeneral + 1'b1;
					end
					
			end


/*=================================== I2C_CLK ==========================================*/

//assign I2C_CLK = (I2C_CLK_ENABLE) ? CLK2MHZ : (CLK_CONTROL) ? 1'b1 : 1'b0;

always @ (posedge CLK)
		begin
			if (STATE == DELAY_11ms_POWER_UP)
				begin
					I2C_CLK_ENABLE <= 1'b1;
				end
//////////////////////////////////////////////////////////////////////////////////////////				
//			else if (STATE == TRANSMISSION_START)
//				begin
//					if (CounterGeneral <= 1249)
//						Value_CLK <= 1'b1;
//					else if (CounterGeneral >= 1250 && CounterGeneral <= 1499)
//						Value_CLK <= 1'b0;
//					else if (CounterGeneral >= 1500 && CounterGeneral <= 2749)
//						Value_CLK <= 1'b1;
//					else if (CounterGeneral >= FINISH_TIME)
//						Value_CLK <= 1'b0;
//				end
//////////////////////////////////////////////////////////////////////////////////////////			
			else if (STATE == TRANSMISSION_START)
				begin
					if (CounterGeneral <= 249)
						Value_CLK <= 1'b1;
					else if (CounterGeneral >= 250 && CounterGeneral <= 499)
						Value_CLK <= 1'b0;
					else if (CounterGeneral >= 500 && CounterGeneral <= 749)
						Value_CLK <= 1'b1;
					else if (CounterGeneral >= 750 && CounterGeneral <= FINISH_TIME)
						Value_CLK <= 1'b0;
				end
//////////////////////////////////////////////////////////////////////////////////////////			
			else if (STATE == SEND_ADDRESS_MEASUREMENT)
				begin
						if (CounterGeneral >= 8 && CounterGeneral <= 249 && CNT_BITS_COMMAND <= 8)
							Value_CLK <= 1'b1;
						else if (CounterGeneral >= 250 && CounterGeneral <= 499 && CNT_BITS_COMMAND <= 8)
							Value_CLK <= 1'b0;
				end
				
			else if (STATE == READSTATUSREGISTERS)
				begin
						if (CounterGeneral <= 249 && CNT_BITS_COMMAND <= 8)
							Value_CLK <= 1'b1;
						else if (CounterGeneral >= 250 && CounterGeneral <= 499 && CNT_BITS_COMMAND <= 8)
							Value_CLK <= 1'b0;
				end
//////////////////////////////////////////////////////////////////////////////////////////				
			else if (STATE == DELAY)
						begin
							Value_CLK <= 1'b0;
						end
//////////////////////////////////////////////////////////////////////////////////////////

			else if (STATE == IDLE_BITS_AND_BITS_4_MSB_HUMIDITY)
						begin
								if (CounterGeneral >= 2 && CounterGeneral <= 249 && CNT_BITS_COMMAND <= 7)
									Value_CLK <= 1'b1;
								else if (CounterGeneral >= 250 && CounterGeneral <= 499 && CNT_BITS_COMMAND <= 7)
									Value_CLK <= 1'b0;
								else if (CNT_BITS_COMMAND == 8)
									Value_CLK <= 1'b0;
								else if (CounterGeneral >= 2 && CounterGeneral <= 249 && CNT_BITS_COMMAND == 9)
									Value_CLK <= 1'b1;
								else if (CounterGeneral >= 250 && CounterGeneral <= 499 && CNT_BITS_COMMAND == 9)
									Value_CLK <= 1'b0;
								else if (CounterGeneral >= 2 && CounterGeneral <= 249 && CNT_BITS_COMMAND >= 10 && CNT_BITS_COMMAND <= 17)
									Value_CLK <= 1'b1;
								else if (CounterGeneral >= 250 && CounterGeneral <= 499 && CNT_BITS_COMMAND >= 10 && CNT_BITS_COMMAND <= 17)
									Value_CLK <= 1'b0;
								else if (CNT_BITS_COMMAND == 18)
									Value_CLK <= 1'b0;
								else if (CounterGeneral >= 2 && CounterGeneral <= 249 && CNT_BITS_COMMAND == 19)
									Value_CLK <= 1'b1;
								else if (CounterGeneral >= 250 && CounterGeneral <= 499 && CNT_BITS_COMMAND == 19)
									Value_CLK <= 1'b0;
								
//////////////////////////////////////////////////////////////////////////////////////////

			else if (STATE == DELAY)
				begin
					Value_CLK <= 1'b0;
				end
						end
		end

/*=================================== I2C_DATA ==========================================*/

//assign I2C_DATA  = (I2C_DATA_ENABLE) ? 1'bz(1'b1) : 1'b0; // 1= 1'bz, 0 = 1'b0;

always @ (posedge CLK)
			begin
				if (STATE == DELAY_11ms_POWER_UP || STATE == READSTATUSREGISTERS)
					begin
						I2C_DATA_ENABLE <= 1'b1;
					end
					
       else if (STATE == TRANSMISSION_START)
					begin
					if (CounterGeneral >= 125 && CounterGeneral <= 625)
						I2C_DATA_ENABLE <= 1'b0;
					else 
						I2C_DATA_ENABLE <= 1'b1;					
					end
					
		else if (STATE == SEND_ADDRESS_MEASUREMENT)
//					begin
//						if (CNT_BITS_COMMAND <= 7)
							begin
								if (CounterGeneral <= 249 && COMMAND[7] == 1'b1 && CNT_BITS_COMMAND <= 7)
									I2C_DATA_ENABLE <= 1'b1;
								if (CounterGeneral <= 249 && COMMAND[7] == 1'b0 && CNT_BITS_COMMAND <= 7)
									I2C_DATA_ENABLE <= 1'b0;
								else if (CounterGeneral >= 249 && CounterGeneral <= 499 && COMMAND[7] == 1'b1 && CNT_BITS_COMMAND <= 7)
									I2C_DATA_ENABLE <= 1'b1;
								else if (CounterGeneral >= 249 && CounterGeneral <= 499 && COMMAND[7] == 1'b0 && CNT_BITS_COMMAND <= 7)
									I2C_DATA_ENABLE <= 1'b0;
//							end
						else if (CNT_BITS_COMMAND == 8) 
							I2C_DATA_ENABLE <= 1'b1;
					end
					
		else if (STATE == MEASUREMENT_80ms)
					begin
						I2C_DATA_ENABLE <= 1'b1;
					end
					
		else if (STATE == DELAY)
				begin
					I2C_DATA_ENABLE <= 1'b1;
				end
		
		else if (STATE == IDLE_BITS_AND_BITS_4_MSB_HUMIDITY)
				begin
					if (CNT_BITS_COMMAND == 8 )
						I2C_DATA_ENABLE <= 1'b1;
					else if (CNT_BITS_COMMAND == 9 )
						I2C_DATA_ENABLE <= 1'b0;
					else if (CNT_BITS_COMMAND >= 10 && CNT_BITS_COMMAND <= 19)
						I2C_DATA_ENABLE <= 1'b1;
				end
				
			
			end
/*=================================== COMMANDS ==========================================*/

always @ (posedge CLK)
		begin
			if (STATE == COMMAND_EQYALS_MEASURE_HUMIDITY)
				COMMAND <= measureRH;
			
			else if (STATE == COMMAND_EQYALS_READ_REGISTERS)
				COMMAND <= READ_STATUS_REGISTERS;
				
			else if (STATE == SEND_ADDRESS_MEASUREMENT)
				begin
							if (CNT_BITS_COMMAND <= 8 && CounterGeneral == 499 )
								begin
									COMMAND <= COMMAND << 1;
									CNT_BITS_COMMAND <= CNT_BITS_COMMAND + 1'b1;
								end
							else if (CNT_BITS_COMMAND == 9 )
									CNT_BITS_COMMAND <= 0;
				end
				
			else if (STATE == DELAY_11ms_POWER_UP || STATE == MEASUREMENT_80ms)
					  begin
						CNT_BITS_COMMAND <= 0;
					  end
					  
			else if (STATE == IDLE_BITS_AND_BITS_4_MSB_HUMIDITY || STATE == READSTATUSREGISTERS)
						begin
							if (CNT_BITS_COMMAND <= 19 && CounterGeneral == 499)
								begin
									CNT_BITS_COMMAND <= CNT_BITS_COMMAND + 1'b1;
								end
						end
			
		end
/*=================================== HUMIDITY DATA ==========================================*/

always @ (posedge CLK)
		begin
			if (STATE == IDLE_BITS_AND_BITS_4_MSB_HUMIDITY)
				begin
					if (CounterGeneral == 0 && I2C_DATA == 1'b1 && CNT_BITS_COMMAND >= 4 && CNT_BITS_COMMAND <= 7)
							HUMIDITY_CACHE[0] <= 1'b1;
					else if (CounterGeneral == 0 && I2C_DATA == 1'b1 && CNT_BITS_COMMAND >= 10 && CNT_BITS_COMMAND <= 17)
							HUMIDITY_CACHE[0] <= 1'b1;
					else if (CounterGeneral == 0 && I2C_DATA == 1'b0 && CNT_BITS_COMMAND >= 4 && CNT_BITS_COMMAND <= 7)
							HUMIDITY_CACHE[0] <= 1'b0;
					else if (CounterGeneral == 0 && I2C_DATA == 1'b0 && CNT_BITS_COMMAND >= 10 && CNT_BITS_COMMAND <= 17)
							HUMIDITY_CACHE[0] <= 1'b0;		
					else if (CounterGeneral == 255 && CNT_BITS_COMMAND >= 4 && CNT_BITS_COMMAND <= 7)
							HUMIDITY_CACHE <= HUMIDITY_CACHE << 1;
					else if (CounterGeneral == 255 && CNT_BITS_COMMAND >= 10 && CNT_BITS_COMMAND <= 16)
							HUMIDITY_CACHE <= HUMIDITY_CACHE << 1;
					else if (CNT_BITS_COMMAND == 20)
							 DATA_HUMIDITY <= HUMIDITY_CACHE;
				end
//			if (STATE == SEND_HUMIDITY_TO_SHT10)
//				begin
//					
//				end
		end

/*=================================== BCD DATA ==========================================*/

always @ (posedge CLK)
				begin
					if (STATE == BCD)
						begin
							if (CounterGeneral <= 2)
								BCD_CONTROL <= 1'b1;
							else
								BCD_CONTROL <= 1'b0;
						end
				end

/*=================================== MAIN LOGIC ===============================================*/

always @ (posedge CLK)
			begin
				case (STATE)
DELAY:																																	// 15
							begin
								if (CounterGeneral == DELAY_6sec)
										STATE <= DELAY_11ms_POWER_UP;
									
							end	
DELAY_11ms_POWER_UP:																													// 1
							begin
								if (CounterGeneral == 550000)
									STATE <= TRANSMISSION_START;
									
							end
TRANSMISSION_START:																													// 2
							begin
								if (CounterGeneral == FINISH_TIME)
									STATE <= COMMAND_EQYALS_MEASURE_HUMIDITY;			
							end
//DELAY:																																	// 15
//							begin
//								if (CounterGeneral == DELAY_TEST)
//									STATE <= COMMAND_EQYALS_MEASURE_HUMIDITY;			
//							end														
COMMAND_EQYALS_MEASURE_HUMIDITY:																									// 3
							begin
									STATE <= SEND_ADDRESS_MEASUREMENT;
							end
//COMMAND_EQYALS_READ_REGISTERS:																									// 12
//							begin
//									STATE <= SEND_ADDRESS_MEASUREMENT;
//							end														
SEND_ADDRESS_MEASUREMENT:																											// 4
							begin
								if (CNT_BITS_COMMAND == 9)
									STATE <= MEASUREMENT_80ms;
							end
//SEND_ADDRESS_MEASUREMENT:																										// 4
//							begin
//								if (CNT_BITS_COMMAND == 9)
//									STATE <= READSTATUSREGISTERS;
//							end
MEASUREMENT_80ms: 																													// 5
							begin
								if (CounterGeneral == ms_80)
									STATE <= IDLE_BITS_AND_BITS_4_MSB_HUMIDITY;
									
							end
IDLE_BITS_AND_BITS_4_MSB_HUMIDITY: 																								// 7
							begin
								if (CNT_BITS_COMMAND == 20)
										STATE <= BCD;
							end
BCD:
							begin
								if (CounterGeneral == 76)
									STATE <= DELAY;
							end
//READSTATUSREGISTERS:																												// 11
//							begin
//								if (CNT_BITS_COMMAND == 9)
//									STATE <= DELAY;
//							end
							
				endcase
			end

Binary_to_BCD_Humidity BCD_temp
  (
.i_Clock					(CLK),
.i_Binary				(HUMIDITY_VALUE),
.i_Start					(BCD_CONTROL),
   //
.o_BCD					(HUMIDITY_BCD),
.o_DV						()
 );

HUMIDITY_WIDE Convert_to_RealHumidity (
	.address		(DATA_HUMIDITY),
	.clock			(CLK),
	
	.q				(HUMIDITY_VALUE)
);

/*
X = 1'b0
1 = 1'b1
0000_0000_0000_000X		// 0		// RECORD
0000_0000_0000_00X0		// 0		// SHIFT
0000_0000_0000_00XX		// 0-1	// RECORD
0000_0000_0000_0XX0		// 1		// SHIFT
0000_0000_0000_0XXX    	// 1-2	// RECORD
0000_0000_0000_XXX0		// 2		// SHIFT
0000_0000_0000_XXXX		// 2-3	// RECORD
0000_0000_000X_XXX0		// 3		// SHIFT
0000_0000_000X_XXXX		// 3-4	// RECORD
0000_0000_00XX_XXX0		// 4		// SHIFT
0000_0000_00XX_XXX1		// 4-5	// RECORD			// 1
0000_0000_0XXX_XX10		// 5		// SHIFT				// 2
0000_0000_0XXX_XX11		// 5-6	// RECORD			// 3
0000_0000_XXXX_X110		// 6		// SHIFT				// 6
0000_0000_XXXX_X111		// 6-7	// RECORD			// 7
0000_000X_XXXX_1110		// 7		// SHIFT				// 14
0000_0000_0000_0000		// 7-8	// RECORD
0000_0000_0000_0000		// 8		// SHIFT
0000_0000_0000_0000		// 8-9	// RECORD
0000_0000_0000_0000		// 9		// SHIFT
0000_0000_0000_0000		// 9-10	// RECORD
0000_0000_0000_0000		// 10		// SHIFT
0000_0000_0000_0000		// 10-11	// RECORD
0000_0000_0000_0000		// 11		// SHIFT
0000_0000_0000_0000		// 11-12	// RECORD
0000_0000_0000_0000		// 12		// SHIFT
0000_0000_0000_0000		// 12-13	// RECORD
0000_0000_0000_0000		// 13		// SHIFT
0000_0000_0000_0000		// 13-14	// RECORD
0000_0000_0000_0000		// 14		// SHIFT
0000_0000_0000_0000		// 14-15	// RECORD
0000_0000_0000_0000		// 15		// SHIFT
0000_0000_0000_0000		// 15-16	// RECORD

*/

endmodule