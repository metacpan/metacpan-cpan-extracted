#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

# API call
$ms = new_ok('Text::MacroScript');
is $ms->expand("X"), "X";
$ms->define_macro('X', 123);
is $ms->expand("X"), "123";
$ms->undefine_macro('X');
is $ms->expand("X"), "X";
$ms->undefine_macro('X');
is $ms->expand("X"), "X";

$ms = new_ok('Text::MacroScript');
is $ms->expand("X"), "X";
$ms->define(-macro, 'X', 123);
is $ms->expand("X"), "123";
$ms->undefine(-macro, 'X');
is $ms->expand("X"), "X";
$ms->undefine(-macro, 'X');
is $ms->expand("X"), "X";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%UNDEFINE")};
is $@, "Error at file - line 1: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%UNDEFINE", "file.asm", 10)};
is $@, "Error at file file.asm line 10: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
eval { $ms->undefine(-xxx, "xxx") };
check_error(__LINE__-1, $@, "-xxx method not supported __LOC__.\n");

# define and undefine macro
is $ms->expand("X"), "X";
is $ms->expand("%UNDEFINE X X"), "X";
is $ms->expand("X"), "X";
is $ms->expand("%UNDEFINE X X"), "X";
is $ms->expand("X"), "X";
is $ms->expand("%DEFINE X[123]X"), "123";
is $ms->expand("%DEFINE X[123]X\\\n%UNDEFINE X X"), "123 X";

done_testing;
