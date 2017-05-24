use Test::More;
use Test::Output;
use Test::File::Contents;
use Verilog::VCD::Writer;
use DateTime;
use Path::Tiny qw( path );
$|=1;
 

 my $dt = DateTime->new(
     year      => 2000,
     month     => 5,
     day       => 10,
     hour      => 15,
     minute    => 15,
     time_zone => 'America/Los_Angeles',
 );

my $expectedVCD1=<<'VCD';
$date
2000-05-10T15:15:00
$end
$version
VCD
my $expectedVCD2="   Perl VCD Writer Version ".$Verilog::VCD::Writer::VERSION."\n";
my $expectedVCD3=<<'VCD';
$end
$comment
   Author:Vijayvithal
$end
$timescale 1ps $end
$scope module Utop $end
$var  wire 1 ! TX  $end
$var  wire 4 " RX [3:0] $end
$var  wire 3 # c [3:1] $end
$upscope $end
$scope module UDUT $end
$var  wire 4 " b [0:3] $end
$var  wire 1 ! a  $end
$var  wire 1 $ cat  $end
$upscope $end
$enddefinitions $end
$dumpvars

#0
0!
b0 "
b0 #
#5
1!
b0 "
0$
VCD

my $expectedVCD= $expectedVCD1.  $expectedVCD2.  $expectedVCD3;

sub wr{
	my $writer=shift;
	my $m1=$writer->addModule("Utop");
	my $m2=$writer->addModule("UDUT");
	my $TX=$m1->addSignal("TX");
	my $RX=$m1->addSignal("RX",3,0);
	my $s3=$m1->addSignal("c",3,1);
	my $s4=$m2->dupSignal($RX,"b",0,3);
	my $s5=$m2->dupSignal($TX,"a");
	my $s6=$m2->addSignal("cat");
	$writer->writeHeaders();
	$writer->setTime(0);
	$writer->addValue($TX,0);
	$writer->addValue($RX,0);
	$writer->addValue($s3,0);
	$writer->setTime(5);
	$writer->addValue($TX,1);
	$writer->addValue($RX,0);
	$writer->addValue($s6,0);
	ok($TX);
	ok($RX);
	ok($s3);
}

sub readFile{
	my $file=shift;
	open(my $fh,"<$file") or die "unable to openfile $file";
	local $/=undef;
	my $data=<$fh>;
	return $data;
}

print "start Testing\n";

my $writer=Verilog::VCD::Writer->new(date=>$dt,vcdfile=>'test.vcd');
$writer->addComment("Author:Vijayvithal");
isa_ok($writer, "Verilog::VCD::Writer");
print "Testing Print to STDOUT\n";
wr($writer);
#stdout_is(sub{wr($writer)},$expectedVCD,"VCD Output Matches");
$writer->flush;
sleep 1;

#file_contents_eq_or_diff('test.vcd', 't/out1.vcd',"VCD Output Matches");
my $data = path('test.vcd')->slurp;
is($data,$expectedVCD,"OKOK");

done_testing;
