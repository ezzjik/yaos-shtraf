module main(clk, rst, d0, d1, d2, d3, d4, d5, d6, d7, row, col0, col1, action0, action1, action2, t_busy, r_busy, t_cell0, t_cell1, t_cell2, t_cell3, t_cell4, t_cell5, t_cell6, t_cell7, r_cell0, r_cell1, r_cell2, r_cell3, r_cell4, r_cell5, r_cell6, r_cell7);

input clk;
input rst;
input d0, d1, d2, d3, d4, d5, d6, d7;
input row;
input col0, col1;
input action0, action1, action2;
output t_busy, r_busy;
output t_cell0, t_cell1, t_cell2, t_cell3, t_cell4, t_cell5, t_cell6, t_cell7;
output r_cell0, r_cell1, r_cell2, r_cell3, r_cell4, r_cell5, r_cell6, r_cell7;

wire tx_wire;

transmitter tx_inst(
    clk,
    rst,
    d0, d1, d2, d3, d4, d5, d6, d7,
    row,
    col0, col1,
    action0, action1, action2,
    tx_wire,
    t_busy,
    t_cell0, t_cell1, t_cell2, t_cell3, t_cell4, t_cell5, t_cell6, t_cell7
);

receiver rx_inst(
    clk,
    rst,
    row,
    col0, col1,
    action0, action1, action2,
    tx_wire,
    r_busy,
    r_cell0, r_cell1, r_cell2, r_cell3, r_cell4, r_cell5, r_cell6, r_cell7
);

endmodule
