#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A basic test of performance. By default it's configured to run fast
# at the cost of precision. To increase the precision increase the number
# of iterations by setting the environment variable:
#  TRICEPS_PERF_COUNT=100000 perl t/Perf.t

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 2 };
use Triceps;
use strict;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################


our $pcount = $ENV{TRICEPS_PERF_COUNT}? $ENV{TRICEPS_PERF_COUNT}+0 : 1000; # the default for the fast run
our($start, $end, $df, $loopdf, $i);

print "Performance test, $pcount iterations, real time.\n";

my @def1 = (
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
my $rt1 = Triceps::RowType->new( # used later
	@def1
);
my $u1 = Triceps::Unit->new("u1");
my $lbDummy = $u1->makeDummyLabel($rt1, "lbDummy");
my $lbDummy2 = $u1->makeDummyLabel($rt1, "lbDummy2");
$lbDummy2->chain($lbDummy);
my $lbPerl = $u1->makeLabel($rt1, "lbPerl", undef, sub { });

my $row1 = $rt1->makeRowArray(
	"uint8",
	1,
	3e15+0,
	3.14,
	"string",
);
my $ropDummy = $lbDummy->makeRowop("OP_INSERT", $row1);
my $ropDummy2 = $lbDummy2->makeRowop("OP_INSERT", $row1);
my $ropPerl = $lbPerl->makeRowop("OP_INSERT", $row1);

my $ttSingleHashed = Triceps::TableType->new($rt1)
	->addSubIndex("primary",
		Triceps::IndexType->newHashed(key => ["b"])
	);
;
$ttSingleHashed->initialize();
my $tSingleHashed = $u1->makeTable($ttSingleHashed, "tSingleHashed");
my $rhSingleHashed = $tSingleHashed->makeRowHandle($row1);
my $ropSingleHashed = $tSingleHashed->getInputLabel()->makeRowop("OP_INSERT", $row1);

my $ljSingleHashed = Triceps::LookupJoin->new(
	unit => $u1,
	name => "ljSingleHashed",
	leftRowType => $rt1,
	rightTable => $tSingleHashed,
	rightIdxPath => ["primary"],
	rightFields => [ "e/ee" ],
	by => [ "b" => "b" ],
	isLeft => 1,
);

my $ttDoubleHashed = Triceps::TableType->new($rt1)
	->addSubIndex("primary",
		Triceps::IndexType->newHashed(key => ["b"])
	)
	->addSubIndex("secondary",
		Triceps::IndexType->newHashed(key => ["b"])
	);
;
$ttDoubleHashed->initialize();
my $tDoubleHashed = $u1->makeTable($ttDoubleHashed, "tDoubleHashed");
my $rhDoubleHashed = $tDoubleHashed->makeRowHandle($row1);
my $ropDoubleHashed = $tDoubleHashed->getInputLabel()->makeRowop("OP_INSERT", $row1);

my $ttSingleSorted = Triceps::TableType->new($rt1)
	->addSubIndex("primary",
		Triceps::IndexType->newPerlSorted("basic", undef, sub {
			return ($_[0]->get("b") <=> $_[1]->get("b"));
		})
	);
;
$ttSingleSorted->initialize();
my $tSingleSorted = $u1->makeTable($ttSingleSorted, "tSingleSorted");
my $rhSingleSorted = $tSingleSorted->makeRowHandle($row1);
my $ropSingleSorted = $tSingleSorted->getInputLabel()->makeRowop("OP_INSERT", $row1);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { }
$end = &Triceps::now();
$df = $end - $start;
$loopdf = $df; # the loop overhead

printf("Empty Perl loop %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

sub emptyFunc { }

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	&emptyFunc(
		"uint8",
		1,
		3e15+0,
		3.14,
		"string",
	);
}
$end = &Triceps::now();
$df = $end - $start;
$loopdf = $df; # the loop overhead

printf("Empty Perl function of 5 args %f s, %.02f per second.\n", $df, $pcount/$df);

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	&emptyFunc(
		a => "uint8",
		b => 1,
		c => 3e15+0,
		d => 3.14,
		e => "string",
	);
}
$end = &Triceps::now();
$df = $end - $start;
$loopdf = $df; # the loop overhead

printf("Empty Perl function of 10 args %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$rt1->makeRowArray(
		"uint8",
		$i,
		3e15+0,
		3.14,
		"string",
	);
}
$end = &Triceps::now();
$df = $end - $start;
my $mkarraydf = $df;

printf("Row creation from array and destruction %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$rt1->makeRowHash(
		a => "uint8",
		b => $i,
		c => 3e15+0,
		d => 3.14,
		e => "string",
	);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Row creation from hash and destruction %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$lbDummy->makeRowop("OP_INSERT", $row1);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Rowop creation and destruction %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$u1->call($ropDummy);
}
$end = &Triceps::now();
$df = $end - $start;
my $dummydf = $df;

printf("Calling a dummy label %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$u1->call($ropDummy2);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Calling a chained dummy label %f s, %.02f per second.\n", $df, $pcount/$df);

$df -= $dummydf;
printf("  Pure chained call %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$u1->call($ropPerl);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Calling a Perl label %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tSingleHashed->makeRowHandle($row1);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Row handle creation and destruction %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tSingleHashed->insert($row1);
}
$end = &Triceps::now();
$df = $end - $start;
my $hasheddf = $df;

printf("Repeated table insert (single hashed idx, direct) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tSingleHashed->insert($tSingleHashed->makeRowHandle($row1));
}
$end = &Triceps::now();
$df = $end - $start;

printf("Repeated table insert (single hashed idx, direct & Perl construct) %f s, %.02f per second.\n", $df, $pcount/$df);

$df -= $hasheddf;
printf("  RowHandle creation overhead in Perl %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tSingleSorted->insert($row1);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Repeated table insert (single sorted idx, direct) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$u1->call($ropSingleHashed);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Repeated table insert (single hashed idx, call) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tSingleHashed->insert(
		$rt1->makeRowArray(
			"uint8",
			$i,
			3e15+0,
			3.14,
			"string",
		)
	);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Table insert makeRowArray (single hashed idx, direct) %f s, %.02f per second.\n", $df, $pcount/$df);

$df -= $mkarraydf;
	printf("  Excluding makeRowArray %f s, %.02f per second.\n", $df, $pcount/$df);
my $insertsingledf = $df;

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tDoubleHashed->insert(
		$rt1->makeRowArray(
			"uint8",
			$i,
			3e15+0,
			3.14,
			"string",
		)
	);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Table insert makeRowArray (double hashed idx, direct) %f s, %.02f per second.\n", $df, $pcount/$df);

$df -= $mkarraydf;
	printf("  Excluding makeRowArray %f s, %.02f per second.\n", $df, $pcount/$df);

$df -= $insertsingledf;
	printf("  Overhead of second index %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

$start = &Triceps::now();
for ($i = 0; $i < $pcount; $i++) { 
	$tSingleSorted->insert(
		$rt1->makeRowArray(
			"uint8",
			$i,
			3e15+0,
			3.14,
			"string",
		)
	);
}
$end = &Triceps::now();
$df = $end - $start;

printf("Table insert makeRowArray (single sorted idx, direct) %f s, %.02f per second.\n", $df, $pcount/$df);

$df -= $mkarraydf;
	printf("  Excluding makeRowArray %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

{
	my $rh = $tSingleHashed->makeRowHandle(
			$rt1->makeRowArray(
				"uint8",
				$pcount/2,
				3e15+0,
				3.14,
				"string",
			)
		);
	$start = &Triceps::now();
	for ($i = 0; $i < $pcount; $i++) { 
		$tSingleHashed->find($rh);
	}
	$end = &Triceps::now();
}
$df = $end - $start;

printf("Table lookup (single hashed idx) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

{
	my $rh = $tSingleSorted->makeRowHandle(
			$rt1->makeRowArray(
				"uint8",
				$pcount/2,
				3e15+0,
				3.14,
				"string",
			)
		);
	$start = &Triceps::now();
	for ($i = 0; $i < $pcount; $i++) { 
		$tSingleSorted->find($rh);
	}
	$end = &Triceps::now();
}
$df = $end - $start;

printf("Table lookup (single sorted idx) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

{
	my $rop = $ljSingleHashed->getInputLabel()->makeRowop("OP_INSERT",
			$rt1->makeRowArray(
				"uint8",
				$pcount/2,
				3e15+0,
				3.14,
				"string",
			)
		);
	$start = &Triceps::now();
	for ($i = 0; $i < $pcount; $i++) { 
		$u1->call($rop);
	}
	$end = &Triceps::now();
}
$df = $end - $start;

printf("Lookup join (single hashed idx) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

# this is a bigger one, with multithreading
{
	Triceps::Triead::startHere(
		app => "perfTriead",
		thread => "writer",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("writer main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};

			my $lb = $to->unit()->makeDummyLabel($rt1, "lb");
			my $fa = $to->makeNexus(
				name => "nx",
				labels => [
					lb => $lb,
				],
				# queueLimit => 1,
				import => "writer",
			);

			Triceps::Triead::start(
				app => "perfTriead",
				thread => "reader",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("reader main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};

					my $fa = $to->importNexus(
						from => "writer/nx",
						import => "reader",
					);
					$to->readyReady();
					$to->mainLoop();
				}
			);

			my $unit = $to->unit();
			my $rop = $lb->makeRowop("OP_INSERT", $row1);

			$to->readyReady();

			$start = &Triceps::now();
			for ($i = 0; $i < $pcount; $i++) { 
				$unit->call($rop);
				$to->flushWriters();
			}
			{
				my $ad = Triceps::AutoDrain::makeShared($to);
				$end = &Triceps::now();
				$to->app()->shutdown();
			}
		}
	);
}
$df = $end - $start;
my $onerowdf = $df;

printf("Nexus pass (1 row/flush) %f s, %.02f per second.\n", $df, $pcount/$df);

#########################

# same as last one, only 10 rows at a time
{
	Triceps::Triead::startHere(
		app => "perfTriead",
		thread => "writer",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("writer main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};

			my $lb = $to->unit()->makeDummyLabel($rt1, "lb");
			my $fa = $to->makeNexus(
				name => "nx",
				labels => [
					lb => $lb,
				],
				# queueLimit => 1,
				import => "writer",
			);

			Triceps::Triead::start(
				app => "perfTriead",
				thread => "reader",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("reader main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};

					my $fa = $to->importNexus(
						from => "writer/nx",
						import => "reader",
					);
					$to->readyReady();
					$to->mainLoop();
				}
			);

			my $unit = $to->unit();
			my $rop = $lb->makeRowop("OP_INSERT", $row1);

			$to->readyReady();

			$start = &Triceps::now();
			for ($i = 0; $i < $pcount; $i++) { 
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$unit->call($rop);
				$to->flushWriters();
			}
			{
				my $ad = Triceps::AutoDrain::makeShared($to);
				$end = &Triceps::now();
				$to->app()->shutdown();
			}
		}
	);
}
$df = $end - $start;

printf("Nexus pass (10 rows/flush) %f s, %.02f per row per second.\n", $df, $pcount*10/$df);

my $perrowdf = ($df - $onerowdf)/9.;
printf("  Overhead of each row %f s, %.02f per second.\n", $perrowdf, $pcount/$perrowdf);
my $perflushdf1 = $onerowdf - $perrowdf;
printf("  Overhead of flush %f s, %.02f per second.\n", $perflushdf1, $pcount/$perflushdf1);

#########################

ok(1);
