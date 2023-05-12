#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
$ms->define_variable("A", "1");
$ms->define_variable("AA", "2");
is $ms->expand("#AAA"), "2A";
is $ms->expand("#AA"), "2";
is $ms->expand("#A"), "1";
is $ms->expand("#"), "#";

done_testing;
