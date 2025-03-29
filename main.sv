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

    input  logic M_DATA      // Dados do microfone
);

logic [2:0] busy_sync;
logic data_in_valid, busy, data_out_valid, busy_posedge;

logic [7:0] memory [0:15]; // 16 bytes of memory

logic [3:0] address;
logic [7:0] leds;

initial begin
    $readmemh("test.hex", memory);
end

SPI_Slave U1(
    .clk            (clk),
    .rst_n          (CPU_RESETN),

    .sck            (sck),
    .cs             (cs),
    .mosi           (mosi),
    .miso           (miso),

    .data_in_valid  (data_in_valid),
    .data_out_valid (data_out_valid),
    .busy           (busy),

    .data_in        (memory[address]),
    .data_out       (leds)
);

always_ff @(posedge clk) begin
    if(!CPU_RESETN) begin
        busy_sync <= 3'b000;
    end else begin
        busy_sync <= {busy_sync[1:0], busy};
    end
end

always_ff @(posedge clk) begin
    if(!CPU_RESETN) begin
        data_in_valid <= 1'b0;
        address       <= 4'b0000;
    end else begin
        if(busy_posedge) begin
            data_in_valid <= 1'b1;
            address       <= address + 1'b1;
        end else begin
            data_in_valid <= 1'b0;
        end
    end
end

always_ff @(posedge clk) begin
    if(!CPU_RESETN) begin
        LED <= 16'h616C;
    end else begin
        if(data_out_valid) begin
            LED <= {leds, 8'b00000000};
        end
    end
end

assign busy_posedge = (busy_sync[2:1] == 2'b01) ? 1'b1 : 1'b0;

endmodule

