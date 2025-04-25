module PDM #(
    parameter DECIMATION_FACTOR        = 256,
    parameter DATA_WIDTH               = 16,
    parameter FIR_TAPS                 = 64,
    parameter CLK_FREQ                 = 100_000_000,
    parameter PDM_CLK_FREQ             = 1_800_000,
    parameter CIC_STAGES               = 4,
    parameter FIFO_DEPTH               = 524288, // 520kB
    parameter FIFO_WIDTH               = 8,
    parameter SPI_BITS_PER_WORD        = 8,
    parameter ENABLE_COMPRESSION       = 1,
    parameter PDM_CHANNEL              = 0, // 0 - Canal esquerdo, 1 - Canal direito
    parameter SECOND_DECIMATION_FACTOR = 2,
    parameter COMPRESSED_DATA_WIDTH    = 8
) (
    input  logic clk,
    input  logic rst_n,

    output logic [15:0] LED,

    input  logic mosi,
    output logic miso,
    input  logic sck,
    input  logic cs,

    output logic M_CLK,      // Clock do microfone
    output logic M_LRSEL,    // Left/Right Select (Escolha do canal)

    input  logic M_DATA,     // Dados do microfone

    output logic [7:0] debug_leds
);

logic [2:0] busy_sync;
logic data_in_valid, busy, data_out_valid, busy_posedge;

logic [7:0] leds;
logic [7:0] spi_send_data;

logic [15:0] pcm_out;
logic pcm_ready;

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

    .pcm_out    (pcm_out),
    .ready      (pcm_ready)
);

logic valid_processed;
logic [7:0] processed_sample_out;

generate
if(ENABLE_COMPRESSION) begin
down_sample_and_resolution #(
    .DATA_IN_WIDTH     (DATA_WIDTH),
    .DATA_OUT_WIDTH    (COMPRESSED_DATA_WIDTH),
    .DECIMATION_FACTOR (SECOND_DECIMATION_FACTOR)
) u_downsample (
    .clk        (clk),
    .rst_n      (rst_n),

    .valid_in   (pcm_ready),
    .data_in    (pcm_out),

    .valid_out  (valid_processed),
    .data_out   (processed_sample_out)
);
end 
endgenerate

SPI_Slave #(
    .SPI_BITS_PER_WORD (SPI_BITS_PER_WORD)
) U1(
    .clk            (clk),
    .rst_n          (rst_n),

    .sck            (sck),
    .cs             (cs),
    .mosi           (mosi),
    .miso           (miso),

    .data_in_valid  (data_in_valid),
    .data_out_valid (data_out_valid),
    .busy           (busy),

    .data_in        (spi_send_data),
    .data_out       (leds)
);


logic fifo_wr_en, fifo_rd_en, fifo_full, fifo_empty;
logic [7:0] fifo_read_data, fifo_write_data;

FIFO #(
    .DEPTH        (FIFO_DEPTH), // 520kB
    .WIDTH        (FIFO_WIDTH) // 8 bits
) tx_fifo (
    .clk          (clk),
    .rst_n        (rst_n),

    .wr_en_i      (fifo_wr_en),
    .rd_en_i      (fifo_rd_en),

    .write_data_i (fifo_write_data),
    .full_o       (fifo_full),
    .empty_o      (fifo_empty),
    .read_data_o  (fifo_read_data)
);

typedef enum logic { 
    IDLE,
    WRITE_FIRST_BYTE
} write_fifo_state_t;

write_fifo_state_t write_fifo_state;

always_ff @(posedge clk) begin
    fifo_wr_en <= 1'b0;

    if(!rst_n) begin
        write_fifo_state <= IDLE;
    end else begin

    if(ENABLE_COMPRESSION) begin
        if(valid_processed && !fifo_full) begin
            fifo_write_data <= processed_sample_out;
            fifo_wr_en      <= 1'b1;
        end
    end else begin
        unique case (write_fifo_state)
            IDLE: begin
                if(pcm_ready && !fifo_full) begin
                    fifo_write_data <= pcm_out[7:0];
                    fifo_wr_en      <= 1'b1;
                    write_fifo_state <= WRITE_FIRST_BYTE;
                end
            end 
            WRITE_FIRST_BYTE: begin
                if(!fifo_full) begin
                    fifo_write_data <= pcm_out[15:8];
                    fifo_wr_en      <= 1'b1;
                    write_fifo_state <= IDLE;
                end else begin
                    fifo_wr_en <= 1'b0;
                end
            end
            default: write_fifo_state <= IDLE;
        endcase
    end

    end
end

always_ff @(posedge clk) begin
    if(!rst_n) begin
        busy_sync <= 3'b000;
    end else begin
        busy_sync <= {busy_sync[1:0], busy};
    end
end

logic write_back_fifo;

always_ff @(posedge clk) begin
    fifo_rd_en <= 1'b0;

    if(!rst_n) begin
        data_in_valid <= 1'b0;
        spi_send_data <= 8'b0;
        write_back_fifo <= 1'b0;
    end else begin
        if(busy_posedge) begin
            if(fifo_empty) begin
                spi_send_data <= fifo_read_data;
                data_in_valid <= 1'b1;
            end else begin
                fifo_rd_en <= 1'b1;
                write_back_fifo <= 1'b1;
            end
        end else begin
            data_in_valid <= 1'b0;
        end

        if(write_back_fifo) begin
            fifo_rd_en <= 1'b0;
            write_back_fifo <= 1'b0;
            spi_send_data <= fifo_read_data;
            data_in_valid <= 1'b1;
        end
    end
end

assign busy_posedge = ~busy_sync[2] & busy_sync[1];
assign M_LRSEL      = PDM_CHANNEL; // Canal esquerdo
assign LED          = pcm_out;

assign debug_leds[0] = ~fifo_empty;
assign debug_leds[1] = 1'b1;
assign debug_leds[2] = ~fifo_full;
assign debug_leds[3] = 1'b1;
assign debug_leds[4] = ~busy;
assign debug_leds[5] = 1'b1;
assign debug_leds[6] = 1'b1;
assign debug_leds[7] = 1'b1;

endmodule

