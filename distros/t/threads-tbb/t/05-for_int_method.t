#!/usr/bin/perl
#
#  test parallelisation with arbitrary associated data
#

use Test::More no_plan;
use strict;
use lib "t";
use MethodCB;
use Devel::Peek;
BEGIN { use_ok("threads::tbb") };

my $tbb = threads::tbb->new(
	threads => 4,
	modules => [ "MethodCB" ],
);

my $range = threads::tbb::blocked_int->new(0, 10, 3);
is($range->end, 10, "Made a blocked range");

my $object = Datum->new( x => 17 );
if ( Datum::DEBUG ) {
	diag("object is: $object");
	Dump($object);
}
my $body = $tbb->for_int_method( $object, "callback" );

isa_ok($body, "threads::tbb::for_int_method", "new for_int_method");

$body->parallel_for($range);
pass("for_int_method: parallel_for didn't crash");

is($object->end, 4, "expected number of tasks ran");

my %saw_worker;
my @seen = (0..9);
for ( my $i = 0; $i < $object->end; $i++ ) {
	my ($begin, $end, $worker, $x) = eval{ @{ $object->fetch($i) }};
	diag($@) if $@;
	ok($x && !$@, "slot $i OK");
	delete @seen[$begin..$end-1];
	$saw_worker{$worker}++;
}

is( scalar keys %saw_worker, 4, "every worker ran" );
