#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Test::Mail;

BEGIN: { use_ok('Test::Mail', "use Test::Mail"); }
my $tm = Test::Mail->new(logfile => "t/testmail.log");
ok($tm, "new returns true");
ok($tm->isa("Test::Mail"), "\$tm is a Test::Mail object");


