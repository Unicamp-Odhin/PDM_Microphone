module PDM #(
    parameter DECIMATION_FACTOR        = 256,
    parameter DATA_WIDTH               = 16,
    parameter FIR_TAPS                 = 64,
    parameter CLK_FREQ                 = 100_000_000,
    parameter PDM_CLK_FREQ             = 1_800_000,
    parameter CIC_STAGES               = 4,
    parameter ENABLE_COMPRESSION       = 1,
    parameter PDM_CHANNEL              = 0, // 0 - Canal esquerdo, 1 - Canal direito
    parameter SECOND_DECIMATION_FACTOR = 2,
    parameter COMPRESSED_DATA_WIDTH    = 8
) (
    // Global signals
    input  logic clk,
    input  logic rst_n,

    // PDM Signals
    output logic M_CLK,      // Clock do microfone
    output logic M_LRSEL,    // Left/Right Select (Escolha do canal)
    input  logic M_DATA,     // Dados do microfone

    // PCM Signals
    output logic pcm_ready,
    output logic [DATA_WIDTH-1:0] pcm_out
);

logic pdm_ready;
logic [DATA_WIDTH-1:0] pdm_out;

pdm_capture #(
    .DECIMATION_FACTOR (DECIMATION_FACTOR),
    .DATA_WIDTH        (DATA_WIDTH),
    .FIR_TAPS          (FIR_TAPS),
    .CLK_FREQ          (CLK_FREQ),     // Frequência do clock do sistema
    .PDM_CLK_FREQ      (PDM_CLK_FREQ), // Frequência do clock PDM
    .CIC_STAGES        (CIC_STAGES)    // Número de estágios do CIC
) u_pdm_capture_fir (
    .clk        (clk),
    .rst_n      (rst_n),

    .pdm_clk    (M_CLK),
    .pdm_data   (M_DATA),

    .pcm_out    (pdm_out),
    .ready      (pdm_ready)
);

generate
if(ENABLE_COMPRESSION) begin

logic valid_processed;
logic [7:0] processed_sample_out;

down_sample_and_resolution #(
    .DATA_IN_WIDTH     (DATA_WIDTH),
    .DATA_OUT_WIDTH    (COMPRESSED_DATA_WIDTH),
    .DECIMATION_FACTOR (SECOND_DECIMATION_FACTOR)
) u_downsample (
    .clk        (clk),
    .rst_n      (rst_n),

    .valid_in   (pdm_ready),
    .data_in    (pdm_out),

    .valid_out  (valid_processed),
    .data_out   (processed_sample_out)
);

    assign pcm_ready = valid_processed;
    assign pcm_out   = {0, processed_sample_out};

end else begin
    assign pcm_ready = pdm_ready;
    assign pcm_out   = pdm_out;
end
endgenerate

assign M_LRSEL      = PDM_CHANNEL; // Canal esquerdo

endmodule

