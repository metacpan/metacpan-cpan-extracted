#!/usr/bin/perl

use strict;
use warnings;

use Log::Log4perl;
# do some setup here...honest guv

use Test::More tests => 11;
use Test::Builder::Tester;
use Test::Log::Log4perl;
use Test::Exception;

my $logger   = Log::Log4perl->get_logger("Foo");
my $tlogger  = Test::Log::Log4perl->get_logger("Foo");
my $t2logger = Test::Log::Log4perl->get_logger("Bar");

########################################################

test_out("ok 1 - Log4perl test");

Test::Log::Log4perl->start();
$tlogger->error("my hair is on fire!");
$logger->error("my hair is on fire!");
Test::Log::Log4perl->end();

test_test("basic ok test");

########################################################

test_out("ok 1 - Log4perl test");

Test::Log::Log4perl->start();
$tlogger->error("my hair is on fire!");
$logger->error("my hair is on ", "fire!");
Test::Log::Log4perl->end();

test_test("basic ok test");

########################################################

test_out("ok 1 - Log4perl test");

Test::Log::Log4perl->start();
$tlogger->error("my hair is on ", "fire!");
$logger->error("my hair is on fire!");
Test::Log::Log4perl->end();

test_test("basic ok test");

########################################################

test_out("not ok 1 - Log4perl test");
test_fail(+6);
test_diag("Unexpected error of type 'Foo':");
test_diag("  'my hair is on fire!'");

Test::Log::Log4perl->start();
$logger->error("my hair is on fire!");
Test::Log::Log4perl->end();

test_test("not expecting anything");

########################################################

test_out("not ok 1 - Log4perl test");
test_fail(+7);
test_diag("Ended logging run, but still expecting 1 more log(s)");
test_diag("Expecting error of type 'Foo' next:");
test_diag("  'my hair is on fire!'");

Test::Log::Log4perl->start();
$tlogger->error("my hair is on fire!");
Test::Log::Log4perl->end();

test_test("expecting but not getting anything");

########################################################

test_out("not ok 1 - Log4perl test");
test_fail(+9);
test_diag("Message 1 logged wasn't what we expected:");
test_diag("  message was 'your hair is on fire!'");
test_diag("          not 'my hair is on fire!'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");

Test::Log::Log4perl->start();
$tlogger->error("my hair is on fire!");
$logger->error("your hair is on fire!");
Test::Log::Log4perl->end();

test_test("getting wrong message");

########################################################

test_out("not ok 1 - Log4perl test");
test_fail(+9);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" priority was 'warn'");
test_diag("          not 'error'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");

Test::Log::Log4perl->start();
$tlogger->error("my hair is on fire!");
$logger->warn("my hair is on fire!");
Test::Log::Log4perl->end();

test_test("getting wrong priority");

########################################################

test_out("not ok 1 - Log4perl test");
test_fail(+9);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" category was 'Foo'");
test_diag("          not 'Bar'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");

Test::Log::Log4perl->start();
$t2logger->error("my hair is on fire!");
$logger->error("my hair is on fire!");
Test::Log::Log4perl->end();

test_test("getting wrong category");

########################################################

test_out("not ok 1 - Log4perl test");
test_fail(+13);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" category was 'Foo'");
test_diag("          not 'Bar'");
test_diag(" priority was 'warn'");
test_diag("          not 'error'");
test_diag("  message was 'your hair is on fire!'");
test_diag("          not 'my hair is on fire!'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");

Test::Log::Log4perl->start();
$t2logger->error("my hair is on fire!");
$logger->warn("your hair is on fire!");
Test::Log::Log4perl->end();

test_test("getting it all wrong");

########################################################

Test::Log::Log4perl->start();
$tlogger->fatal("my hair is on fire!");

throws_ok {
 $logger->logdie("my hair is on fire!");
} qr/my hair is on fire!/, "logdie dies";

test_out("ok 1 - Log4perl test");
Test::Log::Log4perl->end();
test_test("logdie");

##################################
##################################

sub filename
{
  return (caller)[1];
}
