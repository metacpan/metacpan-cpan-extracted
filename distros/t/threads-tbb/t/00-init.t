#!/usr/bin/perl -w

use Test::More no_plan;
BEGIN { use_ok('threads::tbb') };

use Data::Dumper;

use Scalar::Util qw(reftype refaddr);
my $TERMINAL = ( -t STDOUT );
{
	my $tbb = threads::tbb->new(4);
	ok($tbb, "made a perl_tbb_init()");
	isa_ok($tbb, "threads::tbb", "threads::tbb->new");
	diag Dumper $tbb if $TERMINAL;

	$tbb->terminate;
	pass("called terminate");
}

pass("destroyed perl_tbb_init()");
