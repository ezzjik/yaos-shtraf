module receiver(clk, rst, row, col0, col1, action0, action1, action2, rx, busy, cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7);

input clk;
input rst;
input row;
input col0, col1;
input action0, action1, action2;
input rx;
output busy;
output cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

reg busy;
reg cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

parameter W = 8;
parameter DIV = 3;
parameter PAR = 0;

wire [1:0] col = {col1, col0};
wire [2:0] action = {action2, action1, action0};

// Матрица приемника
reg [7:0] M00, M01, M02, M03;
reg [7:0] M10, M11, M12, M13;

// Выход cell
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

// Состояния приемника
reg [2:0] state;
reg [7:0] bit_counter;
reg [7:0] div_counter;
reg [7:0] shift_reg;
reg [2:0] cells_received;
reg [2:0] cells_to_receive;
reg [1:0] rx_row;
reg [1:0] rx_col;
reg [2:0] rx_action;

parameter IDLE = 0;
parameter DETECT_START = 1;
parameter RECEIVE_DATA = 2;
parameter RECEIVE_PARITY = 3;
parameter RECEIVE_STOP = 4;
parameter SAVE_CELL = 5;
parameter NEXT_RX_CELL = 6;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        M00 <= 0; M01 <= 0; M02 <= 0; M03 <= 0;
        M10 <= 0; M11 <= 0; M12 <= 0; M13 <= 0;
        
        busy <= 0;
        state <= IDLE;
        bit_counter <= 0;
        div_counter <= 0;
        cells_received <= 0;
    end else begin
        case (state)
            IDLE: begin
                busy <= 0;
                bit_counter <= 0;
                div_counter <= 0;
                
                if (rx == 0) begin // Обнаружили старт-бит
                    busy <= 1;
                    state <= DETECT_START;
                    // Сохраняем параметры приема
                    rx_row <= row;
                    rx_col <= col;
                    rx_action <= action;
                    
                    // Определяем сколько ячеек ожидать
                    case (action)
                        2: cells_to_receive <= 1;
                        3: cells_to_receive <= 4;
                        4: cells_to_receive <= 2;
                        5: cells_to_receive <= 8;
                        default: cells_to_receive <= 0;
                    endcase
                end
            end
            
            DETECT_START: begin
                if (div_counter == (DIV/2) - 1) begin
                    div_counter <= 0;
                    state <= RECEIVE_DATA;
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            RECEIVE_DATA: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    shift_reg[bit_counter] <= rx;
                    
                    if (bit_counter == 7) begin
                        bit_counter <= 0;
                        if (PAR == 0) begin
                            state <= RECEIVE_STOP;
                        end else begin
                            state <= RECEIVE_PARITY;
                        end
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            RECEIVE_PARITY: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    // Пропускаем проверку четности для упрощения
                    state <= RECEIVE_STOP;
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            RECEIVE_STOP: begin
                if (div_counter == DIV - 1) begin
                    div_counter <= 0;
                    state <= SAVE_CELL;
                end else begin
                    div_counter <= div_counter + 1;
                end
            end
            
            SAVE_CELL: begin
                // Сохраняем принятые данные в матрицу
                case ({rx_row, rx_col})
                    3'b000: M00 <= shift_reg;
                    3'b001: M01 <= shift_reg;
                    3'b010: M02 <= shift_reg;
                    3'b011: M03 <= shift_reg;
                    3'b100: M10 <= shift_reg;
                    3'b101: M11 <= shift_reg;
                    3'b110: M12 <= shift_reg;
                    3'b111: M13 <= shift_reg;
                endcase
                
                cells_received <= cells_received + 1;
                
                if (cells_received + 1 >= cells_to_receive) begin
                    state <= IDLE;
                end else begin
                    state <= NEXT_RX_CELL;
                end
            end
            
            NEXT_RX_CELL: begin
                // Переходим к следующей ячейке в зависимости от action
                case (rx_action)
                    3: begin
                        if (rx_col == 3) begin
                            rx_col <= 0;
                        end else begin
                            rx_col <= rx_col + 1;
                        end
                    end
                    4: begin
                        if (rx_row == 1) begin
                            rx_row <= 0;
                        end else begin
                            rx_row <= rx_row + 1;
                        end
                    end
                    5: begin
                        if (rx_col == 3) begin
                            rx_col <= 0;
                            if (rx_row == 1) begin
                                rx_row <= 0;
                            end else begin
                                rx_row <= rx_row + 1;
                            end
                        end else begin
                            rx_col <= rx_col + 1;
                        end
                    end
                endcase
                
                state <= DETECT_START;
            end
            
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
