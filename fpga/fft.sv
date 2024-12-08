`default_nettype none

typedef struct {
    logic [15:0] re;
    logic [15:0] im;
} complex_t;

typedef struct {
    logic [2:0] stage;
    logic valid;
    logic is_last;
} stage_info_t;

module top_fft 
#(
    parameter N = 8,
    parameter DATA_WIDTH = 16,
    parameter FRACBITS = 0
)
(
    input logic clk, rst_n, start,
    output logic finish
);

    logic stall;
    logic [$clog2(N)-1:0] addr1_agu, addr2_agu, addrT_agu;
    logic [$clog2(N)-1:0] addr1_mem, addr2_mem;
    logic [$clog2(N)-1:0] addr1_mult, addr2_mult;
    complex_t data1_mem, data2_mem, dataT_mem;
    complex_t data1_mult, data2_mult;
    stage_info_t stage_info_agu, stage_info_mem, stage_info_mult;
    
    agu #(N, DATA_WIDTH) agu_inst(.clk, .rst_n, .start, .finish, .stall, 
                .addr1(addr1_agu), .addr2(addr2_agu), 
                .addrT(addrT_agu), .stage_info(stage_info_agu));

    memory_controller #(N, DATA_WIDTH) mem_control(.clk, .stall, .finish, .rst_n,
                .stage_info_R(stage_info_agu), .stage_info_W(stage_info_mult), 
                .DataInA(data1_mult), .DataInB(data2_mult), 
                .addr1_R(addr1_agu), .addr2_R(addr2_agu), .addrT_R(addrT_agu),
                .addr1_W(addr1_mult), .addr2_W(addr2_mult),
                .DataOutA(data1_mem), .DataOutB(data2_mem), .DataOutT(dataT_mem),
                .addr1_out(addr1_mem), .addr2_out(addr2_mem),
                .stage_info_out(stage_info_mem));

    pt2_butterfly #(N, DATA_WIDTH, FRACBITS) butterfly(
        .Ain(data1_mem), .Bin(data2_mem), .T(dataT_mem),
        .addr1_in(addr1_mem), .addr2_in(addr2_mem),
        .stage_info_in(stage_info_mem),
        .addr1_out(addr1_mult), .addr2_out(addr2_mult),
        .stage_info_out(stage_info_mult),
        .Aout(data1_mult), .Bout(data2_mult));

endmodule

module agu 
#(
    parameter N = 8,
    parameter DATA_WIDTH = 16
)
(
    input logic clk, rst_n, start, stall, finish,
    output logic [$clog2(N)-1:0] addr1, addr2, addrT, 
    output stage_info_t stage_info
);

    localparam mask = {{{$clog2(N)-1}{1'b1}}, {{$clog2(N)-1}{1'b0}}};

    logic [$clog2(N)-1:0] stage, level;
    logic finLevel, start_operations;

    assign finLevel = (level == (N/2 - 1));

    // Need to change this code -- kinda taken direclty from their paper which was made for C not sv (also need to check if it works for sizes other than 32)
    assign addr1 = (((level << 1) << stage) | ((level << 1) >> ($clog2(N)-stage))) & (N-1); 
    assign addr2 = ((((level<<1)+1) << stage) | (((level<<1)+1) >> ($clog2(N)-stage))) & (N-1);
    assign addrT = (mask >> stage) & level;   

    assign stage_info.stage = stage;
    assign stage_info.valid = start_operations & ~stall;   
    assign stage_info.is_last = (stage == $clog2(N)-1) & finLevel;

    always_ff @(posedge clk) begin
        if (~rst_n | finish) begin
            stage <= 0;
            level <= 0;
            start_operations <= 0;
        end 
        else if (start) begin
            stage <= 0;
            level <= 0;
            start_operations <= start;
        end
        else begin
            start_operations <= start_operations;
            if (start_operations) begin
                if (stall) begin 
                    stage <= stage;
                    level <= level;
                end
                else if (finLevel) begin
                    stage <= stage + 1;
                    level <= 0;
                end 
                else begin
                    stage <= stage;
                    level <= level + 1;
                end
            end
            else begin
                stage <= 0;
                level <= 0;
            end
        end
    end

endmodule 

module memory_controller 
#(
    parameter N = 8,
    parameter DATA_WIDTH = 16
)
(   
    input logic clk, rst_n,
    input stage_info_t stage_info_R, stage_info_W, 
    input complex_t DataInA, DataInB,
    input logic [$clog2(N)-1:0] addr1_R, addr2_R, addrT_R,
    input logic [$clog2(N)-1:0] addr1_W, addr2_W,
    output complex_t DataOutA, DataOutB, DataOutT,
    output logic [$clog2(N)-1:0] addr1_out, addr2_out,
    output stage_info_t stage_info_out,
    output logic stall,
    output logic finish
);

    logic [$clog2(N)-1:0] Addr_port1_mem0, Addr_port2_mem0, Addr_port1_mem1, Addr_port2_mem1;
    logic we_1_mem0, we_2_mem0, we_1_mem1, we_2_mem1; // writing is 1, reading is 0
    logic [2*DATA_WIDTH-1:0] Data_R1_mem0, Data_R2_mem0, Data_R1_mem1, Data_R2_mem1;

    stage_info_t stage_buffer;
    logic [$clog2(N)-1:0] addr1_out_buffer, addr2_out_buffer;

    assign stall = (stage_info_W.valid == 1) & (stage_info_W.stage != stage_info_R.stage);

    always_comb begin 
        if (stall) begin
            if (stage_info_W.stage[0] == 0) begin
                // write to mem1 
                Addr_port1_mem1 = addr1_W;
                Addr_port2_mem1 = addr2_W;
                we_1_mem1 = stage_info_W.valid;
                we_2_mem1 = stage_info_W.valid;
                // read from mem0
                Addr_port1_mem0 = addr1_R;
                Addr_port2_mem0 = addr2_R;
                we_1_mem0 = 1'b0;
                we_2_mem0 = 1'b0;
                {DataOutA.re, DataOutA.im} = Data_R1_mem0;
                {DataOutB.re, DataOutB.im} = Data_R2_mem0;
            end 
            else begin
                // write to mem0
                Addr_port1_mem0 = addr1_W;
                Addr_port2_mem0 = addr2_W;
                we_1_mem0 = stage_info_W.valid;
                we_2_mem0 = stage_info_W.valid;
                // read from mem1
                Addr_port1_mem1 = addr1_R;
                Addr_port2_mem1 = addr2_R;
                we_1_mem1 = 1'b0;
                we_2_mem1 = 1'b0;
                {DataOutA.re, DataOutA.im} = Data_R1_mem1;
                {DataOutB.re, DataOutB.im} = Data_R2_mem1;
            end
        end 
        else if (stage_info_R.stage[0] == 0) begin
            // write to mem1 
            Addr_port1_mem1 = addr1_W;
            Addr_port2_mem1 = addr2_W;
            we_1_mem1 = stage_info_W.valid;
            we_2_mem1 = stage_info_W.valid;
            // read from mem0
            Addr_port1_mem0 = addr1_R;
            Addr_port2_mem0 = addr2_R;
            we_1_mem0 = 1'b0;
            we_2_mem0 = 1'b0;
            {DataOutA.re, DataOutA.im} = Data_R1_mem0;
            {DataOutB.re, DataOutB.im} = Data_R2_mem0;
        end 
        else begin
            // write to mem0
            Addr_port1_mem0 = addr1_W;
            Addr_port2_mem0 = addr2_W;
            we_1_mem0 = stage_info_W.valid;
            we_2_mem0 = stage_info_W.valid;
            // read from mem1
            Addr_port1_mem1 = addr1_R;
            Addr_port2_mem1 = addr2_R;
            we_1_mem1 = 1'b0;
            we_2_mem1 = 1'b0;
            {DataOutA.re, DataOutA.im} = Data_R1_mem1;
            {DataOutB.re, DataOutB.im} = Data_R2_mem1;
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            stage_info_out <= '{default: '0};
            stage_buffer <= '{default: '0};
            finish <= 0;
        end
        else begin
            stage_buffer <= stage_info_R;
            addr1_out_buffer <= addr1_R;
            addr2_out_buffer <= addr2_R;

            stage_info_out <= stage_buffer;
            addr1_out <= addr1_out_buffer;
            addr2_out <= addr2_out_buffer;

            finish <= (stage_info_W.valid == 1) & (stage_info_W.is_last == 1);
        end
    end

    // true_dpram_sclk #(2*DATA_WIDTH, N) mem0(.clk, .rst_n,
    //                     .addr_a(Addr_port1_mem0), .addr_b(Addr_port2_mem0), 
    //                     .we_a(we_1_mem0), .we_b(we_2_mem0),
    //                     .data_a({DataInA.re, DataInA.im}), .data_b({DataInB.re, DataInB.im}), 
    //                     .q_a(Data_R1_mem0), .q_b(Data_R2_mem0));
    // true_dpram_sclk #(2*DATA_WIDTH, N) mem1(.clk, .rst_n,
    //                     .addr_a(Addr_port1_mem1), .addr_b(Addr_port2_mem1), 
    //                     .we_a(we_1_mem1), .we_b(we_2_mem1),
    //                     .data_a({DataInA.re, DataInA.im}), .data_b({DataInB.re, DataInB.im}), 
    //                     .q_a(Data_R1_mem1), .q_b(Data_R2_mem1));
    // single_port_rom #(2*DATA_WIDTH, N) memT(.clk, 
    //                     .addr(addrT_R), 
    //                     .q({DataOutT.re, DataOutT.im}));
    dualportram mem0(.clock(clk), .address_a(Addr_port1_mem0), .address_b(Addr_port2_mem0),
	                .data_a({DataInA.re, DataInA.im}), .data_b({DataInB.re, DataInB.im}),
	                .wren_a(we_1_mem0), .wren_b(we_2_mem0),
	                .q_a(Data_R1_mem0), .q_b(Data_R2_mem0));
    dualportram mem1(.clock(clk), .address_a(Addr_port1_mem1), .address_b(Addr_port2_mem1),
	                .data_a({DataInA.re, DataInA.im}), .data_b({DataInB.re, DataInB.im}),
	                .wren_a(we_1_mem1), .wren_b(we_2_mem1),
	                .q_a(Data_R1_mem1), .q_b(Data_R2_mem1));
    singleportrom memT(.clock(clk), .address(addrT_R), .q({DataOutT.re, DataOutT.im}));
    
endmodule 

module pt2_butterfly 
#(
    parameter N = 8,
    parameter DATA_WIDTH = 16,
    parameter FRACBITS = 0
)
(
    input complex_t Ain, Bin, T,
    input logic [$clog2(N)-1:0] addr1_in, addr2_in,
    input stage_info_t stage_info_in,
    output logic [$clog2(N)-1:0] addr1_out, addr2_out,
    output stage_info_t stage_info_out,
    output complex_t Aout, Bout
);

    complex_t multOut;

    complex_multiply #(DATA_WIDTH, FRACBITS) BtW (.X0(Bin), .X1(T), .out(multOut));

    assign Aout.re = Ain.re + multOut.re;
    assign Aout.im = Ain.im + multOut.im;
    assign Bout.re = Ain.re - multOut.re;
    assign Bout.im = Ain.im - multOut.im;

    // change once pipelined
    assign stage_info_out = stage_info_in;

    assign addr1_out = addr1_in;
    assign addr2_out = addr2_in;

endmodule 

// // simple combinational implementation with 4 multipliers and 2 adders
// // Can also do it with 3 multipliers and 5 adders 
// // https://link.springer.com/article/10.1007/s11265-023-01867-7
// // Also could pipeline it 
module complex_multiply 
#(
    parameter WIDTH = 16,
    parameter FRACBITS = 0
)
(
    input complex_t X0, X1,
    output complex_t out
);

    logic [2*WIDTH-1:0] ac, ad, bc, bd, acbd, adbc;
    //(a + ib)*(c + id)
    multiplier AC(.dataa(X0.re), .datab(X1.re), .result(ac));
    multiplier AD(.dataa(X0.re), .datab(X1.im), .result(ad));
    multiplier BC(.dataa(X0.im), .datab(X1.re), .result(bc));
    multiplier BD(.dataa(X0.im), .datab(X1.im), .result(bd));

    assign acbd = ac - bd;
    assign adbc = ad + bc;

    assign out.re = acbd[(WIDTH-1+FRACBITS):FRACBITS];
    assign out.im = adbc[(WIDTH-1+FRACBITS):FRACBITS];

endmodule 

// module true_dpram_sclk
// #(
//     parameter WIDTH = 32,
//     parameter DEPTH = 8
// )
// (
// 	input logic [WIDTH-1:0] data_a, data_b,
// 	input logic [$clog2(DEPTH)-1:0] addr_a, addr_b,
// 	input logic we_a, we_b, clk, rst_n,
// 	output logic [WIDTH-1:0] q_a, q_b
// );
// 	logic [WIDTH-1:0] ram[DEPTH-1:0];

// 	always_ff @(posedge clk) begin
//         if (~rst_n) begin
//             $readmemh ("input_samples.mem", ram); 
//         end
//         else begin
//             // Port A
//             if (we_a) begin
//                 ram[addr_a] <= data_a;
//                 q_a <= data_a;
//             end
//             else begin
//                 q_a <= ram[addr_a];
//             end
//             // Port B
//             if (we_b) begin
//                 ram[addr_b] <= data_b;
//                 q_b <= data_b;
//             end
//             else begin
//                 q_b <= ram[addr_b];
//             end
//         end
// 	end
	
// endmodule

// module single_port_rom
// #(
//     parameter WIDTH = 32,
//     parameter DEPTH = 8
// )
// (
// 	input logic [$clog2(DEPTH)-1:0] addr,
// 	input logic clk,
// 	output logic [WIDTH-1:0] q
// );
// 	logic [WIDTH-1:0] rom[DEPTH-1:0];
	
// 	always_ff @(posedge clk) begin
// 		q <= rom[addr];
// 	end
	
// endmodule






