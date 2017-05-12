#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Rowop.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 76 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


######################### preparations (originating from Label.t)  #############################

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

$lb = $t1->getInputLabel();
ok(ref $lb, "Triceps::Label");

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

@dataset2 = (
	xa => 123,
	xb => 456,
	xc => 3e15+0,
	xd => 3.14,
	xe => "text",
);
$row2 = $rt2->makeRowHash(@dataset2);
ok(ref $row2, "Triceps::Row");

@dataset3 = (
	e => "text",
	a => 123,
	b => 456,
	c => 3e15+0,
	d => 3.14,
);
$row3 = $rt3->makeRowHash(@dataset3);
ok(ref $row3, "Triceps::Row");

######################### factory  #############################
# and printP

$rop1 = $lb->makeRowop("OP_INSERT", $row1);
ok(ref $rop1, "Triceps::Rowop");
ok($rop1->printP(), "tab1.in OP_INSERT a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");
ok($rop1->printP("data"), "data OP_INSERT a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");

$rop = $lb->makeRowop(&Triceps::OP_INSERT, $row1);
ok(ref $rop, "Triceps::Rowop");

eval { $lb->makeRowop("OCF_INSERT", $row1); };
ok($@, qr/^Triceps::Label::makeRowop: unknown opcode string 'OCF_INSERT', if integer was meant, it has to be cast/);

$rop = $lb->makeRowop("OP_INSERT", $row1, "EM_CALL");
ok(ref $rop, "Triceps::Rowop");

$rop = $lb->makeRowop("OP_INSERT", $row1, &Triceps::EM_CALL);
ok(ref $rop, "Triceps::Rowop");

eval { $lb->makeRowop("OP_INSERT", $row1, "something"); };
ok($@, qr/^Triceps::Label::makeRowop: unknown enqueuing mode string 'something', if integer was meant, it has to be cast/);

eval { $lb->makeRowop("OP_INSERT", $row1, "EM_CALL", 9); };
ok($@, qr/^Usage: Triceps::Label::makeRowop\(label, opcode, row \[, enqMode\]\), received too many arguments/);

# a matching row type is OK
# (and as printP shows, the row will be logically cast to our row type)
$rop2 = $lb->makeRowop("OP_DELETE", $row2, "EM_CALL");
ok(ref $rop2, "Triceps::Rowop");
ok($rop2->printP(), "tab1.in OP_DELETE a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");

eval { $lb->makeRowop("OP_INSERT", $row3, "EM_CALL"); };
ok($@, qr/^Triceps::Label::makeRowop: row types do not match\n  Label:\n    row {\n      uint8 a,\n      int32 b,\n      int64 c,\n      float64 d,\n      string e,\n    }\n  Row:\n    row {\n      string e,\n      uint8 a,\n      int32 b,\n      int64 c,\n      float64 d,\n    }/);

####
# convenience factories

$rop = $lb->makeRowopHash("OP_INSERT", @dataset1);
ok(ref $rop, "Triceps::Rowop");
ok($rop->printP(), "tab1.in OP_INSERT a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");

$rop = $lb->makeRowopHash(&Triceps::OP_DELETE, @dataset1);
ok(ref $rop, "Triceps::Rowop");
ok($rop->printP(), "tab1.in OP_DELETE a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");

$rop = $lb->makeRowopArray("OP_INSERT", $row1->toArray());
ok(ref $rop, "Triceps::Rowop");
ok($rop->printP(), "tab1.in OP_INSERT a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");

$rop = $lb->makeRowopArray(&Triceps::OP_DELETE, $row1->toArray());
ok(ref $rop, "Triceps::Rowop");
ok($rop->printP(), "tab1.in OP_DELETE a=\"123\" b=\"456\" c=\"3000000000000000\" d=\"3.14\" e=\"text\" ");

# errors
undef $rop;
eval {
	$rop = $lb->makeRowopHash("OP_INSET", @dataset1);
};
ok(!defined $rop);
ok($@ =~ /^Triceps::Label::makeRowop: unknown opcode string 'OP_INSET', if integer was meant, it has to be cast/);

undef $rop;
eval {
	$rop = $lb->makeRowopArray("OP_INSET", $row1->toArray());
};
ok(!defined $rop);
ok($@ =~ /^Triceps::Label::makeRowop: unknown opcode string 'OP_INSET', if integer was meant, it has to be cast/);

undef $rop;
eval {
	$rop = $lb->makeRowopHash("OP_INSERT", "zzz" => 123);
};
ok(!defined $rop);
ok($@ =~ /^Triceps::RowType::makeRowHash: attempting to set an unknown field 'zzz'/);

undef $rop;
eval {
	$rop = $lb->makeRowopArray("OP_INSERT", [1, 2, 3]);
};
ok(!defined $rop);
ok($@ =~ /^Triceps::RowType::makeRowArray: attempting to set an array into scalar field 'a'/);

######################### copy and sameness #############################

# XXX when get a genuine way to make the same rowop, check it for same()

$v = $rop1->same($rop1);
ok($v);

$v = $rop1->same($rop2);
ok(!$v);

$rop3 = $rop1->copy();
ok(ref $rop3, "Triceps::Rowop");
$v = $rop1->same($rop3);
ok(!$v);

######################### getting info  #############################

$rop3 = $lb->makeRowop("OP_NOP", $row1);
ok(ref $rop3, "Triceps::Rowop");

$v = $rop1->getOpcode();
ok($v, &Triceps::OP_INSERT);
$v = $rop2->getOpcode();
ok($v, &Triceps::OP_DELETE);
$v = $rop3->getOpcode();
ok($v, &Triceps::OP_NOP);

$v = $rop1->isInsert();
ok($v);
$v = $rop2->isInsert();
ok(!$v);
$v = $rop3->isInsert();
ok(!$v);

$v = $rop1->isDelete();
ok(!$v);
$v = $rop2->isDelete();
ok($v);
$v = $rop3->isDelete();
ok(!$v);

$v = $rop1->isNop();
ok(!$v);
$v = $rop2->isNop();
ok(!$v);
$v = $rop3->isNop();
ok($v);

# the static isInsert() etc are in the base Triceps:: class

$lb2 = $rop1->getLabel();
ok(ref $lb2, "Triceps::Label");
ok($lb->same($lb2));

$row = $rop1->getRow();
ok(ref $row, "Triceps::Row");
ok($row1->same($row));

$v = $rop1->getEnqMode();
ok($v, &Triceps::EM_FORK);

######################### adopt #############################

$labx1 = $u1->makeDummyLabel($rt1, "labx1");
ok(ref $labx1, "Triceps::Label");
$labx2 = $u1->makeDummyLabel($rt2, "labx2");
ok(ref $labx2, "Triceps::Label");
$labx3 = $u1->makeDummyLabel($rt3, "labx3");
ok(ref $labx3, "Triceps::Label");
$laby1 = $u2->makeDummyLabel($rt1, "laby1");
ok(ref $laby1, "Triceps::Label");

$ropx1 = $labx1->adopt($rop1);
ok(ref $ropx1, "Triceps::Rowop");
ok($rop1->getRow()->same($ropx1->getRow()));
ok($rop1->getOpcode(), $ropx1->getOpcode());
ok($ropx1->getLabel()->same($labx1));

# a matching type is OK
$ropx1 = $labx2->adopt($rop1);
ok(ref $ropx1, "Triceps::Rowop");

# an unmatching type is not OK
$ropx1 = eval { $labx3->adopt($rop1); };
ok(!defined $ropx1);
ok($@, 
qr/^Triceps::Label::adopt: row types do not match
  Label:
    row {
      string e,
      uint8 a,
      int32 b,
      int64 c,
      float64 d,
    }
  Row:
    row {
      uint8 a,
      int32 b,
      int64 c,
      float64 d,
      string e,
    }/);

# an unmatching unit is OK
$ropx1 = $laby1->adopt($rop1);
ok(ref $ropx1, "Triceps::Rowop");
