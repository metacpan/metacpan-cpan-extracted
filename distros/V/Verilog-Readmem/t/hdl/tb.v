module tb;
initial begin: memory
//    reg [47:0] mem [0:100];
//    reg [47:0] mem [0:4095];
//    reg [47:0] mem [0:65_535]; // 16-bit
    reg [47:0] mem [0:16_777_215];  // 24-bit
    integer i;

    `ifdef BIN
        $display("BIN");
        $readmemb("in.dat", mem);
    `else
        $display("HEX");
        $readmemh("in.dat", mem);
    `endif

    for (i=0; i<12; i=i+1) begin
        $display("ADDRdec=%0d, DATAhex=%0h, DATAdec=%0d", i, mem[i], mem[i]);
    end
    $finish;
end
endmodule
