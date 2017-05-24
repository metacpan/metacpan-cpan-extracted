use Test::More;
use Test::Output;
use Capture::Tiny qw(capture_stdout);
use Verilog::VCD::Writer::Module;
my $m=Verilog::VCD::Writer::Module->new(name=>"top",type=>"module");
	isa_ok($m, "Verilog::VCD::Writer::Module");
	my $s1=$m->addSignal("a");
	my $s2=$m->addSignal("b",3,0);
	my $s3=$m->addSignal("c",3,1);
		isa_ok($s1, "Verilog::VCD::Writer::Signal");
		isa_ok($s2, "Verilog::VCD::Writer::Signal");
		isa_ok($s3, "Verilog::VCD::Writer::Signal");
		my $m2=$m->addSubModule(name=>"DUT",type=>"module");
isa_ok($m2, "Verilog::VCD::Writer::Module");
		my $m3=$m2->addSubModule(name=>"DUTTER",type=>"module");
		my $s4=$m2->dupSignal($s2,"b",0,3);
		my $s5=$m2->dupSignal($s1,"a");
		my $s6=$m2->addSignal("cat");
		my $s7=$m3->addSignal("cat");
		isa_ok($s6, "Verilog::VCD::Writer::Signal");
	#diag explain $m->printScope;
	#	diag explain $m2;
#diag explain $s2;
my $expectedScope=<<'EOD';
$scope module top $end
$var  wire 1 ! a  $end
$var  wire 4 " b [3:0] $end
$var  wire 3 # c [3:1] $end
$scope DUT name $end
$var  wire 4 " b [0:3] $end
$var  wire 1 ! a  $end
$var  wire 1 $ cat  $end
$scope DUTTER name $end
$var  wire 1 % cat  $end
$upscope $end
$upscope $end
$upscope $end
EOD
open my $fh,'>-' or die;
 $|=1;
 my $out=capture_stdout(sub{$m->printScope($fh)});
is($out,$expectedScope,"Scope Matches");

done_testing;
