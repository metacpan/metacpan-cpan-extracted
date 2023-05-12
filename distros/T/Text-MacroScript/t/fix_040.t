#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

use_ok 'Text::MacroScript';

my $ms;

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_VARIABLE N1 [#N1+1]#N1"), "1";
is $ms->expand("%DEFINE_VARIABLE N1 [#N1+1]#N1"), "2";
is $ms->expand("%DEFINE_VARIABLE N1 [#N1+1]#N1"), "3";

done_testing;
