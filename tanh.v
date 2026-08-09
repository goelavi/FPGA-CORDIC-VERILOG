`timescale 1ns / 1ps

module cordic(
    input clk,
    input start,
    input rst,
    input signed [20:0] angle,
    output reg signed [20:0] tanh_out
);
parameter ITER = 18;
parameter IDLE        = 2'd0;
parameter CORDIC_HYP  = 2'd1;
parameter CORDIC_DIV  = 2'd2;
parameter OUTPUT      = 2'd3;
reg [1:0] state;
reg [4:0] current_iter;
reg signed [20:0] x, y, z;
reg signed [20:0] x_temp, y_temp;
// atanh lookup table
wire signed [20:0] atanh_table [0:ITER-1];
assign atanh_table[00] = 21'b000001000110010100000;
assign atanh_table[01] = 21'b000000100000101100001;
assign atanh_table[02] = 21'b000000010000001010100;
assign atanh_table[03] = 21'b000000001000000011010;
assign atanh_table[04] = 21'b000000001000000011010;
assign atanh_table[05] = 21'b000000000100000001101;
assign atanh_table[06] = 21'b000000000010000000111;
assign atanh_table[07] = 21'b000000000001000000001;
assign atanh_table[08] = 21'b000000000000100000000;
assign atanh_table[09] = 21'b000000000000010000000;
assign atanh_table[10] = 21'b000000000000001000000;
assign atanh_table[11] = 21'b000000000000000100000;
assign atanh_table[12] = 21'b000000000000000010000;
assign atanh_table[13] = 21'b000000000000000001000;
assign atanh_table[14] = 21'b000000000000000001000;
assign atanh_table[15] = 21'b000000000000000000100;
assign atanh_table[16] = 21'b000000000000000000010;
assign atanh_table[17] = 21'b000000000000000000001;
// shift schedule
wire [5:0] shift [0:ITER-1];
assign shift[00] = 1;
assign shift[01] = 2;
assign shift[02] = 3;
assign shift[03] = 4;
assign shift[04] = 4;
assign shift[05] = 5;
assign shift[06] = 6;
assign shift[07] = 7;
assign shift[08] = 8;
assign shift[09] = 9;
assign shift[10] = 10;
assign shift[11] = 11;
assign shift[12] = 12;
assign shift[13] = 13;
assign shift[14] = 13;
assign shift[15] = 14;
assign shift[16] = 15;
assign shift[17] = 16;
always @(posedge clk) begin

    if (rst) begin

        state <= IDLE;

        x <= 0;

        y <= 0;

        z <= 0;

        tanh_out <= 0;

        current_iter <= 0;

    end else begin

        case (state)



        // ---------------- IDLE ----------------

        IDLE: begin

            if (start) begin

                x <= 21'b000010011010000100000; // precomputed K^-1

                y <= 0;

                z <= angle;

                current_iter <= 0;

                state <= CORDIC_HYP;

            end

        end



        // ------------ HYPERBOLIC CORDIC ------------

        CORDIC_HYP: begin

            if (current_iter < ITER) begin



                // compute using temp variables (CRITICAL FIX)

                if (z[20] == 1'b0) begin

                    x_temp = x + (y >>> shift[current_iter]);

                    y_temp = y + (x >>> shift[current_iter]);

                    z      <= z - atanh_table[current_iter];

                end else begin

                    x_temp = x - (y >>> shift[current_iter]);

                    y_temp = y - (x >>> shift[current_iter]);

                    z      <= z + atanh_table[current_iter];

                end



                x <= x_temp;

                y <= y_temp;

                current_iter <= current_iter + 1;



            end else begin

                current_iter <= 0;

                z <= 0;

                state <= CORDIC_DIV;

            end

        end



        // ---------------- DIVISION (y/x) ----------------

        CORDIC_DIV: begin

            if (current_iter < 17) begin

                if (y[20] == 1'b1) begin

                    y <= y + (x >>> current_iter);

                    z <= z - (21'b000010000000000000000 >>> current_iter);

                end else begin

                    y <= y - (x >>> current_iter);

                    z <= z + (21'b000010000000000000000 >>> current_iter);

                end



                current_iter <= current_iter + 1;



            end else begin

                state <= OUTPUT;

            end

        end



        // ---------------- OUTPUT ----------------

        OUTPUT: begin

            tanh_out <= z;

            state <= IDLE;   // FIX: return to idle

        end



        endcase

    end

end



endmodule