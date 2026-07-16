module arbiter #(
    parameter REQ_WIDTH = 4) 
(
    input  wire                 clk,
    input  wire                 aresetn,
    input  wire [REQ_WIDTH-1:0] req,
    input  wire                 advance,
    output wire [REQ_WIDTH-1:0] grant
);
    reg  [REQ_WIDTH-1:0] mask;
    reg  [REQ_WIDTH-1:0] held_grant;
    reg                  grant_held;
    wire [REQ_WIDTH-1:0] masked_req;
    wire [REQ_WIDTH-1:0] unmasked_grant;
    wire [REQ_WIDTH-1:0] masked_grant;
    wire [REQ_WIDTH-1:0] selected_grant;

    assign masked_req       = req & mask;
    assign masked_grant     = masked_req & (~masked_req + 1'b1);
    assign unmasked_grant   = req & (~req + 1'b1);
    assign selected_grant   = (|masked_req) ? masked_grant : unmasked_grant;
    assign grant            = grant_held ? held_grant : selected_grant;

    always @(posedge clk, negedge aresetn) begin
        if (!aresetn) begin
            mask       <= {REQ_WIDTH{1'b1}};
            held_grant <= {REQ_WIDTH{1'b0}};
            grant_held <= 1'b0;
        end else if (grant_held) begin
            if (advance) begin
                mask       <= (~held_grant + 1'b1) ^ held_grant;
                grant_held <= 1'b0;
            end
        end else if (|selected_grant) begin
            if (advance) begin
                mask <= (~selected_grant + 1'b1) ^ selected_grant;
            end else begin
                held_grant <= selected_grant;
                grant_held <= 1'b1;
            end
        end
    end

endmodule
