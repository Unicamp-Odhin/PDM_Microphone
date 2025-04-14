module down_sample_and_resolution (
    input  logic clk,
    input  logic rst_n,

    input  logic valid_in,
    input  logic [15:0] data_in,

    output logic valid_out,
    output logic [7:0] data_out
);

    logic [31:0] acc;
    logic [1:0] counter;
    logic valid_acc;

    logic [15:0] acc_out;
    logic valid_acc_out;

    always_ff @(posedge clk ) begin
        if(!rst_n) begin
            acc           <= 0;
            counter       <= 0;
            valid_acc_out <= 0;
            acc_out       <= 0;
        end else begin
            if(valid_in) begin
                acc     <= acc + {{16{data_in[15]}}, data_in};
                counter <= counter + 1;
            end

            if(counter == 'd2) begin
                acc_out       <= acc >>> 1;
                valid_acc_out <= 1;
                acc           <= 0;
                counter       <= 0;
            end else begin
                valid_acc_out <= 0;
            end
        end
    end

    logic [15:0] product;
    logic valid_product;

    always_ff @(posedge clk) begin
        valid_out <= 0;

        if(!rst_n) begin
            data_out      <= 0;
            valid_out     <= 0;
            product       <= 0;
            valid_product <= 0;
        end else begin
            valid_product <= valid_acc_out;
            product       <= acc_out + 'd32768;
            valid_out     <= valid_product;
            data_out      <= $signed(product >>> 8);
        end
    end

endmodule

