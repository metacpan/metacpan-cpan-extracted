#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
eval { $ms->expand("%CASE 1\n%END_CASE") };
is $@, "Error at file - line 1: Expected [EXPR]\n";
eval { $ms->expand("%CASE [1+]\n%END_CASE") };
is $@, "Error at file - line 1: Eval error: syntax error\n";

done_testing;
