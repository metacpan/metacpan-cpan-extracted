#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

sub _define {
	$ms->define_variable('A', 1); 
	$ms->define_variable('B', 2);
}

# API call
$ms = new_ok('Text::MacroScript');
is $ms->expand("#A#B"), "#A#B";
_define;
is $ms->expand("#A#B"), "12";

$ms->undefine_all_variable;
is $ms->expand("#A#B"), "#A#B";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->undefine_all()};
check_error(__LINE__-1, $@, " method not supported __LOC__.\n");

# %UNDEFINE_ALL_VARIABLE
$ms = new_ok('Text::MacroScript');
is $ms->expand("#A#B"), "#A#B";
_define;
is $ms->expand("#A#B"), "12";
is $ms->expand("%UNDEFINE_ALL_VARIABLE #A#B"), "#A#B";

done_testing;
