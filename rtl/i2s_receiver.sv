module i2s_receiver #(
    parameter CLK_FREQ     = 100_000_000, // Frequência do clock principal
    parameter I2S_CLK_FREQ = 3_072_000,   // Frequência do clock I2S (3.072 MHz)
    parameter DATA_WIDTH   = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,

    output logic                  i2s_clk_o,
    output logic                  i2s_ws_o,
    input  logic                  i2s_data_i,
    
    output logic [DATA_WIDTH-1:0] pcm_data_o,
    output logic                  ready_o
);

    localparam PDM_CLK_PERIOD   = CLK_FREQ / I2S_CLK_FREQ;
    localparam LAST_BIT_COUNTER = $clog2(PDM_CLK_PERIOD);

    // Clock PDM (3.072 MHz)
    logic [LAST_BIT_COUNTER:0] decimator_cnt = 0;

    logic [1:0] i2s_clk_posedge_reg;
    logic       i2s_clk_posedge;

    logic [3:0] i2s_data_counter;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            pcm_data_o <= 0;
            i2s_ws_o   <= 1'b0;
        end else begin
            if(i2s_clk_posedge) begin
                pcm_data_o <= {pcm_data_o[DATA_WIDTH-2:0], i2s_data_i};
                i2s_data_counter <= i2s_data_counter + 1;
                if(&i2s_data_counter) begin
                    i2s_ws_o <= ~i2s_ws_o;
                    ready_o  <= 1'b1;
                end else begin
                    ready_o <= 1'b0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            i2s_clk_o           <= 1'b0;
            decimator_cnt       <= 0;
            i2s_clk_posedge_reg <= 2'b00;
        end else begin
            if (decimator_cnt < PDM_CLK_PERIOD / 2)
                i2s_clk_o <= 1'b1;
            else
                i2s_clk_o <= 1'b0;

            if (decimator_cnt == PDM_CLK_PERIOD) begin
                decimator_cnt <= 0;
            end else begin
                decimator_cnt <= decimator_cnt + 1;
            end

            i2s_clk_posedge_reg <= {i2s_clk_posedge_reg[0], i2s_clk_o};
        end
    end

    assign i2s_clk_posedge = ~i2s_clk_posedge_reg[1] & i2s_clk_posedge_reg[0];

endmodule

