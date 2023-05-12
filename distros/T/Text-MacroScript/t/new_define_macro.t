#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

# API call
$ms = new_ok('Text::MacroScript');
$ms->define_variable('X', 'HELLO');
$ms->define_macro('X', '#X');
is $ms->expand("X"), "HELLO";

$ms->define(-variable, 'X', 'WORLD');
$ms->define(-macro, 'X', '#X');
is $ms->expand("X"), "WORLD";

# constructor definition
$ms = new_ok('Text::MacroScript', [-macro => [ [A => 'HELLO'], [B => 'WORLD'] ] ]);
is $ms->expand("AB"), "HELLOWORLD";
is $ms->expand("A B"), "HELLO WORLD";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE")};
is $@, "Error at file - line 1: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE", "file.asm", 10)};
is $@, "Error at file file.asm line 10: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE*X*"), "";
eval { $ms->DESTROY };
is $@, "Error at file - line 1: Unbalanced open structure at end of file\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE*X*["), "";
eval { $ms->DESTROY };
is $@, "Error at file - line 1: Unbalanced open structure at end of file\n";

# multi-line definition with [] and counting of []
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE*X*["), "";
is $ms->expand("q[hello]"), "";
is $ms->expand("]*X*"), "q[hello]";

# multi-line definition with %END_DEFINE
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE*X*"), "";
is $ms->expand("q[hello]"), "";
is $ms->expand("%END_DEFINE*X*"), "q[hello]";

# macros with parameters in #0..N 
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE ADD [#0+#1]"), "";
is $ms->expand("ADD[1|2]"), "1+2";

# escape |
is $ms->expand("ADD[1\\|2"), ""; # (1 | 2) = 3
is $ms->expand(" | 8]"), "1|2 + 8";

# wrong number of parameters
eval { $ms->expand("ADD[]") };
is $@, "Error at file - line 1: Missing parameters\n";
eval { $ms->expand("ADD[1]") };
is $@, "Error at file - line 1: Missing parameters\n";

# extra parameters are ignored
is $ms->expand("ADD[1|2|3]"), "1+2";

# call macros in macro arguments
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE ADD [#0+#1]"), "";
is $ms->expand("ADD[1|2]"), "1+2";
is $ms->expand("ADD[ ADD[1|2] | ADD[3|4] ]"), " 1+2 + 3+4 ";

# macros accessing variables with #var and in %Var
$ms = new_ok('Text::MacroScript');
is $ms->expand('%DEFINE_VARIABLE MULT [10]'), "";
is $ms->expand('%DEFINE SCALE [#0*#MULT]SCALE[12]'), "12*10";

# macros that modify variables
$ms = new_ok('Text::MacroScript');
is $ms->expand('%DEFINE_VARIABLE COUNT [0]'), "";
is $ms->expand('%DEFINE INC'), "";
is $ms->expand('%DEFINE_VARIABLE COUNT [#COUNT+1]'), "";
is $ms->expand('#COUNT'), "";
is $ms->expand('%END_DEFINE'), "";

is $ms->expand('INC#COUNT'), "11";
is $ms->expand('INC#COUNT'), "22";
is $ms->expand('INC#COUNT'), "33";

done_testing;
