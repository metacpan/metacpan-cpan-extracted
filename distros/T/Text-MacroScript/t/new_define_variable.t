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
$ms->define_variable('X', 123);
is $ms->expand("#X"), "123";

$ms->define(-variable, 'X', 321);
is $ms->expand("#X"), "321";

# constructor definition
$ms = new_ok('Text::MacroScript', [-variable => [ [A => 1], [B => 2] ] ]);
is $ms->expand("#A#B"), "12";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE_VARIABLE")};
is $@, "Error at file - line 1: Expected NAME [EXPR]\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE_VARIABLE", "file.asm", 10)};
is $@, "Error at file file.asm line 10: Expected NAME [EXPR]\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE_VARIABLE*HELLO*")};
is $@, "Error at file - line 1: Expected NAME [EXPR]\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_VARIABLE*HELLO*["), "";
eval { $ms->DESTROY };
is $@, "Error at file - line 1: Unbalanced open structure at end of file\n";

$ms = new_ok('Text::MacroScript');
eval { $ms->expand("%DEFINE_VARIABLE*HELLO*[1|2]") };
is $@, "Error at file - line 1: Only one argument expected\n";

$ms = new_ok('Text::MacroScript');
eval { $ms->define(-xxx, "xxx", "ZZZ") };
check_error(__LINE__-1, $@, "-xxx method not supported __LOC__.\n");

# variable expansion
$ms = new_ok('Text::MacroScript');
is $ms->expand(" %DEFINE_VARIABLE*HELLO*[1+]"), "";
is $ms->expand("*HELLO*"), "*HELLO*";
is $ms->expand("#*HELLO"), "#*HELLO";
is $ms->expand("#*HELLO*"), "1+";
is $ms->expand("\\#*HELLO*"), "#*HELLO*";
is $ms->expand("#*HELLO*#*HELLO*"), "1+1+";
is $ms->expand("#*HELLO* ## #*HELLO*"), "1+1+";

# arithmetic expressions
is $ms->expand("%DEFINE_VARIABLE*HELLO*[1+2]#*HELLO*"), "3";

# perl expressions
is $ms->expand("%DEFINE_VARIABLE hello [ola]#hello"), "ola";
is $ms->expand("%DEFINE_VARIABLE HELLO [uc('#hello')]#HELLO"), "OLA";

# self referencing variable
is $ms->expand("%DEFINE_VARIABLEX[#X+1]#X"), "1";
is $ms->expand("%DEFINE_VARIABLEX[#X+1]#X"), "2";
is $ms->expand("%DEFINE_VARIABLEX[#X+1]#X"), "3";

# multiple line value and counting of []
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_VARIABLE X ["), "";
is $ms->expand("[hello"), "";
is $ms->expand("|"), "";
is $ms->expand("world]"), "";
is $ms->expand("]#X"), "[hello|world]";

# escape [ | ]
is $ms->expand("%DEFINE_VARIABLE X [a\\[b]#X"), "a[b";
is $ms->expand("%DEFINE_VARIABLE X [a\\|b]#X"), "a|b";
is $ms->expand("%DEFINE_VARIABLE X [a\\]b]#X"), "a]b";

done_testing;
