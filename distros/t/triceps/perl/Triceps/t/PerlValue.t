#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for PerlSortedIndexType's interaction with threads.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 61 };
use Triceps;
use Carp;
use strict;
ok(1); # If we made it this far, we're ok.

#########################

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
ok(ref $rt1, "Triceps::RowType");

my $rt1eq = Triceps::RowType->new( # equal to rt1
	@def1
);
ok(ref $rt1eq, "Triceps::RowType");

my $rt2 = Triceps::RowType->new( # matching but not equal to rt1
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	f => "string",
);
ok(ref $rt2, "Triceps::RowType");

my @dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
my $r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

my $r1eq = $rt1eq->makeRowHash( @dataset1); # equal to r1, of an equal type
ok(ref $r1eq, "Triceps::Row");

my $r2 = $rt1->makeRowHash(a => "uint8"); # not equal to r1 but of the same type
ok(ref $r1, "Triceps::Row");

my $r3 = $rt2->makeRowHash( # contents equal to r1 but of a matching type
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	f => "string",
);
ok(ref $r3, "Triceps::Row");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my($v, $vv, $res);

$v = Triceps::PerlValue->new(undef);
ok(ref $v, "Triceps::PerlValue");
$res = $v->get();
ok(!defined $res);

$v = Triceps::PerlValue->new(1);
$res = $v->get();
ok($res, 1);

$v = Triceps::PerlValue->new(1.5);
$res = $v->get();
ok($res, 1.5);

$v = Triceps::PerlValue->new("xxx");
$res = $v->get();
ok($res, "xxx");

$v = Triceps::PerlValue->new($rt1);
$res = $v->get();
ok(ref $res, "Triceps::RowType");
ok($res->equals($rt1));
ok(!$res->same($rt1));

$v = Triceps::PerlValue->new($r1);
$res = $v->get();
ok(ref $res, "Triceps::Row");
ok($res->same($r1));
ok($res->getType()->equals($rt1));
ok(!$res->getType()->same($rt1));

$v = Triceps::PerlValue->new([]);
$res = $v->get();
ok(ref $res, "ARRAY");
ok($#$res, -1);

$v = Triceps::PerlValue->new([1, 1.5, "xxx"]);
$res = $v->get();
ok(ref $res, "ARRAY");
ok($#$res, 2);
ok($$res[0], 1);
ok($$res[1], 1.5);
ok($$res[2], "xxx");

$v = Triceps::PerlValue->new({});
$res = $v->get();
ok(ref $res, "HASH");
ok(join(' ', sort(keys %$res)), "");

$v = Triceps::PerlValue->new({ a => 1,  b=> 1.5,  c => "xxx" });
$res = $v->get();
ok(ref $res, "HASH");
ok(join(' ', sort(keys %$res)), "a b c");
ok($$res{a}, 1);
ok($$res{b}, 1.5);
ok($$res{c}, "xxx");

# double-nested
$v = Triceps::PerlValue->new([$rt1, $r1, { a => 1,  b=> 1.5,  c => "xxx" }]);
$res = $v->get();
ok(ref $res, "ARRAY");
ok($#$res, 2);
ok(ref $$res[0], "Triceps::RowType");
ok($$res[0]->equals($rt1));
ok(ref $$res[1], "Triceps::Row");
ok($$res[1]->same($r1));
ok(join(' ', sort(keys %{$$res[2]})), "a b c");

# multiple row type references preserve the commonality
$v = Triceps::PerlValue->new([$rt1, $rt1, $rt1]);
$res = $v->get();
ok($$res[0]->equals($rt1));
ok(!$$res[0]->same($rt1));
ok($$res[0]->same($$res[1]));
ok($$res[0]->same($$res[2]));

#########################
# test the errors

eval { Triceps::PerlValue->new(sub {}); };
ok($@, qr/^to allow passing between the threads, the value must be one of undef, int, float, string, RowType, or an array or hash thereof/);

eval { Triceps::PerlValue->new([sub {}]); };
ok($@, qr/^invalid value at array index 0:\n  to allow passing between the threads, the value must be one of undef, int, float, string, RowType, or an array or hash thereof/);

eval { Triceps::PerlValue->new({ a => sub {}}); };
ok($@, qr/^invalid value at hash key 'a':\n  to allow passing between the threads, the value must be one of undef, int, float, string, RowType, or an array or hash thereof/);

#########################
# test the equality

$v = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "x" }, $rt1, $r1]);
ok($v->equals($v));

# exactly same contents
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "x" }, $rt1, $r1]);
ok($v->equals($vv));

# equal row type and row values
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "x" }, $rt1eq, $r1eq]);
ok($v->equals($vv));

# hash the same but in different order
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { b => "x", a => 1 }, $rt1, $r1]);
ok($v->equals($vv));

# different value type (and naturally a different element in an array)
$vv = Triceps::PerlValue->new([1, 1, 1.5, "str", { a => 1, b => "x" }, $rt1, $r1]);
ok(!$v->equals($vv));

# different int
$vv = Triceps::PerlValue->new([undef, 2, 1.5, "str", { a => 1, b => "x" }, $rt1, $r1]);
ok(!$v->equals($vv));

# different float
$vv = Triceps::PerlValue->new([undef, 1, 2.5, "str", { a => 1, b => "x" }, $rt1, $r1]);
ok(!$v->equals($vv));

# different string
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "strx", { a => 1, b => "x" }, $rt1, $r1]);
ok(!$v->equals($vv));

# different hash key
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, c => "x" }, $rt1, $r1]);
ok(!$v->equals($vv));

# different hash value
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "y" }, $rt1, $r1]);
ok(!$v->equals($vv));

# different row type
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "x" }, $rt2, $r1]);
ok(!$v->equals($vv));

# different row of the same type
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "x" }, $rt1, $r2]);
ok(!$v->equals($vv));

# a row of the same contents but matching type
$vv = Triceps::PerlValue->new([undef, 1, 1.5, "str", { a => 1, b => "x" }, $rt1, $r3]);
ok(!$v->equals($vv));

