#!env perl
# The input for this file is a CSV dump from a logic analyzer which records two columns seconds on column 1 and D0-D7 on column 2 where D0 is Rx and D1 is TX
use Verilog::VCD::Writer;
use Math::BaseCalc;
use Text::CSV;
use Data::Printer;
use v5.10;
use strict;
use warnings;
use diagnostics;

# We expect the csv file name on the command line and append a .vcd to it to generate the vcd filename.

 die "Requires csv file name on command line try '%serial.pl serial_sample.csv'" if (scalar @ARGV ==0);

my $writer=Verilog::VCD::Writer->new(timescale=>"1us",vcdfile=>$ARGV[0].".vcd");
my $UART=$writer->addModule("UART");

my $csv=Text::CSV->new({binary=>1}) or die "Cannot use CSV:".Text::CSV->error_diag();

# Open Inputfile

open my $fh, "<:encoding(utf8)",$ARGV[0] or die "$ARGV[0]:$!";

#Skip 2 lines of header.
#
my $row = $csv->getline($fh);
$row = $csv->getline($fh);

#Add Signals and writeout the header.

my $TX=$UART->addSignal("TX");
my $RX=$UART->addSignal("RX");
$writer->writeHeaders();

my$bin=new Math::BaseCalc(digits=>[0,1]);
my $initialTime; #Shift StartTime to 0
while(my $row = $csv->getline($fh)){
	my $time=1000000 * shift @{$row}; #Col 1 is seconds convert of microseconds.
	$initialTime= $time if(not defined $initialTime);
	#p $row;
	my $xxx=shift@{$row};
	next if( $xxx eq "");

	my @d=split //,$bin->to_base($xxx);
	my $rxd= pop @d;
	my $txd= pop @d;
	$txd= 0 if (not defined $txd);
	#say  "RX=$rxd, TX=$txd";
	$writer->setTime($time-$initialTime);
	$writer->addValue($TX,$txd);
	$writer->addValue($RX,$rxd);
}
