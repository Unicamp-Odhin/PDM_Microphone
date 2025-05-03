module fir_filter #(
    parameter DATA_WIDTH = 16,
    parameter TAP_NUM    = 64
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic signed [DATA_WIDTH-1:0] in_data,
    output logic signed [DATA_WIDTH-1:0] out_data
);

    // Coeficientes do filtro FIR - Exemplo de filtro passa-baixa
    logic signed [DATA_WIDTH-1:0] coeffs [0:TAP_NUM-1] = '{
        1, 2, 3, 5, 7, 10, 14, 19,
        24, 30, 35, 39, 43, 46, 48, 49,
        49, 48, 46, 43, 39, 35, 30, 24,
        19, 14, 10, 7, 5, 3, 2, 1,
        1, 2, 3, 5, 7, 10, 14, 19,
        24, 30, 35, 39, 43, 46, 48, 49,
        49, 48, 46, 43, 39, 35, 30, 24,
        19, 14, 10, 7, 5, 3, 2, 1
    };

    logic signed [31:0] acc;
    logic signed [DATA_WIDTH-1:0] delay_line [0:TAP_NUM-1];
    integer i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc      <= 0;
            out_data <= 0;
            for (i = 0; i < TAP_NUM; i = i + 1) begin
                delay_line[i] <= 0;
            end
        end else begin
            acc <= 0;

            // Atualiza a linha de atraso
            for (i = TAP_NUM-1; i > 0; i = i - 1) begin
                delay_line[i] <= delay_line[i-1];
            end
            delay_line[0] <= in_data;

            // Acumula o produto dos coeficientes
            for (i = 0; i < TAP_NUM; i = i + 1) begin
                acc <= acc + delay_line[i] * coeffs[i];
            end

            // Normaliza a saída
            out_data <= acc >>> 8;
        end
    end
endmodule
