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
	$ms->define_script('A', 1); 
	$ms->define_script('B', 2);
	$ms->define_macro('X', 8); 
	$ms->define_macro('Y', 9);
}

# API call
$ms = new_ok('Text::MacroScript');
is $ms->expand("ABXY"), "ABXY";
_define;
is $ms->expand("ABXY"), "1289";

$ms->undefine_all_script;
is $ms->expand("ABXY"), "AB89";

_define;
$ms->undefine_all(-script);
is $ms->expand("ABXY"), "AB89";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->undefine_all()};
check_error(__LINE__-1, $@, " method not supported __LOC__.\n");

# %UNDEFINE_ALL_SCRIPT
$ms = new_ok('Text::MacroScript');
is $ms->expand("ABXY"), "ABXY";
_define;
is $ms->expand("ABXY"), "1289";
is $ms->expand("%UNDEFINE_ALL_SCRIPT ABXY"), "AB89";

done_testing;
