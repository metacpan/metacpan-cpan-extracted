#!/usr/bin/env perl

use strict;

use Test::More tests => 9;
use Test::Recent qw(recent);
use Test::Builder::Tester;

ok(defined &recent, "exported");

# now is not now

# now is not now
my $now = DateTime->new(
	year => '2012',
	month => '05',
	day => '23',
	hour => '10',
	minute => '36',
	second => '30',
	time_zone => 'Z',
);

# manually set the clock
$Test::Recent::OverridedNowForTesting =  $now;

my $ten = DateTime::Duration->new( seconds => 10 );

test_out("ok 1 - now");
recent $now, $ten, "now";
test_test("test");

test_out("not ok 1 - future");
test_fail(+2);
test_diag("2012-05-23T10:36:31 not recent to 2012-05-23T10:36:30");
recent $now + DateTime::Duration->new( seconds => 1), $ten, "future";
test_test("test");

test_out("ok 1 - past");
recent $now + DateTime::Duration->new( seconds => -1), $ten, "past";
test_test("test");

test_out("not ok 1 - too past");
test_fail(+2);
test_diag("2012-05-23T10:36:19 not recent to 2012-05-23T10:36:30");
recent $now + DateTime::Duration->new( seconds => -11), $ten, "too past";
test_test("test");


test_out("ok 1 - now");
recent '2012-05-23T10:36:30Z', "10s", "now";
test_test("test");

test_out("not ok 1 - future");
test_fail(+2);
test_diag("2012-05-23T10:36:31Z not recent to 2012-05-23T10:36:30");
recent '2012-05-23T10:36:31Z', "10s", "future";
test_test("test");

test_out("ok 1 - past");
recent '2012-05-23T10:36:29Z', "10s", "past";
test_test("test");

test_out("not ok 1 - too past");
test_fail(+2);
test_diag("2012-05-23T10:36:19Z not recent to 2012-05-23T10:36:30");
recent '2012-05-23T10:36:19Z', "10s", "too past";
test_test("test");


