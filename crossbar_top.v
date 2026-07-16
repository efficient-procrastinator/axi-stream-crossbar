module crossbar_top #(
    parameter IN_PORTS  = 4,
    parameter OUT_PORTS = 4,
    parameter DATA_WIDTH    = 32,
    parameter DEST_WIDTH    = $clog2(OUT_PORTS), 
    parameter FIFO_DEPTH    = 16
)(
    input wire clk,
    input wire aresetn,

    input  wire [DATA_WIDTH-1:0] s_tdata  [0:IN_PORTS-1],
    input  wire [DEST_WIDTH-1:0] s_tdest  [0:IN_PORTS-1],
    input  wire                  s_tvalid [0:IN_PORTS-1],
    output wire                  s_tready [0:IN_PORTS-1],

    output reg  [DATA_WIDTH-1:0] m_tdata  [0:OUT_PORTS-1],
    output reg                   m_tvalid [0:OUT_PORTS-1],
    input  wire                  m_tready [0:OUT_PORTS-1]
);

    localparam PACKET_WIDTH = DATA_WIDTH + DEST_WIDTH;

    wire [PACKET_WIDTH-1:0] fifo_dout  [0:IN_PORTS-1];
    wire [IN_PORTS-1:0] fifo_empty;
    wire [IN_PORTS-1:0] fifo_full;
    wire [IN_PORTS-1:0] fifo_rd_en;

    wire [IN_PORTS-1:0] arb_req   [0:OUT_PORTS-1];   
    wire [IN_PORTS-1:0] arb_grant [0:OUT_PORTS-1]; 
    wire [OUT_PORTS-1:0] arb_advance;


    genvar in, out;

    generate
        for (in = 0; in < IN_PORTS; in = in + 1) begin : fifos
            FIFO #(
                .DATA_WIDTH(PACKET_WIDTH), 
                .FIFO_DEPTH(FIFO_DEPTH)
            ) fifo_inst (
                .clk(clk),
                .aresetn(aresetn),
                .wr_en(s_tvalid[in]),
                .wr_data({s_tdest[in], s_tdata[in]}),
                .rd_en(fifo_rd_en[in]),
                .full(fifo_full[in]),
                .rd_data(fifo_dout[in]),
                .empty(fifo_empty[in])
            );
            assign s_tready[in] = ~fifo_full[in];
        end
    endgenerate

    generate
        for (out = 0; out < OUT_PORTS; out = out + 1) begin: out_req
            for (in = 0; in < IN_PORTS; in = in + 1) begin: in_req
                assign arb_req[out][in] = (!fifo_empty[in]) && (fifo_dout[in][PACKET_WIDTH-1:DATA_WIDTH] == out);
            end
        end
    endgenerate

    generate
        for (out = 0; out < OUT_PORTS; out = out + 1) begin: out_arb
            arbiter #(
                .REQ_WIDTH(IN_PORTS)
            )  arb_inst (
                .clk(clk),
                .aresetn(aresetn),
                .req(arb_req[out]),
                .advance(arb_advance[out]),
                .grant(arb_grant[out])
            );

            assign arb_advance[out] = (|arb_grant[out]) && m_tready[out];
        end
    endgenerate
    generate
        for (in = 0; in < IN_PORTS; in = in + 1) begin
            wire [OUT_PORTS-1:0] read_req;
            for (out = 0; out < OUT_PORTS; out = out + 1) begin
                assign read_req[out] = arb_grant[out][in] && m_tready[out] && !fifo_empty[in]; 
            end
            assign fifo_rd_en[in] = |read_req;
        end
    endgenerate
    integer i,o;
    always @(*) begin
        for (o = 0; o < OUT_PORTS; o++) begin
            m_tdata[o] = {DATA_WIDTH{1'b0}};
            m_tvalid[o] = |arb_grant[o];
            for (i = 0; i < IN_PORTS; i++) begin
                if (arb_grant[o][i]) m_tdata[o] = fifo_dout[i][DATA_WIDTH-1:0];
            end
        end
    end
endmodule
