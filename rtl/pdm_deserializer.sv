module pdm_deserializer #(
    parameter CLK_FREQ     = 100_000_000, // Frequência do clock principal
    parameter PDM_CLK_FREQ = 3_072_000    // Frequência do clock PDM (3.072 MHz)
)(
    input  logic        clk,         // Clock principal (100 MHz)
    input  logic        rst_n,       // Reset ativo baixo

    output logic        pdm_clk,     // Clock fornecido ao microfone PDM
    input  logic        pdm_data,    // Dados PDM recebidos do microfone
    output logic [15:0] data_out,

    output logic        ready        // Sinal de pronto para leitura de PCM
);

    localparam PDM_CLK_PERIOD   = CLK_FREQ / PDM_CLK_FREQ;
    localparam LAST_BIT_COUNTER = $clog2(PDM_CLK_PERIOD);

    // Clock PDM (3.072 MHz)
    logic [LAST_BIT_COUNTER:0] decimator_cnt = 0;

    logic pdm_posedge;
    logic [2:0] edge_counter;

    logic [3:0] shifft_counter;
    logic [15:0] data_buffer;

    always_ff @(posedge clk) begin
        ready <= 1'b0;

        if (!rst_n) begin
            edge_counter   <= 0;
            data_out       <= 0;
            ready          <= 1'b0;
            shifft_counter <= 0;
            data_buffer    <= 0;
        end else begin
            edge_counter <= {edge_counter[1:0], pdm_clk};

            if(pdm_posedge) begin
                shifft_counter <= shifft_counter + 1;
                data_buffer    <= {data_buffer[14:0], pdm_data};
            end

            if(&shifft_counter) begin
                data_out <= data_buffer;
                ready    <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
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

    assign pdm_posedge = ~edge_counter[2] & edge_counter[1];

endmodule