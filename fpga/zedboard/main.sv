module top (
    input  logic clk,
    input  logic rst,

    output logic [7:0]LED,

    input  logic mosi,
    output logic miso,
    input  logic sck,
    input  logic cs,

    output logic M_CLK,      // Clock do microfone
    output logic M_LRSEL,    // Left/Right Select (Escolha do canal)

    input  logic M_DATA,     // Dados do microfone

    output logic [7:0] PMOD_LED
);


PDM #(
    .DECIMATION_FACTOR   (256),
    .DATA_WIDTH          (16),
    .FIR_TAPS            (64),
    .CLK_FREQ            (100_000_000),
    .PDM_CLK_FREQ        (1_800_000),
    .CIC_STAGES          (4),
    .FIFO_DEPTH          (65536), // 64kB
    .FIFO_WIDTH          (8),
    .SPI_BITS_PER_WORD   (8),
    .ENABLE_COMPRESSION  (1),
    .PDM_CHANNEL         (0)
) pdm_inst (
    .clk         (clk),     // sys clock
    .rst_n       (~rst),    // reset (ativo baixo)

    .LED         (LED),     // saída de LEDs com audio PCM

    .mosi        (mosi),    // entrada do SPI
    .miso        (miso),    // saída do SPI
    .sck         (sck),     // entrada do SPI clock
    .cs          (cs),      // entrada do chip select SPI

    .M_CLK       (M_CLK),   // saída do clock para o microfone
    .M_LRSEL     (M_LRSEL), // seleção de canal do microfone

    .M_DATA      (M_DATA),  // entrada de dados do microfone

    .debug_leds  (PMOD_LED) // saída para LEDs de debug
);


endmodule
