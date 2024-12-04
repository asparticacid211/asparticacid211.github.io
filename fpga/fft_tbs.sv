`default_nettype none

// module agu_tb;

//     localparam N_samples = 8;

//     logic clk, rst_n, finish, start;
//     logic [$clog2(N_samples)-1:0] addr1, addr2, addrT, stage;

//     agu #(N_samples) TOP(.*);

//     initial begin
//         clk = 1'b0;
//         forever #5 clk = ~clk;
//     end

//     initial begin
//         #10000
//         $display("@%0t: Error timeout! Finish never asserted.", $time);
//         $finish;
//     end

//     initial begin
//         rst_n = 1'b1;
//         rst_n <= 1'b0;
//         start <= 1'b0;
//         @(posedge clk);
//         @(posedge clk);
//         rst_n <= #1 1'b1;
//         @(posedge clk);
//         start <= 1'b1;
//         @(posedge clk);
//         start <= 1'b0;

//         $monitor("@%0t: Stage=%d, Level=%d, Addr1=%d, Addr2=%d, AddrT=%d", $time, TOP.stage, TOP.level, addr1, addr2, addrT);
        
//         @(posedge finish);

//         $finish;
//     end

// endmodule 

module fft_tb;

    localparam N_samples = 8;
    localparam DATA_SIZE = 16;
    localparam FRACBITS = 0;

    logic clk, rst_n, finish, start;

    top_fft #(N_samples, DATA_SIZE, FRACBITS) TOP(.*);

    // Internal register to store the counter value
    logic [31:0] cycle_count;
    logic counting; // Flag to indicate counting state
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            // Reset all outputs and internal registers
            cycle_count <= 0;
            counting <= 0;
        end else begin
            if (start) begin
                // Start counting when start is asserted
                counting <= 1;
                cycle_count <= 0; // Reset cycle count
            end else if (finish) begin
                // Stop counting when finish is asserted
                counting <= 0;
                cycle_count <= cycle_count; // Latch the cycle count
            end else if (counting) begin
                // Increment counter during the counting phase
                cycle_count <= cycle_count + 1;
            end
        end
    end

    initial begin
        $readmemh ("twiddle_factors.mem", TOP.mem_control.memT.rom); 
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        #100000000
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

        // $monitor("@%0t: Addr1=%d, Addr2=%d, stall=%d", $time, TOP.addr1_agu, TOP.addr2_agu, TOP.stall);
        
        @(posedge finish);

        $writememh("memory_contents_mem0.hex", TOP.mem_control.mem0.ram);
        $writememh("memory_contents_mem1.hex", TOP.mem_control.mem1.ram);
        @(posedge clk);
        $display("Cycle Count:%d", cycle_count);

        $finish;
    end

endmodule 

