#!/usr/bin/perl
#
#  this program demonstrates that 

use strict;

use threads::tbb;

sub run_prog {
	my $range = shift;
	my $array = shift;
	for my $x ( $range->begin .. ($range->end-1) ) {
		my $cmd = "sh -c 'exit $x'";
		print STDERR "thread $threads::tbb::worker running $cmd\n";
		my $rc = system($cmd);
		$array->STORE($x, $rc>>8);
	}
}

unless ( $threads::tbb::worker ) {
	my $tbb = threads::tbb->new( requires => [$0], threads => 2 );
	tie my @array, "threads::tbb::concurrent::array";
	my $body = $tbb->for_int_array_func( tied(@array), 'run_prog' );
	my $range = threads::tbb::blocked_int->new(0, 255, 5);
	$body->parallel_for($range);

	my $errors;
	for my $x ( 0..254 ) {
		if ( $array[$x] != $x ) {
			print STDERR "array[$x] == ".$array[$x]."\n";
			$errors++;
		}
	}
	print "There were ".($errors?"$errors error(s)" : "no errors")
		." with threads getting their waitpid results\n";
}
