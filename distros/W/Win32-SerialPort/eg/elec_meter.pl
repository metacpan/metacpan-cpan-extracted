#!/usr/bin/perl
#---------------------------------------------------------------------------
#  Title:
#      Cross-Platform Demo - "uses" right module on either Win32 or linux
#  Usage:
#      perl elec_meter.pl PORT
#  if PORT eq 'TEST' uses Test::Device:SerialPort emulator
#---------------------------------------------------------------------------

# must be LF-only line ends to run on all platforms

use lib './lib','../lib';	# can run before final install

use strict;
use warnings;
use Data::Dumper;

our $OS_win;
our $ob;
our $port;

BEGIN {
	die "\nUsage: perl elec_meter.pl PORT\n" unless (@ARGV);
	$port = shift @ARGV;
	my $eval_module;
	my $module_version;

        $OS_win = ($^O eq "MSWin32" || $^O eq "cygwin") ? 1 : 0;

        print "Perl version: $]\n";
        print "OS   version: $^O\n";

            # This must be in a BEGIN in order for the 'use' to be conditional
        if ($port eq 'TEST') {
        	print "Loading Emulator module\n";
        	$eval_module = "Test::Device::SerialPort";
		$module_version = 0.04;
        }
        elsif ($OS_win) {
        	print "Loading Windows module\n";
        	$eval_module = "Win32::SerialPort";
		$module_version = 0.21;
        }
        else {
            print "Loading Unix module\n";
            $eval_module = "Device::SerialPort";
	    $module_version = 1.04;
        }
        my $eval_str = "use $eval_module qw( :STAT $module_version ); \$ob = $eval_module->new('$port');";
	warn $eval_str . "\n";
	eval $eval_str;
	die "$@\n" if ($@);
	die "Can't open serial port $port: $^E\n" unless ($ob);
} # End BEGIN

$ob->user_msg(1); # misc. warnings
## $ob->error_msg(1); # hardware and data errors

$ob->baudrate(1200) || die "fail setting baud";
$ob->parity("even") || die "fail setting parity";
$ob->parity_enable(1);
$ob->databits(7) || die "fail setting databits";
$ob->stopbits(1) || die "fail setting stopbits";
$ob->handshake("none") || die "fail setting handshake";

$ob->write_settings || die "no settings";

$ob->are_match("\cM\cC");	# end string = CR ETX

if ($port eq 'TEST') {
	# emulate meter output
	$ob->set_test_mode_active(1);
	my $data = "PAPP 00400 %\cM\cJ";	# start partway thru pattern
	$data .= "MOTDETAT 000000 B\cM\cC\cB\cJ";
	$data .= "ADCO 012345678901 E\cM\cJ";
	$data .= "OPTARIF BASE 0\cM\cJ";
	$data .= "ISOUSC 30 9\cM\cJ";
	$data .= "BASE 024576277 3\cM\cJ";
	$data .= "PTEC TH.. \$\cM\cJ";
	$data .= "IINST 002 Y\cM\cJ";
	$data .= "IMAX 026 G\cM\cJ";
	$data .= $data;
	$data .= $data;		# total of 4 sets of pattern
	$ob->lookclear($data);		# preset buffers
} else {
	# really read from the meter
	$ob->lookclear;		# empty buffers
}
my $gotit = "";
my $match1 = "";
until ("" ne $gotit) {
	if ($OS_win) {
		# *ix handles errors differently
		my @stat = $ob->status;
		if ($stat[ST_ERROR]) {
			$ob->reset_error;
		}
	}
	$gotit = $ob->streamline;	# poll until data ready
	last if ($gotit);
	$match1 = $ob->matchclear;	# match is first thing received
	last if ($match1);
	sleep 1;
}

# so to get here, we have seen an ETX aned synced up
# but we don't know how much of a transmission was caught
# so we discard it and start new_but_sync'd

$gotit = "";
until ("" ne $gotit) {
	# I doubt if we need the status check here, but it does no harm
	# reset_error only needed on Windows
	if ($OS_win) {
		my @stat = $ob->status;
		if ($stat[ST_ERROR]) {
			$ob->reset_error;
		}
	}
	$gotit = $ob->streamline;	# poll until next ETX
}

# so let's see what we actually got

$gotit =~ s/\cB\cJ//g;	# remove STX LF from start

my @readings = split ("\cM\cJ", $gotit);
push @readings, 'BAD_ONE 00610 (';	# added for test, WCB
## warn Dumper \@readings;

my %results;

foreach my $r (@readings) {
	my $sum = 0;
	my $csum = chop $r; # remove and save checksum
	chop $r; # remove space before checksum
	my @char = unpack ('C*', $r);
	foreach my $c (@char) {
		$sum += $c;
	}
	# print "$r\n@char\n";
	my $sum2 = $sum & 0x3f;
	$sum2 += 0x20;
	my $csum2 = chr($sum2);
	# printf "sum=%x, sum2=%x, %s..%s\n", $sum, $sum2, $csum2, $csum;
	my ($item, $value) = split (' ', $r);
	if ($csum eq $csum2) {
		$results{$item} = $value;
	} else {
		$results{$item} = 'invalid';
	}
}
warn Dumper \%results;

$ob->close || die "\nclose problem with $port\n";
undef $ob;
