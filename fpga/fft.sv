`default_nettype none

typedef struct {
    logic [15:0] a;
    logic [15:0] b;
} complex_16;

// simple combinational implementation with 4 multipliers and 2 adders
// Can also do it with 3 multipliers and 5 adders 
// https://link.springer.com/article/10.1007/s11265-023-01867-7
// Also could pipeline it 
module complex_multiply 
(
    input complex_16 X0, X1;
    output complex_16 out;
);

    logic [31:0] ac, ad, bc, bd, acbd, adbc;
    //(a + ib)*(c + id)
    multiplier_161632 AC(.dataa(X0.a), .datab(X1.a), .result(ac));
    multiplier_161632 AD(.dataa(X0.a), .datab(X1.b), .result(ad));
    multiplier_161632 BC(.dataa(X0.b), .datab(X1.a), .result(bc));
    multiplier_161632 BD(.dataa(X0.b), .datab(X1.b), .result(bd));

    assign acbd = ac + cd;
    assign adbc = ad + bc;

    assign out.a = acbd[30:15];
    assign out.b = adbc[30:15];

endmodule 

module 2_pt_butterfly 
(
    input complex_16 Ain, Bin, W;
    output complex_16 Aout, Bout;
);

    complex_16 multOut;

    complex_multiply BtW (.X0(Bin), .X1(W), .out(multOut));

    Aout.a = Ain.a + multOut.a;
    Aout.b = Ain.b + multOut.b;
    Bout.a = Bin.a - multOut.a;
    Bout.b = Bin.b - multOut.b;

endmodule 

module agu 
#(parameter N = 8)
(
    input logic clk, rst_n, start, 
    output logic finish,
    output logic [$clog2(N)-1:0] addr1, addr2, addrT, stage
);

    localparam mask = {{{$clog2(N)-1}{1'b1}}, {{$clog2(N)-1}{1'b0}}};

    logic [$clog2(N)-1:0] level;
    logic finStage, start_operations;

    assign finish = (stage == $clog2(N));
    assign finStage = (level == (N/2 - 1));

    // Need to change this code -- kinda taken direclty from their paper which was made for C not sv (also need to check if it works for sizes other than 32)
    assign addr1 = (((level << 1) << stage) | ((level << 1) >> ($clog2(N)-stage))) & (N-1); 
    assign addr2 = ((((level<<1)+1) << stage) | (((level<<1)+1) >> ($clog2(N)-stage))) & (N-1);
    assign addrT = (mask >> stage) & level;      

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            stage <= 0;
            level <= 0;
            start_operations <= 0;
        end 
        else if (finish) begin
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
                if (finStage) begin
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
#(parameter N = 8)
(
    input logic [$clog2(N)-1:0] addr1_R, addr2_R, addrT_R, stage_R,
    input logic [$clog2(N)-1:0] addr1_W, addr2_W, stage_W,
    output complex_16 DataA, DataB, DataW, DataStage
);

    memDoublePort #(N, 32) 



endmodule 





