`timescale 1ns / 1ps

module tanh_tb;

    // Clock and reset
    reg clk;
    reg rst;
    reg start;

    // Input/output
    reg signed [20:0] angle;      // Q4.16
    wire signed [20:0] tanh_out;  // Q4.16

    integer i;
    integer outfile;

    // Instantiate the CORDIC module
    cordic uut (
        .clk(clk),
        .start(start),
        .rst(rst),
        .angle(angle),
        .tanh_out(tanh_out)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Inputs: 61 points from -3 to 3 (Q4.16)
    reg signed [20:0] test_inputs [0:60];

    initial begin
    // Precompute Q4.16 values: x*2^16 over [-1.1, 1.1]
    for (i = 0; i <= 60; i = i + 1) begin
        test_inputs[i] = $rtoi(((-1.1) + i*(2.2/60)) * 65536.0);
    end
end

    // Testbench procedure
    initial begin
        // Open output file
        outfile = $fopen("tanh_verilog.txt","w");

        // Initialize signals
        rst = 1; start = 0; angle = 0;
        #20;
        rst = 0;

        // Loop over all inputs
        for (i = 0; i <= 60; i = i + 1) begin
            angle = test_inputs[i];
            start = 1;
            #10;
            start = 0;

            // Wait until output is valid
            wait(uut.state == uut.OUTPUT);
            #10; // small delay for output to settle

            // Write output to file
            $fwrite(outfile, "%d\n", tanh_out);

            #10; // spacing between inputs
        end

        $fclose(outfile);
        $display("Simulation finished. Outputs saved to tanh_verilog.txt");
        $finish;
    end

    // GTKWave dump
    initial begin
        $dumpfile("tanh_tb.vcd");
        $dumpvars(0,tanh_tb);
    end

endmodule