#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot;

push @INC, "t/var_expand";

my $DIR = "t/var_expand";
my $cfg_name = "$DIR/cfg.prop";
my $test_plan_name = "$DIR/testplan.xml";

my $webrobot = WWW::Webrobot -> new(\$cfg_name);
my $exit = $webrobot -> run(\$test_plan_name);

exit $exit;

1;
