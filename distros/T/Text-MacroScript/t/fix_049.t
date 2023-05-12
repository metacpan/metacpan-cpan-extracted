#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE ADD [#0+#1]ADD[1|2]"), "1+2";
eval { $ms->expand("ADD[]") };
is $@, "Error at file - line 1: Missing parameters\n";
eval { $ms->expand("ADD[1]") };
is $@, "Error at file - line 1: Missing parameters\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT ADD [#0+#1]ADD[1|2]"), "3";
eval { $ms->expand("ADD[]") };
is $@, "Error at file - line 1: Missing parameters\n";
eval { $ms->expand("ADD[1]") };
is $@, "Error at file - line 1: Missing parameters\n";

done_testing;
