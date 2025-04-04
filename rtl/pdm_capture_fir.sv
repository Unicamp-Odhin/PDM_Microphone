module pdm_capture_fir #(
    parameter DECIMATION_FACTOR = 128,
    parameter DATA_WIDTH        = 16,
    parameter FIR_TAPS          = 64,
    parameter CLK_FREQ          = 100_000_000,
    parameter PDM_CLK_FREQ      = 3_072_000,
    parameter CIC_STAGES        = 3
)(
    input  logic                    clk,
    input  logic                    rst_n,
    output logic                    pdm_clk,
    input  logic                    pdm_data,
    output logic [DATA_WIDTH - 1:0] pcm_out,
    output logic                    ready
);

    localparam PDM_CLK_PERIOD   = CLK_FREQ / PDM_CLK_FREQ;
    localparam LAST_BIT_COUNTER = $clog2(PDM_CLK_PERIOD);

    logic [LAST_BIT_COUNTER:0] decimator_cnt;
    logic pdm_posedge;
    logic [1:0] edge_counter;

    logic signed [31:0] integrator [0:CIC_STAGES-1];
    logic signed [31:0] comb [0:CIC_STAGES-1];
    logic signed [31:0] comb_delay [0:CIC_STAGES-1];
    logic [15:0] fir_buffer [0:FIR_TAPS-1];
    logic signed [31:0] fir_sum;

    integer i;

    logic [8:0] decim_counter;
    logic [DATA_WIDTH-1:0] pcm_temp;
    logic [15:0] sample_count;
    logic [5:0] fir_index;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pdm_clk <= 0;
            decimator_cnt <= 0;
            edge_counter <= 0;
        end else begin
            if (decimator_cnt >= (PDM_CLK_PERIOD / 2)) begin
                pdm_clk <= ~pdm_clk;
                decimator_cnt <= 0;
            end else begin
                decimator_cnt <= decimator_cnt + 1;
            end

            edge_counter <= {edge_counter[0], pdm_clk};
        end
    end

    assign pdm_posedge = ~edge_counter[1] & edge_counter[0];

// CIC Integrator Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < CIC_STAGES; i = i + 1) integrator[i] <= 0;
        end else if (pdm_posedge) begin
            integrator[0] <= integrator[0] + (pdm_data ? 1 : -1);
            for (i = 1; i < CIC_STAGES; i = i + 1)
                integrator[i] <= integrator[i] + integrator[i-1];
        end
    end

    // CIC Comb Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < CIC_STAGES; i = i + 1) begin
                comb[i] <= 0;
                comb_delay[i] <= 0;
            end
            ready <= 0;
            decim_counter <= 0;
        end else if (pdm_posedge) begin
            if (decim_counter == (DECIMATION_FACTOR - 1)) begin
                decim_counter <= 0;

                comb[0] <= integrator[CIC_STAGES-1] - comb_delay[0];
                comb_delay[0] <= integrator[CIC_STAGES-1];
                
                for (i = 1; i < CIC_STAGES; i = i + 1) begin
                    comb[i] <= comb[i-1] - comb_delay[i];
                    comb_delay[i] <= comb[i-1];
                end

                pcm_temp <= comb[CIC_STAGES-1][31:16];
                //pcm_out <= comb[CIC_STAGES-1][31:16];
                ready <= 1;
            end else begin
                decim_counter <= decim_counter + 1;
                ready <= 0;
            end
        end
    end

    // FIR Filter Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fir_sum <= 0;
            fir_index <= 0;
            for (i = 0; i < FIR_TAPS; i = i + 1) fir_buffer[i] <= 0;
            pcm_out <= 0;
        end else if (ready) begin
            // Atualiza o buffer com o novo valor de entrada
            fir_buffer[fir_index] <= pcm_temp;
            fir_index <= (fir_index + 1) % FIR_TAPS;

            // Calcula a soma de todos os taps do filtro FIR
            fir_sum = 0;
            for (i = 0; i < FIR_TAPS; i = i + 1) begin
                fir_sum = fir_sum + fir_buffer[i];
            end

            // Normaliza a saída e envia para pcm_out
            pcm_out <= fir_sum / FIR_TAPS;
        end
    end
endmodule
