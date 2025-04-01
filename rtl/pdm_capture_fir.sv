module pdm_capture_fir #(
    parameter DECIMATION_FACTOR = 192, // Fator de decimação para 16 kHz
    parameter DATA_WIDTH        = 16,
    parameter FIR_TAPS          = 32,  // Número de taps aumentado para melhor filtragem
    parameter CLK_FREQ          = 100_000_000, // Frequência do clock principal
    parameter PDM_CLK_FREQ      = 3_072_000   // Frequência do clock PDM (3.072 MHz)
)(
    input  logic        clk,         // Clock principal (100 MHz)
    input  logic        rst_n,       // Reset ativo baixo

    output logic        pdm_clk,     // Clock fornecido ao microfone PDM
    input  logic        pdm_data,    // Dados PDM recebidos do microfone
    output logic [15:0] pcm_out,     // Áudio PCM filtrado

    output logic        ready        // Sinal de pronto para leitura de PCM
);

    localparam PDM_CLK_PERIOD   = CLK_FREQ / PDM_CLK_FREQ;
    localparam LAST_BIT_COUNTER = $clog2(PDM_CLK_PERIOD);

    // Clock PDM (3.072 MHz)
    logic [LAST_BIT_COUNTER:0] decimator_cnt = 0;

    // Filtros CIC
    logic [31:0] integrator;         // Integrador
    logic [31:0] comb, comb_reg;     // Comb e registrador de histórico

    logic [8:0] decim_counter;

    // Filtro FIR
    logic signed [15:0] fir_buffer [0:FIR_TAPS-1];
    logic signed [15:0] fir_coeffs [0:FIR_TAPS-1];
    logic signed [31:0] fir_acc;
    integer i;

    initial begin
        // Coeficientes gerados usando uma janela Hamming para passa-baixa com corte em 8 kHz
        fir_coeffs[0]  = 2;   fir_coeffs[1]  = 4;
        fir_coeffs[2]  = 6;   fir_coeffs[3]  = 8;
        fir_coeffs[4]  = 11;  fir_coeffs[5]  = 13;
        fir_coeffs[6]  = 15;  fir_coeffs[7]  = 17;
        fir_coeffs[8]  = 19;  fir_coeffs[9]  = 21;
        fir_coeffs[10] = 22;  fir_coeffs[11] = 23;
        fir_coeffs[12] = 24;  fir_coeffs[13] = 24;
        fir_coeffs[14] = 23;  fir_coeffs[15] = 22;
        fir_coeffs[16] = 21;  fir_coeffs[17] = 19;
        fir_coeffs[18] = 17;  fir_coeffs[19] = 15;
        fir_coeffs[20] = 13;  fir_coeffs[21] = 11;
        fir_coeffs[22] = 8;   fir_coeffs[23] = 6;
        fir_coeffs[24] = 4;   fir_coeffs[25] = 2;
        fir_coeffs[26] = 1;   fir_coeffs[27] = 0;
        fir_coeffs[28] = -1;  fir_coeffs[29] = -2;
        fir_coeffs[30] = -4;  fir_coeffs[31] = -6;
    end

    always_ff @(posedge pdm_clk or negedge rst_n) begin
        if (!rst_n) begin
            integrator    <= 0;
            comb          <= 0;
            comb_reg      <= 0;
            pcm_out       <= 0;
            ready         <= 0;
            decim_counter <= 0;
        end else begin
            // Filtro Integrador
            if (pdm_data)
                integrator <= integrator + 1;
            else
                integrator <= integrator - 1;

            // Contador de Decimação
            decim_counter <= decim_counter + 1;

            if (decim_counter == DECIMATION_FACTOR) begin
                decim_counter <= 0;

                // Filtro Comb
                comb <= integrator - comb_reg;
                comb_reg <= integrator;

                // Desloca o buffer FIR
                for (i = FIR_TAPS-1; i > 0; i = i - 1) begin
                    fir_buffer[i] <= fir_buffer[i-1];
                end
                fir_buffer[0] <= comb[31:16];

                // FIR passa-baixa
                fir_acc = 0;
                for (i = 0; i < FIR_TAPS; i = i + 1) begin
                    fir_acc = fir_acc + fir_buffer[i] * fir_coeffs[i];
                end

                // Normalização
                pcm_out <= fir_acc[31:16]; // Ajuste para saída de 16 bits

                //pcm_out <= comb[15:0]; // Saída do filtro comb
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pdm_clk       <= 1'b0;
            decimator_cnt <= 0;
        end else begin
            if (decimator_cnt < PDM_CLK_PERIOD / 2)
                pdm_clk <= 1'b1;
            else
                pdm_clk <= 1'b0;

            if (decimator_cnt == PDM_CLK_PERIOD) begin
                decimator_cnt <= 0;
            end else begin
                decimator_cnt <= decimator_cnt + 1;
            end
        end
    end

endmodule
