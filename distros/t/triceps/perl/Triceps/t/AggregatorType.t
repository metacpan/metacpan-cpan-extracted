#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for IndexType.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 59 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

###################### new #################################

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

@def2 = (
	x => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
$rt2 = Triceps::RowType->new( # used later
	@def2
);
ok(ref $rt2, "Triceps::RowType");

@def3 = (
	b => "int32",
	a => "uint8",
	c => "int64",
	d => "float64",
	e => "string",
);
$rt3 = Triceps::RowType->new( # used later
	@def3
);
ok(ref $rt3, "Triceps::RowType");

$agt1 = Triceps::AggregatorType->new($rt1, "aggr", undef, sub { });
ok(ref $agt1, "Triceps::AggregatorType");

$agt1 = Triceps::AggregatorType->new($rt1, "aggr", sub { }, sub { });
ok(ref $agt1, "Triceps::AggregatorType");

$agt1 = Triceps::AggregatorType->new($rt1, "aggr", sub { }, sub { }, 1, 2, "x");
ok(ref $agt1, "Triceps::AggregatorType");

# errors

$agt1 = eval { Triceps::AggregatorType->new($rt1, "aggr", sub { }, undef); };
ok(! defined $agt1);
ok($@, qr/^Triceps::AggregatorType::new\(handler\): code must be a source code string or a reference to Perl function at/);

$agt1 = eval { Triceps::AggregatorType->new($rt1, "aggr", sub { }, 3); };
ok(! defined $agt1);
ok($@, qr/^Triceps::AggregatorType::new\(handler\): code must be a source code string or a reference to Perl function at/);

$agt1 = eval { Triceps::AggregatorType->new($rt1, "aggr", 4, sub { }); };
ok(! defined $agt1);
ok($@, qr/^Triceps::AggregatorType::new\(constructor\): code must be a source code string or a reference to Perl function at/);

###################### copy/equality #################################

sub dummyCall
{ }

$agt1 = Triceps::AggregatorType->new($rt1, "aggr", undef, \&dummyCall);
ok(ref $agt1, "Triceps::AggregatorType");
ok($agt1->same($agt1));
# sameness also tested in IndexType.t

$agt2 = $agt1->copy();
ok(ref $agt2, "Triceps::AggregatorType");
ok($agt1->equals($agt2));
ok($agt1->match($agt2));

$agt2 = Triceps::AggregatorType->new($rt1, "another", undef, \&dummyCall);
ok(ref $agt2, "Triceps::AggregatorType");
ok(!$agt1->equals($agt2));
ok($agt1->match($agt2));

$agt2 = Triceps::AggregatorType->new($rt3, "aggr", undef, \&dummyCall);
ok(ref $agt2, "Triceps::AggregatorType");
ok(!$agt1->equals($agt2));
ok(!$agt1->match($agt2));

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", undef, sub { }); # different reference
ok(ref $agt2, "Triceps::AggregatorType");
ok(!$agt1->equals($agt2));
ok(!$agt1->match($agt2));

# source code snippets
$agt2 = Triceps::AggregatorType->new($rt1, "aggr", ' ', ' ');
ok(ref $agt2, "Triceps::AggregatorType");
$agt3 = Triceps::AggregatorType->new($rt1, "aggr", ' ', ' ');
ok(ref $agt3, "Triceps::AggregatorType");
ok($agt3->equals($agt2));
ok($agt3->match($agt2));

# another prototype
$agt1 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 1, "2", "a");
ok(ref $agt1, "Triceps::AggregatorType");

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 1.0, "2", "a");
ok(ref $agt2, "Triceps::AggregatorType");
ok($agt1->equals($agt2));
ok($agt1->match($agt2));

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 1, 2.0, "a");
ok(ref $agt2, "Triceps::AggregatorType");
ok($agt1->equals($agt2));
ok($agt1->match($agt2));
ok($agt2->equals($agt1));
ok($agt2->match($agt1));

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", undef, \&dummyCall, 1, "2", "a");
ok(ref $agt2, "Triceps::AggregatorType");
ok(!$agt1->equals($agt2));
ok(!$agt1->match($agt2));
ok(!$agt2->equals($agt1));
ok(!$agt2->match($agt1));

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 1, "2", "a", 3);
ok(!$agt1->equals($agt2));
ok(!$agt1->match($agt2));
ok(!$agt2->equals($agt1));
ok(!$agt2->match($agt1));

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 2, "2", "a");
ok(!$agt1->equals($agt2));
ok(!$agt1->match($agt2));

# another prototype - "2.0" is a string, a number converted to it will be "2" and won't match
$agt1 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 1, "2.0", "a");
ok(ref $agt1, "Triceps::AggregatorType");

$agt2 = Triceps::AggregatorType->new($rt1, "aggr", \&dummyCall, \&dummyCall, 1, 2.0, "a");
ok(ref $agt2, "Triceps::AggregatorType");
ok(!$agt1->equals($agt2));
ok(!$agt1->match($agt2));
ok(!$agt2->equals($agt1));
ok(!$agt2->match($agt1));

###################### print #################################

$res = $agt1->print();
ok($res, "aggregator (\n  row {\n    uint8 a,\n    int32 b,\n    int64 c,\n    float64 d,\n    string e,\n  }\n) aggr");

$res = $agt1->print(undef);
ok($res, "aggregator ( row { uint8 a, int32 b, int64 c, float64 d, string e, } ) aggr");
