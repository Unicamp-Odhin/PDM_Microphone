module top (
    input  logic clk,
    input  logic CPU_RESETN,

    input  logic rx,
    output logic tx,

    output logic [15:0]LED,

    input  logic mosi,
    output logic miso,
    input  logic sck,
    input  logic cs,

    input  logic [15:0] SW,

    output logic [3:0] VGA_R,
    output logic [3:0] VGA_G,
    output logic [3:0] VGA_B,
    output logic VGA_HS,
    output logic VGA_VS,

    output logic M_CLK,      // Clock do microfone
    output logic M_LRSEL,    // Left/Right Select (Escolha do canal)

    input  logic M_DATA,     // Dados do microfone

    output logic i2s_clk,    // Clock do I2S
    output logic i2s_ws,     // Word Select do I2S
    input  logic i2s_sd,     // Dados do I2S

    output logic [7:0] JC
);

logic [2:0] busy_sync;
logic data_in_valid, busy, data_out_valid, busy_posedge;

logic [7:0] leds;
logic [7:0] spi_send_data;

logic [15:0] pcm_out;
logic pcm_ready;

// Instanciação do módulo

pdm_capture_fir #(
    .DECIMATION_FACTOR (256),
    .DATA_WIDTH        (16),
    .FIR_TAPS          (128),
    .CLK_FREQ          (100_000_000), // Frequência do clock do sistema
    .PDM_CLK_FREQ      (3_072_000),   // Frequência do clock PDM
    .CIC_STAGES        (5)            // Número de estágios do CIC
) u_pdm_capture_fir (
    .clk        (clk),
    .rst_n      (CPU_RESETN),

    .pdm_clk    (M_CLK),
    .pdm_data   (M_DATA),

    .pcm_out    (pcm_out),
    .ready      (pcm_ready)
);
/*
pdm_deserializer #(
    .CLK_FREQ          (100_000_000), // Frequência do clock do sistema
    .PDM_CLK_FREQ      (3_072_000)    // Frequência do clock PDM
) u_pdm_capture_fir (
    .clk        (clk),
    .rst_n      (CPU_RESETN),

    .pdm_clk    (M_CLK),
    .pdm_data   (M_DATA),

    .data_out   (pcm_out),
    .ready      (pcm_ready)
);


i2s_receiver #(
    .CLK_FREQ     (100_000_000), // Frequência do clock do sistema
    .I2S_CLK_FREQ (3_072_000),    // Frequência do clock I2S
    .DATA_WIDTH   (16) // Definição do parâmetro de largura de dados (pode ser ajustado conforme necessário)
) u_i2s_receiver (
    .clk        (clk),         // Conecte o clock do sistema
    .rst_n      (CPU_RESETN),       // Conecte o reset ativo baixo

    .i2s_clk_o  (i2s_clk),   // Saída do clock I2S
    .i2s_ws_o   (i2s_ws),    // Saída do word select I2S
    .i2s_data_i (i2s_sd),  // Entrada de dados I2S
    
    .pcm_data_o (pcm_out),  // Saída de dados PCM
    .ready_o    (pcm_ready)      // Sinal de pronto
);
*/

SPI_Slave #(
    .SPI_BITS_PER_WORD (8)
) U1(
    .clk            (clk),
    .rst_n          (CPU_RESETN),

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
    .DEPTH        (524288), // 520kB
    .WIDTH        (8)
) tx_fifo (
    .clk          (clk),
    .rst_n        (CPU_RESETN),

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

    if(!CPU_RESETN) begin
        write_fifo_state <= IDLE;
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

always_ff @(posedge clk) begin
    if(!CPU_RESETN) begin
        busy_sync <= 3'b000;
    end else begin
        busy_sync <= {busy_sync[1:0], busy};
    end
end

logic write_back_fifo;

always_ff @(posedge clk) begin
    fifo_rd_en <= 1'b0;

    if(!CPU_RESETN) begin
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

logic [14:0] led;

always_ff @(posedge clk) begin
    if(!CPU_RESETN) begin
        led <= 16'h616C;
    end else begin
        if(data_out_valid) begin
            led <= {leds, 6'b000000, fifo_empty};
        end
    end
end

assign busy_posedge = ~busy_sync[2] & busy_sync[1];
assign M_LRSEL      = 1'b0; // Canal esquerdo
assign LED          = pcm_out;

assign VGA_R  = 4'b0000;
assign VGA_G  = 4'b0000;
assign VGA_B  = 4'b0000;
assign VGA_HS = 1'b0;
assign VGA_VS = 1'b0;

assign JC[0] = ~fifo_empty;
assign JC[1] = 1'b1;
assign JC[2] = ~fifo_full;
assign JC[3] = 1'b1;
assign JC[4] = ~busy;
assign JC[5] = 1'b1;
assign JC[6] = 1'b1;
assign JC[7] = 1'b1;

endmodule

