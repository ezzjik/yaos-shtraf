module transmitter_fsm(clk, rst, d0, d1, d2, d3, d4, d5, d6, d7, row, col0, col1, action0, action1, action2, tx, busy, cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7);

input clk;
input rst;
input d0, d1, d2, d3, d4, d5, d6, d7;
input row;
input col0, col1;
input action0, action1, action2;
output tx;
output busy;
output cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

// === УПРАВЛЯЮЩИЙ АВТОМАТ (Control Unit) ===
// Регистры состояний управляющего автомата
reg [2:0] cu_state;
reg [2:0] cu_next_state;

// Управляющие сигналы для операционного автомата
reg cu_load_matrix;
reg cu_start_transmission;
reg cu_load_shift_reg;
reg cu_shift_enable;
reg cu_update_bit_counter;
reg cu_update_div_counter;
reg cu_update_cell_indices;
reg cu_reset_counters;
reg cu_calculate_parity;
reg cu_set_tx_start;
reg cu_set_tx_data;
reg cu_set_tx_parity;
reg cu_set_tx_stop;
reg cu_set_busy;
reg cu_clear_busy;

// Параметры состояний управляющего автомата
parameter CU_IDLE        = 3'd0;
parameter CU_START_BIT   = 3'd1;
parameter CU_DATA_BITS   = 3'd2;
parameter CU_PARITY_BIT  = 3'd3;
parameter CU_STOP_BIT    = 3'd4;
parameter CU_NEXT_CELL   = 3'd5;

// === ОПЕРАЦИОННЫЙ АВТОМАТ (Data Path) ===
// Регистры операционного автомата
reg [7:0] dp_M00, dp_M01, dp_M02, dp_M03;
reg [7:0] dp_M10, dp_M11, dp_M12, dp_M13;
reg [7:0] dp_shift_reg;
reg [7:0] dp_bit_counter;
reg [7:0] dp_div_counter;
reg dp_parity_bit;
reg [1:0] dp_tx_row;
reg [1:0] dp_tx_col;
reg [2:0] dp_tx_action;
reg [3:0] dp_cells_to_send;
reg [3:0] dp_cells_sent;

// Выходные регистры операционного автомата
reg dp_tx;
reg dp_busy;
reg [7:0] dp_cell;

// Сигналы обратной связи от операционного автомата к управляющему
wire dp_div_max = (dp_div_counter == 8'd2);  // DIV-1, где DIV=3
wire dp_bit_max = (dp_bit_counter == 8'd7);  // W-1, где W=8
wire dp_cells_done = (dp_cells_sent >= dp_cells_to_send);

// Входные векторы для удобства
wire [7:0] dp_d = {d7, d6, d5, d4, d3, d2, d1, d0};
wire [1:0] dp_col = {col1, col0};
wire [2:0] dp_action = {action2, action1, action0};

// Параметры (по умолчанию)
parameter W = 8;
parameter DIV = 3;
parameter PAR = 0;

// === УПРАВЛЯЮЩИЙ АВТОМАТ: комбинационная логика ===
always @(*) begin
    // Значения по умолчанию для управляющих сигналов
    cu_load_matrix = 0;
    cu_start_transmission = 0;
    cu_load_shift_reg = 0;
    cu_shift_enable = 0;
    cu_update_bit_counter = 0;
    cu_update_div_counter = 0;
    cu_update_cell_indices = 0;
    cu_reset_counters = 0;
    cu_calculate_parity = 0;
    cu_set_tx_start = 0;
    cu_set_tx_data = 0;
    cu_set_tx_parity = 0;
    cu_set_tx_stop = 0;
    cu_set_busy = 0;
    cu_clear_busy = 0;
    
    // Логика выбора следующего состояния
    cu_next_state = cu_state;
    
    case (cu_state)
        CU_IDLE: begin
            cu_clear_busy = 1;
            cu_reset_counters = 1;
            
            if (dp_action == 3'd1) begin
                cu_load_matrix = 1;
            end
            else if (dp_action >= 3'd2 && dp_action <= 3'd5) begin
                cu_start_transmission = 1;
                cu_set_busy = 1;
                cu_next_state = CU_START_BIT;
            end
        end
        
        CU_START_BIT: begin
            cu_set_busy = 1;
            cu_set_tx_start = 1;
            
            if (dp_div_max) begin
                cu_load_shift_reg = 1;
                cu_next_state = CU_DATA_BITS;
            end
            else begin
                cu_update_div_counter = 1;
            end
        end
        
        CU_DATA_BITS: begin
            cu_set_busy = 1;
            cu_set_tx_data = 1;
            
            if (dp_div_max) begin
                cu_shift_enable = 1;
                
                if (dp_bit_max) begin
                    if (PAR == 0) begin
                        cu_next_state = CU_STOP_BIT;
                    end
                    else begin
                        cu_calculate_parity = 1;
                        cu_next_state = CU_PARITY_BIT;
                    end
                end
                else begin
                    cu_update_bit_counter = 1;
                end
            end
            else begin
                cu_update_div_counter = 1;
            end
        end
        
        CU_PARITY_BIT: begin
            cu_set_busy = 1;
            cu_set_tx_parity = 1;
            
            if (dp_div_max) begin
                cu_next_state = CU_STOP_BIT;
            end
            else begin
                cu_update_div_counter = 1;
            end
        end
        
        CU_STOP_BIT: begin
            cu_set_busy = 1;
            cu_set_tx_stop = 1;
            
            if (dp_div_max) begin
                if (dp_cells_done) begin
                    cu_next_state = CU_IDLE;
                end
                else begin
                    cu_update_cell_indices = 1;
                    cu_next_state = CU_NEXT_CELL;
                end
            end
            else begin
                cu_update_div_counter = 1;
            end
        end
        
        CU_NEXT_CELL: begin
            cu_set_busy = 1;
            cu_next_state = CU_START_BIT;
        end
    endcase
end

// === УПРАВЛЯЮЩИЙ АВТОМАТ: последовательная логика ===
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cu_state <= CU_IDLE;
    end
    else begin
        cu_state <= cu_next_state;
    end
end

// === ОПЕРАЦИОННЫЙ АВТОМАТ: последовательная логика ===
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Сброс регистров операционного автомата
        dp_M00 <= 8'b0; dp_M01 <= 8'b0; dp_M02 <= 8'b0; dp_M03 <= 8'b0;
        dp_M10 <= 8'b0; dp_M11 <= 8'b0; dp_M12 <= 8'b0; dp_M13 <= 8'b0;
        dp_shift_reg <= 8'b0;
        dp_bit_counter <= 8'b0;
        dp_div_counter <= 8'b0;
        dp_parity_bit <= 1'b0;
        dp_tx_row <= 2'b0;
        dp_tx_col <= 2'b0;
        dp_tx_action <= 3'b0;
        dp_cells_to_send <= 4'b0;
        dp_cells_sent <= 4'b0;
        dp_tx <= 1'b1;
        dp_busy <= 1'b0;
        dp_cell <= 8'b0;
    end
    else begin
        // Обработка управляющих сигналов
        if (cu_reset_counters) begin
            dp_bit_counter <= 8'b0;
            dp_div_counter <= 8'b0;
        end
        
        if (cu_load_matrix) begin
            // Загрузка данных в матрицу
            case ({row, dp_col})
                3'b000: dp_M00 <= dp_d;
                3'b001: dp_M01 <= dp_d;
                3'b010: dp_M02 <= dp_d;
                3'b011: dp_M03 <= dp_d;
                3'b100: dp_M10 <= dp_d;
                3'b101: dp_M11 <= dp_d;
                3'b110: dp_M12 <= dp_d;
                3'b111: dp_M13 <= dp_d;
            endcase
        end
        
        if (cu_start_transmission) begin
            dp_tx_action <= dp_action;
            dp_tx_row <= row;
            dp_tx_col <= dp_col;
            dp_cells_sent <= 4'b0;
            
            case (dp_action)
                3'd2: dp_cells_to_send <= 4'd1;
                3'd3: dp_cells_to_send <= 4'd4;
                3'd4: dp_cells_to_send <= 4'd2;
                3'd5: dp_cells_to_send <= 4'd8;
                default: dp_cells_to_send <= 4'b0;
            endcase
        end
        
        if (cu_update_div_counter) begin
            dp_div_counter <= dp_div_counter + 1;
        end
        
        if (cu_load_shift_reg) begin
            // Загрузка данных в сдвиговый регистр из выбранной ячейки
            case ({dp_tx_row, dp_tx_col})
                3'b000: dp_shift_reg <= dp_M00;
                3'b001: dp_shift_reg <= dp_M01;
                3'b010: dp_shift_reg <= dp_M02;
                3'b011: dp_shift_reg <= dp_M03;
                3'b100: dp_shift_reg <= dp_M10;
                3'b101: dp_shift_reg <= dp_M11;
                3'b110: dp_shift_reg <= dp_M12;
                3'b111: dp_shift_reg <= dp_M13;
            endcase
            dp_div_counter <= 8'b0;
        end
        
        if (cu_shift_enable) begin
            dp_shift_reg <= {1'b0, dp_shift_reg[7:1]};
            dp_div_counter <= 8'b0;
        end
        
        if (cu_update_bit_counter) begin
            dp_bit_counter <= dp_bit_counter + 1;
        end
        
        if (cu_calculate_parity) begin
            // Вычисление бита четности
            if (PAR == 1) begin
                // Четность
                dp_parity_bit <= ^dp_shift_reg;
            end
            else if (PAR == 2) begin
                // Нечетность
                dp_parity_bit <= ~(^dp_shift_reg);
            end
        end
        
        if (cu_update_cell_indices) begin
            dp_cells_sent <= dp_cells_sent + 1;
            
            case (dp_tx_action)
                3'd3: begin // Строка
                    if (dp_tx_col == 2'd3) begin
                        dp_tx_col <= 2'd0;
                    end
                    else begin
                        dp_tx_col <= dp_tx_col + 1;
                    end
                end
                3'd4: begin // Столбец
                    if (dp_tx_row == 1'b1) begin
                        dp_tx_row <= 1'b0;
                    end
                    else begin
                        dp_tx_row <= dp_tx_row + 1;
                    end
                end
                3'd5: begin // Вся матрица
                    if (dp_tx_col == 2'd3) begin
                        dp_tx_col <= 2'd0;
                        if (dp_tx_row == 1'b1) begin
                            dp_tx_row <= 1'b0;
                        end
                        else begin
                            dp_tx_row <= dp_tx_row + 1;
                        end
                    end
                    else begin
                        dp_tx_col <= dp_tx_col + 1;
                    end
                end
            endcase
        end
        
        // Установка выходов tx
        if (cu_set_tx_start) begin
            dp_tx <= 1'b0;
        end
        else if (cu_set_tx_data) begin
            dp_tx <= dp_shift_reg[0];
        end
        else if (cu_set_tx_parity) begin
            dp_tx <= dp_parity_bit;
        end
        else if (cu_set_tx_stop) begin
            dp_tx <= 1'b1;
        end
        
        // Установка busy
        if (cu_set_busy) begin
            dp_busy <= 1'b1;
        end
        else if (cu_clear_busy) begin
            dp_busy <= 1'b0;
        end
        
        // Непрерывное обновление выхода cell
        case ({row, dp_col})
            3'b000: dp_cell <= dp_M00;
            3'b001: dp_cell <= dp_M01;
            3'b010: dp_cell <= dp_M02;
            3'b011: dp_cell <= dp_M03;
            3'b100: dp_cell <= dp_M10;
            3'b101: dp_cell <= dp_M11;
            3'b110: dp_cell <= dp_M12;
            3'b111: dp_cell <= dp_M13;
            default: dp_cell <= 8'b0;
        endcase
    end
end

// === ПРИСВАИВАНИЕ ВЫХОДОВ ===
assign tx = dp_tx;
assign busy = dp_busy;
assign {cell7, cell6, cell5, cell4, cell3, cell2, cell1, cell0} = dp_cell;

endmodule
