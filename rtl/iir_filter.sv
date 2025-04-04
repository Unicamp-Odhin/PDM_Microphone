module iir_filter #(
    parameter DATA_WIDTH = 16
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic signed [DATA_WIDTH-1:0] in_data,
    output logic signed [DATA_WIDTH-1:0] out_data
);

    // Coeficientes IIR - Calculados para um filtro Butterworth passa-baixa
    localparam signed [DATA_WIDTH-1:0] a1 = -16'sd23170;  // Coeficiente de feedback 1
    localparam signed [DATA_WIDTH-1:0] a2 =  16'sd11585;  // Coeficiente de feedback 2
    localparam signed [DATA_WIDTH-1:0] b0 =  16'sd3277;   // Coeficiente de entrada 0
    localparam signed [DATA_WIDTH-1:0] b1 =  16'sd6554;   // Coeficiente de entrada 1
    localparam signed [DATA_WIDTH-1:0] b2 =  16'sd3277;   // Coeficiente de entrada 2

    // Registros para armazenar o histórico das entradas e saídas
    logic signed [31:0] y0, y1, y2;
    logic signed [31:0] x0, x1, x2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= 0; x1 <= 0; x2 <= 0;
            y0 <= 0; y1 <= 0; y2 <= 0;
            out_data <= 0;
        end else begin
            // Atualiza os registros de entrada
            x2 <= x1;
            x1 <= x0;
            x0 <= in_data;

            // Filtro IIR (Forma Direta II)
            y0 <= (b0 * x0 + b1 * x1 + b2 * x2
                  - a1 * y1 - a2 * y2) >>> 15;

            // Atualiza os registros de saída
            y2 <= y1;
            y1 <= y0;

            // Saída do filtro
            out_data <= y0[DATA_WIDTH-1:0];
        end
    end
endmodule
