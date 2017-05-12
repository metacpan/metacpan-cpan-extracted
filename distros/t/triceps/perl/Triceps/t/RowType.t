#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for RowType.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 41 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

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
@xdef1 = $rt1->getdef();
ok(join(",", @xdef1), join(",", @def1));
@xfld1 = $rt1->getFieldNames();
ok(join(",", @xfld1), "a,b,c,d,e");
@xfld1 = $rt1->getFieldTypes();
ok(join(",", @xfld1), "uint8,int32,int64,float64,string");
@xfld1 = $rt1->getFieldMapping();
ok(join(",", @xfld1), "a,0,b,1,c,2,d,3,e,4");

@def3 = (
	a => "uint8[]",
	b => "int32[]",
	c => "int64[]",
	d => "float64[]",
	e => "string",
);
$rt3 = Triceps::RowType->new( # used later
	@def3
);
ok(ref $rt3, "Triceps::RowType");
@xdef3 = $rt3->getdef();
ok(join(",", @xdef3), join(",", @def3));
@xfld3 = $rt3->getFieldNames();
ok(join(",", @xfld3), "a,b,c,d,e");
@xfld3 = $rt3->getFieldTypes();
ok(join(",", @xfld3), "uint8[],int32[],int64[],float64[],string");
@xfld3 = $rt3->getFieldMapping();
ok(join(",", @xfld3), "a,0,b,1,c,2,d,3,e,4");

$rt2 = eval { Triceps::RowType->new(
	a => "void",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string[]",
); };
ok(!defined $rt2);
ok($@, qr/^Triceps::RowType::new: field 'e' string array type is not supported\nTriceps::RowType::new: The specification was: {\n  a => void\n  b => int32\n  c => int64\n  d => float64\n  e => string\[\]\n} at/);

$rt2 = eval { Triceps::RowType->new(
	a => "void",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
); };
ok(!defined $rt2);
ok($@, qr/^Triceps::RowType::new: incorrect specification:\n  field 'a' type must not be void\nTriceps::RowType::new: The specification was: \{\n  a => void\n  b => int32\n  c => int64\n  d => float64\n  e => string\n\} at/);

$rt2 = eval { Triceps::RowType->new(
	a => "",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
); };
ok(!defined $rt2);
ok($@, qr/^Triceps::RowType::new: field 'a' has an unknown type ''\nTriceps::RowType::new: The specification was: \{\n  a => \n  b => int32\n  c => int64\n  d => float64\n  e => string\n\} at/);

$rt2 = eval { Triceps::RowType->new(
); };
ok(!defined $rt2);
ok($@, qr/^Usage: Triceps::RowType::new\(CLASS, fieldName, fieldType, ...\), names and types must go in pairs\nTriceps::RowType::new: The specification was: \{\n\} at/);

undef $@;
$rt2 = eval { Triceps::RowType->new(
	a => "",
	b => "int32",
	c => "int64",
	d => "float64",
	"string",
); };
ok(!defined $rt2);
ok($@, qr/^Usage: Triceps::RowType::new\(CLASS, fieldName, fieldType, ...\), names and types must go in pairs\nTriceps::RowType::new: The specification was: \{\n  a => \n  b => int32\n  c => int64\n  d => float64\n  string => \n\} at/);

# schema inheritance
$rt2 = Triceps::RowType->new(
	$rt1->getdef(),
	z => "string"
);
ok(ref $rt2, "Triceps::RowType");
@xdef2 = $rt2->getdef();
ok(join(",", @xdef2), join(",", @def1, "z", "string"));

######################### comparisons ###########################################

# same() gets successfull when getting the row type of some other object, see Label
$rt2 = Triceps::RowType->new(
	@def1
);
ok(ref $rt2, "Triceps::RowType");
ok($rt2->equals($rt1));
ok($rt1->equals($rt2));
ok($rt2->match($rt1));
ok(!$rt2->same($rt1));

$rt2 = Triceps::RowType->new(
	A => "uint8",
	B => "int32",
	C => "int64",
	D => "float64",
	E => "string",
);
ok(ref $rt2, "Triceps::RowType");
ok(!$rt2->equals($rt1));
ok($rt1->match($rt2));
ok($rt2->match($rt1));

ok(!$rt3->match($rt1));

########################### print ##########################################

$v = $rt1->print();
ok($v, "row {\n  uint8 a,\n  int32 b,\n  int64 c,\n  float64 d,\n  string e,\n}");
$v = $rt1->print("++");
ok($v, "row {\n++  uint8 a,\n++  int32 b,\n++  int64 c,\n++  float64 d,\n++  string e,\n++}");
$v = $rt1->print("++", "--");
ok($v, "row {\n++--uint8 a,\n++--int32 b,\n++--int64 c,\n++--float64 d,\n++--string e,\n++}");
$v = $rt1->print(undef);
ok($v, "row { uint8 a, int32 b, int64 c, float64 d, string e, }");
$v = $rt1->print(undef, "    ");
ok($v, "row { uint8 a, int32 b, int64 c, float64 d, string e, }");

$v = eval { $rt1->print(undef, "    ", "zzzz"); };
ok(!defined $v);
ok ($@, qr/^Usage: Triceps::RowType::print\(self \[, indent  \[, subindent \] \]\) at/);

$v = $rt3->print();
ok($v, "row {\n  uint8[] a,\n  int32[] b,\n  int64[] c,\n  float64[] d,\n  string e,\n}");
