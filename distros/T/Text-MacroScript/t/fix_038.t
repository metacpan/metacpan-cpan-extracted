#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
$ms->define_variable("A", 10);
$ms->define_variable("B", "#A+1");
is $ms->expand("#B"), "11";

done_testing;
