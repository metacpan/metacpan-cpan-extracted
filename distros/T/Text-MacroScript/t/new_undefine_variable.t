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
is $ms->expand("#X"), "#X";
$ms->define_variable('X', 123);
is $ms->expand("#X"), "123";
$ms->undefine_variable('X');
is $ms->expand("#X"), "#X";
$ms->undefine_variable('X');
is $ms->expand("#X"), "#X";

$ms = new_ok('Text::MacroScript');
is $ms->expand("#X"), "#X";
$ms->define(-variable, 'X', 123);
is $ms->expand("#X"), "123";
$ms->undefine(-variable, 'X');
is $ms->expand("#X"), "#X";
$ms->undefine(-variable, 'X');
is $ms->expand("#X"), "#X";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%UNDEFINE_VARIABLE")};
is $@, "Error at file - line 1: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%UNDEFINE_VARIABLE", "file.asm", 10)};
is $@, "Error at file file.asm line 10: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
eval { $ms->undefine(-xxx, "xxx") };
check_error(__LINE__-1, $@, "-xxx method not supported __LOC__.\n");

# define and undefine variable
is $ms->expand("#X"), "#X";
is $ms->expand("%UNDEFINE_VARIABLE X #X"), "#X";
is $ms->expand("#X"), "#X";
is $ms->expand("%UNDEFINE_VARIABLE X #X"), "#X";
is $ms->expand("#X"), "#X";
is $ms->expand("%DEFINE_VARIABLE X[123]#X"), "123";
is $ms->expand("%DEFINE_VARIABLE X[123]#X\\\n%UNDEFINE_VARIABLE X #X"), "123 #X";

done_testing;
