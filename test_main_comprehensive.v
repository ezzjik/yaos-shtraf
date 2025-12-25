module test_main_comprehensive;

reg clk;
reg rst;
reg [7:0] d;
reg row;
reg [1:0] col;
reg [2:0] action;

wire t_busy, r_busy;
wire [7:0] t_cell, r_cell;

// Разбиваем входы на отдельные биты
wire d0, d1, d2, d3, d4, d5, d6, d7;
assign d0 = d[0];
assign d1 = d[1];
assign d2 = d[2];
assign d3 = d[3];
assign d4 = d[4];
assign d5 = d[5];
assign d6 = d[6];
assign d7 = d[7];

wire col0, col1;
assign col0 = col[0];
assign col1 = col[1];

wire action0, action1, action2;
assign action0 = action[0];
assign action1 = action[1];
assign action2 = action[2];

// Собираем выходы из отдельных бит
wire t_cell0, t_cell1, t_cell2, t_cell3, t_cell4, t_cell5, t_cell6, t_cell7;
assign t_cell = {t_cell7, t_cell6, t_cell5, t_cell4, t_cell3, t_cell2, t_cell1, t_cell0};

wire r_cell0, r_cell1, r_cell2, r_cell3, r_cell4, r_cell5, r_cell6, r_cell7;
assign r_cell = {r_cell7, r_cell6, r_cell5, r_cell4, r_cell3, r_cell2, r_cell1, r_cell0};

main dut(
    .clk(clk),
    .rst(rst),
    .d0(d0), .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5), .d6(d6), .d7(d7),
    .row(row),
    .col0(col0), .col1(col1),
    .action0(action0), .action1(action1), .action2(action2),
    .t_busy(t_busy),
    .r_busy(r_busy),
    .t_cell0(t_cell0), .t_cell1(t_cell1), .t_cell2(t_cell2), .t_cell3(t_cell3),
    .t_cell4(t_cell4), .t_cell5(t_cell5), .t_cell6(t_cell6), .t_cell7(t_cell7),
    .r_cell0(r_cell0), .r_cell1(r_cell1), .r_cell2(r_cell2), .r_cell3(r_cell3),
    .r_cell4(r_cell4), .r_cell5(r_cell5), .r_cell6(r_cell6), .r_cell7(r_cell7)
);

initial begin
    $dumpfile("test_main_comprehensive.vcd");
    $dumpvars(0, test_main_comprehensive);
    
    clk = 0;
    rst = 1;
    d = 8'h00;
    row = 0;
    col = 0;
    action = 0;
    
    // Сброс
    #10 rst = 0;
    #10;
    
    $display("=== Тест 1: Запись в передатчик ===");
    
    // Записываем данные в матрицу передатчика
    d = 8'h11; row = 0; col = 0; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h22; row = 0; col = 1; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h33; row = 0; col = 2; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h44; row = 0; col = 3; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h55; row = 1; col = 0; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h66; row = 1; col = 1; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h77; row = 1; col = 2; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    d = 8'h88; row = 1; col = 3; action = 1;
    @(posedge clk); #1 action = 0;
    #10;
    
    $display("Проверка чтения из передатчика...");
    row = 0; col = 0; #10;
    if (t_cell !== 8'h11) $display("Ошибка: t_cell[0,0] должен быть 0x11, получен 0x%h", t_cell);
    row = 1; col = 3; #10;
    if (t_cell !== 8'h88) $display("Ошибка: t_cell[1,3] должен быть 0x88, получен 0x%h", t_cell);
    
    $display("=== Тест 2: Передача одной ячейки (action=2) ===");
    row = 0; col = 1; action = 2;
    @(posedge clk); #1 action = 0;
    
    // Ждем завершения передачи
    wait(t_busy == 0);
    #100;
    
    $display("=== Тест 3: Передача строки (action=3) ===");
    row = 0; action = 3;
    @(posedge clk); #1 action = 0;
    
    // Ждем завершения передачи
    wait(t_busy == 0);
    #100;
    
    $display("=== Тест 4: Передача столбца (action=4) ===");
    col = 2; action = 4;
    @(posedge clk); #1 action = 0;
    
    // Ждем завершения передачи
    wait(t_busy == 0);
    #100;
    
    $display("=== Тест 5: Передача всей матрицы (action=5) ===");
    action = 5;
    @(posedge clk); #1 action = 0;
    
    // Ждем завершения передачи
    wait(t_busy == 0);
    #100;
    
    $display("=== Все тесты завершены ===");
    $finish;
end

always #5 clk = ~clk;

endmodule
