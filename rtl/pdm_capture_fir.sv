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
    logic cic_ready;
    logic [1:0] edge_counter;

    logic signed [31:0] integrator [0:CIC_STAGES-1];
    logic signed [31:0] comb [0:CIC_STAGES-1];
    logic signed [31:0] comb_delay [0:CIC_STAGES-1];
    logic [15:0] fir_buffer [0:FIR_TAPS-1];
    logic signed [31:0] fir_sum;

    integer i;

    logic [8:0] decim_counter;
    logic signed [DATA_WIDTH-1:0] pcm_temp;
    logic [15:0] sample_count;
    logic [5:0] fir_index;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pdm_clk       <= 0;
            decimator_cnt <= 0;
            edge_counter  <= 0;
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
                comb[i]       <= 0;
                comb_delay[i] <= 0;
            end

            decim_counter <= 0;
            cic_ready     <= 0;
        end else if (pdm_posedge) begin
            if (decim_counter == (DECIMATION_FACTOR - 1)) begin
                decim_counter <= 0;

                comb[0] <= integrator[CIC_STAGES-1] - comb_delay[0];
                comb_delay[0] <= integrator[CIC_STAGES-1];
                
                for (i = 1; i < CIC_STAGES; i = i + 1) begin
                    comb[i] <= comb[i-1] - comb_delay[i];
                    comb_delay[i] <= comb[i-1];
                end

                pcm_temp <= $signed(comb[CIC_STAGES-1][28:13]);
                cic_ready <= 1;
            end else begin
                decim_counter <= decim_counter + 1;
                cic_ready <= 0;
            end
        end
    end

    logic fir_ready;
    logic signed [31:0] fir_avg;

    // FIR Filter Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fir_sum   <= 0;
            fir_index <= 0;
            fir_avg   <= 0;
            fir_ready <= 0;

            for (i = 0; i < FIR_TAPS; i = i + 1) fir_buffer[i] <= 0;
        end else if (cic_ready) begin
            // Atualiza o buffer com o novo valor de entrada
            fir_buffer[fir_index] <= pcm_temp;
            fir_index <= (fir_index + 1) % FIR_TAPS;

            // Calcula a soma de todos os taps do filtro FIR
            fir_sum = 0;
            for (i = 0; i < FIR_TAPS; i = i + 1) begin
                fir_sum = fir_sum + fir_buffer[i];
            end

            // Normaliza a saída e envia para pcm_out
            fir_avg <= fir_sum >> $clog2(FIR_TAPS);
            fir_ready <= 1;
        end else begin
            fir_ready <= 0;
        end
    end

    logic signed [DATA_WIDTH - 1:0] pcm_out_old;

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            fir_sum <= 0;
            pcm_out <= 0;
            ready   <= 0;
        end else if(fir_ready) begin
            pcm_out <= $signed(fir_avg[15:0]);
            pcm_out_old <= pcm_out;
            ready   <= 1;
        end else begin
            ready   <= 0;
        end
    end

endmodule
