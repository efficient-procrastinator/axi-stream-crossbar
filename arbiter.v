module arbiter #(
    parameter REQ_WIDTH = 4) 
(
    input  wire                 clk,
    input  wire                 aresetn,
    input  wire [REQ_WIDTH-1:0] req,
    output wire [REQ_WIDTH-1:0] grant
);
    reg  [REQ_WIDTH-1:0] mask;
    wire [REQ_WIDTH-1:0] masked_req;
    wire [REQ_WIDTH-1:0] unmasked_grant;
    wire [REQ_WIDTH-1:0] masked_grant;

    assign masked_req       = req & mask;
    assign masked_grant     = masked_req & (~masked_req + 1'b1);
    assign unmasked_grant   = req & (~req + 1'b1);
    assign grant            = (|masked_req) ? masked_grant : unmasked_grant;

    always @(posedge clk, negedge aresetn) begin
        if (!aresetn) mask <= {REQ_WIDTH{1'b1}};
        else begin
            if (|grant) mask <= (~grant + 1'b1) ^ grant;
        end
    end

endmodule