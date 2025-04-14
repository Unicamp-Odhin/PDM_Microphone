module cic_decimator #(
    parameter N         = 3,  // Número de estágios
    parameter R         = 8,  // Fator de decimação
    parameter IN_WIDTH  = 16, // Largura da entrada PCM
    parameter OUT_WIDTH = 16  // Largura da saída
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        in_valid,
    input  logic signed [IN_WIDTH-1:0]  in_sample,
    output logic                        out_valid,
    output logic signed [OUT_WIDTH-1:0] out_sample
);

    localparam ACC_WIDTH  = IN_WIDTH + N * 4;
    localparam GAIN_SHIFT = $clog2(R ** N); // log2(R ^ N) para o shift

    // Limites de saturação
    localparam signed [OUT_WIDTH-1:0] MAX_OUT =  {1'b0, {(OUT_WIDTH-1){1'b1}}};
    localparam signed [OUT_WIDTH-1:0] MIN_OUT =  {1'b1, {(OUT_WIDTH-1){1'b0}}};

    // Integradores e combinadores
    logic signed [ACC_WIDTH-1:0] integrator [0:N-1];
    logic signed [ACC_WIDTH-1:0] comb_delay [0:N-1];
    logic signed [ACC_WIDTH-1:0] comb_output;
    logic signed [ACC_WIDTH-1:0] shifted_output;

    // Contador
    logic [$clog2(R)-1:0] decim_cnt = 0;

    integer i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < N; i++) begin
                integrator[i] <= '0;
                comb_delay[i] <= '0;
            end
            comb_output    <= '0;
            shifted_output <= '0;
            decim_cnt      <= '0;
            out_sample     <= '0;
            out_valid      <= 0;
        end else if (in_valid) begin
            // Integradores
            integrator[0] <= integrator[0] + in_sample;
            for (i = 1; i < N; i++) begin
                integrator[i] <= integrator[i] + integrator[i-1];
            end

            // Decimação
            decim_cnt <= decim_cnt + 1;
            if (decim_cnt == R - 1) begin
                decim_cnt <= 0;

                // Combs
                comb_delay[0] <= integrator[N-1];
                for (i = 1; i < N; i++) begin
                    comb_delay[i] <= comb_delay[i] - comb_delay[i-1];
                end

                // Compensação de ganho com arredondamento
                comb_output    <= comb_delay[N-1];
                shifted_output <= (comb_delay[N-1] + (1 <<< (GAIN_SHIFT - 1))) >>> GAIN_SHIFT;

                // Saturação
                if (shifted_output > MAX_OUT)
                    out_sample <= MAX_OUT;
                else if (shifted_output < MIN_OUT)
                    out_sample <= MIN_OUT;
                else
                    out_sample <= shifted_output[OUT_WIDTH-1:0];

                out_valid <= 1;
            end else begin
                out_valid <= 0;
            end
        end else begin
            out_valid <= 0;
        end
    end

endmodule
