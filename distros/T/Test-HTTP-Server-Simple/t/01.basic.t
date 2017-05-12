#!/usr/bin/perl

use Test::More tests => 6;
use Test::Builder::Tester;

test_out("not ok 1 - baz");
test_fail(+2);
test_diag("HTTP::Server::Simple->background failed: random failure");
THSS::FailOnBackground->new(1234)->started_ok("baz");
test_test("detect background failure");

test_out("not ok 1 - blop");
test_fail(+2);
test_diag("HTTP::Server::Simple->background didn't return a valid PID");
THSS::ReturnInvalidPid->new(4194)->started_ok("blop");
test_test("detect bad pid");

test_out("ok 1 - beep");
my $URL = THSS::Good->new(9583)->started_ok("beep");
test_test("start up correctly");

is($URL, "http://localhost:9583");

test_out("ok 1 - started server");
$URL = THSS::Good->new(9384)->started_ok;
test_test("start up correctly (with default message)");

is($URL, "http://localhost:9384");


# unfortunately we do not test the child-killing properties of THHS,
# even though that's the main point of the module


package THSS::FailOnBackground;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple/;
sub background { die "random failure\n" }

package THSS::ReturnInvalidPid;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple/;
sub background { return "" }

package THSS::Good;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple::CGI/;
