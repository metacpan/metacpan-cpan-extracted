#!/usr/bin/perl

use strict;
use warnings;

use Log::Log4perl;
# do some setup here...honest guv

use Test::More tests => 2;
use Test::Builder::Tester;
use Test::Log::Log4perl;
use Test::Exception;

my $logger   = Log::Log4perl->get_logger("Foo");
my $tlogger  = Test::Log::Log4perl->get_logger("Foo");
my $t2logger = Test::Log::Log4perl->get_logger("Bar");

########################################################

# test that we ignore some priorities

test_out("ok 1 - Log4perl test");

Test::Log::Log4perl->start(
  ignore_priority => "warn",
);

$tlogger->error("my hair is on fire!");
$logger->trace("ignore ignore ignore");
$logger->debug("ignore me");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

# but they go back at the start of the next thing

test_out("not ok 2 - Log4perl test");
test_fail(+16);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" priority was 'debug'");
test_diag("          not 'error'");
test_diag("  message was 'ignore me'");
test_diag("          not 'my hair is on fire!'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");
Test::Log::Log4perl->start();

$tlogger->error("my hair is on fire!");
$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

# test that we can ignore everything

test_out("ok 3 - Log4perl test");

Test::Log::Log4perl->start(
  ignore_priority => "everything",
);

$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("ignore with pleasure");
$logger->fatal("ignore this finally");

Test::Log::Log4perl->end();

# but they go back at the start of the next thing

test_out("not ok 4 - Log4perl test");
test_fail(+16);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" priority was 'debug'");
test_diag("          not 'error'");
test_diag("  message was 'ignore me'");
test_diag("          not 'my hair is on fire!'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");
Test::Log::Log4perl->start();

$tlogger->error("my hair is on fire!");
$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

test_test("ignoring priority");

########################################################

# test that we ignore some priorities forever

test_out("ok 1 - Log4perl test");

Test::Log::Log4perl->start(
  # this should be overriden
  ignore_priority => "error",
);

Test::Log::Log4perl->ignore_priority("warn");

$tlogger->error("my hair is on fire!");
$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

# and they don't go back, the ignore priority
# should still be set

test_out("ok 2 - Log4perl test");

Test::Log::Log4perl->start();

$tlogger->error("my hair is on fire!");
$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

# though we can turn them off with ignore nothing

Test::Log::Log4perl->start();

Test::Log::Log4perl->ignore_priority("nothing");

test_out("not ok 3 - Log4perl test");
test_fail(+16);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" priority was 'debug'");
test_diag("          not 'error'");
test_diag("  message was 'ignore me'");
test_diag("          not 'my hair is on fire!'");
test_diag(" (Offending log call from line ".(__LINE__+4)." in ".filename().")");
Test::Log::Log4perl->start();

$tlogger->error("my hair is on fire!");
$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

# and that's still set next time

Test::Log::Log4perl->start();

test_out("not ok 4 - Log4perl test");
test_fail(+17);
test_diag("Message 1 logged wasn't what we expected:");
test_diag(" priority was 'debug'");
test_diag("          not 'error'");
test_diag("  message was 'ignore me'");
test_diag("          not 'my hair is on fire!'");
test_diag(" (Offending log call from line ".(__LINE__+5)." in ".filename().")");

Test::Log::Log4perl->start();

$tlogger->error("my hair is on fire!");
$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("my hair is on fire!");

Test::Log::Log4perl->end();

# and we can ignore everything

Test::Log::Log4perl->start();
Test::Log::Log4perl->ignore_priority("everything");

test_out("ok 5 - Log4perl test");

$logger->debug("ignore me");
$logger->info("ignore me too");
$logger->trace("ignore ignore ignore");
$logger->warn("ignore me as well");
$logger->error("ignore with pleasure");
$logger->fatal("ignore this finally");

Test::Log::Log4perl->end();

# and things are still ignored

Test::Log::Log4perl->start();
Test::Log::Log4perl->ignore_priority("everything");

test_out("ok 6 - Log4perl test");

$logger->debug("ignore me");
$logger->trace("ignore ignore ignore");
$logger->info("ignore me too");
$logger->warn("ignore me as well");
$logger->error("ignore with pleasure");
$logger->fatal("ignore this finally");

Test::Log::Log4perl->end();

# and we can ignore nothing

Test::Log::Log4perl->start();
Test::Log::Log4perl->ignore_priority("nothing");

test_out("ok 7 - Log4perl test");

$tlogger->debug("don't ignore me");
$tlogger->trace("no ignore no ignore no ignore");
$tlogger->info("don't ignore me too");
$tlogger->warn("don't ignore me as well");
$tlogger->error("don't ignore with pleasure");
$tlogger->fatal("don't ignore this finally");
$logger->debug("don't ignore me");
$logger->trace("no ignore no ignore no ignore");
$logger->info("don't ignore me too");
$logger->warn("don't ignore me as well");
$logger->error("don't ignore with pleasure");
$logger->fatal("don't ignore this finally");

Test::Log::Log4perl->end();

# and that remains set too

Test::Log::Log4perl->start();

test_out("ok 8 - Log4perl test");

$tlogger->debug("don't ignore me");
$tlogger->trace("no ignore no ignore no ignore");
$tlogger->info("don't ignore me too");
$tlogger->warn("don't ignore me as well");
$tlogger->error("don't ignore with pleasure");
$tlogger->fatal("don't ignore this finally");
$logger->debug("don't ignore me");
$logger->trace("no ignore no ignore no ignore");
$logger->info("don't ignore me too");
$logger->warn("don't ignore me as well");
$logger->error("don't ignore with pleasure");
$logger->fatal("don't ignore this finally");

Test::Log::Log4perl->end();

test_test("ignoring priority forever");

##################################
##################################

sub filename
{
  return (caller)[1];
}
