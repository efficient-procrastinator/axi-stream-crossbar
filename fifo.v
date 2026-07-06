module FIFO #(
    parameter DATA_WIDTH = 8, 
    parameter FIFO_DEPTH = 16)
(
    input   wire                    clk,
    input   wire                    aresetn,
    input   wire                    wr_en,
    input   wire [DATA_WIDTH-1:0]   wr_data,
    input   wire                    rd_en, 
    output  wire                    full,
    output  wire [DATA_WIDTH-1:0]   rd_data,
    output  wire                    empty
);
localparam PTR_WIDTH = $clog2(FIFO_DEPTH);

reg [DATA_WIDTH-1:0] FIFO_vec [FIFO_DEPTH-1:0];
reg [PTR_WIDTH:0] rd_ptr, wr_ptr;

assign full =
(wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]) &&
(wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);
assign empty = (wr_ptr == rd_ptr);
assign rd_data = FIFO_vec[rd_ptr[PTR_WIDTH-1:0]];

always @(posedge clk, negedge aresetn) begin
    if (!aresetn) begin
        rd_ptr <= 0;
        wr_ptr <= 0;
    end
    else begin
        if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
            FIFO_vec[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
        end
        if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end
end
endmodule
