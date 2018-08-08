#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use UR;
use Command::Shell;
use CmdTest;
use CmdTest::C2;
use CmdTest::C3;

# Put this into Perl5Lib so when we exec the commands below, they can
# find CmdTest::Stuff
$ENV{PERL5LIB} .= ':' . File::Basename::dirname(__FILE__)."/../..";

ok(CmdTest->isa('Command::Tree'), "CmdTest isa Command::Tree");

use_ok("CmdTest::C3");
my $path = $INC{"CmdTest/C3.pm"};
ok($path, "found path to test module")
    or die "cannot continue!";

my $result1 = `$^X \Q$path\E --thing=two`;
chomp $result1;
is($result1, "thing_id is 222", "specifying an object automatically specifies its indirect value");

my $result2 = `$^X \Q$path\E --thing-name=two`;
chomp $result2;
is($result2, "thing_id is 222", "specifying an indirect value automatically sets the value it is via");

