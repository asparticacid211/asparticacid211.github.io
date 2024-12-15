`default_nettype none

// Following is a simple testbench that checks the FFT operation
module fft_tb;

    localparam N_samples = 8;
    localparam DATA_WIDTH = 16;
    localparam FRACBITS = 8;

    logic clk, rst_n, finish, start;

    top_fft #(N_samples, DATA_WIDTH, FRACBITS) TOP(.*);

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
        // $readmemh ("twiddle_factors.mem", TOP.mem_control.memT.rom); 
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        #100000000
        $display("@%0t: Error timeout! Finish never asserted.", $time);
        $finish;
    end

    static int r1;
    logic [2*DATA_WIDTH-1:0] mem_val;
    int fd;
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
        
        @(posedge finish);
        
        force TOP.mem_control.we_1_mem0 = 0;
        force TOP.mem_control.we_1_mem1 = 0;
        $display("Cycle Count:%d", cycle_count);

        /*  Read Data from RAM0     */
        for (int i=0; i<N_samples; i++) begin
            r1 = i;
            force TOP.mem_control.Addr_port1_mem0 = r1;
            @(posedge clk);
            @(posedge clk);
            mem_val = TOP.mem_control.Data_R1_mem0;
            $display("Mem0 | Addr:%h | Val_re:%h | Val_im:%h", TOP.mem_control.Addr_port1_mem0, $signed(mem_val[2*DATA_WIDTH-1:DATA_WIDTH]), $signed(mem_val[DATA_WIDTH-1:0]));
            release TOP.mem_control.Addr_port1_mem0;
        end
        release TOP.mem_control.we_1_mem0;

        $display("**********************************************");
        fd = $fopen("outputs.mem", "w");
        /*  Read Data from RAM1     */
        for (int i=0; i<N_samples; i++) begin
            r1 = i;
            force TOP.mem_control.Addr_port1_mem1 = r1;
            @(posedge clk);
            @(posedge clk);
            mem_val = TOP.mem_control.Data_R1_mem1;
            $display("Mem1 | Addr:%h | Val_re:%h | Val_im:%h", TOP.mem_control.Addr_port1_mem1, $signed(mem_val[2*DATA_WIDTH-1:DATA_WIDTH]), $signed(mem_val[DATA_WIDTH-1:0]));
            $fdisplay(fd, "%h", mem_val);
            release TOP.mem_control.Addr_port1_mem1;
        end
        release TOP.mem_control.we_1_mem1;

        $display("**********************************************");

        /*  Read Data from ROM     */
        for (int i=0; i<N_samples; i++) begin
            r1 = i;
            force TOP.mem_control.addrT_R = r1;
            @(posedge clk);
            @(posedge clk);
            $display("ROM  | Addr:%h | Val_re:%h | Val_im:%h", TOP.mem_control.addrT_R, $signed(TOP.mem_control.DataOutT.re), $signed(TOP.mem_control.DataOutT.im));
            release TOP.mem_control.addrT_R;
        end

        $finish;
    end

endmodule 

// // Uncomment the following code if you need to test the AGU only 
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
