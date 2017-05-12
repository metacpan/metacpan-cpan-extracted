#!/usr/bin/perl

# Run like this:
#	YAZ_LOG=irspy,irspy_test IRSPY_SAVE_XML=1 perl -I../lib irspy.pl -t Quick localhost:8018/IR-Explain---1 Z39.50:amicus.oszk.hu:1616/ANY
#	YAZ_LOG=irspy,irspy_test sudo ./setrlimit -n 3000 -u mike -- perl -I../lib irspy.pl -t Main -a localhost:8018/IR-Explain---1
#	YAZ_LOG=irspy,irspy_test perl -I../lib irspy.pl -t Main -a -n 100 localhost:8018/IR-Explain---1
#
# Available log-levels are as follows:
#	irspy -- high-level application logging
#	irspy_debug -- low-level debugging (not very interesting)
#	irspy_event -- invocations of ZOOM_event() and individual events
#	irspy_unhandled -- unhandled events (not very interesting)
#	irspy_test -- adding, queueing and running tests
#	irspy_task -- adding, queueing and running tasks

# I have no idea why this directory is not in Ubuntu's default Perl
# path, but we need it because just occasionally overload.pm:88
# requires Scalar::Util, which is in this directory.
#use lib '/usr/share/perl/5.8.7';

use Scalar::Util;
use Getopt::Std;
use ZOOM::IRSpy::Web;
use Carp;

use strict;
use warnings;

$SIG{__DIE__} = sub {
    my($msg) = @_;
    confess($msg);
};

my %opts;
if (!getopts('dwt:af:n:m:M:', \%opts) || @ARGV < 1) {
    print STDERR "\
Usage $0: [options] <IRSpy-database> [<target> ...]
	-d		debug
	-w		Use ZOOM::IRSpy::Web subclass
	-t <test>	Run the specified <test> [default: all tests]
	-a		Test all targets (slow!)
	-f <query>	Test targets found by the specified query
	-n <number>	Number of connection to keep in active set
	-m <n>,<i>	Only test targets whose hash mod <n> is <i>
	-M max_depth 	maximum number of nested template calls and variables/params
";
    exit 1;
}

my($dbname, @targets) = @ARGV;
my $class = "ZOOM::IRSpy";
$class .= "::Web" if $opts{w};

if ($opts{M} && $opts{M} > 0) {
    no warnings;
    $ZOOM::IRSpy::xslt_max_depth = $opts{M};
}
if ($opts{d}) { 
    no warnings;
    $ZOOM::IRSpy::debug = $opts{d};
}

my $spy = $class->new($dbname, "admin", "fruitbat", $opts{n});
if (@targets) {
    $spy->targets(@targets);
} elsif ($opts{f}) {
    $spy->find_targets($opts{f});
} elsif (!$opts{a}) {
    print STDERR "$0: specify -a, -f <query> or list of targets\n";
    exit 2;
}

if (defined $opts{m}) {
    my($n, $i) = ($opts{m} =~ /^(\d+),(\d+)$/);
    if (!defined $n) {
	print STDERR "$0: argument to -m must be of the form <n>,<i>\n";
	exit 3;
    }
    $spy->restrict_modulo($n, $i);
}

$spy->initialise($opts{t});
my $res = $spy->check();
if ($res == 0) {
    print "All tests were attempted\n";
} else {
    print "$res tests were skipped\n";
}


# Fake the HTML::Mason class that ZOOM::IRSpy::Web uses
package HTML::Mason::Commands;
BEGIN { our $m = bless {}, "HTML::Mason::Commands" }
sub flush_buffer { print shift(), " flushing\n" if 0 }
