#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Table.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 258 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


######################### preparations (originating from Unit.t)  #############################

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

$u2 = Triceps::Unit->new("u2");
ok(ref $u2, "Triceps::Unit");

@def1 = (
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
$rt1 = Triceps::RowType->new( # used later
	@def1
);
ok(ref $rt1, "Triceps::RowType");

$it1 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
	);
ok(ref $it1, "Triceps::IndexType");

$tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it1)
	->addSubIndex("reverse", Triceps::IndexType->newFifo(reverse => 1))
	;
ok(ref $tt1, "Triceps::TableType");

$it1cp = $tt1->findSubIndex("grouping");
ok(ref $it1cp, "Triceps::IndexType");

$itrev = $tt1->findSubIndex("reverse");
ok(ref $itrev, "Triceps::IndexType");

$res = $tt1->initialize();
ok($res, 1);

$t1 = $u1->makeTable($tt1, "tab1");
ok(ref $t1, "Triceps::Table");

### table 2 with a different type

@def2 = (
	a => "uint8[]",
	b => "int32[]",
	c => "int64[]",
	d => "float64[]",
	e => "string",
);
$rt2 = Triceps::RowType->new( # used later
	@def2
);
ok(ref $rt2, "Triceps::RowType");

$tt2 = Triceps::TableType->new($rt2)
	->addSubIndex("grouping", Triceps::IndexType->newHashed(key => [ "b", "c" ]) ); 
ok(ref $tt2, "Triceps::TableType");

$res = $tt2->initialize();
ok($res, 1);

$t2 = $u1->makeTable($tt2, "tab2");
ok(ref $t2, "Triceps::Table");

########################## basic functions #################################################

# currently there is no way to get 2 different refs to the same table
$res = $t1->same($t1);
ok($res);

$res = $t1->same($t2);
ok(!$res);

$res = $t1->getName();
ok($res, "tab1");

$rtt = $t1->getRowType();
ok(ref $rtt, "Triceps::RowType");
ok($rt1->same($rtt));

$res = $t1->size();
ok($res, 0); # no data in the table yet

# successful getAggregatorLabel() tested in Aggregator.t, here test a bad arg
$res = eval { $t1->getAggregatorLabel("zzz"); };
ok(!defined $res);
ok($@, qr/^Triceps::Table::getAggregatorLabel: aggregator 'zzz' is not defined on table 'tab1' at/);

########################## get label #################################################

$lb = $t1->getInputLabel();
ok(ref $lb, "Triceps::Label");
ok($lb->getName(), "tab1.in");

$lb = $t1->getPreLabel();
ok(ref $lb, "Triceps::Label");
ok($lb->getName(), "tab1.pre");

$lb = $t1->getOutputLabel();
ok(ref $lb, "Triceps::Label");
ok($lb->getName(), "tab1.out");

$res = $t1->getUnit();
ok(ref $res, "Triceps::Unit");

################# getting back and sameness of various objects  ##############################
# sameness tested here because a table is a convenient way to get back another reference to
# existing objects

$tt2 = $t1->getType();
ok($tt1->same($tt2));

# copying of types after initialization
$it3 = $tt1->findSubIndex("grouping");
ok(ref $it3, "Triceps::IndexType");
ok($it3->isInitialized());
$it4 = $it3->copy();
ok(ref $it4, "Triceps::IndexType");
ok(!$it4->isInitialized());

########################## makeRowHandle  #################################################

@dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

@dataset2 = (
	a => "uint8",
	b => [ 123 ],
	c => [ 3e15+0 ],
	d => [ 3.14 ],
	e => "string",
);
$r2 = $rt2->makeRowHash( @dataset2);
ok(ref $r2, "Triceps::Row");

$rh1 = $t1->makeRowHandle($r1);
ok(ref $rh1, "Triceps::RowHandle");
ok(!$rh1->isNull());

$rhn1 = $t1->makeNullRowHandle();
ok(ref $rhn1, "Triceps::RowHandle");
ok($rhn1->isNull());

$rh2 = eval { $t1->makeRowHandle($r2); };
ok(!defined $rh2);
ok($@, qr/^Triceps::Table::makeRowHandle: table and row types are not equal, in table: row \{ uint8 a, int32 b, int64 c, float64 d, string e, \}, in row: row \{ uint8\[\] a, int32\[\] b, int64\[\] c, float64\[\] d, string e, \} at/);

$rh2 = $t2->makeRowHandle($r2);
ok(ref $rh2, "Triceps::RowHandle");

########################## tests of RowHandle  #################################################

# XXX test RowHandle::same() later
$res = $rh1->isInTable();
ok(!$res);

$res = $rh1->getRow();
ok(ref $res, "Triceps::Row");
ok($r1->same($res));

$res = eval { $rhn1->getRow(); };
ok(!defined $res);
ok($@, qr/^Triceps::RowHandle::getRow: RowHandle is NULL at/);

$res = $rhn1->getRowSafe();
ok(!defined $res);

$res = $rhn1->isInTable();
ok($res, 0);

########################## basic ops  #################################################

# insert
$res = $t1->insert($rh1);
ok($res == 1);
$res = $t1->size();
ok($res, 1);
$res = $rh1->isInTable();
ok($res);

# inserting the same row 2nd time returns 0
$res = $t1->insert($rh1);
ok($res == 0);
ok(defined $res);

# insert a Row directly
$res = $t1->insert($r1);
ok($res, 1);
$res = $t1->size();
ok($res, 2); # they get collected in a FIFO

# groupSize
$res  = $t1->groupSizeIdx($it1cp, $rh1);
ok($res, 2);
$res  = $t1->groupSizeIdx($it1cp, $r1);
ok($res, 2);

# basic iteration
$rhit = $t1->begin();
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh1));

$rhit = $t1->next($rhit);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok(!$rhit->same($rh1)); # that one was auto-created
# try as a method of RowHandle
$rhit = $rhit->next();
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());
ok($rhit->same($rhn1));
$rhit = $rhit->next(); # try going beyond the end
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());

# iteration with index, use the reverse for a change
$rhit = $t1->beginIdx($itrev);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok(!$rhit->same($rh1)); # that one was auto-created
$rhit = $t1->nextIdx($itrev, $rhit);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh1));
# try as a method of RowHandle
$rhit = $rhit->nextIdx($itrev);
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());
ok($rhit->same($rhn1));
$rhit = $rhit->nextIdx($itrev); # try going beyond the end
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());

# group search
$rhit = $t1->firstOfGroupIdx($itrev, $rh1);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok(!$rhit->same($rh1)); # that one was auto-created
$rhit = $t1->nextGroupIdx($itrev, $rh1);
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());

# group search as a method of RowHandle
$rhit = $rh1->firstOfGroupIdx($itrev);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok(!$rhit->same($rh1)); # that one was auto-created
$rhit = $rh1->nextGroupIdx($itrev);
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());

# find
$rhit = $t1->find($r1);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh1)); # finds the first watching
$rhit = $t1->find($t1->makeRowHandle($r1));
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh1)); # finds the first watching

# find with index (reverse fifo searches still in the direct order)
$rhit = $t1->findIdx($itrev, $r1);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh1)); # finds the first watching
$rhit = $t1->findIdx($itrev, $t1->makeRowHandle($r1));
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh1)); # finds the first watching

# findBy is better to be done on t2, since it has a direct hash index, see below

# This portion formerly used a Copy Tray which got replaced by the
# FnReturn now. The rest of the FnReturn tests are way below.

$fret2 = $t2->fnReturn();
ok(ref $fret2, "Triceps::FnReturn");
$fbind2 = Triceps::FnBinding->new(
	unit => $u1,
	name => "fbind2",
	on => $fret2,
	withTray => 1,
	labels => [
		out => sub { }, # another way to make a dummy
	],
);
ok(ref $fbind2, "Triceps::FnBinding");

$ctr = $fbind2->swapTray(); # just clears the tray

$fret2->push($fbind2);
$res = $t2->insert($r2);
ok($res == 1);
$fret2->pop($fbind2);

$res = $t2->size();
ok($res, 1);
ok($fbind2->traySize(), 1);
$ctr = $fbind2->swapTray(); # get the updates on an insert
$res = $ctr->size();
ok($res, 1);
@arr = $ctr->toArray();
ok($arr[0]->getOpcode(), &Triceps::OP_INSERT);
ok($r2->same($arr[0]->getRow()));

$fret2->push($fbind2);
$res = $t2->insert($rh2);
ok($res == 1);
$fret2->pop($fbind2);

$res = $t2->size();
ok($res, 1); # old record gets pushed out
$ctr = $fbind2->swapTray(); # get the updates on an insert
ok($ctr->size(), 2); # both delete and insert
@arr = $ctr->toArray();
ok($arr[0]->getOpcode(), &Triceps::OP_DELETE);
ok($r2->same($arr[0]->getRow()));
ok($arr[1]->getOpcode(), &Triceps::OP_INSERT);
ok($r2->same($arr[1]->getRow()));

# findBy
$rhit = $t2->findBy( # just the key fields
	b => [ 123 ],
	c => [ 3e15+0 ],
);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh2)); 

$rhit = $t2->findBy( # just the key fields - an absent row
	b => [ 456 ],
	c => [ 3e15+0 ],
);
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());

ok(!eval { $rhit = $t2->findBy( # invalid fields, making it to fail
	zz => [ 456 ],
	c => [ 3e15+0 ],
); });
ok($@ =~ /^Triceps::RowType::makeRowHash: attempting to set an unknown field 'zz' at .*\n\tTriceps::Table::findBy.*/) or print STDERR "got: $@\n";

# findIdxBy
$it2m = $t2->getType()->findSubIndex("grouping");
ok(ref $it2m, "Triceps::IndexType");

$rhit = $t2->findIdxBy($it2m, # just the key fields
	b => [ 123 ],
	c => [ 3e15+0 ],
);
ok(ref $rhit, "Triceps::RowHandle");
ok(!$rhit->isNull());
ok($rhit->same($rh2)); 

$rhit = $t2->findIdxBy($it2m, # just the key fields - an absent row
	b => [ 456 ],
	c => [ 3e15+0 ],
);
ok(ref $rhit, "Triceps::RowHandle");
ok($rhit->isNull());

ok(!eval { $rhit = $t2->findIdxBy($it2m, # invalid fields, making it to fail
	zz => [ 456 ],
	c => [ 3e15+0 ],
); });
ok($@ =~ /^Triceps::RowType::makeRowHash: attempting to set an unknown field 'zz' at .*\n\tTriceps::Table::findIdxBy.*/) or print STDERR "got: $@\n";

# bad args insert
ok(!eval {
	$res = $t1->insert(0);
});
ok($@ =~ /^Triceps::Table::insert: row argument is not a blessed SV reference to Row or RowHandle at/);

ok(!eval {
	$res = $t1->insert($t2);
});
ok($@ =~ /Triceps::Table::insert: row argument has an incorrect magic for Row or RowHandle/);

ok(!eval {
	$res = $t1->insert($r2);
});
ok($@ =~ /Triceps::Table::insert: table and row types are not equal, in table: row \{ uint8 a, int32 b, int64 c, float64 d, string e, \}, in row: row \{ uint8\[\] a, int32\[\] b, int64\[\] c, float64\[\] d, string e, \}/);

ok(!eval {
	$res = $t1->insert($rh2);
});
ok($@ =~ /Triceps::Table::insert: row argument is a RowHandle in a wrong table tab2/);

# bad args iteration
ok(! eval { $t2->beginIdx($itrev); });
ok($@ =~ /^Triceps::Table::beginIdx: indexType argument does not belong to table's type/);

ok(! eval { $t1->next($rh2); });
ok($@ =~ /^Triceps::Table::next: row argument is a RowHandle in a wrong table tab2/);

ok(! eval { $t1->nextIdx($itrev, $rh2); });
ok($@ =~ /^Triceps::Table::nextIdx: row argument is a RowHandle in a wrong table tab2/);

ok(! eval { $t2->nextIdx($itrev, $rh2); });
ok($@ =~ /^Triceps::Table::nextIdx: indexType argument does not belong to table's type/);

ok(! eval { $t1->firstOfGroupIdx($itrev, $rh2); });
ok($@ =~ /^Triceps::Table::firstOfGroupIdx: row argument is a RowHandle in a wrong table tab2/);

ok(! eval { $t2->firstOfGroupIdx($itrev, $rh2); });
ok($@ =~ /^Triceps::Table::firstOfGroupIdx: indexType argument does not belong to table's type/);

ok(! eval { $t1->nextGroupIdx($itrev, $rh2); });
ok($@ =~ /^Triceps::Table::nextGroupIdx: row argument is a RowHandle in a wrong table tab2/);

ok(! eval { $t2->nextGroupIdx($itrev, $rh2); });
ok($@ =~ /^Triceps::Table::nextGroupIdx: indexType argument does not belong to table's type/);

# bad args find: shares the parse function with index, so just touch-test
ok(! eval { $t1->find($t2); });
ok($@ =~ /^Triceps::Table::find: row argument has an incorrect magic for Row or RowHandle/);

ok(! eval { $t1->findIdx($itrev, $t2); });
ok($@ =~ /^Triceps::Table::findIdx: row argument has an incorrect magic for Row or RowHandle/);

ok(! eval { $t2->findIdx($itrev, $rh2); }); # this one is different from insert()
ok($@ =~ /^Triceps::Table::findIdx: indexType argument does not belong to table's type/);

# bad args iteration and finds directly on RowHandle
ok(! eval { $rh2->nextIdx($itrev); });
ok($@ =~ /^Triceps::RowHandle::nextIdx: indexType argument does not belong to table's type/);

ok(! eval { $rh2->firstOfGroupIdx($itrev); });
ok($@ =~ /^Triceps::RowHandle::firstOfGroupIdx: indexType argument does not belong to table's type/);

ok(! eval { $rh2->nextGroupIdx($itrev); });
ok($@ =~ /^Triceps::RowHandle::nextGroupIdx: indexType argument does not belong to table's type/);

# remove
$res = $t1->remove($rh1);
ok($res, 1);
$res = $t1->size();
ok($res, 1);
$res = $rh1->isInTable();
ok(!$res);

# This portion formerly used a Copy Tray which got replaced by the
# FnReturn now. The rest of the FnReturn tests are way below.

$ctr = $fbind2->swapTray(); # just clears the tray

ok($rh2->isInTable());

$fret2->push($fbind2);
$res = $t2->remove($rh2);
ok($res, 1);
$fret2->pop($fbind2);

ok(!$rh2->isInTable());
$res = $t2->size();
ok($res, 0);
$ctr = $fbind2->swapTray(); # get the updates on a delete
$res = $ctr->size();
ok($res, 1);
@arr = $ctr->toArray();
ok($arr[0]->getOpcode(), &Triceps::OP_DELETE);
ok($r2->same($arr[0]->getRow()));

# attempt to remove a row not in table
$fret2->push($fbind2);
$res = $t2->remove($rh2);
ok($res, 1);
$fret2->pop($fbind2);

ok($fbind2->trayEmpty());

# bad args remove
ok(!eval {
	$res = $t1->remove($rh2);
});
ok($@ =~ /Triceps::Table::remove: row argument is a RowHandle in a wrong table tab2/);

# clear out the table
while ( ! ($rhit = $t1->begin())->isNull() ) {
	#print STDERR "DEBUG begin $rhit size " . $t1->size() . "\n";
	$t1->remove($rhit);
}
# insert back record , before testing of deleteRow
$res = $t1->insert($rh1);
ok($res == 1);
$res = $rh1->isInTable();
ok($res);
$res = $t1->insert($r1);
ok($res == 1);
$res = $t1->size();
ok($res, 2); # they get collected in a FIFO

# test deleteRow
$res = $t1->deleteRow($r1);
ok($res == 1);
$res = $t1->size();
ok($res, 1); 
$res = $rh1->isInTable(); # $rh1 was first in table, so it would be found and deleted first
ok(!$res);

# test deleteRow for non-existing record
$res = $t1->deleteRow($r1);
ok($res == 1);
$res = $t1->size();
ok($res, 0); 
$res = $t1->deleteRow($r1);
ok(defined $res && $res == 0);

# bad args deleteRow
ok(!eval { $res = $t1->deleteRow($r1, 1, 2) });
ok($@ =~ /^Usage: Triceps::Table::deleteRow\(self, wr\) at/) or print STDERR "got: $@\n";

ok(!eval {
	$res = $t1->deleteRow($r2);
});
ok($@ =~ /Triceps::Table::deleteRow: table and row types are not equal, in table: row \{ uint8 a, int32 b, int64 c, float64 d, string e, \}, in row: row \{ uint8\[\] a, int32\[\] b, int64\[\] c, float64\[\] d, string e, \}/);

# table clearing (repeats the logic of C++ test)
{
	my $ttc1 = Triceps::TableType->new($rt1)
		->addSubIndex("fifo", Triceps::IndexType->newFifo())
		;
	ok(ref $ttc1, "Triceps::TableType");
	$ttc1->initialize();
	my $tc1 = $u1->makeTable($ttc1, "tc1");
	ok(ref $tc1, "Triceps::Table");
	
	for (my $i = 0; $i < 10; $i++) {
		my $r = $rt1->makeRowHash(b => $i);
		$tc1->insert($r);
	}

	my $next = 0;
	my $lbc = $u1->makeLabel($rt1, "lbc", undef, sub {
		ok($_[1]->getRow()->get("b"), $next);
		++$next;
	});
	ok(ref $lbc, "Triceps::Label");
	$tc1->getOutputLabel()->chain($lbc);

	$tc1->clear(3);
	ok($next, 3);
	$tc1->clear();
	ok($next, 10);
	$tc1->clear(99);
	ok($next, 10);

	# bad args
	ok(!eval { $tc1->clear(1, 2) });
	ok($@ =~ /^Usage: Triceps::Table::clear\(self \[, limit\]\) at/) or print STDERR "got: $@\n";
	ok(!eval { $tc1->clear(-1) });
	ok($@ =~ /^Triceps::Table::clear: the limit argument must be >=0, got -1/) or print STDERR "got: $@\n";
}

############################## function return #######################################

{
	my $u9 = Triceps::Unit->new("u9");
	ok(ref $u9, "Triceps::Unit");

	my $tt9 = Triceps::TableType->new($rt1)
		->addSubIndex("grouping", $it1)
		->addSubIndex("reverse", Triceps::IndexType->newFifo(reverse => 1))
		;
	ok(ref $tt9, "Triceps::TableType");

	# with an aggregator
	Triceps::SimpleAggregator::make(
		tabType => $tt9,
		name => "myAggr",
		idxPath => [ "grouping" ],
		result => [
			b => "int32", "first", sub {$_[0]->get("b");},
			c => "int64", "first", sub {$_[0]->get("c");},
			d => "float64", "first", sub {$_[0]->get("d");},
		],
	);

	ok($tt9->initialize(), 1);

	my $t9 = $u9->makeTable($tt9, "t9");
	ok(ref $t9, "Triceps::Table");
	my $fret = $t9->fnReturn();
	ok(ref $fret, "Triceps::FnReturn");

	my $buf;
	Triceps::FnBinding::call(
		name => "test",
		on => $fret,
		unit => $u9,
		labels => [
			pre => sub { $buf .= "on pre\n"; },
			out => sub { $buf .= "on out\n"; },
			dump => sub { $buf .= "on dump\n"; },
			myAggr => sub { $buf .= "on myAggr\n"; },
		],
		code => sub {
			$t9->insert($r1);
		},
	);
	ok($buf, "on pre\non out\non myAggr\n");
}

# test the exception handling in FnReturn creation
{
	my $u9 = Triceps::Unit->new("u9");
	ok(ref $u9, "Triceps::Unit");

	my $tt9 = Triceps::TableType->new($rt1)
		->addSubIndex("grouping", $it1)
		->addSubIndex("reverse", Triceps::IndexType->newFifo(reverse => 1))
		;
	ok(ref $tt9, "Triceps::TableType");

	# with an aggregator used to trigger the error
	Triceps::SimpleAggregator::make(
		tabType => $tt9,
		name => "pre",
		idxPath => [ "grouping" ],
		result => [
			b => "int32", "first", sub {$_[0]->get("b");},
			c => "int64", "first", sub {$_[0]->get("c");},
			d => "float64", "first", sub {$_[0]->get("d");},
		],
	);

	ok($tt9->initialize(), 1);

	my $t9 = $u9->makeTable($tt9, "t9");
	ok(ref $t9, "Triceps::Table");

	my $fret = eval { $t9->fnReturn(); };
	ok(!defined $fret);
	#print "$@";
	ok($@ =~ /^Failed to create an FnReturn on table 't9':\n  duplicate row name 'pre' at/);
}

############################## dump ##################################################

{
	my $u9 = Triceps::Unit->new("u9");
	ok(ref $u9, "Triceps::Unit");

	my $tt9 = Triceps::TableType->new($rt1)
		->addSubIndex("bc", Triceps::SimpleOrderedIndex->new("b" => "ASC", "c" => "ASC"))
		->addSubIndex("cb", Triceps::SimpleOrderedIndex->new("c" => "ASC", "b" => "ASC"))
		;
	ok(ref $tt9, "Triceps::TableType");
	ok($tt9->initialize(), 1);

	my $t9 = $u9->makeTable($tt9, "t9");
	ok(ref $t9, "Triceps::Table");
	my $fret = $t9->fnReturn();
	ok(ref $fret, "Triceps::FnReturn");

	my $dlab = $t9->getDumpLabel();
	ok(ref $dlab, "Triceps::Label");

	my($res1, $res2);
	my $lp1 = $u9->makeLabel($rt1, "lp1", undef, sub {
		$res1 .= $_[1]->printP();
		$res1 .= "\n";
	});
	my $lp2 = $u9->makeLabel($rt1, "lp2", undef, sub {
		$res2 .= $_[1]->printP();
		$res2 .= "\n";
	});

	$dlab->chain($lp1);

	$t9->insert($rt1->makeRowHash(b => 1, c => 1, e => "r11"));
	$t9->insert($rt1->makeRowHash(b => 1, c => 2, e => "r12"));
	$t9->insert($rt1->makeRowHash(b => 2, c => 2, e => "r22"));
	$t9->insert($rt1->makeRowHash(b => 2, c => 1, e => "r21"));

	ok(!defined $res1);

	# default order, default opcode
	Triceps::FnBinding::call(
		name => "test",
		on => $fret,
		unit => $u9,
		labels => [
			dump => $lp2,
		],
		code => sub {
			$t9->dumpAll();
		},
	);
	#print "$res1";
	ok($res1,
't9.dump OP_INSERT b="1" c="1" e="r11" 
t9.dump OP_INSERT b="1" c="2" e="r12" 
t9.dump OP_INSERT b="2" c="1" e="r21" 
t9.dump OP_INSERT b="2" c="2" e="r22" 
');
	#print "$res2";
	ok($res2,
'lp2 OP_INSERT b="1" c="1" e="r11" 
lp2 OP_INSERT b="1" c="2" e="r12" 
lp2 OP_INSERT b="2" c="1" e="r21" 
lp2 OP_INSERT b="2" c="2" e="r22" 
');

	# default order, explicit opcode
	undef $res1;
	undef $res2;
	Triceps::FnBinding::call(
		name => "test",
		on => $fret,
		unit => $u9,
		labels => [
			dump => $lp2,
		],
		code => sub {
			$t9->dumpAll("OP_DELETE");
		},
	);
	#print "$res1";
	ok($res1,
't9.dump OP_DELETE b="1" c="1" e="r11" 
t9.dump OP_DELETE b="1" c="2" e="r12" 
t9.dump OP_DELETE b="2" c="1" e="r21" 
t9.dump OP_DELETE b="2" c="2" e="r22" 
');
	#print "$res2";
	ok($res2,
'lp2 OP_DELETE b="1" c="1" e="r11" 
lp2 OP_DELETE b="1" c="2" e="r12" 
lp2 OP_DELETE b="2" c="1" e="r21" 
lp2 OP_DELETE b="2" c="2" e="r22" 
');

	# explicit order, default opcode
	undef $res1;
	undef $res2;
	Triceps::FnBinding::call(
		name => "test",
		on => $fret,
		unit => $u9,
		labels => [
			dump => $lp2,
		],
		code => sub {
			$t9->dumpAllIdx($t9->getType()->findIndexPath("cb"));
		},
	);
	#print "$res1";
	ok($res1,
't9.dump OP_INSERT b="1" c="1" e="r11" 
t9.dump OP_INSERT b="2" c="1" e="r21" 
t9.dump OP_INSERT b="1" c="2" e="r12" 
t9.dump OP_INSERT b="2" c="2" e="r22" 
');
	#print "$res2";
	ok($res2,
'lp2 OP_INSERT b="1" c="1" e="r11" 
lp2 OP_INSERT b="2" c="1" e="r21" 
lp2 OP_INSERT b="1" c="2" e="r12" 
lp2 OP_INSERT b="2" c="2" e="r22" 
');

	# explicit order, explicit opcode
	undef $res1;
	undef $res2;
	Triceps::FnBinding::call(
		name => "test",
		on => $fret,
		unit => $u9,
		labels => [
			dump => $lp2,
		],
		code => sub {
			$t9->dumpAllIdx($t9->getType()->findIndexPath("cb"), &Triceps::OP_DELETE);
		},
	);
	#print "$res1";
	ok($res1,
't9.dump OP_DELETE b="1" c="1" e="r11" 
t9.dump OP_DELETE b="2" c="1" e="r21" 
t9.dump OP_DELETE b="1" c="2" e="r12" 
t9.dump OP_DELETE b="2" c="2" e="r22" 
');
	#print "$res2";
	ok($res2,
'lp2 OP_DELETE b="1" c="1" e="r11" 
lp2 OP_DELETE b="2" c="1" e="r21" 
lp2 OP_DELETE b="1" c="2" e="r12" 
lp2 OP_DELETE b="2" c="2" e="r22" 
');

	# dumpAll errors

	# the bad args
	my $res;
	$res = eval {
		$t9->dumpAll($t9->getType()->findIndexPath("cb"), 2);
	};
	ok(!defined $res);
	#print "$@\n";
	ok($@ =~ /^Usage: Triceps::Table::dumpAll\(self \[, opcode\]\)/);

	$res = eval {
		$t9->dumpAll("zzz");
	};
	ok(!defined $res);
	#print "$@\n";
	ok($@ =~ /^Triceps::Table::dumpAll: unknown opcode string 'zzz', if integer was meant, it has to be cast/);

	# dumpAllIdx errors

	# the bad args
	$res = eval {
		$t9->dumpAllIdx($t9->getType()->findIndexPath("cb"), 2, 3);
	};
	ok(!defined $res);
	#print "$@\n";
	ok($@ =~ /^Usage: Triceps::Table::dumpAllIdx\(self, widx \[, opcode\]\)/);

	$res = eval {
		$t9->dumpAllIdx($t9->getType()->findIndexPath("cb"), "zzz");
	};
	ok(!defined $res);
	#print "$@\n";
	ok($@ =~ /^Triceps::Table::dumpAllIdx: unknown opcode string 'zzz', if integer was meant, it has to be cast/);

	$res = eval {
		$t9->dumpAllIdx($it1);
	};
	ok(!defined $res);
	#print "$@\n";
	ok($@ =~ /^Triceps::Table::dumpAllIdx: indexType argument does not belong to table's type/);
}

############################## CopyTray1 #############################################
# CopyTray analog.

{
use strict;

my $unit = Triceps::Unit->new("unit");

my @schema = (
	a => "int32",
	b => "string"
);

my $rt1 = Triceps::RowType->new(@schema);

my $tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("byA", Triceps::IndexType->newHashed(key => [ "a" ])
); 
$tt1->initialize();

my $t1 = $unit->makeTable($tt1, "t1");

my $row1 = $rt1->makeRowArray(1, "x");

### start snippet
my $fret1 = $t1->fnReturn();
my $fbind1 = Triceps::FnBinding->new(
    unit => $unit,
    name => "fbind1",
    on => $fret1,
    withTray => 1,
    labels => [
        out => sub { }, # another way to make a dummy
    ],
);

$fret1->push($fbind1);
$t1->insert($row1);
$fret1->pop($fbind1);

# $tray contains the rowops produced by the update
my $tray = $fbind1->swapTray(); # get the updates on an insert
my @rowops = $tray->toArray();
### end snippet

ok($tray->size(), 1);
ok($#rowops, 0);
}

############################## CopyTray2 #############################################
# CopyTray analog - find if any rows got displaced.

{
use strict;

my $unit = Triceps::Unit->new("unit");

my @schema = (
	a => "int32",
	b => "string"
);

my $rt1 = Triceps::RowType->new(@schema);

my $tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("byA", Triceps::IndexType->newHashed(key => [ "a" ])
); 
$tt1->initialize();

my $t1 = $unit->makeTable($tt1, "t1");

my $row1 = $rt1->makeRowArray(1, "x");

### start snippet
my $seenDelete;

my $fret1 = $t1->fnReturn();
my $fbind1 = Triceps::FnBinding->new(
    unit => $unit,
    name => "fbind1",
    on => $fret1,
    labels => [
        out => sub {
			$seenDelete = 1 if ($_[1]->isDelete());
		}
    ],
);

$fret1->push($fbind1);
$seenDelete = 0;
$t1->insert($row1);
$fret1->pop($fbind1);

if ($seenDelete) {
	# there was a displacement
}
### end snippet

ok($seenDelete, 0);

$fret1->push($fbind1);
$seenDelete = 0;
$t1->insert($row1);
$fret1->pop($fbind1);

ok($seenDelete, 1);
}
