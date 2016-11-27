`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:51:37 04/11/2013 C
// Design Name: 
// Module Name:    labkit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module labkit(
    input clk_100mhz,
    input [7:0] switch,
	 
    input btn_up,       // buttons, depress = high
    input btn_enter,
    input btn_left,
    input btn_down,
    input btn_right,
	 
    output [7:0] seg,   //output 0->6 = seg A->G ACTIVE LOW, 
                        //output 7 = decimal point, all active low
								
    output [3:0] dig,   //selects digits 0-3, ACTIVE LOW
    output [7:0] led,   // 1 turns on leds
	 
    output [2:0] vgared,
    output [2:0] vgagreen,
    output [2:1] vgablue,
    output hsync,
    output vsync,
	 
    inout [7:0] ja,
    inout [7:0] jb,
    inout [7:0] jc,
    input [7:0] jd,
    inout [19:0] exp_io_n,
    inout [19:0] exp_io_p
    );

    // all unused outputs must be assigned
//    assign vgared = 3'b111;
//    assign vgagreen = 3'b111;
//    assign vgablue = 2'b11;
//    assign hsync = 1'b1;
//    assign vsync = 1'b1;
	 
// next three lines turns the 7 seg display completely off
//    assign seg = 7'b111_1111; 	//output 0->6 = seg A->G ACTIVE LOW
//    assign dp = 1'b1; 				//decimal point ACTIVE LOW
//    assign dig = 4'hF;  			//selectives digits 0-3, ACTIVE LOW
 //
 
  
//////////////////////////////////////////////////////////////////
// dcm_all is a general purpose digital clock manager. It is used
// to create clocks at desired frequncies and phases.
//
   wire clk_65mhz;
	wire clk_100mhz_buf;  // 100mhz buffered clock, not used
		
   dcm_all_v2 #(.DCM_DIVIDE(20), .DCM_MULTIPLY(13))
     	my_clocks(
				.CLK(clk_100mhz),
				.CLKSYS(clk_100mhz_buf),
//				.CLK25(CLK25),
				.CLK_out(clk_65mhz)
	);
//
//////////////////////////////////////////////////////////////////

   wire pixel_clk = clk_65mhz;  // clock for 1024 x 768 60hz resolution  

   assign led = switch;  // provide feedback

   wire [10:0] hcount;
   wire [9:0]  vcount;   
	wire blank, hblank;
		
	wire [7:0] pixel; //,paddle_pix,ball;
	
	//assign pixel = paddle_pix | ball;
	
	assign vgared = blank ? pixel[7:5] : 3'b0;
	assign vgagreen = blank ? pixel[4:2] : 3'b0;
	assign vgablue = blank ? pixel[1:0] : 2'b0;
	
	debounce  db_up(.reset(reset), .clock(pixel_clk), .noisy(btn_up), .clean(up));			 
	debounce  db_down(.reset(reset), .clock(pixel_clk), .noisy(btn_down), .clean(down));
	debounce  db_left(.reset(reset), .clock(pixel_clk), .noisy(btn_left), .clean(left));			 
	debounce  db_right(.reset(reset), .clock(pixel_clk), .noisy(btn_right), .clean(right));    
	debounce  db_enter(.reset(1'b0), .clock(pixel_clk), .noisy(btn_enter), .clean(enter)); 
	
   assign reset = enter;
	
   vga_general video_driver(.pixel_clk(pixel_clk),.hcount(hcount), .vcount(vcount),
		.hsync(hsync1),.vsync(vsync1), .blank(blank1), .hblank(hblank1));

   wire [7:0] pong_pixel;
	
	reg [7:0] rgb;
	reg hs, vs, b;
   
	wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount==767);
	
   always @(posedge pixel_clk) begin
//     case (switch[7:6])
     case (switch[1:0])
		2'b00: begin   // send the pong pixels through
		         hs <= phsync;
					vs <= pvsync;
					b <= pblank;
					rgb <= pong_pixel;
				 end
		2'b01:	 begin  // 1 pixel outline of visible area (white)
		         hs <= hsync1;
					vs <= vsync1;
					b <= blank1;
					rgb <= {{8{border}}};
				 end
		2'b10:  begin  // color bars
		         hs <= hsync1;
					vs <= vsync1;
					b <= blank1;
					rgb <= {{3{hcount[8]}}, {3{hcount[7]}}, {2{hcount[6]}}};				
             end
		2'b11: begin   // send the pong pixels through
		         hs <= phsync;
					vs <= pvsync;
					b <= pblank;
					rgb <= pong_pixel;
				 end
		 endcase
	  end
				 
               
		
   assign pixel = rgb; //{{3{hcount[8]}}, {3{hcount[7]}}, {2{hcount[6]}}};	//rgb;
	assign blank = b;
	assign vsync = vs;
	assign hsync = hs;	
	
   pong_game psolution(.pixel_clk(pixel_clk), .reset(reset), .up(up), .down(down),.left(left), .right(right), .pspeed(switch[7:4]),
	    .hcount(hcount), .vcount(vcount), .hsync(hsync1), .vsync(vsync1), .blank(blank1),
		 .phsync(phsync), .pvsync(pvsync), .pblank(pblank), .pixel(pong_pixel));
	

//////////////////////////////////////////////////////////////////
// 
// just show counter working as a system check - not necessary.
	reg [30:0] counter;
	
	always@(posedge pixel_clk) begin
	  counter <=  counter + 1;
	end
	
	assign seg[7] = 1'b0; // turn off decimal point

	display_4hex  my_display(
	  .clk(pixel_clk),
     .data(counter[30:15]),
	  .seg(seg[6:0]),
     .strobe(dig)
    );
//
//////////////////////////////////////////////////////////////////

/////
reg [30:0] timecounter = 0;
reg [30:0] timeTaken = 0;
reg [1:0] triggerState = 1;
reg [30:0] distance = 0;
reg [1:0] tempja = 0;
//always@(posedge clk_100mhz) begin

if (triggerState == 1) begin
	if (timecounter < 500) begin //triggers trigger pin low for more than 5ms
	tempja = 0;
	end
	if (timecounter < 1500) begin //triggers trigger pin high for more than 10ms
		ja[0] = 1;
	end
	if (timecounter >= 1500) begin
	ja[0] <= 0;
	triggerState <= 2;
	timecounter <= 0;
	timeTaken <= 0;
	end
end
 if (triggerState == 2) begin
	if (ja[1] == 1) begin //start tracking the time after sound is triggered
	timeTaken <= timecounter;
	distance <= timeTaken/58200; //distance in cm
	triggerState <= 1;
	timecounter <= 0;
	end
	if (timecounter > 18181) begin //timeout if more than 3 metres
		timecounter <= 0;
		triggerState <= 1;
		end
	
	end
//timecounter <= timecounter + 1;


//end
ja[0] = tempja;
	



/////
	
endmodule



////////////////////////////////////////////////////////////////////////////////
//
// pong_game: the game itself!
//
////////////////////////////////////////////////////////////////////////////////

module pong_game (
   input pixel_clk,	// 65MHz clock
   input reset,		// 1 to initialize module
   input up,		// 1 when paddle should move up
   input down,  	// 1 when paddle should move down
      input left,		// 1 when paddle B should move up
   input right,  	// 1 when paddle B should move down
   input [3:0] pspeed,  // puck speed in pixels/tick 
   input [10:0] hcount,	// horizontal index of current pixel (0..1023)
   input [9:0]  vcount, // vertical index of current pixel (0..767)
   input hsync,		// XVGA horizontal sync signal (active low)
   input vsync,		// XVGA vertical sync signal (active low)
   input blank,		// XVGA blanking (1 means output black pixel)
 	
   output phsync,	// pong game's horizontal sync
   output pvsync,	// pong game's vertical sync
   output pblank,	// pong game's blanking
   output [7:0] pixel	// pong game's pixel  // r=7:5, g=4:2, b=1:0 
   );

   wire [2:0] checkerboard;
	
////////////////////////////////////////////////////////////////////	
// REPLACE ME! The code below just generates a color checkerboard
// using 64 pixel by 64 pixel squares.
   
//   assign phsync = hsync;
//   assign pvsync = vsync;
//   assign pblank = blank;
//   assign checkerboard = hcount[8:6] + vcount[8:6];

   // here we use three bits from hcount and vcount to generate the \
   // checkerboard

//  assign pixel = {{8{checkerboard[2]}}, {8{checkerboard[1]}}, {8{checkerboard[0]}}} ;
////////////////////////////////////////////////////////////////////	


////////////////////////////////////////////////////////////////////	
// need to take care of the pipe line delays;
// the round puck is delayed by two clock cycles
// deleay paddle_pix, hsync, vsync, pblank by two clock cycles

  reg [15:0] paddle_pix_delay;
  reg [1:0] hsync_delay, vsync_delay, blank_delay;
  
  always @(posedge pixel_clk) begin
    hsync_delay <= {hsync_delay[0],hsync};
	 vsync_delay <= {vsync_delay[0],vsync};
	 blank_delay <= {blank_delay[0],blank};
	 paddle_pix_delay <= {paddle_pix_delay[7:0],paddle_pix};
  end
 
   assign phsync = hsync_delay[1];
   assign pvsync = vsync_delay[1];
   assign pblank = blank_delay[1]; 
	assign pixel = paddle_pix_delay[15:8] | ball;
  



////////////////////////////////////////////////////////////////////	



//   assign pixel =  paddle_pix | ball; //{{8{checkerboard[2]}}, {8{checkerboard[1]}}, {8{checkerboard[0]}}} ;
 
 
 	wire [7:0] paddle_pix,ball;

   parameter PADDLE_WIDTH = 16; //dimension of the paddle
	parameter PADDLE_HEIGHT = 256;
   parameter PADDLE_XB = 1023-PADDLE_WIDTH; //fixed X position of the paddle B
   parameter PADDLE_XA = 28; //fixed X position of the paddle A
   wire [9:0] paddle_yA,paddle_yB;
	
	draw_box1 #(.WIDTH(PADDLE_WIDTH), .HEIGHT(PADDLE_HEIGHT), .COLOR(8'b111_000_00))
	   paddle (.pixel_clk(pixel_clk), .hcount(hcount), .vcount(vcount),
		.xA(PADDLE_XA), .yA(paddle_yA),.xB(PADDLE_XB), .yB(paddle_yB), .pixel(paddle_pix));
		


//////////////////////////////////////////////////////////////////
// create a pulse every vertical refresh

	reg vsync_delayed;    
	always @(posedge pixel_clk)
	vsync_delayed <= vsync;
	assign vsync_pulse = vsync_delayed && ~vsync;
//
//////////////////////////////////////////////////////////////////


			 			
	wire stop;  // used to halt the game
	

	if (switch[3] == 0) begin
   	move_paddle paddle_motion(.pixel_clk(pixel_clk), .vsync_pulse(vsync_pulse),
		.up(up), .down(down), .left(left), .right(right), .paddle_yA(paddle_yA),.paddle_yB(paddle_yB), .reset(system_reset), .stop(stop));
   end
   else if (switch[3] == 1) begin
   	move_paddle_extended paddle_motion_extended(.pixel_clk(pixel_clk), .vsync_pulse(vsync_pulse),
		.distance(distance), .paddle_yA(paddle_yA),.paddle_yB(paddle_yB), .reset(system_reset), .stop(stop));
   end

	reg [9:0] ball_y = 300; 
	reg [10:0] ball_x = 300;
	wire [4:0] speed_x, speed_y;
	
	assign speed_x = pspeed[3:2]*4;
	assign speed_y = pspeed[1:0]*4;

   parameter BALL_SIZE = 7'd20;
   parameter MAX_BALL_Y = 767 - BALL_SIZE; //defines the Y boundaries in which the ball can move/bounce it
   parameter MIN_BALL_Y = 1;
   parameter MAX_BALL_X = 1023 - BALL_SIZE; //defines the X boundaries in which the ball can move/bounce it
	
	reg ball_up, ball_right;
	
	wire [10:0] new_ball_x = ball_right ? ball_x + speed_x : ball_x - speed_x;
	wire [9:0]  new_ball_y = ball_up    ? ball_y - speed_y : ball_y + speed_y;
	wire paddle_range1A = ((ball_y+BALL_SIZE)>= paddle_yA) &&  //checks if ball is beyond paddle A in y direction
				(ball_y<paddle_yA+PADDLE_HEIGHT);
	wire paddle_range1B = ((ball_y+BALL_SIZE)>= paddle_yB) &&  //checks if ball is beyond paddle B in y direction
				(ball_y<paddle_yB+PADDLE_HEIGHT);

   //assign stop = ball_x + 1 < PADDLE_X + PADDLE_WIDTH; //this is the code that determines when the game "loses", checks when ball is out of left boundary
   assign stop = ((ball_x + 1 > PADDLE_XB + PADDLE_WIDTH) || (ball_x + 1 < PADDLE_XA + PADDLE_WIDTH)) ; //this is the code that determines when the game "loses", checks when ball is out of right boundary
//	reg [9:0] scoreA = 0;  
//	reg [9:0] scoreB = 0;  //initialises the score 
//
//
//   if ((ball_x + 1 < PADDLE_XA + PADDLE_WIDTH)) begin //A loses
//   //assign scoreB = scoreB + 1;
//   assign stop = 1;
//   end
//   
//   if (ball_x + 1 > PADDLE_XB + PADDLE_WIDTH) begin //B loses
//   //assign scoreA = scoreA + 1;
//	assign stop = 1;
//   end

//////////////////////////////////////////////////////////////////	
// use to draw a square puck
//
//	draw_box #(.WIDTH(BALL_SIZE), .HEIGHT(BALL_SIZE), .COLOR(8'b111_111_11))
//	   create_ball (.pixel_clk(pixel_clk), .hcount(hcount), .vcount(vcount),
//		.x(ball_x), .y(ball_y), .pixel(ball));
//
//////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////
// create a round puck, pipelined by two stages

   round_piped round_puck(.pixel_clk(pixel_clk), .ball_size(BALL_SIZE), .rx(ball_x),
	   .hcount(hcount), .ry(ball_y), .vcount(vcount), .rpixel(ball));
////
//////////////////////////////////////////////////////////////////


	always @(posedge pixel_clk)
		if (reset) begin
//			speed_x <= {3'b0,switch[3:2]};
//			speed_y <= {3'b0,switch[1:0]};
			ball_x <= 400; //starting X position of ball
			ball_y <= 400; //starting Y position of ball
			ball_up <= 0; //
			ball_right <= 1;
//			scoreA <= 0;
//			scoreB <= 0;
			end
		else if (vsync_pulse && ~stop) begin
		// vertical movement
				ball_y <= new_ball_y;
			   if ((ball_up)&&(new_ball_y < MIN_BALL_Y) || (new_ball_y>MAX_BALL_Y)) begin //changes direction to downwards when it hits the top wall
					ball_up <= 0;
					ball_y <= MIN_BALL_Y;
				end
			   if ((~ball_up)&&(new_ball_y > MAX_BALL_Y))begin //changes direction to upwards when it hits the btm wall
					ball_up <= 1;
					ball_y <= MAX_BALL_Y;
				end
		//horizontal movement
				ball_x <= new_ball_x;
				// if ((ball_right)&&(new_ball_x > MAX_BALL_X)) begin //this will make a bouncable right wall
				//    ball_right <= 0; //this changes direction from left to right
				// 	ball_x <= MAX_BALL_X;
				//    end

				// if (~ball_right && paddle_range1	&& new_ball_x < PADDLE_X+PADDLE_WIDTH) begin //this code is to make it bounce only on the left side paddle
				// 	ball_right <=1; //this changes direction from right to left //paddle_range1 checks if the y pos of ball is within y pos of paddle
				// 	ball_x <= PADDLE_X+PADDLE_WIDTH;
				if (~ball_right && paddle_range1A && new_ball_x < PADDLE_XA+PADDLE_WIDTH) begin //this code is to make it bounce only on the left side paddle
					ball_right <=1; //this changes direction from right to left //paddle_range1 checks if the y pos of ball is within y pos of paddle
					ball_x <= PADDLE_XA+PADDLE_WIDTH;
					end
				if (ball_right && paddle_range1B && new_ball_x > PADDLE_XB) begin //this code is to make it bounce only on the right side paddle
					ball_right <=0; //this changes direction from left to right //paddle_range1 checks if the y pos of ball is within y pos of paddle
					ball_x <= PADDLE_XB;

					// lower half of the paddle, speed up 4x
//					speed_x <= (ball_y >= paddle_y + paddle_height/2) ? sw[3:2]*4 : sw[3:2];
//					speed_y <= (ball_y >= paddle_y + paddle_height/2) ? sw[1:0]*4 : sw[1:0];
//					speed_x <= switch[3:2];
//					speed_y <= switch[1:0];
					end		
			
       end				


 
endmodule

// END OF PONG GAME MODULE--------------------------------------------------------------------------------------




// DRAW SCORE MODULE









//--------------- Draw paddle (1)------------------------------------------------------------------------------


module draw_box1 #(parameter WIDTH=200,
                            HEIGHT=16,
									 COLOR=8'b111_000_00)
									  
   (input pixel_clk, 
    input [10:0] hcount, xA, xB,
    input [9:0] vcount, yA, yB,
	 output reg [7:0] pixel
	 );
	 

    always @(hcount or vcount) begin //this draws the two paddles
	 
		if (((hcount >= xA && hcount < (xA+WIDTH))  &&(vcount >= yA && vcount < (yA+HEIGHT))) ||  ((hcount >= xB && hcount < (xB+WIDTH))  &&(vcount >= yB && vcount < (yB+HEIGHT))))
			pixel = COLOR;
		
		else 
			pixel = 0;
	end

endmodule

//-------------------------------------------------------------------------------------------------


//-------------------Draw Paddle (2)--------------------------------------------------------------




//--------------------------------------------------------------------------------------------------------


// MOVE PADDLE

module move_paddle (
    input pixel_clk, vsync_pulse,
//    input [10:0] hcount, x,
    input up, down, left,right, reset, stop,
	 output reg [9:0] paddle_yA, paddle_yB
	 );
	 
	 parameter JUMP = 10;	 
	 parameter DEPTH=767;
	 parameter PADDLEHEIGHT = 128;
	

	 
	 
	 // paddle motion
    always @ (posedge pixel_clk) 
		begin
			
			if (reset)
				begin
				paddle_yA<=0;
				paddle_yB<=0;
				end
			else if (vsync_pulse && ~stop)
				begin
				
				if (up) //FOR PADDLE A
					paddle_yA<=paddle_yA - JUMP;				
					
				if (down)
					paddle_yA<=paddle_yA + JUMP;
					
				
				if (paddle_yA <10)
					paddle_yA<=10;
				
					
				if (paddle_yA+PADDLEHEIGHT > DEPTH - PADDLEHEIGHT)
					paddle_yA<=511;

				if (left) //FOR PADDLE B
					paddle_yB<=paddle_yB - JUMP;				
					
				if (right)
					paddle_yB<=paddle_yB + JUMP;
					
				
				if (paddle_yB <10)
					paddle_yB<=10;
				
					
				if (paddle_yB+PADDLEHEIGHT > DEPTH - PADDLEHEIGHT)
					paddle_yB<=511;
					
			
				end
		end
		
  
	 
endmodule


//extended paddle movement mapped by sonar sensor
// MOVE PADDLE

module move_paddle_extended (
    input pixel_clk, vsync_pulse,
//    input [10:0] hcount, x,
    input distance, reset, stop,
	 output reg [9:0] paddle_yA, paddle_yB
	 );
	 
	 parameter JUMP = 10;	 
	 parameter DEPTH=767;
	 parameter PADDLEHEIGHT = 128;

	
	 
	 
	 // paddle motion
    always @ (posedge pixel_clk) 
		begin
			
			if (reset)
				begin
				paddle_yA<=0;
				paddle_yB<=0;
				end
			else if (vsync_pulse && ~stop)
				begin
				
					
				
				if (distance <15)
					paddle_yA<=510;
				
				if (distance > 115)
					paddle_yA <= 10;
					
				if ((distance >= 15) && (distance < 116)) begin
					paddle_yA <= (510 - (distance - 15)*5);
				end
					

				// if (left) //FOR PADDLE B
				// 	paddle_yB<=paddle_yB - JUMP;				
					
				// if (right)
				// 	paddle_yB<=paddle_yB + JUMP;
					
				
				// if (paddle_yB <10)
				// 	paddle_yB<=10;
				
					
				// if (paddle_yB+PADDLEHEIGHT > DEPTH - PADDLEHEIGHT)
				// 	paddle_yB<=511;
					
			
				end
		end
		
  
	 
endmodule





//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:51:37 04/02/2007 
// Design Name: 
// Module Name:    round_piped 
// Project Name: 

//////////////////////////////////////////////////////////////////////////////////
module round_piped
  (input pixel_clk,
   input [7:0] ball_size,
   input [10:0] rx,hcount,
   input [9:0] ry,vcount,
   output reg [7:0] rpixel);

//   reg [7:0] rpixel,rpixel2;
//   reg [10:0] rx2,hcount2;
//   reg [9:0] ry2,vcount2;

   wire [7:0] radius = ball_size[6:0];
   
   wire [16:0] rsquare = radius*radius;
   wire  [10:0] x1 = (hcount>rx)?hcount-rx:rx-hcount;
   wire  [9:0] y1 = (vcount>ry)?vcount-ry:ry-vcount;
   reg  [21:0] x1square;
   reg  [19:0] y1square;
   
   parameter rCOLOR = 8'b111_111_11; // default color: white


      
   always @ (posedge pixel_clk)
		begin
			x1square<= x1*x1;
			y1square<= y1*y1;
		end
			
		
	always @ (posedge pixel_clk)
		begin		
			if (x1square+y1square<=rsquare)
			rpixel<= rCOLOR;
			else
			rpixel <=0;
		end
	
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Gim P. Hom 3/22/2007
// 
// Create Date:    17:51:37 03/11/2007 
// Design Name: 
// Module Name:    vga_general 
// Project Name: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_general(
    input pixel_clk, 
    output reg [10:0] hcount,
    output reg [9:0] vcount,
    output blank,
    output hblank,	 
    output  hsync, 
    output  vsync
);	 
/*   //reg  hblank=1;
	assign vclock = pixel_clk;
	
   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   reg vblank;
   wire hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount == 1023);    
   assign hsyncon = (hcount == 1047);
   assign hsyncoff = (hcount == 1183);
   assign hreset = (hcount == 1343);

   // vertical: 806 lines total
   // display 768 lines
   wire vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount == 767);    
   assign vsyncon = hreset & (vcount == 776);
   assign vsyncoff = hreset & (vcount == 782);
   assign vreset = hreset & (vcount == 805);

   // sync and blanking
   wire next_hblank,next_vblank;
   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   always @(posedge vclock) begin
      hcount <= hreset ? 0 : hcount + 1;
      hblank <= next_hblank;
      hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low

      vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
      vblank <= next_vblank;
      vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low

      blank <= next_vblank | (next_hblank & ~hreset);
   end*/

	 wire vblank;
	 
 
	 // 1024 x 768 @ 60hz;  alternate resolution = 640x480 75hz
	 parameter hfp = 24;  //24;  // 16;  
	 parameter hsy = 136;  //136; // 96;
	 parameter hbp = 160;  //160; // 48;
	 
	 parameter vfp = 3;  //3;  //  11;
	 parameter vsy = 6;   //6;  //  2;
	 parameter vbp = 29;  //29; //  32;
	 
	 parameter hsize = 1023; //1023; //639;  // there are 640 pixels counting 0
	 parameter vsize = 767; //767; //479;  // similarly there are 480 lines counting line 0
	 
	 wire  h_end = (hcount == (hsize + hfp + hsy + hbp));
	 wire  v_end = (vcount == (vsize + vfp + vsy + vbp));
	 
	 assign hsync = ((hcount < hsize + hfp) || (hcount > hsize + hfp + hsy));
	 assign vsync = ((vcount < vsize + vfp) || (vcount > vsize + vfp + vsy));
	 
	 assign hblank = (hcount <= hsize);
	 assign vblank = (vcount <= vsize);
	 
	 assign blank = hblank && vblank;
	 
	 always @(posedge pixel_clk)
	    begin
		 hcount <= h_end ? 0 : hcount + 1;
		 vcount <= h_end ? (v_end ? 0 : vcount + 1) : vcount;  
		 end
		 
endmodule

// Switch Debounce Module
// use your system clock for the clock input
// to produce a synchronous, debounced output
module debounce #(parameter DELAY=400000)   // .01 sec with a 49Mhz clock
	        (input reset, clock, noisy,
	         output reg clean);

   reg [19:0] count;
   reg new;

   always @(posedge clock)
     if (reset)
       begin
	  count <= 0;
	  new <= noisy;
	  clean <= noisy;
       end
     else if (noisy != new)
       begin
	  new <= noisy;
	  count <= 0;
       end
     else if (count == DELAY)
       clean <= new;
     else
       count <= count+1;
      
endmodule

// Description:  Display 4 hex numbers on 7 segment display
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module display_4hex(
    input clk,                 // system clock
    input [15:0] data,         // 4 hex numbers, msb first
    output reg [6:0] seg,      // seven segment display output
    output reg [3:0] strobe    // digit strobe
    );

    localparam bits = 13;
     
    reg [bits:0] counter = 0;  // clear on power up
     
    wire [6:0] segments[15:0]; // 16 7 bit memorys
    assign segments[0]  = 7'b100_0000;
    assign segments[1]  = 7'b111_1001;
    assign segments[2]  = 7'b010_0100;
    assign segments[3]  = 7'b011_0000;
    assign segments[4]  = 7'b001_1001;
    assign segments[5]  = 7'b001_0010;
    assign segments[6]  = 7'b000_0010;
    assign segments[7]  = 7'b111_1000;
    assign segments[8]  = 7'b000_0000;
    assign segments[9]  = 7'b001_1000;
    assign segments[10] = 7'b000_1000;
    assign segments[11] = 7'b000_0011;
    assign segments[12] = 7'b010_0111;
    assign segments[13] = 7'b010_0001;
    assign segments[14] = 7'b000_0110;
    assign segments[15] = 7'b000_1110;
     
    always @(posedge clk) begin
      counter <= counter + 1;
      case (counter[bits:bits-1])
          2'b00: begin
                  seg <= segments[data[15:12]];
                  strobe <= 4'b0111;
                 end

          2'b01: begin
                  seg <= segments[data[11:8]];
                  strobe <= 4'b1011;
                 end

          2'b10: begin
                   seg <= segments[data[7:4]];
                   strobe <= 4'b1101;
                  end
          2'b11: begin
                  seg <= segments[data[3:0]];
                  strobe <= 4'b1110;
                 end
       endcase
      end

endmodule



//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc 2011
// Engineer: Michelle Yu  
// Create Date:    08/26/2011
// Module Name:    dcm_all
// Project Name:     PmodPS2_Demo
// Target Devices: Nexys3 
// Tool version:     ISE 14.2
// Description: This file contains the design for a dcm that generates a 25MHz and a 
//                40MHz clock from a 100MHz clock.
//
// Revision: 
// Revision 0.01 - File Created
// Revision 1.00 - Converted from VHDL to Verilog (Josh Sackos)
// Revision 2.00 - removed CLK25, add parameters for divide/multiply
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
//                                 Define Module
// =======================================================================================
module dcm_all_v2  #(parameter DCM_DIVIDE = 4,
                               DCM_MULTIPLY = 2)
     (
      CLK,
//    RST,
      CLKSYS,
//      CLK25,
      CLK_out
);

// =======================================================================================
//                               Port Declarations
// =======================================================================================

         input   CLK;
//         input   RST;
         output  CLKSYS;
//         output  CLK25;
         output  CLK_out;

// =======================================================================================
//                        Parameters, Registers, and Wires
// =======================================================================================   

         // Output registers
         wire CLKSYS;
         wire CLK25;
         wire CLK_out;

         // architecture of dcm_all entity
         wire    GND = 1'b0;
         wire    CLKSYSint;
         wire    CLKSYSbuf;
         
         assign CLKSYS = CLKSYSbuf;

// =======================================================================================
//                                 Implementation
// =======================================================================================   

         // buffer system clock and wire to dcm feedback
         BUFG BUFG_clksys(
                  .O(CLKSYSbuf),
                  .I(CLKSYSint)
         );

         // Instantiation of the DCM device primitive.
         // Feedback is not used.
         // Clock multiplier is 2
         // Clock divider is 5
         // 100MHz * 2/5 = 40MHz   
         // The following generics are only necessary if you wish to change the default behavior.
         DCM #(
                  .CLK_FEEDBACK("1X"),
                  .CLKDV_DIVIDE(4.0),                   //  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                                                        //             7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
                  .CLKFX_DIVIDE(DCM_DIVIDE),            //  Can be any interger from 2 to 32
                  .CLKFX_MULTIPLY(DCM_MULTIPLY),        //  Can be any integer from 2 to 32
                  .CLKIN_DIVIDE_BY_2("FALSE"),          //  TRUE/FALSE to enable CLKIN divide by two feature
                  .CLKIN_PERIOD(10000.0),               //  Specify period of input clock (ps)
                  .CLKOUT_PHASE_SHIFT("NONE"),          //  Specify phase shift of NONE, FIXED or VARIABLE
                  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), //  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                                        //        an integer from 0 to 15
                  .DFS_FREQUENCY_MODE("LOW"),           //  HIGH or LOW frequency mode for frequency synthesis
                  .DLL_FREQUENCY_MODE("LOW"),           //  HIGH or LOW frequency mode for DLL
                  .DUTY_CYCLE_CORRECTION("TRUE"),       //  Duty cycle correction, TRUE or FALSE
                  .FACTORY_JF(16'hC080),                //  FACTORY JF Values
                  .PHASE_SHIFT(0),                      //  Amount of fixed phase shift from -255 to 255
                  .STARTUP_WAIT("FALSE")                //  Delay configuration DONE until DCM LOCK, TRUE/FALSE
         )
         DCM_inst(
                  .CLK0(CLKSYSint),                     // 0 degree DCM CLK ouptput
                  .CLK180(),                            // 180 degree DCM CLK output
                  .CLK270(),                            // 270 degree DCM CLK output
                  .CLK2X(),                             // 2X DCM CLK output
                  .CLK2X180(),                          // 2X, 180 degree DCM CLK out
                  .CLK90(),                             // 90 degree DCM CLK output
                  .CLKDV(), //(CLK25),                  // Divided DCM CLK out (CLKDV_DIVIDE)
                  .CLKFX(CLK_out),                      // DCM CLK synthesis out (M/D)
                  .CLKFX180(),                          // 180 degree CLK synthesis out
                  .LOCKED(),                            // DCM LOCK status output
                  .PSDONE(),                            // Dynamic phase adjust done output
                  .STATUS(),                            // 8-bit DCM status bits output
                  .CLKFB(CLKSYSbuf),                    // DCM clock feedback
                  .CLKIN(CLK),                          // Clock input (from IBUFG, BUFG or DCM)
                  .PSCLK(GND),                          // Dynamic phase adjust clock input
                  .PSEN(GND),                           // Dynamic phase adjust enable input
                  .PSINCDEC(GND),                       // Dynamic phase adjust increment/decrement
                  .DSSEN(1'b0),
                  .RST (1'b0)  //(RST)                  // DCM asynchronous reset input
         );
   
endmodule