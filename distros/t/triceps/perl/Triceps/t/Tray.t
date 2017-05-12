#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Tray.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 56 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


######################### preparations (originating from Rowop.t)  #############################

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

# a type matching rt1
@def2 = (
	xa => "uint8",
	xb => "int32",
	xc => "int64",
	xd => "float64",
	xe => "string",
);
$rt2 = Triceps::RowType->new( # used later
	@def2
);
ok(ref $rt2, "Triceps::RowType");

# a type not matching rt1
@def3 = (
	e => "string",
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
);
$rt3 = Triceps::RowType->new( # used later
	@def3
);
ok(ref $rt3, "Triceps::RowType");

$it1 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
	);
ok(ref $it1, "Triceps::IndexType");

$tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it1);
ok(ref $tt1, "Triceps::TableType");

$res = $tt1->initialize();
ok($res, 1);

$t1 = $u1->makeTable($tt1, "tab1");
ok(ref $t1, "Triceps::Table");

$lb1 = $t1->getInputLabel();
ok(ref $lb1, "Triceps::Label");

$t2 = $u2->makeTable($tt1, "tab2");
ok(ref $t2, "Triceps::Table");

$lb2 = $t2->getInputLabel();
ok(ref $lb2, "Triceps::Label");

# create a row for Rowop building
@dataset1 = (
	a => 123,
	b => 456,
	c => 3e15+0,
	d => 3.14,
	e => "text",
);
$row1 = $rt1->makeRowHash(@dataset1);
ok(ref $row1, "Triceps::Row");

$rop11 = $lb1->makeRowop("OP_INSERT", $row1);
ok(ref $rop11, "Triceps::Rowop");
$rop12 = $lb1->makeRowop("OP_DELETE", $row1);
ok(ref $rop12, "Triceps::Rowop");

$rop21 = $lb2->makeRowop("OP_INSERT", $row1);
ok(ref $rop21, "Triceps::Rowop");
$rop22 = $lb2->makeRowop("OP_DELETE", $row1);
ok(ref $rop22, "Triceps::Rowop");

######################### factory  #############################

$tray1 = $u1->makeTray($rop11, $rop12);
ok(ref $tray1, "Triceps::Tray");

ok($tray1->size(), 2);
@arr = $tray1->toArray();
ok($#arr, 1);
ok($rop11->same($arr[0]));
ok($rop12->same($arr[1]));

$tray2 = $tray1;
ok($tray1->same($tray2));

$v = $tray1->getUnit();
ok($u1->same($v));

# make a copy
$tray2 = $tray1->copy();
ok(ref $tray2, "Triceps::Tray");
ok(!$tray1->same($tray2));
ok($tray2->size(), 2);
@arr = $tray2->toArray();
ok($#arr, 1);
ok($rop11->same($arr[0]));
ok($rop12->same($arr[1]));

# clear the copy
$tray2->clear();
ok($tray2->size(), 0);
@arr = $tray2->toArray();
ok($#arr, -1);
@arr = $tray1->toArray();
ok($#arr, 1);

# push
$v = $tray1->push($rop12);
ok(ref $v, "Triceps::Tray");
ok($tray1->same($v));
@arr = $tray1->toArray();
ok($#arr, 2);
ok($rop11->same($arr[0]));
ok($rop12->same($arr[1]));
ok($rop12->same($arr[2]));

# construct invalid values
$tray2 = eval { $u1->makeTray($rop11, $rop12, 0); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Unit::makeTray: argument 3 is not a blessed SV reference to Rowop/);
$tray2 = eval { $u1->makeTray($rop11, $rop12, $tray1); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Unit::makeTray: argument 3 has an incorrect magic for Rowop/);
$tray2 = eval { $u1->makeTray(undef, $rop11, $rop12); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Unit::makeTray: argument 1 is not a blessed SV reference to Rowop/);
$tray2 = eval { $u1->makeTray($rop21, $rop22); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Unit::makeTray: argument 1 is a Rowop for label tab2.in from a wrong unit u2/);

# push invalid values
$tray2 = eval { $tray1->push($rop11, $rop12, 0); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Tray::push: argument 3 is not a blessed SV reference to Rowop/);
$tray2 = eval { $tray1->push($rop11, $rop12, $tray1); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Tray::push: argument 3 has an incorrect magic for Rowop/);
$tray2 = eval { $tray1->push(undef, $rop11, $rop12); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Tray::push: argument 1 is not a blessed SV reference to Rowop/);
$tray2 = eval { $tray1->push($rop21, $rop22); };
ok(!defined $tray2);
ok($@, qr/^Triceps::Tray::push: argument 1 is a Rowop for label tab2.in from a wrong unit u2/);
