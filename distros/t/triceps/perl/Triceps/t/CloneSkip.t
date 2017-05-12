#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Test that all the Triceps classes get skipped in thread cloning.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl App.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;
use strict;
use threads;

use Test;
BEGIN { plan tests => 92 };
use Triceps;
ok(5); # If we made it this far, we're ok.

#########################

my $a1 = Triceps::App::make("a1");
ok(ref $a1, "Triceps::App");

my $to1 = Triceps::TrieadOwner->new(undef, undef, $a1, "t1", "");
ok(ref $to1, "Triceps::TrieadOwner");

my $tri1 = $to1->get();
ok(ref $tri1, "Triceps::Triead");

my $drain = Triceps::AutoDrain::makeSharedNoWait($a1);
ok(ref $drain, "Triceps::AutoDrain");

my $u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

my $uts1 = Triceps::UnitTracerStringName->new();
ok(ref $uts1, "Triceps::UnitTracerStringName");

my $utp1 = Triceps::UnitTracerPerl->new(sub {1;});
ok(ref $utp1, "Triceps::UnitTracerPerl");

my @def1 = (
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
my $rt1 = Triceps::RowType->new(
	@def1
);
ok(ref $rt1, "Triceps::RowType");

my $tested_context = 0;
my $agt1 = Triceps::AggregatorType->new($rt1, "aggr", undef, sub { 
	# test of the AggregatorContext that will be triggered by inserting a row
	my $context = $_[1];
	@_ = (); # shut up the "Scalars leaked" error from threads->create()
	ok(ref $context, "Triceps::AggregatorContext");
	threads->create(sub { 1; })->join() or die "Failed to make a thread";
	ok(ref $context, "Triceps::AggregatorContext");
	$tested_context = 1;
});
ok(ref $agt1, "Triceps::AggregatorType");

my $it1 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt1)
	);
ok(ref $it1, "Triceps::IndexType");

my $it2 = Triceps::SimpleOrderedIndex->new(
	a => "ASC",
);
ok(ref $it2, "Triceps::SimpleOrderedIndex");

my $tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it1)
	->addSubIndex("reverse", Triceps::IndexType->newFifo(reverse => 1))
	;
ok(ref $tt1, "Triceps::TableType");
ok($tt1->initialize(), 1);

my $t1 = $u1->makeTable($tt1, "t1");
ok(ref $t1, "Triceps::Table");

my $t2 = $u1->makeTable($tt1, "t2"); # for joins
ok(ref $t2, "Triceps::Table");

my $lb1 = $t1->getOutputLabel();
ok(ref $lb1, "Triceps::Label");

my @dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
my $r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

my $rh1 = $t1->makeRowHandle($r1);
ok(ref $rh1, "Triceps::RowHandle");

my $rop1 = $lb1->makeRowop("OP_INSERT", $r1);
ok(ref $rop1, "Triceps::Rowop");

my $tray1 = $u1->makeTray($rop1);
ok(ref $tray1, "Triceps::Tray");

my $m1 = Triceps::FrameMark->new("mark1");
ok(ref $m1, "Triceps::FrameMark");

my $fret1 = Triceps::FnReturn->new(
	name => "fret1",
	unit => $u1,
	labels => [
		one => $lb1,
	]
);
ok(ref $fret1, "Triceps::FnReturn");

my $fbind1 = Triceps::FnBinding->new(
	on => $fret1,
	name => "fbind1",
	unit => $u1,
	labels => [
		one => sub { 1; },
	]
);
ok(ref $fbind1, "Triceps::FnBinding");

my $ab1 = Triceps::AutoFnBind->new(
	$fret1 => $fbind1,
);
ok(ref $ab1, "Triceps::AutoFnBind");

my $fa1 = $to1->makeNexus(
	name => "nx1",
	labels => [
		one => $rt1,
	],
	import => "writer",
);
ok(ref $fa1, "Triceps::Facet");

my $nx1 = $fa1->nexus();
ok(ref $nx1, "Triceps::Nexus");

# XXX add AutoDrain

my $collapse = Triceps::Collapse->new(
	unit => $u1,
	name => "collapse",
	data => [
		name => "idata",
		rowType => $rt1,
		key => [ "b" ],
	],
);
ok(ref $collapse, "Triceps::Collapse");

my $jointwo = Triceps::JoinTwo->new(
	name => "jointwo",
	leftTable => $t1,
	rightTable => $t2,
	leftIdxPath => ["grouping"],
	rightIdxPath => ["grouping"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "inner",
);
ok(ref $jointwo, "Triceps::JoinTwo");

my $lookupjoin = Triceps::LookupJoin->new( # will be used in both (2a) and (2b)
	unit => $u1,
	name => "lookupjoin",
	leftRowType => $rt1,
	rightTable => $t1,
	rightIdxPath => ["grouping"],
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	by => [ "b" => "b", "c" => "c" ],
	isLeft => 1,
);
ok(ref $lookupjoin, "Triceps::LookupJoin");

my $tql = Triceps::X::Tql->new(
	name => "tql",
	tables => [
		$t1,
		$t2,
	],
);
ok(ref $tql, "Triceps::X::Tql");

#########################

# create a thread to trigger the cloning
my @tres = threads->create({'context' => 'list'},
	sub { 
		return (
			ref $collapse,
			ref $jointwo,
			ref $lookupjoin,
			ref $it2,
			ref $tql,
		);
	}
)->join();
ok($tres[0], "SCALAR"); # collapse
ok($tres[1], "SCALAR"); # jointwo
ok($tres[2], "SCALAR"); # lookupjoin
ok($tres[3], "SCALAR"); # it2
ok($tres[4], "SCALAR"); # tql

#########################
# the AggregatorContext is a special tricky thing to test

{
	ok($t1->insert($r1), 1);
	ok($tested_context, 1);
}

#########################

# running the XS methods (like same()) triggers the Triceps magic code check
# that is likely to detect the reference count errors as bad magic

ok(ref $a1, "Triceps::App");
ok($a1->same($a1));

ok(ref $to1, "Triceps::TrieadOwner");
ok($a1->same($to1->app()));

ok(ref $tri1, "Triceps::Triead");
ok($tri1->same($tri1));

ok(ref $drain, "Triceps::AutoDrain");
ok($drain->same($drain));

ok(ref $u1, "Triceps::Unit");
ok($u1->same($u1));

ok(ref $uts1, "Triceps::UnitTracerStringName");
ok($uts1->same($uts1));

ok(ref $utp1, "Triceps::UnitTracerPerl");
ok($utp1->same($utp1));

ok(ref $rt1, "Triceps::RowType");
ok($rt1->same($rt1));

ok(ref $it1, "Triceps::IndexType");
ok($it1->same($it1));

ok(ref $it2, "Triceps::SimpleOrderedIndex");

ok(ref $agt1, "Triceps::AggregatorType");
ok($agt1->same($agt1));

ok(ref $tt1, "Triceps::TableType");
ok($tt1->same($tt1));

ok(ref $t1, "Triceps::Table");
ok($t1->same($t1));

ok(ref $lb1, "Triceps::Label");
ok($lb1->same($lb1));

ok(ref $r1, "Triceps::Row");
ok($r1->same($r1));

ok(ref $rh1, "Triceps::RowHandle");
ok($rh1->same($rh1));

ok(ref $rop1, "Triceps::Rowop");
ok($rop1->same($rop1));

ok(ref $tray1, "Triceps::Tray");
ok($tray1->same($tray1));

ok(ref $m1, "Triceps::FrameMark");
ok($m1->same($m1));

ok(ref $fret1, "Triceps::FnReturn");
ok($fret1->same($fret1));

ok(ref $fbind1, "Triceps::FnBinding");
ok($fbind1->same($fbind1));

ok(ref $ab1, "Triceps::AutoFnBind");
ok($ab1->same($ab1));

ok(ref $fa1, "Triceps::Facet");
ok($fa1->same($fa1));

ok(ref $nx1, "Triceps::Nexus");
ok($nx1->same($nx1));

ok(ref $collapse, "Triceps::Collapse");
ok(ref ($collapse->getInputLabel("idata")), "Triceps::Label");

ok(ref $jointwo, "Triceps::JoinTwo");

ok(ref $lookupjoin, "Triceps::LookupJoin");

ok(ref $tql, "Triceps::X::Tql");

