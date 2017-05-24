use Test::More;
use Verilog::VCD::Writer::Signal;
my $writer=Verilog::VCD::Writer::Signal->new(name=>'a');
my $writer1=Verilog::VCD::Writer::Signal->new(name=>'b',symbol=>'X');
my $writer2=Verilog::VCD::Writer::Signal->new(name=>'c');
isa_ok($writer, "Verilog::VCD::Writer::Signal");
isa_ok($writer1, "Verilog::VCD::Writer::Signal");
isa_ok($writer2, "Verilog::VCD::Writer::Signal");

is($writer->symbol,'!',"Got !");
is($writer1->symbol,'X',"Got X");
is($writer2->symbol,'"',"Got \"");
done_testing;
