#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Row.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use lib "$ENV{HOME}/inst/usr/local/lib64/perl5/site_perl/5.10.0";
use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 78 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

sub row2string 
{
	join (', ', map {
		if (defined $_) {
			if (ref $_) {
				'[' . join(', ', @$_) . ']'
			} else {
				$_
			}
		} else {
			'-'
		}
	} @_);
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

########################### types for later use ################################

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

########################### hash format ################################
# and also test printP, since internally it uses toHash

# non-null scalars
@dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");
ok($r1->getType()->same($rt1));
ok($r1->isEmpty(), 0);

# this result is dependent on the machine byte order, so it's not for final tests
# but just for debugging
# print STDERR "\n", $r1->hexdump;

@d1 = $r1->toHash();
ok(join(',', @d1), join(',', @dataset1));
# conversion of "c" may differ on 32-bit machines...
ok($r1->printP(), "a=\"uint8\" b=\"123\" c=\"3000000000000000\" d=\"3.14\" e=\"string\" ");

# nulls
@dataset2 = (
	a => undef,
	b => undef,
	c => 3e15+0,
	d => undef,
	e => undef,
);
$r2 = $rt1->makeRowHash( @dataset2);
ok(ref $r2, "Triceps::Row");

@d2 = $r2->toHash();
ok(join(',', map {defined $_? $_ : "-"} @d2), join(',', map {defined $_? $_ : "-"} @dataset2));
ok($r2->printP(), "c=\"3000000000000000\" ");
#print STDERR "\n dataset d2: ", &row2string(@d2), "\n";

# all nulls
$rempty = $rt1->makeRowHash();
ok(ref $rempty, "Triceps::Row");
ok($rempty->isEmpty(), 1);

# arrays
@dataset3 = (
	a => "uint8",
	b => [ 123, 456, 789 ],
	c => [ 3e15+0, 42, 65535 ], # +0 triggers the data conversion to int64 in Perl
	d => [ 3.14, 2.71, 3.123456789012345+0 ],
	e => "string",
);
#print STDERR "\n dataset:", &row2string(@dataset3), "\n";
$r3 = $rt3->makeRowHash( @dataset3);
ok(ref $r3, "Triceps::Row");

# this result is dependent on the machine byte order, so it's not for final tests
# but just for debugging
#print STDERR "\n", $r3->hexdump;

@d3 = $r3->toHash();
ok(&row2string(@d3), &row2string(@dataset3));
# conversion of "c" may differ on 32-bit machines, and rounding of long pi may also differ...
ok($r3->printP(), "a=\"uint8\" b=[\"123\", \"456\", \"789\"] c=[\"3000000000000000\", \"42\", \"65535\"] d=[\"3.14\", \"2.71\", \"3.12345678901234\"] e=\"string\" ");

# arrays with nulls
@dataset4 = (
	a => "uint8",
	b => undef,
	c => undef,
	d => undef,
	e => "string",
);
#print STDERR "\n dataset:", &row2string(@dataset4), "\n";
$r4 = $rt3->makeRowHash( @dataset4);
ok(ref $r4, "Triceps::Row");

# this result is dependent on the machine byte order, so it's not for final tests
# but just for debugging
#print STDERR "\n", $r4->hexdump;

@d4 = $r4->toHash();
ok(&row2string(@d4), &row2string(@dataset4));
ok($r4->printP(), "a=\"uint8\" e=\"string\" ");

# test the escaping in printP
@dataset5 = (
	a => "-\\-\"-\\-\"",
	b => undef,
	c => undef,
	d => undef,
	e => "+\\+\"+\\+\"",
);
$r5 = $rt3->makeRowHash( @dataset5);
ok(ref $r5, "Triceps::Row");
ok($r5->printP(), "a=\"-\\\\-\\\"-\\\\-\\\"\" e=\"+\\\\+\\\"+\\\\+\\\"\" ");

########################### array CSV-like format ################################

# non-null scalars
@dataset1 = (
	"uint8",
	123,
	3e15+0,
	3.14,
	"string",
);
$r1 = $rt1->makeRowArray( @dataset1);
ok(ref $r1, "Triceps::Row");

# this result is dependent on the machine byte order, so it's not for final tests
# but just for debugging
# print STDERR "\n", $r1->hexdump;

@d1 = $r1->toArray();
ok(join(',', @d1), join(',', @dataset1));

# nulls and auto-filling
@dataset2 = (
	undef,
	undef,
	3e15+0,
);
$r2 = $rt1->makeRowArray( @dataset2);
ok(ref $r2, "Triceps::Row");

@d2 = $r2->toArray();
ok(&row2string(@d2), &row2string(undef,undef,3e15+0,undef,undef));
#print STDERR "\n dataset d2: ", &row2string(@d2), "\n";

# arrays
@dataset3 = (
	"uint8",
	[ 123, 456, 789 ],
	[ 3e15+0, 42, 65535 ], # +0 triggers the data conversion to int64 in Perl
	[ 3.14, 2.71, 3.123456789012345+0 ],
	"string",
);
#print STDERR "\n dataset:", &row2string(@dataset3), "\n";
$r3 = $rt3->makeRowArray( @dataset3);
ok(ref $r3, "Triceps::Row");

# this result is dependent on the machine byte order, so it's not for final tests
# but just for debugging
#print STDERR "\n", $r3->hexdump;

@d3 = $r3->toArray();
ok(&row2string(@d3), &row2string(@dataset3));

# arrays with nulls
@dataset4 = (
	"uint8",
	undef,
	undef,
	undef,
	"string",
);
#print STDERR "\n dataset:", &row2string(@dataset4), "\n";
$r4 = $rt3->makeRowArray( @dataset4);
ok(ref $r4, "Triceps::Row");

# this result is dependent on the machine byte order, so it's not for final tests
# but just for debugging
#print STDERR "\n", $r4->hexdump;

@d4 = $r4->toArray();
ok(&row2string(@d4), &row2string(@dataset4));

########################### copymod ################################

# non-null scalars
@dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

$r2 = $r1->copymod(
	b => 456,
	e => "changed",
);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(
	a => "uint8",
	b => 456,
	c => 3e15+0,
	d => 3.14,
	e => "changed",
));
# check that the original row didn't change
@d2 = $r1->toHash();
ok(&row2string(@d2), &row2string(@dataset1));

# replacing all fields
@dataset2 = (
	a => "bytes",
	b => 789,
	c => 4e15+0,
	d => 2.71,
	e => "text",
);
$r2 = $r1->copymod(@dataset2);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset2));

# replacing non-nulls with nulls
@dataset3 = (
	a => undef,
	b => undef,
	c => undef,
	d => undef,
	e => undef,
);
$r2 = $r1->copymod(@dataset3);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset3));

# replacing nulls with non-nulls
$r2 = $r2->copymod(@dataset2);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset2));

# arrays 
# replacing some fields
@dataset1 = (
	a => "uint8",
	b => [ 123, 456, 789 ],
	c => [ 3e15+0, 42, 65535 ],
	d => [ 3.14, 2.71, 3.123456789012345+0 ],
	e => "string",
);
$r1 = $rt3->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

@dataset3 = (
	a => "bytesbytes",
	b => [ 950, 888, 123, 456, 789 ],
	c => [ 3e15+0, 42, 65535 ],
	d => [ 3.14, 2.71, 3.123456789012345+0 ],
	e => "string",
);
$r2 = $r1->copymod(
	a => "bytesbytes",
	b => [ 950, 888, 123, 456, 789 ],
);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset3));
# check that the original row didn't change
@d2 = $r1->toHash();
ok(&row2string(@d2), &row2string(@dataset1));

# replacing all fields, with scalars
@dataset2 = (
	a => "bytes",
	b => 789,
	c => 4e15+0,
	d => 2.71,
	e => "text",
);
$r2 = $r1->copymod(@dataset2);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(
	a => "bytes",
	b => [ 789, ],
	c => [ 4e15+0, ],
	d => [ 2.71, ],
	e => "text",
));

# replacing all fields with nulls
@dataset3 = (
	a => undef,
	b => undef,
	c => undef,
	d => undef,
	e => undef,
);
$r2 = $r1->copymod(@dataset3);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset3));

# replacing nulls with non-nulls
$r2 = $r2->copymod(@dataset3);
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset3));

# changing nothing
$r2 = $r1->copymod();
ok(ref $r2, "Triceps::Row");
@d2 = $r2->toHash();
ok(&row2string(@d2), &row2string(@dataset1));

# wrong arg number
$r2 = eval { $r1->copymod(
	a => undef,
	b => 123,
	c => 3e15,
	"e"
); };
ok(!defined $r2);
ok($@, qr/^Usage: Triceps::Row::copymod\(RowType, \[fieldName, fieldValue, ...\]\), names and types must go in pairs at/);

# unknown field
$r2 = eval { $r1->copymod(
	z => 123,
); };
ok(!defined $r2);
ok($@, qr/^Triceps::Row::copymod: attempting to set an unknown field 'z' at/);

# setting an array to a scalar field
@dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

$r2 = eval { $r1->copymod(
	b => [ 950, 888, 123, 456, 789 ],
); };
ok(!defined $r2);
ok($@, qr/^Triceps::Row::copymod: attempting to set an array into scalar field 'b' at/);

# setting an array for uint8
$r1 = $rt3->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

$r2 = eval { $r1->copymod(
	a => [ "a", "b", "c" ],
); };
ok(!defined $r2);
ok($@, qr/^Triceps field 'a' data conversion: array reference may not be used for string and uint8/);

############ get #################################

# get a scalar
@dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

ok($r1->get("a"), "uint8");
ok($r1->get("b"), 123);
ok($r1->get("c"), 3e15+0);
ok($r1->get("d"), 3.14);
ok($r1->get("e"), "string");

# getting an unknown field
ok(!defined eval { $r1->get("z"); });
ok($@, qr/^Triceps::Row::get: unknown field 'z' at/);

# getting a null field
@dataset2 = (
	a => undef,
	b => undef,
	c => 3e15+0,
	d => undef,
	e => undef,
);
$r2 = $rt1->makeRowHash( @dataset2);
ok(ref $r2, "Triceps::Row");

ok(!defined $r2->get("a"));

# getting array fields
@dataset3 = (
	a => "bytesbytes",
	b => [ 950, 888, 123, 456, 789 ],
	c => [ 3e15+0, 42, 65535 ],
	d => [ 3.14, 2.71, 3.123456789012345+0 ],
	e => "string",
);
$r1 = $rt3->makeRowHash( @dataset3);
ok(ref $r1, "Triceps::Row");

ok($r1->get("a"), "bytesbytes");
$v = $r1->get("b");
ok(&row2string(@$v), &row2string(@{$dataset3[3]}));
$v = $r1->get("c");
ok(&row2string(@$v), &row2string(@{$dataset3[5]}));
$v = $r1->get("d");
ok(&row2string(@$v), &row2string(@{$dataset3[7]}));

# getting null from an array field
@dataset2 = (
	a => undef,
	b => undef,
	c => 3e15+0,
	d => undef,
	e => undef,
);
$r2 = $rt3->makeRowHash( @dataset2);
ok(ref $r2, "Triceps::Row");

ok(!defined $r2->get("a"));

