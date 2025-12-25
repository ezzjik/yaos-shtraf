module test_minimal_fsm;

reg clk;
reg rst;
reg d0, d1, d2, d3, d4, d5, d6, d7;
reg row;
reg col0, col1;
reg action0, action1, action2;
wire tx;
wire busy;
wire cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

transmitter_fsm dut(
    .clk(clk),
    .rst(rst),
    .d0(d0), .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5), .d6(d6), .d7(d7),
    .row(row),
    .col0(col0), .col1(col1),
    .action0(action0), .action1(action1), .action2(action2),
    .tx(tx),
    .busy(busy),
    .cell0(cell0), .cell1(cell1), .cell2(cell2), .cell3(cell3),
    .cell4(cell4), .cell5(cell5), .cell6(cell6), .cell7(cell7)
);

initial begin
    $dumpfile("test_minimal_fsm.vcd");
    $dumpvars(0, test_minimal_fsm);
    
    clk = 0;
    rst = 1;
    d0 = 0; d1 = 0; d2 = 0; d3 = 0; d4 = 0; d5 = 0; d6 = 0; d7 = 0;
    row = 0;
    col0 = 0; col1 = 0;
    action0 = 0; action1 = 0; action2 = 0;
    
    #10 rst = 0;
    #10;
    
    // Тест 1: Запись в матрицу (action=1)
    $display("Test 1: Write to matrix");
    d0 = 1; d1 = 0; d2 = 1; d3 = 0; d4 = 1; d5 = 0; d6 = 1; d7 = 0; // 0xAA
    row = 0;
    col0 = 0; col1 = 0;
    action0 = 1; action1 = 0; action2 = 0; // action=1
    @(posedge clk);
    #1 action0 = 0; action1 = 0; action2 = 0;
    
    #100;
    
    // Тест 2: Передача одной ячейки (action=2)
    $display("Test 2: Transmit single cell");
    action0 = 0; action1 = 1; action2 = 0; // action=2
    @(posedge clk);
    #1 action0 = 0; action1 = 0; action2 = 0;
    
    // Ждем завершения передачи
    wait(busy == 0);
    $display("Transmission complete");
    
    #100;
    
    $display("All minimal tests passed");
    $finish;
end

always #5 clk = ~clk;

endmodule
