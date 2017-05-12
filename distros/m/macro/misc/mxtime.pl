#!perl -w
# Macro Compiling Timer
# mxtime.pl example/simple.pl

use strict;
use Benchmark ();

exit unless @ARGV;

$ENV{PERL_MACRO_DEBUG} = 1
	unless defined $ENV{PERL_MACRO_DEBUG};

my $start = Benchmark->new();


require macro;
require macro::filter;
require macro::compiler;
require B::Deparse;
require PPI;

my $initialized = Benchmark->new();

do $ARGV[0];

my $end = Benchmark->new();

print "$ARGV[0]:\n",
	'# Loading:    ', ($initialized->timediff($start)->timestr), "\n",
	'# Processing: ', ($end->timediff($initialized)->timestr), "\n",
	'# Total:      ', ($end->timediff($start)->timestr), "\n";

