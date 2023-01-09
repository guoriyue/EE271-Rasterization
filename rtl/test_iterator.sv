// /*
//  *  Bounding Box Sample Test Iteration
//  *
//  *  Inputs:
//  *    BBox and triangle Information
//  *
//  *  Outputs:
//  *    Subsample location and triangle Information
//  *
//  *  Function:
//  *    Iterate from left to right bottom to top
//  *    across the bounding box.
//  *
//  *    While iterating set the halt signal in
//  *    order to hold the bounding box pipeline in
//  *    place.
//  *
//  *
//  * Long Description:
//  *    The iterator starts in the waiting state,
//  *    when a valid triangle bounding box
//  *    appears at the input. It will enter the
//  *    testing state the next cycle with a
//  *    sample equivelant to the lower left
//  *    cooridinate of the bounding box.
//  *
//  *    While in the testing state, the next sample
//  *    for each cycle should be one sample interval
//  *    to the right, except when the current sample
//  *    is at the right edge.  If the current sample
//  *    is at the right edge, the next sample should
//  *    be one row up.  Additionally, if the current
//  *    sample is on the top row and the right edge,
//  *    next cycles sample should be invalid and
//  *    equivelant to the lower left vertice and
//  *    next cycles state should be waiting.
//  *
//  *
//  *   Author: John Brunhaver
//  *   Created:      Thu 07/23/09
//  *   Last Updated: Tue 10/01/10
//  *
//  *   Copyright 2009 <jbrunhaver@gmail.com>
//  *
//  */

// /* ***************************************************************************
//  * Change bar:
//  * -----------
//  * Date           Author    Description
//  * Sep 19, 2012   jingpu    ported from John's original code to Genesis
//  *
//  * ***************************************************************************/

// /* A Note on Signal Names:
//  *
//  * Most signals have a suffix of the form _RxxN
//  * where R indicates that it is a Raster Block signal
//  * xx indicates the clock slice that it belongs to
//  * and N indicates the type of signal that it is.
//  * H indicates logic high, L indicates logic low,
//  * U indicates unsigned fixed point, and S indicates
//  * signed fixed point.
//  *
//  * For all the signed fixed point signals (logic signed [`$sig_fig`-1:0]),
//  * their highest `$sig_fig-$radix` bits, namely [`$sig_fig-1`:`$radix`]
//  * represent the integer part of the fixed point number,
//  * while the lowest `$radix` bits, namely [`$radix-1`:0]
//  * represent the fractional part of the fixed point number.
//  *
//  *
//  *
//  * For signal subSample_RnnnnU (logic [3:0])
//  * 1000 for  1x MSAA eq to 1 sample per pixel
//  * 0100 for  4x MSAA eq to 4 samples per pixel,
//  *              a sample is half a pixel on a side
//  * 0010 for 16x MSAA eq to 16 sample per pixel,
//  *              a sample is a quarter pixel on a side.
//  * 0001 for 64x MSAA eq to 64 samples per pixel,
//  *              a sample is an eighth of a pixel on a side.
//  *
//  */

// module test_iterator
// #(
//     parameter SIGFIG = 24, // Bits in color and position.
//     parameter RADIX = 10, // Fraction bits in color and position
//     parameter VERTS = 3, // Maximum Vertices in triangle
//     parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
//     parameter COLORS = 3, // Number of color channels
//     parameter PIPE_DEPTH = 1, // How many pipe stages are in this block
//     parameter MOD_FSM = 0 // Use Modified FSM to eliminate a wait state
// )
// (
//     //Input Signals
//     input logic signed [SIGFIG-1:0]     tri_R13S[VERTS-1:0][AXIS-1:0], //triangle to Iterate Over
//     input logic unsigned [SIGFIG-1:0]   color_R13U[COLORS-1:0] , //Color of triangle
//     input logic signed [SIGFIG-1:0]     box_R13S[1:0][1:0], //Box to iterate for subsamples
//     input logic                             validTri_R13H, //triangle is valid

//     //Control Signals
//     input logic [3:0]   subSample_RnnnnU , //Subsample width
//     output logic        halt_RnnnnL , //Halt -> hold current microtriangle
//     //Note that this block generates
//     //Global Signals
//     input logic clk, // Clock
//     input logic rst, // Reset


//     //Outputs
//     output logic signed [SIGFIG-1:0]    tri_R14S[VERTS-1:0][AXIS-1:0], //triangle to Sample Test
//     output logic unsigned [SIGFIG-1:0]  color_R14U[COLORS-1:0] , //Color of triangle
//     // output logic signed [SIGFIG-1:0]    sample_R14S[1:0], //Sample Location to Be Tested
//     // output logic                            validSamp_R14H, //Sample and triangle are Valid

//     // output logic signed [SIGFIG-1:0]    sample_R14S_2[1:0], //Sample Location to Be Tested
//     // output logic                            validSamp_R14H_2 //Sample and triangle are Valid
//     output logic signed [SIGFIG-1:0]    sample_R14S[1:0], //Sample Location to Be Tested
//     output logic                            validSamp_R14H, //Sample and triangle are Valid

//     output logic signed [SIGFIG-1:0]    sample_R14S_2[1:0], //Sample Location to Be Tested
//     output logic                            validSamp_R14H_2 //Sample and triangle are Valid

//     // input logic hit_valid //  Signal from sample test that determines if we should stop our current right/left iterating
    
// );

//     // This module implement a Moore machine to iterarte sample points in bbox
//     // Recall: a Moore machine is an FSM whose output values are determined
//     // solely by its current state.
//     // A simple way to build a Moore machine is to make states for every output
//     // and the values of the current states are the outputs themselves

//     // Now we create the signals for the next states of each outputs and
//     // then instantiate registers for storing these states
//     logic signed [SIGFIG-1:0]       next_tri_R14S[VERTS-1:0][AXIS-1:0];
//     logic unsigned  [SIGFIG-1:0]    next_color_R14U[COLORS-1:0] ;
//     logic signed [SIGFIG-1:0]       next_sample_R14S[1:0];
//     logic                               next_validSamp_R14H;
//     logic                               next_halt_RnnnnL;
//     logic signed [SIGFIG-1:0]       next_sample_R14S_2[1:0];
//     logic                               next_validSamp_R14H_2;


//     // params for second sample
//     typedef enum logic {
//                         LAST_STATE,
//                         THIS_STATE
//     } state_t_second;

//     //////
//     //////  RTL code for original FSM Goes Here
//     //////

//     // To build this FSM we want to have two more state: one is the working
//     // status of this FSM, and the other is the current bounding box where
//     // we iterate sample points

//     // // define two more states, box_R14S and state_R14H
//     // logic signed [SIGFIG-1:0]   box_R14S[1:0][1:0];    		// the state for current bounding box
//     // logic signed [SIGFIG-1:0]   next_box_R14S[1:0][1:0];

//     state_t_second                     state_R14H_second;     //State Designation (Waiting or Testing)
//     state_t_second                   next_state_R14H_second;        //Next Cycles State
    
    

//     // define two more states, box_R14S and state_R14H
//     logic signed [SIGFIG-1:0]   box_R14S_second[1:0][1:0];    		// the state for current bounding box
//     logic signed [SIGFIG-1:0]   next_box_R14S_second[1:0][1:0];

//     // logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
//     // logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H_second;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H_second;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H_second;        //Current sample at end of bbox?

//     // logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
//     // logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H_2_second;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H_2_second;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H_2_second;        //Current sample at end of bbox?



//     logic signed [SIGFIG-1:0]   next_up_samp_R14S_second[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S_second[1:0]; //If jump right, next sample
//     logic signed [SIGFIG-1:0]   next_up_samp_R14S_2_second[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2_second[1:0]; //If jump right, next sample



//     logic                               next_validSamp_R14H_second;
//     logic                               next_validSamp_R14H_2_second;
//     logic signed [SIGFIG-1:0]       next_tri_R14S_second[VERTS-1:0][AXIS-1:0];
//     logic                               next_halt_RnnnnL_second;
//     logic unsigned  [SIGFIG-1:0]    next_color_R14U_second[COLORS-1:0];
//     logic signed [SIGFIG-1:0]       next_sample_R14S_second[1:0];
//     logic signed [SIGFIG-1:0]       next_sample_R14S_2_second[1:0];



//     // // Instantiate registers for storing these states
//     // dff3 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE1(VERTS),
//     //     .ARRAY_SIZE2(AXIS),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d301
//     // (
//     //     .clk    (clk            ),
//     //     .reset  (rst            ),
//     //     .en     (1'b1           ),
//     //     .in     (next_tri_R14S  ),
//     //     .out    (tri_R14S       )
//     // );

//     // dff2 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE(COLORS),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d302
//     // (
//     //     .clk    (clk            ),
//     //     .reset  (rst            ),
//     //     .en     (1'b1           ),
//     //     .in     (next_color_R14U),
//     //     .out    (color_R14U     )
//     // );

//     // dff2 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d303
//     // (
//     //     .clk    (clk                ),
//     //     .reset  (rst                ),
//     //     .en     (1'b1               ),
//     //     .in     (next_sample_R14S   ),
//     //     .out    (sample_R14S        )
//     // );

//     // dff2 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d303_2
//     // (
//     //     .clk    (clk                ),
//     //     .reset  (rst                ),
//     //     .en     (1'b1               ),
//     //     .in     (next_sample_R14S_2   ),
//     //     .out    (sample_R14S_2        )
//     // );


//     // dff #(
//     //     .WIDTH(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0) // No retime
//     // )
//     // d304
//     // (
//     //     .clk    (clk                                    ),
//     //     .reset  (rst                                    ),
//     //     .en     (1'b1                                   ),
//     //     .in     ({next_validSamp_R14H, next_validSamp_R14H_2, next_halt_RnnnnL}),
//     //     .out    ({validSamp_R14H, validSamp_R14H_2, halt_RnnnnL}          )
//     // );
//     // // Instantiate registers for storing these states



//     // Instantiate registers for storing these states using second round
//     dff3 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE1(VERTS),
//         .ARRAY_SIZE2(AXIS),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d301
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_tri_R14S_second  ),
//         .out    (tri_R14S       )
//     );

//     dff2 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE(COLORS),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d302
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_color_R14U_second),
//         .out    (color_R14U     )
//     );

//     dff2 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d303
//     (
//         .clk    (clk                ),
//         .reset  (rst                ),
//         .en     (1'b1               ),
//         .in     (next_sample_R14S_second   ),
//         .out    (sample_R14S        )
//     );

//     dff2 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d303_2
//     (
//         .clk    (clk                ),
//         .reset  (rst                ),
//         .en     (1'b1               ),
//         .in     (next_sample_R14S_2_second   ),
//         .out    (sample_R14S_2        )
//     );


//     dff_width3 #(
//         .WIDTH(3),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0) // No retime
//     )
//     d304
//     (
//         .clk    (clk                                    ),
//         .reset  (rst                                    ),
//         .en     (1'b1                                   ),
//         .in     ({next_validSamp_R14H_second, next_validSamp_R14H_2_second, next_halt_RnnnnL_second}),
//         .out    ({validSamp_R14H, validSamp_R14H_2, halt_RnnnnL}          )
//     );
//     // Instantiate registers for storing these states

//     typedef enum logic {
//                             WAIT_STATE,
//                             TEST_STATE
//                         } state_t;
// generate
// if(MOD_FSM == 0) begin // Using baseline FSM
//     //////
//     //////  RTL code for original FSM Goes Here
//     //////

//     // To build this FSM we want to have two more state: one is the working
//     // status of this FSM, and the other is the current bounding box where
//     // we iterate sample points

//     // define two more states, box_R14S and state_R14H
//     logic signed [SIGFIG-1:0]   box_R14S[1:0][1:0];    		// the state for current bounding box
//     logic signed [SIGFIG-1:0]   next_box_R14S[1:0][1:0];

//     state_t                     state_R14H;     //State Designation (Waiting or Testing)
//     state_t                     next_state_R14H;        //Next Cycles State

//     dff3 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE1(2),
//         .ARRAY_SIZE2(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d305
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_box_R14S  ),
//         .out    (box_R14S       )
//     );

//     always_ff @(posedge clk, posedge rst) begin
//         if(rst) begin
//             state_R14H <= WAIT_STATE;
//         end
//         else begin
//             state_R14H <= next_state_R14H;
//         end
//     end

//     // define some helper signals
//     logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H;        //Current sample at end of bbox?

//     logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H_2;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H_2;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H_2;        //Current sample at end of bbox?


//     //////
//     ////// First calculate the values of the helper signals using CURRENT STATES
//     //////

//     // check the comments 'A Note on Signal Names'
//     // at the begining of the module for the help on
//     // understanding the signals here
//     logic [RADIX+1:0] increment;
//     always_comb begin
//         case (subSample_RnnnnU)
//             4'b1000: increment = { 1'b1, {(RADIX){1'b0}} }; 
//             4'b0100: increment = { 1'b1, {(RADIX-1){1'b0}} }; 
//             4'b0010: increment = { 1'b1, {(RADIX-2){1'b0}} }; 
//             4'b0001: increment = { 1'b1, {(RADIX-3){1'b0}} }; 
//         endcase
//     end

//     always_comb begin
//         // START CODE HERE
//         next_up_samp_R14S = {sample_R14S[1] + increment, box_R14S[0][0]};
//         // next_up_samp_R14S[0] = box_R14S[0][0]; //box_R14S[0][0];

//         next_rt_samp_R14S = {sample_R14S[1], sample_R14S[0] + increment};
//         // next_rt_samp_R14S[1] = sample_R14S[1];
        
//         // at_right_edg_R14H = (sample_R14S[0] >= box_R14S[1][0]);
//         at_right_edg_R14H = (sample_R14S[0] >= box_R14S[1][0]);
        
//         // at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
//         at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
        
//         // at_end_box_R14H = at_right_edg_R14H && at_top_edg_R14H;

//         at_end_box_R14H = (at_top_edg_R14H && at_right_edg_R14H) || (sample_R14S[1]>sample_R14S_2[1]) || ((sample_R14S[1]==sample_R14S_2[1])&&(sample_R14S[0]>=sample_R14S_2[0]));
       
      




//         next_up_samp_R14S_2 = {sample_R14S_2[1] - increment, box_R14S[1][0]};
//         next_rt_samp_R14S_2 = {sample_R14S_2[1], sample_R14S_2[0] - increment};
//         // next_rt_samp_R14S[1] = sample_R14S[1];
        
//         // at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
//         // at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
//         // at_right_edg_R14H_2 = (sample_R14S_2[0] >= box_R14S[0][0]);
//         at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
//         at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
        
//         at_end_box_R14H_2 = at_right_edg_R14H_2 && at_top_edg_R14H_2;

//         // END CODE HERE
//     end
    

//     //////
//     ////// Then complete the following combinational logic defining the
//     ////// next states
//     //////

//     ////// COMPLETE THE FOLLOW ALWAYS_COMB BLOCK

//     always_comb begin	
//         // START CODE HERE
	
// 	    //$display("SAMPLE IS: %0d, %0d", box_R13S[0][0], box_R13S[0][1]);

//         // Try using a case statement on state_R14H
//         case (state_R14H)
//             WAIT_STATE : begin
//                 if (validTri_R13H) begin
//                     next_halt_RnnnnL = 1'b0;
//                     next_state_R14H = TEST_STATE;
//                     next_validSamp_R14H = 1'b1;
//                     next_validSamp_R14H_2 = 1'b1;

//                     next_box_R14S = box_R13S;  // latch the new box in 
//                     next_sample_R14S = box_R13S[0];  // latch the new sample in 
                    
//                     next_sample_R14S_2 = box_R13S[1];  // latch the new sample in

//                     next_color_R14U = color_R13U;
//                     next_tri_R14S = tri_R13S;
//                 end
//                 else begin
//                     next_halt_RnnnnL = 1'b1;
//                     next_state_R14H = WAIT_STATE;
//                     next_validSamp_R14H = 1'b0;
//                     next_validSamp_R14H_2 = 1'b0;

//                     next_box_R14S = box_R14S;
//                     next_sample_R14S = box_R13S[0];
//                     next_sample_R14S_2 = box_R13S[1];

//                     next_color_R14U = color_R14U;
//                     next_tri_R14S = tri_R14S;
//                 end
//             end
//             TEST_STATE : begin
//                 if (at_end_box_R14H) begin
//                     next_halt_RnnnnL = 1'b1;
//                     next_state_R14H = WAIT_STATE;
//                     next_validSamp_R14H = 1'b0;
//                     next_validSamp_R14H_2 = 1'b0;

//                     next_box_R14S = box_R14S;
//                     next_sample_R14S = box_R14S[0];
//                     next_sample_R14S_2 = box_R14S[1];

//                     next_color_R14U = color_R14U;
//                     next_tri_R14S = tri_R14S;

//                 end
//                 else begin
//                     next_halt_RnnnnL = 1'b0;
//                     next_state_R14H = TEST_STATE;
//                     next_validSamp_R14H = 1'b1;
//                     next_validSamp_R14H_2 = 1'b1;

//                     next_box_R14S = box_R14S;
//                     if (at_right_edg_R14H)
//                         next_sample_R14S = next_up_samp_R14S;
//                     else
//                         next_sample_R14S = next_rt_samp_R14S;
                    
//                     if (at_right_edg_R14H_2)
//                         next_sample_R14S_2 = next_up_samp_R14S_2;
//                     else
//                         next_sample_R14S_2 = next_rt_samp_R14S_2;

//                     next_color_R14U = color_R14U;
//                     next_tri_R14S = tri_R14S;

//                 end
//             end
//         endcase
//         // END CODE HERE
//     end // always_comb



























//     dff3 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE1(2),
//         .ARRAY_SIZE2(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d305_nxt
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_box_R14S_second  ),
//         .out    (box_R14S_second       )
//     );

//     always_ff @(posedge clk, posedge rst) begin
//         if(rst) begin
//             state_R14H_second <= LAST_STATE;
//         end
//         else begin
//             state_R14H_second <= next_state_R14H_second;
//         end
//     end

//     // // define some helper signals
//     // logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
//     // logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
//     // logic                       at_right_edg_R14H;      //Current sample at right edge of bbox?
//     // logic                       at_top_edg_R14H;        //Current sample at top edge of bbox?
//     // logic                       at_end_box_R14H;        //Current sample at end of bbox?
//     logic                       next_at_end_R14H;//next cycle at end of bbox?
    
//     // logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
//     // logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
//     // logic                       at_right_edg_R14H_2;      //Current sample at right edge of bbox?
//     // logic                       at_top_edg_R14H_2;        //Current sample at top edge of bbox?
//     // logic                       at_end_box_R14H_2;        //Current sample at end of bbox?


//     //////
//     ////// First calculate the values of the helper signals using CURRENT STATES
//     //////

//     assign next_at_end_R14H =(next_sample_R14S[1]>next_sample_R14S_2[1]) ||((next_sample_R14S[1]==next_sample_R14S_2[1])&&(next_sample_R14S[0]>=next_sample_R14S_2[0]));
    
//     // check the comments 'A Note on Signal Names'
//     // at the begining of the module for the help on
//     // understanding the signals here
//     logic [RADIX+1:0] increment_second;
//     always_comb begin
//         case (subSample_RnnnnU)
//             4'b1000: increment_second = { 1'b1, {(RADIX){1'b0}} }; 
//             4'b0100: increment_second = { 1'b1, {(RADIX-1){1'b0}} }; 
//             4'b0010: increment_second = { 1'b1, {(RADIX-2){1'b0}} }; 
//             4'b0001: increment_second = { 1'b1, {(RADIX-3){1'b0}} }; 
//         endcase
//     end

//     always_comb begin
//         // START CODE HERE
//         next_up_samp_R14S_second = {sample_R14S[1] + increment_second, box_R14S_second[0][0]};
//         // next_up_samp_R14S[1] = sample_R14S[1] + increment; // ( { {(RADIX-3){1'b0}}, subSample_RnnnnU} <<< (RADIX - 3) );
//         // next_up_samp_R14S[0] = box_R14S[0][0]; //box_R14S[0][0];

//         next_rt_samp_R14S_second = {sample_R14S[1], sample_R14S[0] + increment_second};
//         // next_rt_samp_R14S[1] = sample_R14S[1];
//         // next_rt_samp_R14S[0] = sample_R14S[0] + increment; // + ( { {(RADIX-3){1'b0}}, subSample_RnnnnU} <<< (RADIX - 3) );
        
//         // at_right_edg_R14H = (sample_R14S[0] >= box_R14S[1][0]);
//         at_right_edg_R14H_second = (sample_R14S[0] >= box_R14S_second[1][0]);
        
//         // at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
//         at_top_edg_R14H_second = (sample_R14S[1] >= box_R14S_second[1][1]);
        
//         // at_end_box_R14H = at_right_edg_R14H && at_top_edg_R14H;

//         at_end_box_R14H_second = (at_top_edg_R14H_second && at_right_edg_R14H_second) || (sample_R14S[1]>sample_R14S_2[1]) || ((sample_R14S[1]==sample_R14S_2[1])&&(sample_R14S[0]>=sample_R14S_2[0]));
       
      




//         next_up_samp_R14S_2_second = {sample_R14S_2[1] - increment_second, box_R14S_second[1][0]};
//         next_rt_samp_R14S_2_second = {sample_R14S_2[1], sample_R14S_2[0] - increment_second};
//         // next_rt_samp_R14S[1] = sample_R14S[1];
//         // next_rt_samp_R14S[0] = sample_R14S[0] + increment; // + ( { {(RADIX-3){1'b0}}, subSample_RnnnnU} <<< (RADIX - 3) );
        
//         // at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
//         // at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
//         // at_right_edg_R14H_2 = (sample_R14S_2[0] >= box_R14S[0][0]);
//         at_right_edg_R14H_2_second = (sample_R14S_2[0] <= box_R14S_second[0][0]);
        
//         at_top_edg_R14H_2_second = (sample_R14S_2[1] <= box_R14S_second[0][1]);
        
//         at_end_box_R14H_2_second = at_right_edg_R14H_2_second && at_top_edg_R14H_2_second;

//         // END CODE HERE
//     end
    

//     //////
//     ////// Then complete the following combinational logic defining the
//     ////// next states
//     //////

//     ////// COMPLETE THE FOLLOW ALWAYS_COMB BLOCK

//     always_comb begin	
//         // START CODE HERE
	
// 	    //$display("SAMPLE IS: %0d, %0d", box_R13S[0][0], box_R13S[0][1]);

//         // Try using a case statement on state_R14H
//         case (state_R14H_second)
//             LAST_STATE : begin
//                 if (validTri_R13H) begin
//                     // next_halt_RnnnnL = 1'b0;
//                     next_halt_RnnnnL_second = next_at_end_R14H;
//                     if(~next_at_end_R14H) begin
//                         next_state_R14H_second = THIS_STATE;
//                     end
//                     else begin
//                         next_state_R14H_second = LAST_STATE;
//                     end
//                     next_validSamp_R14H_second = 1'b1;
//                     next_validSamp_R14H_2_second = 1'b1;

//                     next_box_R14S_second = box_R13S;  // latch the new box in 
//                     next_sample_R14S_second = box_R13S[0];  // latch the new sample in 
                    
//                     next_sample_R14S_2_second = box_R13S[1];  // latch the new sample in

//                     next_color_R14U_second = color_R13U;
//                     next_tri_R14S_second = tri_R13S;
//                 end
//                 else begin
//                     next_halt_RnnnnL_second = 1'b1;
//                     next_state_R14H_second = LAST_STATE;
//                     next_validSamp_R14H_second = 1'b0;
//                     next_validSamp_R14H_2_second = 1'b0;

//                     next_box_R14S_second = box_R14S_second;
//                     next_sample_R14S_second = box_R13S[0];
//                     next_sample_R14S_2_second = box_R13S[1];

//                     next_color_R14U_second = color_R14U;
//                     next_tri_R14S_second = tri_R14S;
//                 end
//             end
//             THIS_STATE : begin
//                 if (at_end_box_R14H) begin
//                     next_halt_RnnnnL_second = 1'b1;
//                     next_state_R14H_second = LAST_STATE;
//                     next_validSamp_R14H_second = 1'b0;
//                     next_validSamp_R14H_2_second = 1'b0;

//                     next_box_R14S_second = box_R14S_second;
//                     next_sample_R14S_second = box_R14S_second[0];
//                     next_sample_R14S_2_second = box_R14S_second[1];

//                     next_color_R14U_second = color_R14U;
//                     next_tri_R14S_second = tri_R14S;

//                 end
//                 else begin
//                     next_halt_RnnnnL_second = 1'b0;
//                     next_state_R14H_second = THIS_STATE;
//                     next_validSamp_R14H_second = 1'b1;
//                     next_validSamp_R14H_2_second = 1'b1;

//                     next_box_R14S_second = box_R14S_second;
//                     if (at_right_edg_R14H)
//                         next_sample_R14S_second = next_up_samp_R14S_second;
//                     else
//                         next_sample_R14S_second = next_rt_samp_R14S_second;
                    
//                     if (at_right_edg_R14H_2)
//                         next_sample_R14S_2_second = next_up_samp_R14S_2_second;
//                     else
//                         next_sample_R14S_2_second = next_rt_samp_R14S_2_second;

//                     next_color_R14U_second = color_R14U;
//                     next_tri_R14S_second = tri_R14S;

//                 end
//             end
//         endcase
//         // END CODE HERE
//     end // always_comb


//     //Assertions for testing FSM logic

//     // Write assertions to verify your FSM transition sequence
//     // Can you verify that:
//     // 1) A validTri_R13H signal causes a transition from WAIT state to TEST state
//     // 2) An end_box_R14H signal causes a transition from TEST state to WAIT state
//     // 3) What are you missing?

//     //Your assertions goes here
//     // START CODE HERE

//     // assert property( @(posedge clk) (validTri_R13H |-> (state_R14H == WAIT_STATE) ##1 (next_state_R14H == TEST_STATE)));
//     // assert property( @(posedge clk) (at_end_box_R14H |-> (state_R14H == TEST_STATE) ##1 (next_state_R14H == WAIT_STATE)));
//     // I think we should check state_R14H on this clock and next_state_R14H on the next clock
//     // // always something wrong with assert
//     // assert property( @(posedge clk) ((validTri_R13H && (state_R14H == WAIT_STATE)) |-> ##1 (next_state_R14H == TEST_STATE)));
//     // assert property( @(posedge clk) ((at_end_box_R14H && (state_R14H == TEST_STATE)) |-> ##1 (next_state_R14H == WAIT_STATE)));
//     // // TODO: What else do we need? 
//     // assert property( @(posedge clk) ((!at_end_box_R14H && state_R14H == TEST_STATE) |=> (next_state_R14H == TEST_STATE)));
//     // assert property( @(posedge clk) ((!validTri_R13H && state_R14H == WAIT_STATE) |=> (next_state_R14H == WAIT_STATE)));
//     // not sure why for at_end_box_R14H signal, we need to check the transition on current clock

//     assert property( @(posedge clk) ((validTri_R13H && (state_R14H == WAIT_STATE)) |-> (next_state_R14H == TEST_STATE)));
//     assert property( @(posedge clk) ((at_end_box_R14H && (state_R14H == TEST_STATE)) |-> (next_state_R14H == WAIT_STATE)));
//     // // TODO: What else do we need? 
//     assert property( @(posedge clk) ((!at_end_box_R14H && state_R14H == TEST_STATE) |-> (next_state_R14H == TEST_STATE)));
//     assert property( @(posedge clk) ((!validTri_R13H && state_R14H == WAIT_STATE) |-> (next_state_R14H == WAIT_STATE)));

//     // END CODE HERE
//     // Assertion ends

//     //////
//     //////  RTL code for original FSM Finishes
//     //////

//     //Some Error Checking Assertions

//     //Define a Less Than Property
//     //
//     //  a should be less than b
//     property rb_lt( rst, a , b , c );
//         @(posedge clk) rst | ((a<=b) | !c);
//     endproperty

//     //Check that Proposed Sample is in BBox
//     // START CODE HERE

//     // Check that x values are within the bounding box

//     // assert property( rb_lt( rst, sample_R14S[0], box_R14S[1][0], validSamp_R14H ));  // less than upper right
//     // assert property( rb_lt( rst, box_R14S[0][0], sample_R14S[0], validSamp_R14H ));  // greater than lower left

//     // // Check that y values are within the bounding box
//     // assert property( rb_lt( rst, sample_R14S[1], box_R14S[1][1], validSamp_R14H ));  // less than upper right
//     // assert property( rb_lt( rst, box_R14S[0][1], sample_R14S[1], validSamp_R14H ));  // greater than lower left

//     // assert property(rb_lt(rst, box_R14S[0][0], sample_R14S[0], validSamp_R14H));
//     // assert property(rb_lt(rst, sample_R14S[0], box_R14S[1][0],  validSamp_R14H));
//     // assert property(rb_lt(rst, box_R14S[0][1], sample_R14S[1], validSamp_R14H));
//     // assert property(rb_lt(rst, sample_R14S[1], box_R14S[1][1],  validSamp_R14H));

    
//     // assert property(rb_lt(rst, next_sample_R14S[0], next_box_R14S[1][0], next_validSamp_R14H));  // less than upper right
//     // assert property(rb_lt(rst, next_box_R14S[0][0], next_sample_R14S[0], next_validSamp_R14H));  // greater than lower left

//     // // Check that y values are within the bounding box
//     // assert property(rb_lt(rst, next_sample_R14S[1], next_box_R14S[1][1], next_validSamp_R14H));  // less than upper right
//     // assert property(rb_lt(rst, next_box_R14S[0][1], next_sample_R14S[1], next_validSamp_R14H));  // greater than lower left


//     // initial begin
//     //     // $display("aaaaaaaaa");
//     //     // for(int i=0;i < 24; i++) begin
//     //     //     $display("%0d",box_R10S[1][0][i]);
//     //     // end
//     //     $display("aaaaaaaaa");
//     //     for(int i=0;i < 24; i++) begin
//     //         $display("%0d",next_box_R14S[0][0][i]);
//     //     end
//     //     $display("aaaaaaaaa");
//     //     for(int i=0;i < 24; i++) begin
//     //         $display("%0d",next_sample_R14S[0][i]);
//     //     end
//     // end

//     assert property(rb_lt(rst, next_sample_R14S[0], next_box_R14S[1][0], next_validSamp_R14H));  // less than upper right
//     assert property(rb_lt(rst, next_box_R14S[0][0], next_sample_R14S[0], next_validSamp_R14H));  // greater than lower left

//     // Check that y values are within the bounding box
//     assert property(rb_lt(rst, next_sample_R14S[1], next_box_R14S[1][1], next_validSamp_R14H));  // less than upper right
//     assert property(rb_lt(rst, next_box_R14S[0][1], next_sample_R14S[1], next_validSamp_R14H));  // greater than lower left


//     // END CODE HERE
//     // Check that Proposed Sample is in BBox

//     // Error Checking Assertions



// end 
// else begin // Use modified FSM

//     //////
//     //////  RTL code for modified FSM Goes Here
//     //////

//     ////// PLACE YOUR CODE HERE



//     //////
//     //////  RTL code for modified FSM Finishes
//     //////

// end
// endgenerate

// endmodule



/*
 *  Bounding Box Sample Test Iteration
 *
 *  Inputs:
 *    BBox and triangle Information
 *
 *  Outputs:
 *    Subsample location and triangle Information
 *
 *  Function:
 *    Iterate from left to right bottom to top
 *    across the bounding box.
 *
 *    While iterating set the halt signal in
 *    order to hold the bounding box pipeline in
 *    place.
 *
 *
 * Long Description:
 *    The iterator starts in the waiting state,
 *    when a valid triangle bounding box
 *    appears at the input. It will enter the
 *    testing state the next cycle with a
 *    sample equivelant to the lower left
 *    cooridinate of the bounding box.
 *
 *    While in the testing state, the next sample
 *    for each cycle should be one sample interval
 *    to the right, except when the current sample
 *    is at the right edge.  If the current sample
 *    is at the right edge, the next sample should
 *    be one row up.  Additionally, if the current
 *    sample is on the top row and the right edge,
 *    next cycles sample should be invalid and
 *    equivelant to the lower left vertice and
 *    next cycles state should be waiting.
 *
 *
 *   Author: John Brunhaver
 *   Created:      Thu 07/23/09
 *   Last Updated: Tue 10/01/10
 *
 *   Copyright 2009 <jbrunhaver@gmail.com>
 *
 */

/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 19, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/

/* A Note on Signal Names:
 *
 * Most signals have a suffix of the form _RxxN
 * where R indicates that it is a Raster Block signal
 * xx indicates the clock slice that it belongs to
 * and N indicates the type of signal that it is.
 * H indicates logic high, L indicates logic low,
 * U indicates unsigned fixed point, and S indicates
 * signed fixed point.
 *
 * For all the signed fixed point signals (logic signed [`$sig_fig`-1:0]),
 * their highest `$sig_fig-$radix` bits, namely [`$sig_fig-1`:`$radix`]
 * represent the integer part of the fixed point number,
 * while the lowest `$radix` bits, namely [`$radix-1`:0]
 * represent the fractional part of the fixed point number.
 *
 *
 *
 * For signal subSample_RnnnnU (logic [3:0])
 * 1000 for  1x MSAA eq to 1 sample per pixel
 * 0100 for  4x MSAA eq to 4 samples per pixel,
 *              a sample is half a pixel on a side
 * 0010 for 16x MSAA eq to 16 sample per pixel,
 *              a sample is a quarter pixel on a side.
 * 0001 for 64x MSAA eq to 64 samples per pixel,
 *              a sample is an eighth of a pixel on a side.
 *
 */

// module test_iterator
// #(
//     parameter SIGFIG = 24, // Bits in color and position.
//     parameter RADIX = 10, // Fraction bits in color and position
//     parameter VERTS = 3, // Maximum Vertices in triangle
//     parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
//     parameter COLORS = 3, // Number of color channels
//     parameter PIPE_DEPTH = 1, // How many pipe stages are in this block
//     parameter MOD_FSM = 0 // Use Modified FSM to eliminate a wait state
// )
// (
//     //Input Signals
//     input logic signed [SIGFIG-1:0]     tri_R13S[VERTS-1:0][AXIS-1:0], //triangle to Iterate Over
//     input logic unsigned [SIGFIG-1:0]   color_R13U[COLORS-1:0] , //Color of triangle
//     input logic signed [SIGFIG-1:0]     box_R13S[1:0][1:0], //Box to iterate for subsamples
//     input logic                             validTri_R13H, //triangle is valid

//     //Control Signals
//     input logic [3:0]   subSample_RnnnnU , //Subsample width
//     output logic        halt_RnnnnL , //Halt -> hold current microtriangle
//     //Note that this block generates
//     //Global Signals
//     input logic clk, // Clock
//     input logic rst, // Reset


//     //Outputs
//     output logic signed [SIGFIG-1:0]    tri_R14S[VERTS-1:0][AXIS-1:0], //triangle to Sample Test
//     output logic unsigned [SIGFIG-1:0]  color_R14U[COLORS-1:0] , //Color of triangle
//     // output logic signed [SIGFIG-1:0]    sample_R14S[1:0], //Sample Location to Be Tested
//     // output logic                            validSamp_R14H, //Sample and triangle are Valid

//     // output logic signed [SIGFIG-1:0]    sample_R14S_2[1:0], //Sample Location to Be Tested
//     // output logic                            validSamp_R14H_2 //Sample and triangle are Valid
//     output logic signed [SIGFIG-1:0]    sample_R14S[1:0], //Sample Location to Be Tested
//     output logic                            validSamp_R14H, //Sample and triangle are Valid

//     output logic signed [SIGFIG-1:0]    sample_R14S_2[1:0], //Sample Location to Be Tested
//     output logic                            validSamp_R14H_2 //Sample and triangle are Valid

//     // input logic hit_valid //  Signal from sample test that determines if we should stop our current right/left iterating
    
// );

//     // This module implement a Moore machine to iterarte sample points in bbox
//     // Recall: a Moore machine is an FSM whose output values are determined
//     // solely by its current state.
//     // A simple way to build a Moore machine is to make states for every output
//     // and the values of the current states are the outputs themselves

//     // Now we create the signals for the next states of each outputs and
//     // then instantiate registers for storing these states
//     logic signed [SIGFIG-1:0]       next_tri_R14S[VERTS-1:0][AXIS-1:0];
//     logic unsigned  [SIGFIG-1:0]    next_color_R14U[COLORS-1:0] ;
//     logic signed [SIGFIG-1:0]       next_sample_R14S[1:0];
//     logic                               next_validSamp_R14H;
//     logic                               next_halt_RnnnnL;
//     logic signed [SIGFIG-1:0]       next_sample_R14S_2[1:0];
//     logic                               next_validSamp_R14H_2;


//     // params for second sample
//     typedef enum logic {
//                         LAST_STATE,
//                         THIS_STATE
//     } state_t_second;

//     //////
//     //////  RTL code for original FSM Goes Here
//     //////

//     // To build this FSM we want to have two more state: one is the working
//     // status of this FSM, and the other is the current bounding box where
//     // we iterate sample points

//     // // define two more states, box_R14S and state_R14H
//     // logic signed [SIGFIG-1:0]   box_R14S[1:0][1:0];    		// the state for current bounding box
//     // logic signed [SIGFIG-1:0]   next_box_R14S[1:0][1:0];

//     state_t_second                     state_R14H_second;     //State Designation (Waiting or Testing)
//     state_t_second                   next_state_R14H_second;        //Next Cycles State
    
    

//     // define two more states, box_R14S and state_R14H
//     logic signed [SIGFIG-1:0]   box_R14S_second[1:0][1:0];    		// the state for current bounding box
//     logic signed [SIGFIG-1:0]   next_box_R14S_second[1:0][1:0];

//     // logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
//     // logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H_second;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H_second;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H_second;        //Current sample at end of bbox?

//     // logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
//     // logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H_2_second;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H_2_second;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H_2_second;        //Current sample at end of bbox?



//     logic signed [SIGFIG-1:0]   next_up_samp_R14S_second[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S_second[1:0]; //If jump right, next sample
//     logic signed [SIGFIG-1:0]   next_up_samp_R14S_2_second[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2_second[1:0]; //If jump right, next sample



//     logic                               next_validSamp_R14H_second;
//     logic                               next_validSamp_R14H_2_second;
//     logic signed [SIGFIG-1:0]       next_tri_R14S_second[VERTS-1:0][AXIS-1:0];
//     logic                               next_halt_RnnnnL_second;
//     logic unsigned  [SIGFIG-1:0]    next_color_R14U_second[COLORS-1:0];
//     logic signed [SIGFIG-1:0]       next_sample_R14S_second[1:0];
//     logic signed [SIGFIG-1:0]       next_sample_R14S_2_second[1:0];



//     // Instantiate registers for storing these states
//     dff3 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE1(VERTS),
//         .ARRAY_SIZE2(AXIS),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d301
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_tri_R14S  ),
//         .out    (tri_R14S       )
//     );

//     dff2 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE(COLORS),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d302
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_color_R14U),
//         .out    (color_R14U     )
//     );

//     dff2 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d303
//     (
//         .clk    (clk                ),
//         .reset  (rst                ),
//         .en     (1'b1               ),
//         .in     (next_sample_R14S   ),
//         .out    (sample_R14S        )
//     );

//     dff2 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d303_2
//     (
//         .clk    (clk                ),
//         .reset  (rst                ),
//         .en     (1'b1               ),
//         .in     (next_sample_R14S_2   ),
//         .out    (sample_R14S_2        )
//     );


//     dff_width3 #(
//         .WIDTH(3),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0) // No retime
//     )
//     d304
//     (
//         .clk    (clk                                    ),
//         .reset  (rst                                    ),
//         .en     (1'b1                                   ),
//         .in     ({next_validSamp_R14H, next_validSamp_R14H_2, next_halt_RnnnnL}),
//         .out    ({validSamp_R14H, validSamp_R14H_2, halt_RnnnnL}          )
//     );
//     // Instantiate registers for storing these states



//     // // Instantiate registers for storing these states using second round
//     // dff3 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE1(VERTS),
//     //     .ARRAY_SIZE2(AXIS),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d301
//     // (
//     //     .clk    (clk            ),
//     //     .reset  (rst            ),
//     //     .en     (1'b1           ),
//     //     .in     (next_tri_R14S_second  ),
//     //     .out    (tri_R14S       )
//     // );

//     // dff2 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE(COLORS),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d302
//     // (
//     //     .clk    (clk            ),
//     //     .reset  (rst            ),
//     //     .en     (1'b1           ),
//     //     .in     (next_color_R14U_second),
//     //     .out    (color_R14U     )
//     // );

//     // dff2 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d303
//     // (
//     //     .clk    (clk                ),
//     //     .reset  (rst                ),
//     //     .en     (1'b1               ),
//     //     .in     (next_sample_R14S_second   ),
//     //     .out    (sample_R14S        )
//     // );

//     // dff2 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d303_2
//     // (
//     //     .clk    (clk                ),
//     //     .reset  (rst                ),
//     //     .en     (1'b1               ),
//     //     .in     (next_sample_R14S_2_second   ),
//     //     .out    (sample_R14S_2        )
//     // );


//     // dff #(
//     //     .WIDTH(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0) // No retime
//     // )
//     // d304
//     // (
//     //     .clk    (clk                                    ),
//     //     .reset  (rst                                    ),
//     //     .en     (1'b1                                   ),
//     //     .in     ({next_validSamp_R14H_second, next_validSamp_R14H_2_second, next_halt_RnnnnL_second}),
//     //     .out    ({validSamp_R14H, validSamp_R14H_2, halt_RnnnnL}          )
//     // );
//     // // Instantiate registers for storing these states

//     typedef enum logic {
//                             WAIT_STATE,
//                             TEST_STATE
//                         } state_t;
// generate
// if(MOD_FSM == 0) begin // Using baseline FSM
//     //////
//     //////  RTL code for original FSM Goes Here
//     //////

//     // To build this FSM we want to have two more state: one is the working
//     // status of this FSM, and the other is the current bounding box where
//     // we iterate sample points

//     // define two more states, box_R14S and state_R14H
//     logic signed [SIGFIG-1:0]   box_R14S[1:0][1:0];    		// the state for current bounding box
//     logic signed [SIGFIG-1:0]   next_box_R14S[1:0][1:0];

//     state_t                     state_R14H;     //State Designation (Waiting or Testing)
//     state_t                     next_state_R14H;        //Next Cycles State

//     dff3 #(
//         .WIDTH(SIGFIG),
//         .ARRAY_SIZE1(2),
//         .ARRAY_SIZE2(2),
//         .PIPE_DEPTH(1),
//         .RETIME_STATUS(0)
//     )
//     d305
//     (
//         .clk    (clk            ),
//         .reset  (rst            ),
//         .en     (1'b1           ),
//         .in     (next_box_R14S  ),
//         .out    (box_R14S       )
//     );

//     always_ff @(posedge clk, posedge rst) begin
//         if(rst) begin
//             state_R14H <= WAIT_STATE;
//         end
//         else begin
//             state_R14H <= next_state_R14H;
//         end
//     end

//     // define some helper signals
//     logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H;        //Current sample at end of bbox?

//     logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
//     logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
//     logic                       at_right_edg_R14H_2;      //Current sample at right edge of bbox?
//     logic                       at_top_edg_R14H_2;        //Current sample at top edge of bbox?
//     logic                       at_end_box_R14H_2;        //Current sample at end of bbox?


//     //////
//     ////// First calculate the values of the helper signals using CURRENT STATES
//     //////

//     // check the comments 'A Note on Signal Names'
//     // at the begining of the module for the help on
//     // understanding the signals here
//     logic [RADIX+1:0] increment;
//     always_comb begin
//         case (subSample_RnnnnU)
//             4'b1000: increment = { 1'b1, {(RADIX){1'b0}} }; 
//             4'b0100: increment = { 1'b1, {(RADIX-1){1'b0}} }; 
//             4'b0010: increment = { 1'b1, {(RADIX-2){1'b0}} }; 
//             4'b0001: increment = { 1'b1, {(RADIX-3){1'b0}} }; 
//         endcase
//     end

//     always_comb begin
//         // START CODE HERE
//         next_up_samp_R14S = {sample_R14S[1] + increment, box_R14S[0][0]};
//         // next_up_samp_R14S[0] = box_R14S[0][0]; //box_R14S[0][0];

//         next_rt_samp_R14S = {sample_R14S[1], sample_R14S[0] + increment};
//         // next_rt_samp_R14S[1] = sample_R14S[1];
        
//         at_right_edg_R14H = (sample_R14S[0] >= box_R14S[1][0]);
        
//         // at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
//         at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
        
//         // at_end_box_R14H = at_right_edg_R14H && at_top_edg_R14H;

//         // at_end_box_R14H = (at_top_edg_R14H && at_right_edg_R14H) || (sample_R14S[1]>sample_R14S_2[1]) || ((sample_R14S[1]==sample_R14S_2[1])&&(sample_R14S[0]>=sample_R14S_2[0]));
       
      
//         at_end_box_R14H = (sample_R14S[1] == sample_R14S_2[1]&&(sample_R14S[0] == sample_R14S_2[0]||sample_R14S_2[0] == sample_R14S[0] + increment))
//                              ||((sample_R14S_2[1]==sample_R14S[1]+increment)&&at_right_edg_R14H);



//         next_up_samp_R14S_2 = {sample_R14S_2[1] - increment, box_R14S[1][0]};
//         next_rt_samp_R14S_2 = {sample_R14S_2[1], sample_R14S_2[0] - increment};
//         // next_rt_samp_R14S[1] = sample_R14S[1];
        
//         // at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
//         // at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
//         at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
//         at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
        
//         at_end_box_R14H_2 = at_right_edg_R14H_2 && at_top_edg_R14H_2;

//         // END CODE HERE
//     end
    

//     //////
//     ////// Then complete the following combinational logic defining the
//     ////// next states
//     //////

//     ////// COMPLETE THE FOLLOW ALWAYS_COMB BLOCK

//     always_comb begin	
//         // START CODE HERE
	
// 	    //$display("SAMPLE IS: %0d, %0d", box_R13S[0][0], box_R13S[0][1]);

//         // Try using a case statement on state_R14H
//         case (state_R14H)
//             WAIT_STATE : begin
//                 if (validTri_R13H) begin
//                     next_halt_RnnnnL = 1'b0;
//                     next_state_R14H = TEST_STATE;
//                     next_validSamp_R14H = 1'b1;
//                     next_validSamp_R14H_2 = 1'b1;

//                     next_box_R14S = box_R13S;  // latch the new box in 
//                     next_sample_R14S = box_R13S[0];  // latch the new sample in 
//                     next_sample_R14S_2 = box_R13S[1];  // latch the new sample in

//                     next_color_R14U = color_R13U;
//                     next_tri_R14S = tri_R13S;
//                 end
//                 else begin
//                     next_halt_RnnnnL = 1'b1;
//                     next_state_R14H = WAIT_STATE;
//                     next_validSamp_R14H = 1'b0;
//                     next_validSamp_R14H_2 = 1'b0;

//                     next_box_R14S = box_R14S;
//                     next_sample_R14S = box_R13S[0];
//                     next_sample_R14S_2 = box_R13S[1];

//                     next_color_R14U = color_R14U;
//                     next_tri_R14S = tri_R14S;
//                 end
//             end
//             TEST_STATE : begin
//                 if (at_end_box_R14H) begin
//                     next_halt_RnnnnL = 1'b1;
//                     next_state_R14H = WAIT_STATE;
//                     next_validSamp_R14H = 1'b0;
//                     next_validSamp_R14H_2 = 1'b0;

//                     next_box_R14S = box_R14S;
//                     next_sample_R14S = box_R14S[0];
//                     next_sample_R14S_2 = box_R14S[1];

//                     next_color_R14U = color_R14U;
//                     next_tri_R14S = tri_R14S;

//                 end
//                 else begin
//                     next_halt_RnnnnL = 1'b0;
//                     next_state_R14H = TEST_STATE;
//                     next_validSamp_R14H = 1'b1;
//                     next_validSamp_R14H_2 = 1'b1;

//                     next_box_R14S = box_R14S;
//                     if (at_right_edg_R14H)
//                         next_sample_R14S = next_up_samp_R14S;
//                     else
//                         next_sample_R14S = next_rt_samp_R14S;
                    
//                     if (at_right_edg_R14H_2)
//                         next_sample_R14S_2 = next_up_samp_R14S_2;
//                     else
//                         next_sample_R14S_2 = next_rt_samp_R14S_2;

//                     next_color_R14U = color_R14U;
//                     next_tri_R14S = tri_R14S;

//                 end
//             end
//         endcase
//         // END CODE HERE
//     end // always_comb



























//     // dff3 #(
//     //     .WIDTH(SIGFIG),
//     //     .ARRAY_SIZE1(2),
//     //     .ARRAY_SIZE2(2),
//     //     .PIPE_DEPTH(1),
//     //     .RETIME_STATUS(0)
//     // )
//     // d305_nxt
//     // (
//     //     .clk    (clk            ),
//     //     .reset  (rst            ),
//     //     .en     (1'b1           ),
//     //     .in     (next_box_R14S_second  ),
//     //     .out    (box_R14S_second       )
//     // );

//     // always_ff @(posedge clk, posedge rst) begin
//     //     if(rst) begin
//     //         state_R14H_second <= LAST_STATE;
//     //     end
//     //     else begin
//     //         state_R14H_second <= next_state_R14H_second;
//     //     end
//     // end

//     // // // define some helper signals
//     // // logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
//     // // logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
//     // // logic                       at_right_edg_R14H;      //Current sample at right edge of bbox?
//     // // logic                       at_top_edg_R14H;        //Current sample at top edge of bbox?
//     // // logic                       at_end_box_R14H;        //Current sample at end of bbox?
//     // logic                       next_at_end_R14H;//next cycle at end of bbox?
    
//     // // logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
//     // // logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
//     // // logic                       at_right_edg_R14H_2;      //Current sample at right edge of bbox?
//     // // logic                       at_top_edg_R14H_2;        //Current sample at top edge of bbox?
//     // // logic                       at_end_box_R14H_2;        //Current sample at end of bbox?


//     // //////
//     // ////// First calculate the values of the helper signals using CURRENT STATES
//     // //////

//     // assign next_at_end_R14H =(next_sample_R14S[1]>next_sample_R14S_2[1]) ||((next_sample_R14S[1]==next_sample_R14S_2[1])&&(next_sample_R14S[0]>=next_sample_R14S_2[0]));
        
//     // // check the comments 'A Note on Signal Names'
//     // // at the begining of the module for the help on
//     // // understanding the signals here
//     // logic [RADIX+1:0] increment_second;
//     // always_comb begin
//     //     case (subSample_RnnnnU)
//     //         4'b1000: increment_second = { 1'b1, {(RADIX){1'b0}} }; 
//     //         4'b0100: increment_second = { 1'b1, {(RADIX-1){1'b0}} }; 
//     //         4'b0010: increment_second = { 1'b1, {(RADIX-2){1'b0}} }; 
//     //         4'b0001: increment_second = { 1'b1, {(RADIX-3){1'b0}} }; 
//     //     endcase
//     // end

//     // always_comb begin
//     //     // START CODE HERE
//     //     next_up_samp_R14S_second = {sample_R14S[1] + increment_second, box_R14S_second[0][0]};
//     //     // next_up_samp_R14S[1] = sample_R14S[1] + increment; // ( { {(RADIX-3){1'b0}}, subSample_RnnnnU} <<< (RADIX - 3) );
//     //     // next_up_samp_R14S[0] = box_R14S[0][0]; //box_R14S[0][0];

//     //     next_rt_samp_R14S_second = {sample_R14S[1], sample_R14S[0] + increment_second};
//     //     // next_rt_samp_R14S[1] = sample_R14S[1];
//     //     // next_rt_samp_R14S[0] = sample_R14S[0] + increment; // + ( { {(RADIX-3){1'b0}}, subSample_RnnnnU} <<< (RADIX - 3) );
        
//     //     // at_right_edg_R14H = (sample_R14S[0] >= box_R14S[1][0]);
//     //     at_right_edg_R14H_second = (sample_R14S[0] == box_R14S_second[1][0]);
        
//     //     // at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
//     //     at_top_edg_R14H_second = (sample_R14S[1] >= box_R14S_second[1][1]);
        
//     //     // at_end_box_R14H = at_right_edg_R14H && at_top_edg_R14H;

//     //     at_end_box_R14H_second = (at_top_edg_R14H_second && at_right_edg_R14H_second) || (sample_R14S[1]>sample_R14S_2[1]) || ((sample_R14S[1]==sample_R14S_2[1])&&(sample_R14S[0]>=sample_R14S_2[0]));
       
      




//     //     next_up_samp_R14S_2_second = {sample_R14S_2[1] - increment_second, box_R14S_second[1][0]};
//     //     next_rt_samp_R14S_2_second = {sample_R14S_2[1], sample_R14S_2[0] - increment_second};
//     //     // next_rt_samp_R14S[1] = sample_R14S[1];
//     //     // next_rt_samp_R14S[0] = sample_R14S[0] + increment; // + ( { {(RADIX-3){1'b0}}, subSample_RnnnnU} <<< (RADIX - 3) );
        
//     //     // at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
//     //     // at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
//     //     // at_right_edg_R14H_2 = (sample_R14S_2[0] >= box_R14S[0][0]);
//     //     at_right_edg_R14H_2_second = (sample_R14S_2[0] == box_R14S_second[0][0]);
        
//     //     at_top_edg_R14H_2_second = (sample_R14S_2[1] <= box_R14S_second[0][1]);
        
//     //     at_end_box_R14H_2_second = at_right_edg_R14H_2_second && at_top_edg_R14H_2_second;

//     //     // END CODE HERE
//     // end
    

//     // //////
//     // ////// Then complete the following combinational logic defining the
//     // ////// next states
//     // //////

//     // ////// COMPLETE THE FOLLOW ALWAYS_COMB BLOCK

//     // always_comb begin	
//     //     // START CODE HERE
	
// 	//     //$display("SAMPLE IS: %0d, %0d", box_R13S[0][0], box_R13S[0][1]);

//     //     // Try using a case statement on state_R14H
//     //     case (state_R14H_second)
//     //         LAST_STATE : begin
//     //             if (validTri_R13H) begin
//     //                 // next_halt_RnnnnL = 1'b0;
//     //                 next_halt_RnnnnL_second = next_at_end_R14H;
//     //                 if(~next_at_end_R14H) begin
//     //                     next_state_R14H_second = THIS_STATE;
//     //                 end
//     //                 else begin
//     //                     next_state_R14H_second = LAST_STATE;
//     //                 end
//     //                 next_validSamp_R14H_second = 1'b1;
//     //                 next_validSamp_R14H_2_second = 1'b1;

//     //                 next_box_R14S_second = box_R13S;  // latch the new box in 
//     //                 next_sample_R14S_second = box_R13S[0];  // latch the new sample in 
                    
//     //                 next_sample_R14S_2_second = box_R13S[1];  // latch the new sample in

//     //                 next_color_R14U_second = color_R13U;
//     //                 next_tri_R14S_second = tri_R13S;
//     //             end
//     //             else begin
//     //                 next_halt_RnnnnL_second = 1'b1;
//     //                 next_state_R14H_second = LAST_STATE;
//     //                 next_validSamp_R14H_second = 1'b0;
//     //                 next_validSamp_R14H_2_second = 1'b0;

//     //                 next_box_R14S_second = box_R14S_second;
//     //                 next_sample_R14S_second = box_R13S[0];
//     //                 next_sample_R14S_2_second = box_R13S[1];

//     //                 next_color_R14U_second = color_R14U;
//     //                 next_tri_R14S_second = tri_R14S;
//     //             end
//     //         end
//     //         THIS_STATE : begin
//     //             if (at_end_box_R14H) begin
//     //                 next_halt_RnnnnL_second = 1'b1;
//     //                 next_state_R14H_second = LAST_STATE;
//     //                 next_validSamp_R14H_second = 1'b0;
//     //                 next_validSamp_R14H_2_second = 1'b0;

//     //                 next_box_R14S_second = box_R14S_second;
//     //                 // next_sample_R14S_second = box_R14S_second[0];
//     //                 // next_sample_R14S_2_second = box_R14S_second[1];

//     //                 if (at_right_edg_R14H)
//     //                     next_sample_R14S_second = next_up_samp_R14S_second;
//     //                 else
//     //                     next_sample_R14S_second = next_rt_samp_R14S_second;
                    
//     //                 if (at_right_edg_R14H_2)
//     //                     next_sample_R14S_2_second = next_up_samp_R14S_2_second;
//     //                 else
//     //                     next_sample_R14S_2_second = next_rt_samp_R14S_2_second;

//     //                 next_color_R14U_second = color_R14U;
//     //                 next_tri_R14S_second = tri_R14S;

//     //             end
//     //             else begin
//     //                 next_halt_RnnnnL_second = 1'b0;
//     //                 next_state_R14H_second = THIS_STATE;
//     //                 next_validSamp_R14H_second = 1'b1;
//     //                 next_validSamp_R14H_2_second = 1'b1;

//     //                 next_box_R14S_second = box_R14S_second;
//     //                 if (at_right_edg_R14H)
//     //                     next_sample_R14S_second = next_up_samp_R14S_second;
//     //                 else
//     //                     next_sample_R14S_second = next_rt_samp_R14S_second;
                    
//     //                 if (at_right_edg_R14H_2)
//     //                     next_sample_R14S_2_second = next_up_samp_R14S_2_second;
//     //                 else
//     //                     next_sample_R14S_2_second = next_rt_samp_R14S_2_second;

//     //                 next_color_R14U_second = color_R14U;
//     //                 next_tri_R14S_second = tri_R14S;

//     //             end
//     //         end
//     //     endcase
//     //     // END CODE HERE
//     // end // always_comb


//     //Assertions for testing FSM logic

//     // Write assertions to verify your FSM transition sequence
//     // Can you verify that:
//     // 1) A validTri_R13H signal causes a transition from WAIT state to TEST state
//     // 2) An end_box_R14H signal causes a transition from TEST state to WAIT state
//     // 3) What are you missing?

//     //Your assertions goes here
//     // START CODE HERE

//     // assert property( @(posedge clk) (validTri_R13H |-> (state_R14H == WAIT_STATE) ##1 (next_state_R14H == TEST_STATE)));
//     // assert property( @(posedge clk) (at_end_box_R14H |-> (state_R14H == TEST_STATE) ##1 (next_state_R14H == WAIT_STATE)));
//     // I think we should check state_R14H on this clock and next_state_R14H on the next clock
//     // // always something wrong with assert
//     // assert property( @(posedge clk) ((validTri_R13H && (state_R14H == WAIT_STATE)) |-> ##1 (next_state_R14H == TEST_STATE)));
//     // assert property( @(posedge clk) ((at_end_box_R14H && (state_R14H == TEST_STATE)) |-> ##1 (next_state_R14H == WAIT_STATE)));
//     // // TODO: What else do we need? 
//     // assert property( @(posedge clk) ((!at_end_box_R14H && state_R14H == TEST_STATE) |=> (next_state_R14H == TEST_STATE)));
//     // assert property( @(posedge clk) ((!validTri_R13H && state_R14H == WAIT_STATE) |=> (next_state_R14H == WAIT_STATE)));
//     // not sure why for at_end_box_R14H signal, we need to check the transition on current clock

//     assert property( @(posedge clk) ((validTri_R13H && (state_R14H == WAIT_STATE)) |-> (next_state_R14H == TEST_STATE)));
//     assert property( @(posedge clk) ((at_end_box_R14H && (state_R14H == TEST_STATE)) |-> (next_state_R14H == WAIT_STATE)));
//     // // TODO: What else do we need? 
//     assert property( @(posedge clk) ((!at_end_box_R14H && state_R14H == TEST_STATE) |-> (next_state_R14H == TEST_STATE)));
//     assert property( @(posedge clk) ((!validTri_R13H && state_R14H == WAIT_STATE) |-> (next_state_R14H == WAIT_STATE)));

//     // END CODE HERE
//     // Assertion ends

//     //////
//     //////  RTL code for original FSM Finishes
//     //////

//     //Some Error Checking Assertions

//     //Define a Less Than Property
//     //
//     //  a should be less than b
//     property rb_lt( rst, a , b , c );
//         @(posedge clk) rst | ((a<=b) | !c);
//     endproperty

//     //Check that Proposed Sample is in BBox
//     // START CODE HERE

//     // Check that x values are within the bounding box

//     // assert property( rb_lt( rst, sample_R14S[0], box_R14S[1][0], validSamp_R14H ));  // less than upper right
//     // assert property( rb_lt( rst, box_R14S[0][0], sample_R14S[0], validSamp_R14H ));  // greater than lower left

//     // // Check that y values are within the bounding box
//     // assert property( rb_lt( rst, sample_R14S[1], box_R14S[1][1], validSamp_R14H ));  // less than upper right
//     // assert property( rb_lt( rst, box_R14S[0][1], sample_R14S[1], validSamp_R14H ));  // greater than lower left

//     // assert property(rb_lt(rst, box_R14S[0][0], sample_R14S[0], validSamp_R14H));
//     // assert property(rb_lt(rst, sample_R14S[0], box_R14S[1][0],  validSamp_R14H));
//     // assert property(rb_lt(rst, box_R14S[0][1], sample_R14S[1], validSamp_R14H));
//     // assert property(rb_lt(rst, sample_R14S[1], box_R14S[1][1],  validSamp_R14H));

    
//     // assert property(rb_lt(rst, next_sample_R14S[0], next_box_R14S[1][0], next_validSamp_R14H));  // less than upper right
//     // assert property(rb_lt(rst, next_box_R14S[0][0], next_sample_R14S[0], next_validSamp_R14H));  // greater than lower left

//     // // Check that y values are within the bounding box
//     // assert property(rb_lt(rst, next_sample_R14S[1], next_box_R14S[1][1], next_validSamp_R14H));  // less than upper right
//     // assert property(rb_lt(rst, next_box_R14S[0][1], next_sample_R14S[1], next_validSamp_R14H));  // greater than lower left


//     // initial begin
//     //     // $display("aaaaaaaaa");
//     //     // for(int i=0;i < 24; i++) begin
//     //     //     $display("%0d",box_R10S[1][0][i]);
//     //     // end
//     //     $display("aaaaaaaaa");
//     //     for(int i=0;i < 24; i++) begin
//     //         $display("%0d",next_box_R14S[0][0][i]);
//     //     end
//     //     $display("aaaaaaaaa");
//     //     for(int i=0;i < 24; i++) begin
//     //         $display("%0d",next_sample_R14S[0][i]);
//     //     end
//     // end

//     assert property(rb_lt(rst, next_sample_R14S[0], next_box_R14S[1][0], next_validSamp_R14H));  // less than upper right
//     assert property(rb_lt(rst, next_box_R14S[0][0], next_sample_R14S[0], next_validSamp_R14H));  // greater than lower left

//     // Check that y values are within the bounding box
//     assert property(rb_lt(rst, next_sample_R14S[1], next_box_R14S[1][1], next_validSamp_R14H));  // less than upper right
//     assert property(rb_lt(rst, next_box_R14S[0][1], next_sample_R14S[1], next_validSamp_R14H));  // greater than lower left


//     // END CODE HERE
//     // Check that Proposed Sample is in BBox

//     // Error Checking Assertions



// end 
// else begin // Use modified FSM

//     //////
//     //////  RTL code for modified FSM Goes Here
//     //////

//     ////// PLACE YOUR CODE HERE



//     //////
//     //////  RTL code for modified FSM Finishes
//     //////

// end
// endgenerate

// endmodule



module test_iterator
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter PIPE_DEPTH = 1, // How many pipe stages are in this block
    parameter MOD_FSM = 0 // Use Modified FSM to eliminate a wait state
)
(
    //Input Signals
    input logic signed [SIGFIG-1:0]     tri_R13S[VERTS-1:0][AXIS-1:0], //triangle to Iterate Over
    input logic unsigned [SIGFIG-1:0]   color_R13U[COLORS-1:0] , //Color of triangle
    input logic signed [SIGFIG-1:0]     box_R13S[1:0][1:0], //Box to iterate for subsamples
    input logic                             validTri_R13H, //triangle is valid

    //Control Signals
    input logic [3:0]   subSample_RnnnnU , //Subsample width
    output logic        halt_RnnnnL , //Halt -> hold current microtriangle
    //Note that this block generates
    //Global Signals
    input logic clk, // Clock
    input logic rst, // Reset


    //Outputs
    output logic signed [SIGFIG-1:0]    tri_R14S[VERTS-1:0][AXIS-1:0], //triangle to Sample Test
    output logic unsigned [SIGFIG-1:0]  color_R14U[COLORS-1:0] , //Color of triangle
    // output logic signed [SIGFIG-1:0]    sample_R14S[1:0], //Sample Location to Be Tested
    // output logic                            validSamp_R14H, //Sample and triangle are Valid

    // output logic signed [SIGFIG-1:0]    sample_R14S_2[1:0], //Sample Location to Be Tested
    // output logic                            validSamp_R14H_2 //Sample and triangle are Valid
    output logic signed [SIGFIG-1:0]    sample_R14S[1:0], //Sample Location to Be Tested
    output logic                            validSamp_R14H, //Sample and triangle are Valid

    output logic signed [SIGFIG-1:0]    sample_R14S_2[1:0], //Sample Location to Be Tested
    output logic                            validSamp_R14H_2 //Sample and triangle are Valid

    // input logic hit_valid //  Signal from sample test that determines if we should stop our current right/left iterating
    
);

    // This module implement a Moore machine to iterarte sample points in bbox
    // Recall: a Moore machine is an FSM whose output values are determined
    // solely by its current state.
    // A simple way to build a Moore machine is to make states for every output
    // and the values of the current states are the outputs themselves

    // Now we create the signals for the next states of each outputs and
    // then instantiate registers for storing these states
    logic signed [SIGFIG-1:0]       next_tri_R14S[VERTS-1:0][AXIS-1:0];
    logic unsigned  [SIGFIG-1:0]    next_color_R14U[COLORS-1:0] ;
    logic signed [SIGFIG-1:0]       next_sample_R14S[1:0];
    logic                               next_validSamp_R14H;
    logic                               next_halt_RnnnnL;
    logic signed [SIGFIG-1:0]       next_sample_R14S_2[1:0];
    logic                               next_validSamp_R14H_2;


    // Instantiate registers for storing these states
    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(VERTS),
        .ARRAY_SIZE2(AXIS),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d301
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (1'b1           ),
        .in     (next_tri_R14S  ),
        .out    (tri_R14S       )
    );

    dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(COLORS),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d302
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (1'b1           ),
        .in     (next_color_R14U),
        .out    (color_R14U     )
    );

    dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(2),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d303
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (next_sample_R14S   ),
        .out    (sample_R14S        )
    );

    dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(2),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d303_2
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (next_sample_R14S_2   ),
        .out    (sample_R14S_2        )
    );


    dff_width3 #(
        .WIDTH(3),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )
    d304
    (
        .clk    (clk                                    ),
        .reset  (rst                                    ),
        .en     (1'b1                                   ),
        .in     ({next_validSamp_R14H, next_validSamp_R14H_2, next_halt_RnnnnL}),
        .out    ({validSamp_R14H, validSamp_R14H_2, halt_RnnnnL}          )
    );
    // Instantiate registers for storing these states



    // // Instantiate registers for storing these states using second round
    // dff3 #(
    //     .WIDTH(SIGFIG),
    //     .ARRAY_SIZE1(VERTS),
    //     .ARRAY_SIZE2(AXIS),
    //     .PIPE_DEPTH(1),
    //     .RETIME_STATUS(0)
    // )
    // d301
    // (
    //     .clk    (clk            ),
    //     .reset  (rst            ),
    //     .en     (1'b1           ),
    //     .in     (next_tri_R14S_second  ),
    //     .out    (tri_R14S       )
    // );

    // dff2 #(
    //     .WIDTH(SIGFIG),
    //     .ARRAY_SIZE(COLORS),
    //     .PIPE_DEPTH(1),
    //     .RETIME_STATUS(0)
    // )
    // d302
    // (
    //     .clk    (clk            ),
    //     .reset  (rst            ),
    //     .en     (1'b1           ),
    //     .in     (next_color_R14U_second),
    //     .out    (color_R14U     )
    // );

    // dff2 #(
    //     .WIDTH(SIGFIG),
    //     .ARRAY_SIZE(2),
    //     .PIPE_DEPTH(1),
    //     .RETIME_STATUS(0)
    // )
    // d303
    // (
    //     .clk    (clk                ),
    //     .reset  (rst                ),
    //     .en     (1'b1               ),
    //     .in     (next_sample_R14S_second   ),
    //     .out    (sample_R14S        )
    // );

    // dff2 #(
    //     .WIDTH(SIGFIG),
    //     .ARRAY_SIZE(2),
    //     .PIPE_DEPTH(1),
    //     .RETIME_STATUS(0)
    // )
    // d303_2
    // (
    //     .clk    (clk                ),
    //     .reset  (rst                ),
    //     .en     (1'b1               ),
    //     .in     (next_sample_R14S_2_second   ),
    //     .out    (sample_R14S_2        )
    // );


    // dff #(
    //     .WIDTH(2),
    //     .PIPE_DEPTH(1),
    //     .RETIME_STATUS(0) // No retime
    // )
    // d304
    // (
    //     .clk    (clk                                    ),
    //     .reset  (rst                                    ),
    //     .en     (1'b1                                   ),
    //     .in     ({next_validSamp_R14H_second, next_validSamp_R14H_2_second, next_halt_RnnnnL_second}),
    //     .out    ({validSamp_R14H, validSamp_R14H_2, halt_RnnnnL}          )
    // );
    // // Instantiate registers for storing these states

    typedef enum logic {
                            WAIT_STATE,
                            TEST_STATE
                        } state_t;
generate
if(MOD_FSM == 0) begin // Using baseline FSM
    //////
    //////  RTL code for original FSM Goes Here
    //////

    // To build this FSM we want to have two more state: one is the working
    // status of this FSM, and the other is the current bounding box where
    // we iterate sample points

    // define two more states, box_R14S and state_R14H
    logic signed [SIGFIG-1:0]   box_R14S[1:0][1:0];    		// the state for current bounding box
    logic signed [SIGFIG-1:0]   next_box_R14S[1:0][1:0];

    state_t                     state_R14H;     //State Designation (Waiting or Testing)
    state_t                     next_state_R14H;        //Next Cycles State

    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(2),
        .ARRAY_SIZE2(2),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d305
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (1'b1           ),
        .in     (next_box_R14S  ),
        .out    (box_R14S       )
    );

    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            state_R14H <= WAIT_STATE;
        end
        else begin
            state_R14H <= next_state_R14H;
        end
    end

    // define some helper signals
    logic signed [SIGFIG-1:0]   next_up_samp_R14S[1:0]; //If jump up, next sample
    logic signed [SIGFIG-1:0]   next_rt_samp_R14S[1:0]; //If jump right, next sample
    logic                       at_right_edg_R14H;      //Current sample at right edge of bbox?
    // logic                       at_top_edg_R14H;        //Current sample at top edge of bbox?
    logic                       at_end_box_R14H;        //Current sample at end of bbox?

    logic signed [SIGFIG-1:0]   next_up_samp_R14S_2[1:0]; //If jump up, next sample
    logic signed [SIGFIG-1:0]   next_rt_samp_R14S_2[1:0]; //If jump right, next sample
    logic                       at_right_edg_R14H_2;      //Current sample at right edge of bbox?
    // logic                       at_top_edg_R14H_2;        //Current sample at top edge of bbox?
    // logic                       at_end_box_R14H_2;        //Current sample at end of bbox?


    //////
    ////// First calculate the values of the helper signals using CURRENT STATES
    //////

    // check the comments 'A Note on Signal Names'
    // at the begining of the module for the help on
    // understanding the signals here
    logic [RADIX+1:0] increment;
    always_comb begin
        case (subSample_RnnnnU)
            4'b1000: increment = { 1'b1, {(RADIX){1'b0}} }; 
            4'b0100: increment = { 1'b1, {(RADIX-1){1'b0}} }; 
            4'b0010: increment = { 1'b1, {(RADIX-2){1'b0}} }; 
            4'b0001: increment = { 1'b1, {(RADIX-3){1'b0}} }; 
        endcase
    end

    always_comb begin
        // START CODE HERE
        next_up_samp_R14S = {sample_R14S[1] + increment, box_R14S[0][0]};
        // next_up_samp_R14S[0] = box_R14S[0][0]; //box_R14S[0][0];

        next_rt_samp_R14S = {sample_R14S[1], sample_R14S[0] + increment};
        // next_rt_samp_R14S[1] = sample_R14S[1];
        
        at_right_edg_R14H = (sample_R14S[0] >= box_R14S[1][0]);
        
        // at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
        // at_top_edg_R14H = (sample_R14S[1] >= box_R14S[1][1]);
        
        // at_end_box_R14H = at_right_edg_R14H && at_top_edg_R14H;

        // at_end_box_R14H = (at_top_edg_R14H && at_right_edg_R14H) || (sample_R14S[1]>sample_R14S_2[1]) || ((sample_R14S[1]==sample_R14S_2[1])&&(sample_R14S[0]>=sample_R14S_2[0]));
       
      
        at_end_box_R14H = (sample_R14S[1] == sample_R14S_2[1]&&(sample_R14S[0] == sample_R14S_2[0]||sample_R14S_2[0] == sample_R14S[0] + increment))
                             ||((sample_R14S_2[1]==sample_R14S[1]+increment)&&at_right_edg_R14H);



        next_up_samp_R14S_2 = {sample_R14S_2[1] - increment, box_R14S[1][0]};
        next_rt_samp_R14S_2 = {sample_R14S_2[1], sample_R14S_2[0] - increment};
        // next_rt_samp_R14S[1] = sample_R14S[1];
        
        // at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
        // at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
        at_right_edg_R14H_2 = (sample_R14S_2[0] <= box_R14S[0][0]);
        
        // at_top_edg_R14H_2 = (sample_R14S_2[1] <= box_R14S[0][1]);
        
        // at_end_box_R14H_2 = at_right_edg_R14H_2 && at_top_edg_R14H_2;

        // END CODE HERE
    end
    

    //////
    ////// Then complete the following combinational logic defining the
    ////// next states
    //////

    ////// COMPLETE THE FOLLOW ALWAYS_COMB BLOCK

    always_comb begin	
        // START CODE HERE
	
	    //$display("SAMPLE IS: %0d, %0d", box_R13S[0][0], box_R13S[0][1]);

        // Try using a case statement on state_R14H
        case (state_R14H)
            WAIT_STATE : begin
                if (validTri_R13H) begin
                    next_halt_RnnnnL = 1'b0;
                    next_state_R14H = TEST_STATE;
                    next_validSamp_R14H = 1'b1;
                    next_validSamp_R14H_2 = 1'b1;

                    next_box_R14S = box_R13S;  // latch the new box in 
                    next_sample_R14S = box_R13S[0];  // latch the new sample in 
                    next_sample_R14S_2 = box_R13S[1];  // latch the new sample in

                    next_color_R14U = color_R13U;
                    next_tri_R14S = tri_R13S;
                end
                else begin
                    next_halt_RnnnnL = 1'b1;
                    next_state_R14H = WAIT_STATE;
                    next_validSamp_R14H = 1'b0;
                    next_validSamp_R14H_2 = 1'b0;

                    next_box_R14S = box_R14S;
                    next_sample_R14S = box_R13S[0];
                    next_sample_R14S_2 = box_R13S[1];

                    next_color_R14U = color_R14U;
                    next_tri_R14S = tri_R14S;
                end
            end
            TEST_STATE : begin
                if (at_end_box_R14H) begin
                    next_halt_RnnnnL = 1'b1;
                    next_state_R14H = WAIT_STATE;
                    next_validSamp_R14H = 1'b0;
                    next_validSamp_R14H_2 = 1'b0;

                    next_box_R14S = box_R14S;
                    next_sample_R14S = box_R14S[0];
                    next_sample_R14S_2 = box_R14S[1];

                    next_color_R14U = color_R14U;
                    next_tri_R14S = tri_R14S;

                end
                else begin
                    next_halt_RnnnnL = 1'b0;
                    next_state_R14H = TEST_STATE;
                    next_validSamp_R14H = 1'b1;
                    next_validSamp_R14H_2 = 1'b1;

                    next_box_R14S = box_R14S;
                    if (at_right_edg_R14H)
                        next_sample_R14S = next_up_samp_R14S;
                    else
                        next_sample_R14S = next_rt_samp_R14S;
                    
                    if (at_right_edg_R14H_2)
                        next_sample_R14S_2 = next_up_samp_R14S_2;
                    else
                        next_sample_R14S_2 = next_rt_samp_R14S_2;

                    next_color_R14U = color_R14U;
                    next_tri_R14S = tri_R14S;

                end
            end
        endcase
        // END CODE HERE
    end // always_comb


















    assert property( @(posedge clk) ((validTri_R13H && (state_R14H == WAIT_STATE)) |-> (next_state_R14H == TEST_STATE)));
    assert property( @(posedge clk) ((at_end_box_R14H && (state_R14H == TEST_STATE)) |-> (next_state_R14H == WAIT_STATE)));
    // // TODO: What else do we need? 
    assert property( @(posedge clk) ((!at_end_box_R14H && state_R14H == TEST_STATE) |-> (next_state_R14H == TEST_STATE)));
    assert property( @(posedge clk) ((!validTri_R13H && state_R14H == WAIT_STATE) |-> (next_state_R14H == WAIT_STATE)));

    // END CODE HERE
    // Assertion ends

    //////
    //////  RTL code for original FSM Finishes
    //////

    //Some Error Checking Assertions

    //Define a Less Than Property
    //
    //  a should be less than b
    property rb_lt( rst, a , b , c );
        @(posedge clk) rst | ((a<=b) | !c);
    endproperty

    assert property(rb_lt(rst, next_sample_R14S[0], next_box_R14S[1][0], next_validSamp_R14H));  // less than upper right
    assert property(rb_lt(rst, next_box_R14S[0][0], next_sample_R14S[0], next_validSamp_R14H));  // greater than lower left

    // Check that y values are within the bounding box
    assert property(rb_lt(rst, next_sample_R14S[1], next_box_R14S[1][1], next_validSamp_R14H));  // less than upper right
    assert property(rb_lt(rst, next_box_R14S[0][1], next_sample_R14S[1], next_validSamp_R14H));  // greater than lower left


    // END CODE HERE
    // Check that Proposed Sample is in BBox

    // Error Checking Assertions



end 
else begin // Use modified FSM

    //////
    //////  RTL code for modified FSM Goes Here
    //////

    ////// PLACE YOUR CODE HERE



    //////
    //////  RTL code for modified FSM Finishes
    //////

end
endgenerate

endmodule

