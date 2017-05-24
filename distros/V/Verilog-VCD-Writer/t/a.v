`timescale 1ns/1ps
module a (
	input wire x,
	input wire y,
	output wire z);
//$dumpall();
wire zebra;
b because (
	.x(x),
	.y(y),
	.zebra(zebra)
);
b ICan (
	.x(zebra),
	.y(y),
	.zebra(z)
);
endmodule
module b (
	input wire x,
	input wire y,
	output wire zebra);
assign zebra=x^y;
endmodule
module top;
reg x,y;
a ack(
	.x(x),
	.y(y),
	.z(z)
);
initial begin
	$dumpfile("a.vcd");
	$dumpvars(-1, top);
	
	x=0;
	y=0;
	#5;
	x=1;
	y=0;
	#5;
	x=1;
	y=1;
	#5;
	x=0;
	y=1;
	#5;
end
endmodule
