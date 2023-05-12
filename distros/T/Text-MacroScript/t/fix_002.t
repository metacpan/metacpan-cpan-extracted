#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_VARIABLE X ["), "";
is $ms->expand("[hello"), "";
is $ms->expand("|"), "";
is $ms->expand("world]"), "";
is $ms->expand("]#X"), "[hello|world]";

done_testing;
