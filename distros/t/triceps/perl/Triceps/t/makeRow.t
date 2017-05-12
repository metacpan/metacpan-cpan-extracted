#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for RowType row making.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 37 };
use Triceps;
ok(1); # If we made it this far, we're ok.

# the warnings mode causes confusing warnings about data type conversions
no warnings;

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

#################### creating from hashes ######################

$r1 = $rt1->makeRowHash(
	a => "uint8",
	b => 123,
	c => 3e15,
	d => 3.14,
	e => "string",
);
ok(ref $r1, "Triceps::Row");

# try an actual hash
%data1 = (
	a => "uint8",
	b => 123,
	c => 3e15,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash(%data1);
ok(ref $r1, "Triceps::Row");

# try giving a non-numeric but convertible value to a numeric field
$r1 = $rt1->makeRowHash(
	a => "uint8",
	b => "123",
	c => 3e15,
	d => 3.14,
	e => "string",
);
ok(ref $r1, "Triceps::Row");

# try giving a non-numeric and non-convertible value to a numeric field
#print STDERR "\nIgnore the following message about non-numeric, if any\n";
$r1 = $rt1->makeRowHash(
	a => "uint8",
	b => "z123",
	c => 3e15,
	d => 3.14,
	e => "string",
);
ok(ref $r1, "Triceps::Row");

# test that scalar can be transparently set to arrays
$r1 = $rt3->makeRowHash(
	a => "uint8",
	b => 123,
	c => 3e15,
	d => 3.14,
	e => "string",
);
ok(ref $r1, "Triceps::Row");

$r1 = $rt1->makeRowHash(
	a => undef,
	b => 123,
	c => 3e15,
	e => "string",
);
ok(ref $r1, "Triceps::Row");

# all-null row
$r1 = $rt1->makeRowHash();
ok(ref $r1, "Triceps::Row");

# try all the errors
$r1 = eval { $rt1->makeRowHash(
	a => "uint8",
	b => [ 0x123, 0x456 ],
	c => 3e15,
	d => 3.14,
	e => "string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps::RowType::makeRowHash: attempting to set an array into scalar field 'b' at/);

$r1 = eval { $rt1->makeRowHash(
	z => "uint8",
	c => 3e15,
	d => 3.14,
	e => "string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps::RowType::makeRowHash: attempting to set an unknown field 'z' at/);

$r1 = eval { $rt1->makeRowHash(
	a => undef,
	b => 123,
	c => 3e15,
	"e"
); };
ok(!defined $r1);
ok($@, qr/^Usage: Triceps::RowType::makeRowHash\(RowType, fieldName, fieldValue, ...\), names and types must go in pairs at/);

# array fields
$r1 = $rt3->makeRowHash(
	a => "uint8",
	b => [ 0x123, 0x456 ],
	c => 3e15,
	d => 3.14,
	e => "string",
);
ok(ref $r1, "Triceps::Row");
#print STDERR "\n", $r1->hexdump;

$r1 = eval { $rt3->makeRowHash(
	a => [ "uint8" ],
	b => [ 0x123, 0x456 ],
	c => 3e15,
	d => 3.14,
	e => "string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps field 'a' data conversion: array reference may not be used for string and uint8 at/);

# errors related to array fields
$r1 = eval { $rt3->makeRowHash(
	a => "uint8",
	b => [ 0x123, 0x456 ],
	c => 3e15,
	d => 3.14,
	e => [ "string" ],
); };
ok(!defined $r1);
ok($@, qr/^Triceps::RowType::makeRowHash: attempting to set an array into scalar field 'e' at/);

$r1 = eval { $rt3->makeRowHash(
	a => "uint8",
	b => { "a" , 0x456 },
	c => 3e15,
	d => 3.14,
	e => "string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps field 'b' data conversion: reference not to an array at/);

#################### creating from CSV-style arrays ######################

$r1 = $rt1->makeRowArray(
	"uint8",
	123,
	3e15,
	3.14,
	"string",
);
ok(ref $r1, "Triceps::Row");

# test that scalar can be transparently set to arrays
$r1 = $rt3->makeRowArray(
	"uint8",
	123,
	3e15,
	3.14,
	"string",
);
ok(ref $r1, "Triceps::Row");

# all-null row
$r1 = $rt1->makeRowArray();
ok(ref $r1, "Triceps::Row");

# try all the errors
$r1 = eval { $rt1->makeRowArray(
	"uint8",
	[ 0x123, 0x456 ],
	3e15,
	3.14,
	"string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps::RowType::makeRowArray: attempting to set an array into scalar field 'b' at/);

$r1 = eval { $rt1->makeRowArray(
	a => undef,
	b => 123,
	c => 3e15,
	"e"
); };
ok(!defined $r1);
ok($@, qr/^Triceps::RowType::makeRowArray: 7 args, only 5 fields in row { uint8 a, int32 b, int64 c, float64 d, string e, } at/);

# array fields
$r1 = $rt3->makeRowArray(
	"uint8",
	[ 0x123, 0x456 ],
	3e15,
	3.14,
	"string",
);
ok(ref $r1, "Triceps::Row");
#print STDERR "\n", $r1->hexdump;

$r1 = eval { $rt3->makeRowArray(
	[ "uint8" ],
	[ 0x123, 0x456 ],
	3e15,
	3.14,
	"string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps field 'a' data conversion: array reference may not be used for string and uint8 at/);

# errors related to array fields
$r1 = eval { $rt3->makeRowArray(
	"uint8",
	[ 0x123, 0x456 ],
	3e15,
	3.14,
	[ "string" ],
); };
ok(!defined $r1);
ok($@, qr/^Triceps::RowType::makeRowArray: attempting to set an array into scalar field 'e' at/);

$r1 = eval { $rt3->makeRowArray(
	"uint8",
	{ "a" , 0x456 },
	3e15,
	3.14,
	"string",
); };
ok(!defined $r1);
ok($@, qr/^Triceps field 'b' data conversion: reference not to an array at/);

