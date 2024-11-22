`default_nettype none

module agu_tb;

    localparam N_samples = 8;

    logic clk, rst_n, finish, start;
    logic [$clog2(N_samples)-1:0] addr1, addr2, addrT, stage;

    agu #(N_samples) TOP(.*);

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        #10000
        $display("@%0t: Error timeout! Finish never asserted.", $time);
        $finish;
    end

    initial begin
        rst_n = 1'b1;
        rst_n <= 1'b0;
        start <= 1'b0;
        @(posedge clk);
        @(posedge clk);
        rst_n <= #1 1'b1;
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        $monitor("@%0t: Stage=%d, Level=%d, Addr1=%d, Addr2=%d, AddrT=%d", $time, TOP.stage, TOP.level, addr1, addr2, addrT);
        
        @(posedge finish);

        $finish;
    end

endmodule 