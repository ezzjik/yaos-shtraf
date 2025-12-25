module transmitter(clk, rst, d0, d1, d2, d3, d4, d5, d6, d7, row, col0, col1, action0, action1, action2, tx, busy, cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7);

input clk;
input rst;
input d0, d1, d2, d3, d4, d5, d6, d7;
input row;
input col0, col1;
input action0, action1, action2;
output tx;
output busy;
output cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

reg tx;
reg busy;
reg cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

parameter W = 8;
parameter DIV = 3;
parameter PAR = 0;

wire [7:0] d = {d7, d6, d5, d4, d3, d2, d1, d0};
wire [1:0] col = {col1, col0};
wire [2:0] action = {action2, action1, action0};

reg [7:0] M00, M01, M02, M03;
reg [7:0] M10, M11, M12, M13;

wire [7:0] cell_val;
assign cell_val = (row == 0) ? 
                  (col == 0) ? M00 :
                  (col == 1) ? M01 :
                  (col == 2) ? M02 : M03
                : (col == 0) ? M10 :
                  (col == 1) ? M11 :
                  (col == 2) ? M12 : M13;

always @(cell_val) begin
    {cell7, cell6, cell5, cell4, cell3, cell2, cell1, cell0} = cell_val;
end

reg [2:0] state;
reg [7:0] bit_counter;
reg [7:0] div_counter;
reg [7:0] shift_reg;
reg parity_bit;

reg [1:0] tx_row;
reg [1:0] tx_col;
reg [2:0] tx_action;
reg [3:0] cells_to_send;
reg [3:0] cells_sent;

wire [7:0] data_to_send;

assign data_to_send = 
    (tx_row == 0) ? 
        (tx_col == 0) ? M00 :
        (tx_col == 1) ? M01 :
        (tx_col == 2) ? M02 : M03
    : (tx_col == 0) ? M10 :
        (tx_col == 1) ? M11 :
        (tx_col == 2) ? M12 : M13;

parameter IDLE = 0;
parameter START_BIT = 1;
parameter DATA_BITS = 2;
parameter PARITY_BIT = 3;
parameter STOP_BIT = 4;
parameter NEXT_CELL = 5;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        M00 <= 0; M01 <= 0; M02 <= 0; M03 <= 0;
        M10 <= 0; M11 <= 0; M12 <= 0; M13 <= 0;
        
        tx <= 1;
        busy <= 0;
        state <= IDLE;
        bit_counter <= 0;
        div_counter <= 0;
        cells_sent <= 0;
        tx_row <= 0;
        tx_col <= 0;
    end else begin
        case (state)
            IDLE: begin
                tx <= 1;
                busy <= 0;
                bit_counter <= 0;
                div_counter <= 0;
                cells_sent <= 0;
                
                if (action == 1) begin
                    case ({row, col})
                        3'b000: M00 <= d;
                        3'b001: M01 <= d;
                        3'b010: M02 <= d;
                        3'b011: M03 <= d;
                        3'b100: M10 <= d;
                        3'b101: M11 <= d;
                        3'b110: M12 <= d;
                        3'b111: M13 <= d;
                    endcase
                end else if (action >= 2 && action <= 5) begin
                    busy <= 1;
                    tx_action <= action;
                    
                    case (action)
                        2: begin
                            cells_to_send <= 1;
                            tx_row <= row;
                            tx_col <= col;
                        end
                        3: begin
                            cells_to_send <= 4;
                            tx_row <= row;
                            tx_col <= 0;
                        end
                        4: begin
                            cells_to_send <= 2;
                            tx_row <= 0;
                            tx_col <= col;
                        end
                        5: begin
                            cells_to_send <= 8;
                            tx_row <= 0;
                            tx_col <= 0;
                        end
                    endcase
                    
                    state <= START_BIT;
                    tx <= 0;
                end
            end
            
            START_BIT: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    state <= DATA_BITS;
                    shift_reg <= data_to_send;
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            DATA_BITS: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    tx <= shift_reg[0];
                    shift_reg <= {1'b0, shift_reg[7:1]};
                    
                    if (bit_counter == 7) begin
                        bit_counter <= 0;
                        if (PAR == 0) begin
                            state <= STOP_BIT;
                        end else begin
                            state <= PARITY_BIT;
                            if (PAR == 1) begin
                                parity_bit <= ^data_to_send;
                            end else begin
                                parity_bit <= ~(^data_to_send);
                            end
                        end
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            PARITY_BIT: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    tx <= parity_bit;
                    state <= STOP_BIT;
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            STOP_BIT: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    tx <= 1;
                    cells_sent <= cells_sent + 1;
                    
                    if (cells_sent + 1 >= cells_to_send) begin
                        state <= IDLE;
                    end else begin
                        state <= NEXT_CELL;
                    end
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            NEXT_CELL: begin
                case (tx_action)
                    3: begin
                        if (tx_col == 3) begin
                            tx_col <= 0;
                        end else begin
                            tx_col <= tx_col + 1;
                        end
                    end
                    4: begin
                        if (tx_row == 1) begin
                            tx_row <= 0;
                        end else begin
                            tx_row <= tx_row + 1;
                        end
                    end
                    5: begin
                        if (tx_col == 3) begin
                            tx_col <= 0;
                            if (tx_row == 1) begin
                                tx_row <= 0;
                            end else begin
                                tx_row <= tx_row + 1;
                            end
                        end else begin
                            tx_col <= tx_col + 1;
                        end
                    end
                endcase
                
                state <= START_BIT;
                tx <= 0;
            end
            
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
