/*
--------------------------------------------------------------------------------------------------------------------
														Module Real Time Clock DS3231
--------------------------------------------------------------------------------------------------------------------	
	Author: 				Malenkov K.S.
	Date begin: 		14.06.2019
	Date end:			02.07.2019
	Version: 			0.300
--------------------------------------------------------------------------------------------------------------------
															HISTORY
--------------------------------------------------------------------------------------------------------------------															
  Version |	   DATE		|												Description															|
====================================================================================================================
	0.000  |	14.06.2019	| Begin Project																									|	
	0.100  |	27.06.2019	| Work algorithm of reading the MSB of Temperature														|
	0.110  |	27.06.2019	| Work algorithm of reading the MSB of Temperature and LSB Temperature (Double BYTES)		|
	0.200	 | 28.06.2019  | Read all memory from DS3231 and store all in registers												|
	0.300	 | 02.07.2019  | Set the Data and time																							|
	
--------------------------------------------------------------------------------------------------------------------		
	0.00X - Minor Changes
	0.0X0 - Important Changes
	0.X00 - Logic or functional work Changes
	X.000 - Full change or add New elements
	
															PIN-OUTS
															
--------------------------------------------------------------------------------------------------------------------		
		DS3231								|				MAX10 					|		CYCLONE 10 (10CLP025EK00856) DEV KIT	|
--------------------------------------------------------------------------------------------------------------------	
		POWER (3.3V)						|		J4 (PIN #2)		- VCC			|					J10 (PIN #29)	-   VCC			|
		GND									|		J4	(PIN #8) 	- GND			|					J10 (PIN #30)	-   GND			|
		SDA									|		J5	(PIN #6) 	- A3			|					J10 (PIN #32)	-   T4 			|
		SCL									|		J5	(PIN #5) 	- B3			|					J10 (PIN #31)	-   R4 			|
		SQW									|			-//-		 	- NONE		|					J10 (PIN #34)	-   P3			|
		32K									|			-//-		 	- NONE		|					J10 (PIN #33)	-   N3			|

50  MHz = 0.02 us
100 kHz = 10 us (500 tacts)

*/

module RTC_DS3231 (

input 					CLK,						// 50 MHz for Cyclone

output 					RTC_DS3231_SCL,		// Clock of working with DS3231
inout						RTC_DS3231_SDA,		// Data transfer		

output reg 	[7:0]		RTC_SECONDS_SEND,			
output reg 	[7:0]		RTC_MINUTES_SEND,			
output reg 	[7:0]		RTC_HOURS_SEND,				
output reg 	[7:0]		RTC_DAY_SEND,					
output reg 	[7:0]		RTC_DATE_SEND,				
output reg 	[7:0]		RTC_CENTURY_MONTH_SEND,	
output reg 	[7:0]		RTC_YEAR_SEND,
//output 	[7:0]		RTC_ALARM1_SECONDS_SEND,
//output 	[7:0]		RTC_ALARM1_MINUTES_SEND,
//output 	[7:0]		RTC_ALARM1_HOURS_SEND,
//output 	[7:0]		RTC_ALARM1_DAYS_DATE_SEND,
//output 	[7:0]		RTC_ALARM2_MINUTES_SEND,
//output 	[7:0]		RTC_ALARM2_HOURS_SEND,
//output 	[7:0]		RTC_ALARM2_DAYS_DATE_SEND,
//output 	[7:0]		RTC_CONTROL_SEND,
//output 	[7:0]		RTC_CONTROL_STATUS_SEND,
//output 	[7:0]		RTC_OFFSET_SEND,
//output 	[7:0]		RTC_MSB_TEMP_SEND,
//output 	[7:0]		RTC_LSB_TEMP_SEND			

/*========================================= DEBUG ==============================================*/

output reg	[7:0]		STATE
//output reg	[9:0]		general_counter,
//output reg				kHz_100,
//output reg	[7:0]		TEMPERATURE_MSB,
//output reg	[7:0]		TEMPERATURE_LSB
//output reg	[7:0]		RTC_SECONDS,			// Ok
//output reg	[7:0]		RTC_MINUTES,			// Ok
//output reg	[7:0]		RTC_HOURS,				// Ok
//output reg	[7:0]		RTC_DAY,					// Ok
//output reg	[7:0]		RTC_DATE,				// Ok
//output reg	[7:0]		RTC_CENTURY_MONTH,	// Ok
//output reg	[7:0]		RTC_YEAR,
//output reg	[7:0]		RTC_ALARM1_SECONDS,
//output reg	[7:0]		RTC_ALARM1_MINUTES,
//output reg	[7:0]		RTC_ALARM1_HOURS,
//output reg	[7:0]		RTC_ALARM1_DAYS_DATE,
//output reg	[7:0]		RTC_ALARM2_MINUTES,
//output reg	[7:0]		RTC_ALARM2_HOURS,
//output reg	[7:0]		RTC_ALARM2_DAYS_DATE,
//output reg	[7:0]		RTC_CONTROL,
//output reg	[7:0]		RTC_CONTROL_STATUS,
//output reg	[7:0]		RTC_OFFSET,
//output reg	[7:0]		RTC_MSB_TEMP,
//output reg	[7:0]		RTC_LSB_TEMP

);

/*========================================= GENERAL LOGIC ======================================*/

assign RTC_DS3231_SDA = (RTC_DS3231_SDA_EN) ? 1'bz : 1'b0;														// if EN = 1, SDA = 1, if EN = 0 , SDA = 0;
assign RTC_DS3231_SCL = RTC_DS3231_SCL_EN;																			// if EN = 1, SCL = 1, if EN = 0 , SCL = 0;

/*========================================= REGISTERS ==========================================*/

reg				RTC_DS3231_SDA_EN;																						// REG for control SDA signal
reg				RTC_DS3231_SCL_EN;

//reg	[7:0]		STATE;																										// STATES for STATE MACHINE
reg	[8:0]		counter_kHz_100;																							// 50 Mhz/500 = 100kHz (1_1111_0100)
reg				kHz_100;
reg	[9:0]		general_counter;
reg	[27:0]	counter_250ms;
reg	[7:0]		ADDRESS;
reg	[7:0]		CNT_BITS_COMMAND;

reg	[7:0]		RTC_SECONDS;
reg	[7:0]		RTC_MINUTES;
reg	[7:0]		RTC_HOURS;
reg	[7:0]		RTC_DAY;
reg	[7:0]		RTC_DATE;
reg	[7:0]		RTC_CENTURY_MONTH;
reg	[7:0]		RTC_YEAR;
reg	[7:0]		RTC_ALARM1_SECONDS;
reg	[7:0]		RTC_ALARM1_MINUTES;
reg	[7:0]		RTC_ALARM1_HOURS;
reg	[7:0]		RTC_ALARM1_DAYS_DATE;
reg	[7:0]		RTC_ALARM2_MINUTES;
reg	[7:0]		RTC_ALARM2_HOURS;
reg	[7:0]		RTC_ALARM2_DAYS_DATE;
reg	[7:0]		RTC_CONTROL;
reg	[7:0]		RTC_CONTROL_STATUS;
reg	[7:0]		RTC_OFFSET;
reg	[7:0]		RTC_MSB_TEMP;
reg	[7:0]		RTC_LSB_TEMP;

/*========================================= STATES =============================================*/

localparam START = 					 0;	// START COMMAND
localparam COMMAND_SLAVE_ID	 =  1;	// ADDRESS = 1101_0001 (WRITE)
localparam SLAVE_ADDRESS = 		 2;	// WRITE SLAVE ADDRESS
localparam COMMAND_TEMPERATURE =  3;	//	ADDRESS = 0001_0001 (MSB_TEMP)
localparam TEMPERATURE_ADDRESS =  4;	// WRITE ADDRESS MSB_TEMPERATURE
localparam STOP = 					 5;	// STOP COMMAND

localparam START_2 = 				 6;	// START COMMAND
localparam COMMAND_SLAVE_ID_2	 =  7;	// ADDRESS = 1101_0000 (READ)
localparam SLAVE_ADDRESS_2 = 		 8;	// WRITE SLAVE ADDRESS
localparam READ_DATA			 = 	 9;	// READ DATA
localparam STOP_2	=				   10;	// STOP COMMAND

localparam DATA_SEND = 				19;	// SEND DATA TO ANOTHER DEVICE

localparam DELAY =					11;	// DELAY == 250 ms

localparam START_3 = 				12;	// START COMMAND
localparam COMMAND_SLAVE_ID_3 = 	13;	// ADDRESS = 1101_0001 (WRITE)
localparam SLAVE_ADDRESS_3 = 		14;	// WRITE SLAVE ADDRESS
localparam COMMAND_SECONDS = 		15;	//	ADDRESS = 0000_0000 (SECONDS)
localparam SECONDS_ADDRESS =		16;	// WRITE ADDRESS SECONDS
localparam WRITE_DATA =				17;	// WRITE X-Bits														
localparam STOP_3 = 					18;	// STOP COMMAND

localparam DELAY_2 = 				20;	// DELAY == 250 ms

/*========================================= CONSTANTS ==========================================*/
localparam counter_100khz 	= 499; 					//  need +5 tacts for delay of SDA = 504
localparam counter_reset 	= 12_500_000; 			//250ms
localparam WRITE_READ		= 1;						// 1 - WRITE + READ, 0 - ONLY READ

/*================================== SET PARAMETERS =============================*/
localparam SET_SECONDS		= 8'd00;					// 8'b0000_0000;	00 Seconds
localparam SET_MINUTES		= 8'b0100_0101;		// 8'b0001_0000;	40 Minutes			8'h30;
localparam SET_HOURS			= 8'b0001_0001;		// 8'b0001_0001;	11:00 (24h)			8'h11;
localparam SET_DAY			= 8'd1;					// 8'b0000_0010;	1 Day (Monday)
localparam SET_DATE			= 8'b0001_0011;		// 8'b0000_0010;	13 Day by Month 
localparam SET_CENTURY		= 8'd7;					// 8'b0000_0111;	07 Month 2020x Year
localparam SET_YEAR			= 8'b0010_0000;		// 8'b0001_1001;	20th Year

/*========================================= ADDRESS ===========================================*/

localparam MSB_TEMP_ADD = 					8'h11;	//8'b_0001_0001
localparam LSB_TEMP_ADD = 					8'h12; 	//8'b_0001_0010
localparam SLAVE_ADDRESS_READ = 			8'hD1; 	//8'b_1101_0001 ( with WRITE bit) , 8th bit - WRITE - 1; 
localparam SLAVE_ADDRESS_WRITE = 		8'hD0;	//8'b_1101_0000 ( with READ bit) , 8th bit - READ - 0;
localparam SECONDS = 						8'h00;	//8'b_0000_0000

initial
	begin
		STATE = DELAY_2;
	end
	
/*==============================================================================================*/
/*========================================= ALWAYS =============================================*/
/*==============================================================================================*/

/*========================================= MAIN LOGIC =========================================*/

//always @ (posedge CLK)																								 //
//	begin																														 //
//		if (counter_kHz_100 == counter_100khz)		//499															 //
//				begin																											 //
//					counter_kHz_100 <= 0;																				 //	Transfer from 50 Mhz to 100kHz
//					kHz_100 <= 1'b1;																						 //
//				end																											 //
//		else																													 //
//				begin																											 //
//					counter_kHz_100 <= counter_kHz_100 + 1'b1;													 //
//					kHz_100 <= 1'b0;																						 //
//				end
//	end

/*====================================== GENERAL COUNTER =======================================*/
always @ (posedge CLK)
	begin
				if (STATE == START || STATE == START_2 || STATE == START_3 || STATE == SLAVE_ADDRESS || STATE == SLAVE_ADDRESS_2 || STATE == SLAVE_ADDRESS_3 || STATE == READ_DATA || STATE == STOP || STATE == STOP_2 || STATE == STOP_3 || STATE == COMMAND_SLAVE_ID || STATE == COMMAND_TEMPERATURE || STATE == TEMPERATURE_ADDRESS || STATE == COMMAND_SLAVE_ID_2 || STATE == COMMAND_SLAVE_ID_3 || STATE == WRITE_DATA || STATE == COMMAND_SECONDS || STATE == SECONDS_ADDRESS || STATE == DATA_SEND)
					begin
						if (general_counter == 499)
							general_counter <= 0;	
						else
							general_counter <= general_counter + 1'b1;
					end
				else if (STATE == DELAY || STATE == DELAY_2)
					begin
						if (counter_250ms == counter_reset)
							counter_250ms <= 0;
						else
							counter_250ms <= counter_250ms + 1;
					end
	end
/*====================================== SCL CONTROLLER =======================================*/
always @ (posedge CLK)
	begin
				if (STATE == START || STATE == START_2 || STATE == START_3)
					begin
							if (general_counter <= 249)
								RTC_DS3231_SCL_EN <= 1'b1;
							else if (general_counter >= 250 && general_counter <= 499)
								RTC_DS3231_SCL_EN <= 1'b0;
					end
				else if (STATE == SLAVE_ADDRESS || STATE == SLAVE_ADDRESS_2 || STATE == SLAVE_ADDRESS_3 || STATE == READ_DATA || STATE == TEMPERATURE_ADDRESS || STATE == WRITE_DATA || STATE == SECONDS_ADDRESS)
					begin
							if (general_counter >= 0 && general_counter <= 124 && CNT_BITS_COMMAND <= 170)
								RTC_DS3231_SCL_EN <= 1'b0;
							else if (general_counter >= 125 && general_counter <= 374 && CNT_BITS_COMMAND <= 170)
								RTC_DS3231_SCL_EN <= 1'b1;
							else if (general_counter >= 375 && general_counter <= 499 && CNT_BITS_COMMAND <= 170)
								RTC_DS3231_SCL_EN <= 1'b0;
					end
				else if (STATE == STOP || STATE == STOP_2 || STATE == STOP_3)
					begin
							if (general_counter <= 249)
								RTC_DS3231_SCL_EN <= 1'b0;
							else if (general_counter >= 250 && general_counter <= 499)
								RTC_DS3231_SCL_EN <= 1'b1;
				else if (STATE == DELAY)
						begin
							RTC_DS3231_SCL_EN <= 1'b1;	
						end
					end
					
	end

/*====================================== SDA CONTROLLER =======================================*/
always @ (posedge CLK)
	begin				
					if (STATE == START || STATE == START_2 || STATE == START_3)
							begin
								if (general_counter >= 125 && general_counter <= 499)
									RTC_DS3231_SDA_EN <= 1'b0;
								else 
									RTC_DS3231_SDA_EN <= 1'b1;					
							end
							
					else if (STATE == SLAVE_ADDRESS || STATE == SLAVE_ADDRESS_2 || STATE == TEMPERATURE_ADDRESS || STATE == SLAVE_ADDRESS_3 || STATE == SECONDS_ADDRESS)
							begin
								if (ADDRESS[7] == 1 && general_counter <= 499 && CNT_BITS_COMMAND <=7)
									RTC_DS3231_SDA_EN <= 1;
								else if (ADDRESS[7] == 0 && general_counter <= 499 && CNT_BITS_COMMAND <=7)
									RTC_DS3231_SDA_EN <= 0;
								else if (CNT_BITS_COMMAND == 8)
									RTC_DS3231_SDA_EN <= 1;
							end
							
					else if (STATE == READ_DATA)
							begin
								if (CNT_BITS_COMMAND == 8 || CNT_BITS_COMMAND == 17 || CNT_BITS_COMMAND == 26 || CNT_BITS_COMMAND == 35 || CNT_BITS_COMMAND == 44  || CNT_BITS_COMMAND == 53 || CNT_BITS_COMMAND == 62 || CNT_BITS_COMMAND == 71 || CNT_BITS_COMMAND == 80 || CNT_BITS_COMMAND == 89 || CNT_BITS_COMMAND == 98 || CNT_BITS_COMMAND == 107 || CNT_BITS_COMMAND == 116 || CNT_BITS_COMMAND == 125 || CNT_BITS_COMMAND == 134 || CNT_BITS_COMMAND == 143 || CNT_BITS_COMMAND == 152 || CNT_BITS_COMMAND == 161)
									RTC_DS3231_SDA_EN <= 0;
								else
									RTC_DS3231_SDA_EN <= 1;
							end
							
					else if (STATE == STOP || STATE == STOP_2)
							begin
								if (general_counter <= 300)
									RTC_DS3231_SDA_EN <= 1'b0;
								else 
									RTC_DS3231_SDA_EN <= 1'b1;	
							end
							
					else if (STATE == DELAY || STATE == DELAY_2)
							begin
								RTC_DS3231_SDA_EN <= 1'b1;	
							end
							
					else if (STATE == WRITE_DATA)
				begin
					/*========================================= 1st BYTE (RTC SECONDS) =======================================*/
					if (general_counter == 5 && RTC_SECONDS[7] == 1 && CNT_BITS_COMMAND <=7)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_SECONDS[7] == 0 && CNT_BITS_COMMAND <=7)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 8)
						RTC_DS3231_SDA_EN <= 1;
						
					/*======================================== 2nd BYTE (RTC MINUTES) ======================================*/
					
					else if (general_counter == 5 && RTC_MINUTES[7] == 1 && CNT_BITS_COMMAND >= 9 && CNT_BITS_COMMAND <= 16)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_MINUTES[7] == 0 && CNT_BITS_COMMAND >= 9 && CNT_BITS_COMMAND <= 16)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 17)
						RTC_DS3231_SDA_EN <= 1;
						
					/*========================================= 3rd BYTE (RTC HOURS) =======================================*/
					
					else if (general_counter == 5 && RTC_HOURS[7] == 1 && CNT_BITS_COMMAND >= 18 && CNT_BITS_COMMAND <= 25)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_HOURS[7] == 0 && CNT_BITS_COMMAND >= 18 && CNT_BITS_COMMAND <= 25)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 26)
						RTC_DS3231_SDA_EN <= 1;						
					/*========================================== 4th BYTE (RTC DAY) ========================================*/
					
					else if (general_counter == 5 && RTC_DAY[7] == 1 && CNT_BITS_COMMAND >= 27 && CNT_BITS_COMMAND <= 34)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_DAY[7] == 0 && CNT_BITS_COMMAND >= 27 && CNT_BITS_COMMAND <= 34)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 35)
						RTC_DS3231_SDA_EN <= 1;
					/*========================================= 5th BYTE (RTC DATE) =======================================*/
					
					else if (general_counter == 5 && RTC_DATE[7] == 1 && CNT_BITS_COMMAND >= 36 && CNT_BITS_COMMAND <= 43)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_DATE[7] == 0 && CNT_BITS_COMMAND >= 36 && CNT_BITS_COMMAND <= 43)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 44)
						RTC_DS3231_SDA_EN <= 1;
								
					/*===================================== 6th BYTE (RTC Month+Century) ===================================*/
					
					else if (general_counter == 5 && RTC_CENTURY_MONTH[7] == 1 && CNT_BITS_COMMAND >= 45 && CNT_BITS_COMMAND <= 52)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_CENTURY_MONTH[7] == 0 && CNT_BITS_COMMAND >= 45 && CNT_BITS_COMMAND <= 52)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 53)
						RTC_DS3231_SDA_EN <= 1;
						
					/*========================================= 7th BYTE (RTC YEAR) ========================================*/
					
					else if (general_counter == 5 && RTC_YEAR[7] == 1 && CNT_BITS_COMMAND >= 54 && CNT_BITS_COMMAND <= 61)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_YEAR[7] == 0 && CNT_BITS_COMMAND >= 54 && CNT_BITS_COMMAND <= 61)
						RTC_DS3231_SDA_EN <= 0;
					else if (CNT_BITS_COMMAND == 62)
						RTC_DS3231_SDA_EN <= 1;
							
					/*==================================== 8th BYTE (RTC Alarm 1 Seconds) ==================================*/
					
					else if (general_counter == 5 && RTC_ALARM1_SECONDS[7] == 1 && CNT_BITS_COMMAND >= 63 && CNT_BITS_COMMAND <= 70)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM1_SECONDS[7] == 0 && CNT_BITS_COMMAND >= 63 && CNT_BITS_COMMAND <= 70)
						RTC_DS3231_SDA_EN <= 0;
						
					
								
					/*==================================== 9th BYTE (RTC Alarm 1 Minutes) ==================================*/
					
					else if (general_counter == 5 && RTC_ALARM1_MINUTES[7] == 1 && CNT_BITS_COMMAND >= 72 && CNT_BITS_COMMAND <= 79)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM1_MINUTES[7] == 0 && CNT_BITS_COMMAND >= 72 && CNT_BITS_COMMAND <= 79)
						RTC_DS3231_SDA_EN <= 0;
						
					
								
					/*==================================== 10th BYTE (RTC Alarm 1 Hours) ===================================*/
			
					else if (general_counter == 5 && RTC_ALARM1_HOURS[7] == 1 && CNT_BITS_COMMAND >= 81 && CNT_BITS_COMMAND <= 88)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM1_HOURS[7] == 0 && CNT_BITS_COMMAND >= 81 && CNT_BITS_COMMAND <= 88)
						RTC_DS3231_SDA_EN <= 0;
									
					/*===================================  11th BYTE (RTC Alarm 1 Day/Date) =================================*/
					
					else if (general_counter == 5 && RTC_ALARM1_DAYS_DATE[7] == 1 && CNT_BITS_COMMAND >= 90 && CNT_BITS_COMMAND <= 97)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM1_DAYS_DATE[7] == 0 && CNT_BITS_COMMAND >= 90 && CNT_BITS_COMMAND <= 97)
						RTC_DS3231_SDA_EN <= 0;
									
					/*==================================== 12th BYTE (RTC Alarm 2 minutes) ==================================*/
					
					else if (general_counter == 5 && RTC_ALARM2_MINUTES[7] == 1 && CNT_BITS_COMMAND >= 99 && CNT_BITS_COMMAND <= 106)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM2_MINUTES[7] == 0 && CNT_BITS_COMMAND >= 99 && CNT_BITS_COMMAND <= 106)
						RTC_DS3231_SDA_EN <= 0;
						
					
								
					/*===================================== 13th BYTE (RTC Alarm 2 Hours) ====================================*/
					
					else if (general_counter == 5 && RTC_ALARM2_HOURS[7] == 1 && CNT_BITS_COMMAND >= 108 && CNT_BITS_COMMAND <= 115)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM2_HOURS[7] == 0 && CNT_BITS_COMMAND >= 108 && CNT_BITS_COMMAND <= 115)
						RTC_DS3231_SDA_EN <= 0;
					
					
								
					/*==================================  14th BYTE (RTC Alarm 2 Day/Date) ===================================*/
					else if (general_counter == 5 && RTC_ALARM2_DAYS_DATE[7] == 1 && CNT_BITS_COMMAND >= 117 && CNT_BITS_COMMAND <= 124)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_ALARM2_DAYS_DATE[7] == 0 && CNT_BITS_COMMAND >= 117 && CNT_BITS_COMMAND <= 124)
						RTC_DS3231_SDA_EN <= 0;
					
					
						
					/*=======================================  15th BYTE (RTC Control) =======================================*/
					
					else if (general_counter == 5 && RTC_CONTROL[7] == 1 && CNT_BITS_COMMAND >= 126 && CNT_BITS_COMMAND <= 133)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_CONTROL[7] == 0 && CNT_BITS_COMMAND >= 126 && CNT_BITS_COMMAND <= 133)
						RTC_DS3231_SDA_EN <= 0;
					
					
					/*====================================  16th BYTE (RTC Control/Status) ===================================*/
					
					else if (general_counter == 5 && RTC_CONTROL_STATUS[7] == 1 && CNT_BITS_COMMAND >= 135 && CNT_BITS_COMMAND <= 142)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_CONTROL_STATUS[7] == 0 && CNT_BITS_COMMAND >= 135 && CNT_BITS_COMMAND <= 142)
						RTC_DS3231_SDA_EN <= 0;
					
					
											
					/*=====================================  17th BYTE (RTC AgingOffset) =====================================*/
					
					else if (general_counter == 5 && RTC_OFFSET[7] == 1 && CNT_BITS_COMMAND >= 144 && CNT_BITS_COMMAND <= 151)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_OFFSET[7] == 0 && CNT_BITS_COMMAND >= 144 && CNT_BITS_COMMAND <= 151)
						RTC_DS3231_SDA_EN <= 0;
					
					
											
					/*===================================  18th BYTE (RTC MSB_TEMP) ==================================*/
					
					else if (general_counter == 5 && RTC_MSB_TEMP[7] == 1 && CNT_BITS_COMMAND >= 153 && CNT_BITS_COMMAND <= 160)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_MSB_TEMP[7] == 0 && CNT_BITS_COMMAND >= 153 && CNT_BITS_COMMAND <= 160)
						RTC_DS3231_SDA_EN <= 0;
					
					
										
					/*===================================  19th BYTE (RTC LSB_TEMP) =====================================*/
					
					else if (general_counter == 5 && RTC_LSB_TEMP[7] == 1 && CNT_BITS_COMMAND >= 162 && CNT_BITS_COMMAND <= 169)
						RTC_DS3231_SDA_EN <= 1;
					else if (general_counter == 5 && RTC_LSB_TEMP[7] == 0 && CNT_BITS_COMMAND >= 162 && CNT_BITS_COMMAND <= 169)
						RTC_DS3231_SDA_EN <= 0;	
				end
					
	end
/*================================ ADDRESS & CNT_BITS COMMANDS ================================*/
always @ (posedge CLK)
	begin
					if (STATE == SLAVE_ADDRESS || STATE == SLAVE_ADDRESS_2 || STATE == TEMPERATURE_ADDRESS  || STATE == SLAVE_ADDRESS_3 || STATE == SECONDS_ADDRESS)
						begin
						if (CNT_BITS_COMMAND <= 7 && general_counter == 499)
							begin
								ADDRESS[7:0] <= {ADDRESS[6:0],ADDRESS[7],};
								CNT_BITS_COMMAND <= CNT_BITS_COMMAND + 1;
							end
						else if (CNT_BITS_COMMAND == 8 && general_counter == 499 )
							CNT_BITS_COMMAND <= CNT_BITS_COMMAND + 1;
						else if (CNT_BITS_COMMAND == 9)
							CNT_BITS_COMMAND <= 0;
						end
						
					else if (STATE == READ_DATA)
						begin
							if (CNT_BITS_COMMAND <= 170 && general_counter == 499)
								CNT_BITS_COMMAND <= CNT_BITS_COMMAND + 1;
							else if (CNT_BITS_COMMAND == 171)
								CNT_BITS_COMMAND <= 0;
						end
					else if (STATE == WRITE_DATA)
						begin
							if (CNT_BITS_COMMAND <= 61 && general_counter == 499)
								CNT_BITS_COMMAND <= CNT_BITS_COMMAND + 1;
							else if (CNT_BITS_COMMAND == 62)
								CNT_BITS_COMMAND <= 0;
								
						end
					else if (STATE == COMMAND_SLAVE_ID || STATE == COMMAND_SLAVE_ID_3)
						ADDRESS <= SLAVE_ADDRESS_WRITE;
					else if (STATE == COMMAND_SLAVE_ID_2)
						ADDRESS <= SLAVE_ADDRESS_READ;
					else if (STATE == COMMAND_TEMPERATURE || STATE == COMMAND_SECONDS)
						ADDRESS <= SECONDS;
	end
	
/*====================================== DATA READ ======================================*/	
always @ (posedge CLK)
		begin
			if (STATE == READ_DATA)
				begin
					/*========================================= 1st BYTE (RTC SECONDS) =======================================*/
					if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND <=7)
						RTC_SECONDS[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND <=7)
						RTC_SECONDS[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND <=6)
						RTC_SECONDS[7:0] <= {RTC_SECONDS[6:0],RTC_SECONDS[7]};
					
					/*======================================== 2nd BYTE (RTC MINUTES) ======================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 9 && CNT_BITS_COMMAND <= 16)
						RTC_MINUTES[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 9 && CNT_BITS_COMMAND <= 16)
						RTC_MINUTES[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 9 && CNT_BITS_COMMAND <= 15)
						RTC_MINUTES[7:0] <= {RTC_MINUTES[6:0],RTC_MINUTES[7]};
						
					/*========================================= 3rd BYTE (RTC HOURS) =======================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 18 && CNT_BITS_COMMAND <= 25)
						RTC_HOURS[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 18 && CNT_BITS_COMMAND <= 25)
						RTC_HOURS[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 18 && CNT_BITS_COMMAND <= 24)
						RTC_HOURS[7:0] <= {RTC_HOURS[6:0],RTC_HOURS[7]};
								
					/*========================================== 4th BYTE (RTC DAY) ========================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 27 && CNT_BITS_COMMAND <= 34)
						RTC_DAY[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 27 && CNT_BITS_COMMAND <= 34)
						RTC_DAY[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 27 && CNT_BITS_COMMAND <= 33)
						RTC_DAY[7:0] <= {RTC_DAY[6:0],RTC_DAY[7]};
								
					/*========================================= 5th BYTE (RTC DATE) =======================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 36 && CNT_BITS_COMMAND <= 43)
						RTC_DATE[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 36 && CNT_BITS_COMMAND <= 43)
						RTC_DATE[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 36 && CNT_BITS_COMMAND <= 42)
						RTC_DATE[7:0] <= {RTC_DATE[6:0],RTC_DATE[7]};
								
					/*===================================== 6th BYTE (RTC Month+Century) ===================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 45 && CNT_BITS_COMMAND <= 52)
						RTC_CENTURY_MONTH[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 45 && CNT_BITS_COMMAND <= 52)
						RTC_CENTURY_MONTH[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 45 && CNT_BITS_COMMAND <= 51)
						RTC_CENTURY_MONTH[7:0] <= {RTC_CENTURY_MONTH[6:0],RTC_CENTURY_MONTH[7]};
								
					/*========================================= 7th BYTE (RTC YEAR) ========================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 54 && CNT_BITS_COMMAND <= 61)
						RTC_YEAR[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 54 && CNT_BITS_COMMAND <= 61)
						RTC_YEAR[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 54 && CNT_BITS_COMMAND <= 60)
						RTC_YEAR[7:0] <= {RTC_YEAR[6:0],RTC_YEAR[7]};
								
					/*==================================== 8th BYTE (RTC Alarm 1 Seconds) ==================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 63 && CNT_BITS_COMMAND <= 70)
						RTC_ALARM1_SECONDS[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 63 && CNT_BITS_COMMAND <= 70)
						RTC_ALARM1_SECONDS[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 63 && CNT_BITS_COMMAND <= 69)
						RTC_ALARM1_SECONDS[7:0] <= {RTC_ALARM1_SECONDS[6:0],RTC_ALARM1_SECONDS[7]};
								
					/*==================================== 9th BYTE (RTC Alarm 1 Minutes) ==================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 72 && CNT_BITS_COMMAND <= 79)
						RTC_ALARM1_MINUTES[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 72 && CNT_BITS_COMMAND <= 79)
						RTC_ALARM1_MINUTES[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 72 && CNT_BITS_COMMAND <= 78)
						RTC_ALARM1_MINUTES[7:0] <= {RTC_ALARM1_MINUTES[6:0],RTC_ALARM1_MINUTES[7]};
								
					/*==================================== 10th BYTE (RTC Alarm 1 Hours) ===================================*/
			
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 81 && CNT_BITS_COMMAND <= 88)
						RTC_ALARM1_HOURS[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 81 && CNT_BITS_COMMAND <= 88)
						RTC_ALARM1_HOURS[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 81 && CNT_BITS_COMMAND <= 87)
						RTC_ALARM1_HOURS[7:0] <= {RTC_ALARM1_HOURS[6:0],RTC_ALARM1_HOURS[7]};
								
					/*===================================  11th BYTE (RTC Alarm 1 Day/Date) =================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 90 && CNT_BITS_COMMAND <= 97)
						RTC_ALARM1_DAYS_DATE[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 90 && CNT_BITS_COMMAND <= 97)
						RTC_ALARM1_DAYS_DATE[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 90 && CNT_BITS_COMMAND <= 96)
						RTC_ALARM1_DAYS_DATE[7:0] <= {RTC_ALARM1_DAYS_DATE[6:0],RTC_ALARM1_DAYS_DATE[7]};
								
					/*==================================== 12th BYTE (RTC Alarm 2 minutes) ==================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 99 && CNT_BITS_COMMAND <= 106)
						RTC_ALARM2_MINUTES[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 99 && CNT_BITS_COMMAND <= 106)
						RTC_ALARM2_MINUTES[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 99 && CNT_BITS_COMMAND <= 104)
						RTC_ALARM2_MINUTES[7:0] <= {RTC_ALARM2_MINUTES[6:0],RTC_ALARM2_MINUTES[7]};
								
					/*===================================== 13th BYTE (RTC Alarm 2 Hours) ====================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 108 && CNT_BITS_COMMAND <= 115)
						RTC_ALARM2_HOURS[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 108 && CNT_BITS_COMMAND <= 115)
						RTC_ALARM2_HOURS[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 108 && CNT_BITS_COMMAND <= 114)
						RTC_ALARM2_HOURS[7:0] <= {RTC_ALARM2_HOURS[6:0],RTC_ALARM2_HOURS[7]};
								
					/*==================================  14th BYTE (RTC Alarm 2 Day/Date) ===================================*/
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 117 && CNT_BITS_COMMAND <= 124)
						RTC_ALARM2_DAYS_DATE[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 117 && CNT_BITS_COMMAND <= 124)
						RTC_ALARM2_DAYS_DATE[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 117 && CNT_BITS_COMMAND <= 123)
						RTC_ALARM2_DAYS_DATE[7:0] <= {RTC_ALARM2_DAYS_DATE[6:0],RTC_ALARM2_DAYS_DATE[7]};
						
					/*=======================================  15th BYTE (RTC Control) =======================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 126 && CNT_BITS_COMMAND <= 133)
						RTC_CONTROL[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 126 && CNT_BITS_COMMAND <= 133)
						RTC_CONTROL[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 126 && CNT_BITS_COMMAND <= 132)
						RTC_CONTROL[7:0] <= {RTC_CONTROL[6:0],RTC_CONTROL[7]};
											
					/*====================================  16th BYTE (RTC Control/Status) ===================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 135 && CNT_BITS_COMMAND <= 142)
						RTC_CONTROL_STATUS[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 135 && CNT_BITS_COMMAND <= 142)
						RTC_CONTROL_STATUS[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 135 && CNT_BITS_COMMAND <= 141)
						RTC_CONTROL_STATUS[7:0] <= {RTC_CONTROL_STATUS[6:0],RTC_CONTROL_STATUS[7]};	
											
					/*=====================================  17th BYTE (RTC AgingOffset) =====================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 144 && CNT_BITS_COMMAND <= 151)
						RTC_OFFSET[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 144 && CNT_BITS_COMMAND <= 151)
						RTC_OFFSET[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 144 && CNT_BITS_COMMAND <= 150)
						RTC_OFFSET[7:0] <= {RTC_OFFSET[6:0],RTC_OFFSET[7]};
											
					/*===================================  18th BYTE (RTC MSB_TEMP) ==================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 153 && CNT_BITS_COMMAND <= 160)
						RTC_MSB_TEMP[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 153 && CNT_BITS_COMMAND <= 160)
						RTC_MSB_TEMP[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 153 && CNT_BITS_COMMAND <= 159)
						RTC_MSB_TEMP[7:0] <= {RTC_MSB_TEMP[6:0],RTC_MSB_TEMP[7]};
										
					/*===================================  19th BYTE (RTC LSB_TEMP) =====================================*/
					
					else if (general_counter == 249 && RTC_DS3231_SDA == 1 && CNT_BITS_COMMAND >= 162 && CNT_BITS_COMMAND <= 169)
						RTC_LSB_TEMP[0] <= 1;
					else if (general_counter == 249 && RTC_DS3231_SDA == 0 && CNT_BITS_COMMAND >= 162 && CNT_BITS_COMMAND <= 169)
						RTC_LSB_TEMP[0] <= 0;
					else if (general_counter == 499 && CNT_BITS_COMMAND >= 162 && CNT_BITS_COMMAND <= 168)
						RTC_LSB_TEMP[7:0] <= {RTC_LSB_TEMP[6:0],RTC_LSB_TEMP[7]};			
				end
				
			else if (STATE == SLAVE_ADDRESS_2)
					begin
						RTC_SECONDS <= 0;
						RTC_MINUTES <= 0;
						RTC_HOURS <= 0;
						RTC_DAY <= 0;
						RTC_DATE <= 0;
						RTC_CENTURY_MONTH <= 0;
						RTC_YEAR <= 0;
						RTC_ALARM1_SECONDS <= 0;
						RTC_ALARM1_MINUTES <= 0;
						RTC_ALARM1_HOURS <= 0;
						RTC_ALARM1_DAYS_DATE <= 0;
						RTC_ALARM2_MINUTES <= 0;
						RTC_ALARM2_HOURS <= 0;
						RTC_ALARM2_DAYS_DATE <= 0;
						RTC_CONTROL <= 0;
						RTC_CONTROL_STATUS <= 0;
						RTC_OFFSET <= 0;
						RTC_MSB_TEMP <= 0;
						RTC_LSB_TEMP <= 0;
					end
					
			else if (STATE == WRITE_DATA)
					begin
						if (general_counter == 499 && CNT_BITS_COMMAND <=7)
							RTC_SECONDS[7:0] <= {RTC_SECONDS[6:0],RTC_SECONDS[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 9 && CNT_BITS_COMMAND <= 16)
							RTC_MINUTES[7:0] <= {RTC_MINUTES[6:0],RTC_MINUTES[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 18 && CNT_BITS_COMMAND <= 25)
							RTC_HOURS[7:0] <= {RTC_HOURS[6:0],RTC_HOURS[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 27 && CNT_BITS_COMMAND <= 34)
							RTC_DAY[7:0] <= {RTC_DAY[6:0],RTC_DAY[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 36 && CNT_BITS_COMMAND <= 43)
							RTC_DATE[7:0] <= {RTC_DATE[6:0],RTC_DATE[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 45 && CNT_BITS_COMMAND <= 52)
							RTC_CENTURY_MONTH[7:0] <= {RTC_CENTURY_MONTH[6:0],RTC_CENTURY_MONTH[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 54 && CNT_BITS_COMMAND <= 61)
							RTC_YEAR[7:0] <= {RTC_YEAR[6:0],RTC_YEAR[7]};	
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 63 && CNT_BITS_COMMAND <= 70)
							RTC_ALARM1_SECONDS[7:0] <= {RTC_ALARM1_SECONDS[6:0],RTC_ALARM1_SECONDS[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 72 && CNT_BITS_COMMAND <= 79)
							RTC_ALARM1_MINUTES[7:0] <= {RTC_ALARM1_MINUTES[6:0],RTC_ALARM1_MINUTES[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 81 && CNT_BITS_COMMAND <= 88)
							RTC_ALARM1_HOURS[7:0] <= {RTC_ALARM1_HOURS[6:0],RTC_ALARM1_HOURS[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 90 && CNT_BITS_COMMAND <= 97)
							RTC_ALARM1_DAYS_DATE[7:0] <= {RTC_ALARM1_DAYS_DATE[6:0],RTC_ALARM1_DAYS_DATE[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 99 && CNT_BITS_COMMAND <= 105)
							RTC_ALARM2_MINUTES[7:0] <= {RTC_ALARM2_MINUTES[6:0],RTC_ALARM2_MINUTES[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 108 && CNT_BITS_COMMAND <= 115)
							RTC_ALARM2_HOURS[7:0] <= {RTC_ALARM2_HOURS[6:0],RTC_ALARM2_HOURS[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 117 && CNT_BITS_COMMAND <= 124)
							RTC_ALARM2_DAYS_DATE[7:0] <= {RTC_ALARM2_DAYS_DATE[6:0],RTC_ALARM2_DAYS_DATE[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 126 && CNT_BITS_COMMAND <= 133)
							RTC_CONTROL[7:0] <= {RTC_CONTROL[6:0],RTC_CONTROL[7]};											
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 135 && CNT_BITS_COMMAND <= 142)
							RTC_CONTROL_STATUS[7:0] <= {RTC_CONTROL_STATUS[6:0],RTC_CONTROL_STATUS[7]};	
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 144 && CNT_BITS_COMMAND <= 151)
							RTC_OFFSET[7:0] <= {RTC_OFFSET[6:0],RTC_OFFSET[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 153 && CNT_BITS_COMMAND <= 160)
							RTC_MSB_TEMP[7:0] <= {RTC_MSB_TEMP[6:0],RTC_MSB_TEMP[7]};
						else if (general_counter == 499 && CNT_BITS_COMMAND >= 162 && CNT_BITS_COMMAND <= 169)
							RTC_LSB_TEMP[7:0] <= {RTC_LSB_TEMP[6:0],RTC_LSB_TEMP[7]};		
					end
				else if (STATE == COMMAND_SLAVE_ID_3)
					begin
							RTC_SECONDS		 			<=		SET_SECONDS;	
							RTC_MINUTES					<=		SET_MINUTES;															
							RTC_HOURS					<=		SET_HOURS;			
							RTC_DAY						<=		SET_DAY;			
							RTC_DATE						<=		SET_DATE;		
							RTC_CENTURY_MONTH			<=		SET_CENTURY;
							RTC_YEAR						<=		SET_YEAR;
					end
				else if (STATE == DATA_SEND)
					begin
							RTC_SECONDS_SEND			<=		RTC_SECONDS;
							RTC_MINUTES_SEND			<= 	RTC_MINUTES;
							RTC_HOURS_SEND				<= 	RTC_HOURS;
							RTC_DAY_SEND				<=		RTC_DAY;				
							RTC_DATE_SEND				<=    RTC_DATE;
							RTC_CENTURY_MONTH_SEND  <=    RTC_CENTURY_MONTH;
							RTC_YEAR_SEND				<=    RTC_YEAR;
					end
		end
/*==============================================================================================*/
/*====================================== MAIN PROGRAM ==========================================*/
/*==============================================================================================*/
always @ (posedge CLK)
		begin
				case(STATE)
DELAY_2://========================================================// 20																
			begin																		//
					if (counter_250ms == counter_reset)						//
					STATE <= START_3;												//
			end																		//
START://==========================================================// 0
			begin																		//
					if (general_counter == 499)								//	
					STATE <= COMMAND_SLAVE_ID;									//
			end																		//
COMMAND_SLAVE_ID://===============================================// 1
			begin																		//
					if (general_counter == 499)								//
					STATE <= SLAVE_ADDRESS;										//
			end																		//
SLAVE_ADDRESS://==================================================// 2
			begin																		//
					if (CNT_BITS_COMMAND == 9)									//
					STATE <= COMMAND_TEMPERATURE;								//
			end																		//			
COMMAND_TEMPERATURE://============================================// 3
			begin																		//
					if (general_counter == 499)								//
					STATE <= TEMPERATURE_ADDRESS;								//
			end																		//
TEMPERATURE_ADDRESS://============================================// 4
			begin																		//
					if (CNT_BITS_COMMAND == 9)									//
				   STATE <= STOP;													//
			end																		//	
STOP://===========================================================// 5
			begin																		//
					if (general_counter == 499)								//
					STATE <= START_2;												//
			end																		//
START_2://========================================================// 6
			begin																		//
					if (general_counter == 499)								//	
					STATE <= COMMAND_SLAVE_ID_2;								//
			end																		//
COMMAND_SLAVE_ID_2://=============================================// 7
			begin																		//
					if (general_counter == 499)								//
					STATE <= SLAVE_ADDRESS_2;									//
			end																		//
SLAVE_ADDRESS_2://================================================// 8
			begin																		//
					if (CNT_BITS_COMMAND == 9)									//
					STATE <= READ_DATA;											//
			end																		//			
READ_DATA://======================================================// 9
			begin																		//
					if (CNT_BITS_COMMAND == 171)								//
					STATE <= DATA_SEND;											//
			end																		//
DATA_SEND://======================================================// 19
			begin																		//
					if (general_counter == 499)								//
					STATE <= STOP_2;												//
			end																		//
STOP_2://=========================================================// 10
			begin																		//
					if (general_counter == 499)								//
					STATE <= DELAY;												//
			end																		//
START_3://========================================================// 12
			begin																		//
					if (general_counter == 499)								//
					STATE <= COMMAND_SLAVE_ID_3;								//
			end																		//
COMMAND_SLAVE_ID_3://=============================================// 13
			begin																		//
					if (general_counter == 499)								//
					STATE <= SLAVE_ADDRESS_3;									//
			end																		//
SLAVE_ADDRESS_3://================================================// 14
			begin																		//
					if (CNT_BITS_COMMAND == 9)									//
					STATE <= COMMAND_SECONDS;									//
			end																		//
COMMAND_SECONDS://================================================// 15 
			begin																		//
					if (general_counter == 499)								//
					STATE <= SECONDS_ADDRESS;									//
			end																		//
SECONDS_ADDRESS://================================================// 16 
			begin																		//
					if (CNT_BITS_COMMAND == 9)									//
					STATE <= WRITE_DATA;											//
			end																		//
WRITE_DATA://=====================================================// 17
			begin																		//
					if (CNT_BITS_COMMAND == 62)								//
					STATE <= STOP_3;												//
			end																		//
STOP_3://=========================================================// 18
			begin																		//
					if (general_counter == 499)								//
					STATE <= DELAY;												//
			end																		//
DELAY://==========================================================// 11																	
			begin																		//
					if (counter_250ms == counter_reset)						//
					STATE <= START;												//
			end																		//
				endcase
	end
	
endmodule