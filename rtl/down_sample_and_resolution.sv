module down_sample_and_resolution #(
    parameter int DATA_IN_WIDTH     = 16,
    parameter int DATA_OUT_WIDTH    = 8,
    parameter int DECIMATION_FACTOR = 2
) (
    input  logic clk,
    input  logic rst_n,

    input  logic valid_in,
    input  logic [DATA_IN_WIDTH - 1:0] data_in,

    output logic valid_out,
    output logic [DATA_OUT_WIDTH - 1:0] data_out
);

    logic [31:0] acc;
    logic [$clog2(DECIMATION_FACTOR):0] counter;
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

            if(counter == DECIMATION_FACTOR) begin
                acc_out       <= acc >>> $clog2(DECIMATION_FACTOR);
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
            product       <= acc_out + 'd32768; //  Desloca o intervalo de [-32768, +32767] para [0, 65535], removendo o sinal
            valid_out     <= valid_product;
            data_out      <= product >> 8;      // Divide por 8
        end
    end

endmodule

