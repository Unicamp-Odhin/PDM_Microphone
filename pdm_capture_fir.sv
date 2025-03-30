module pdm_capture_fir #(
    parameter DECIMATION_FACTOR = 64,
    parameter DATA_WIDTH        = 16,
    parameter FIR_TAPS          = 16,
    parameter CLK_FREQ          = 100_000_000, // Frequência do clock principal
    parameter PDM_CLK_FREQ      = 2_822_400   // Frequência do clock PDM
)(
    input  logic        clk,         // Clock principal (100 MHz)
    input  logic        rst_n,       // Reset ativo baixo

    output logic        pdm_clk,     // Clock fornecido ao microfone PDM
    input  logic        pdm_data,    // Dados PDM recebidos do microfone
    output logic [15:0] pcm_out,     // Áudio PCM filtrado

    output logic        ready        // Sinal de pronto para leitura de PCM
);

    localparam PDM_CLK_PERIOD   = CLK_FREQ / PDM_CLK_FREQ; // Período do clock PDM
    localparam LAST_BIT_COUNTER = $clog2(PDM_CLK_PERIOD); // Contador para o último bit do decimador
    // Clock PDM (3.2 MHz)
    logic [LAST_BIT_COUNTER:0] decimator_cnt = 0;

    // Filtro CIC
    logic [31:0] integrator; // Integrador e Comb

    logic [5:0] decim_counter;

    logic pdm_clock_posedge;
    logic [2:0] pdm_clock_history;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            integrator    <= 0;
            ready         <= 0;
            decim_counter <= 0;
        end else begin
            // Filtro CIC
            if(pdm_clock_posedge)
                decim_counter <= decim_counter + 1;
                
            if (pdm_clock_posedge) begin
                if (pdm_data)
                    integrator <= integrator + 1;
                else
                    integrator <= integrator - 1;

                if (&decim_counter) begin // verifica o resto da divisão por 64
                    pcm_out    <= integrator[15:0];
                    integrator <= 0;
                    ready   <= 1'b1;
                end else begin
                    ready   <= 1'b0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            pdm_clk       <= 1'b0;
            decimator_cnt <= 0;
            pdm_clock_history <= 0;
        end else begin
            // Gerar o clock PDM
            if (decimator_cnt < PDM_CLK_PERIOD / 2)
                pdm_clk <= 1'b1;
            else
                pdm_clk <= 1'b0;

            if (decimator_cnt == PDM_CLK_PERIOD) begin
                decimator_cnt <= 0;
            end else begin
                decimator_cnt <= decimator_cnt + 1;
            end

            pdm_clock_history <= {pdm_clock_history[1:0], pdm_clk};
        end
    end

    assign pdm_clock_posedge = ~pdm_clock_history[2] & pdm_clock_history[1];
endmodule
