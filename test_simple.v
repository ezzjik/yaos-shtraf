module test_simple;

reg clk;
reg rst;
reg d0, d1, d2, d3, d4, d5, d6, d7;
reg row;
reg col0, col1;
reg action0, action1, action2;
wire tx;
wire busy;
wire cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7;

transmitter dut(
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
    $dumpfile("test_simple.vcd");
    $dumpvars(0, test_simple);
    
    clk = 0;
    rst = 1;
    {d7,d6,d5,d4,d3,d2,d1,d0} = 8'h00;
    row = 0;
    col0 = 0; col1 = 0;
    action0 = 0; action1 = 0; action2 = 0;
    
    #10 rst = 0;
    #10;
    
    // Тест 1: Запись в M[0,0] значения 0x12
    $display("Test 1: Write 0x12 to M[0,0]");
    {d7,d6,d5,d4,d3,d2,d1,d0} = 8'h12;
    row = 0;
    col0 = 0; col1 = 0;
    // action = 1 (binary 001)
    action0 = 1; action1 = 0; action2 = 0;
    @(posedge clk);
    #1 action0 = 0; action1 = 0; action2 = 0;
    
    // Проверяем выход cell (должно быть 0x12)
    #10;
    if ({cell7,cell6,cell5,cell4,cell3,cell2,cell1,cell0} !== 8'h12) begin
        $display("ERROR: cell should be 0x12, got 0x%h", {cell7,cell6,cell5,cell4,cell3,cell2,cell1,cell0});
        $finish;
    end
    
    // Тест 2: Передача одной ячейки (action=2)
    $display("Test 2: Start transmission of M[0,0]");
    // action = 2 (binary 010)
    action0 = 0; action1 = 1; action2 = 0;
    @(posedge clk);
    #1 action0 = 0; action1 = 0; action2 = 0;
    
    // Ждем, пока busy не станет 0
    wait(busy == 0);
    #100;
    
    $display("All tests passed!");
    $finish;
end

always #5 clk = ~clk;

endmodule
