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
$ms->define_script('X', 'uc("hello")');
is $ms->expand("X"), "HELLO";

$ms->define(-script, 'X', 'uc("world")');
is $ms->expand("X"), "WORLD";

# constructor definition
$ms = new_ok('Text::MacroScript', [-script => [ [A => 'uc("hello")'], [B => 'uc("world")'] ] ]);
is $ms->expand("AB"), "HELLOWORLD";
is $ms->expand("A B"), "HELLO WORLD";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE_SCRIPT")};
is $@, "Error at file - line 1: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
eval {$ms->expand("%DEFINE_SCRIPT", "file.asm", 10)};
is $@, "Error at file file.asm line 10: Expected NAME\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT*X*"), "";
eval { $ms->DESTROY };
is $@, "Error at file - line 1: Unbalanced open structure at end of file\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT*X*["), "";
eval { $ms->DESTROY };
is $@, "Error at file - line 1: Unbalanced open structure at end of file\n";

# multi-line definition with [] and counting of []
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT*X*["), "";
is $ms->expand("uc q[hello]"), "";
is $ms->expand("]*X*"), "HELLO";

# multi-line definition with %END_DEFINE
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT*X*"), "";
is $ms->expand("uc q[hello]"), "";
is $ms->expand("%END_DEFINE*X*"), "HELLO";

# scripts with parameters in #0..N 
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT ADD [#0+#1]"), "";
is $ms->expand("ADD[1|2]"), "3";

# escape |
is $ms->expand("ADD[1\\|2"), ""; # (1 | 2) = 3
is $ms->expand(" | 8]"), "11";

# wrong number of parameters
eval { $ms->expand("ADD[]") };
is $@, "Error at file - line 1: Missing parameters\n";
eval { $ms->expand("ADD[1]") };
is $@, "Error at file - line 1: Missing parameters\n";

# extra parameters are ignored
is $ms->expand("ADD[1|2|3]"), "3";

# call scripts in script arguments
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT ADD [#0+#1]"), "";
is $ms->expand("ADD[1|2]"), "3";
is $ms->expand("ADD[ ADD[1|2] | ADD[3|4] ]"), "10";

# scripts with parameters in @Param
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT ADD"), "";
is $ms->expand('my $sum=0; $sum += ($_||0) for @Param; $sum'), "";
is $ms->expand("%END_DEFINE"), "";
is $ms->expand("ADD"), "0";
is $ms->expand("ADD[]"), "0";
is $ms->expand("ADD[1]"), "1";
is $ms->expand("ADD[1|2]"), "3";
is $ms->expand("ADD[1|2|3]"), "6";
is $ms->expand("ADD[1|2|3|4]"), "10";

# count parameters
$ms = new_ok('Text::MacroScript');
is $ms->expand('%DEFINE_SCRIPT SHOW[scalar(@Param)]'), "";
is $ms->expand("SHOW"), "0";
is $ms->expand("SHOW[]"), "1";
is $ms->expand("SHOW[1]"), "1";
is $ms->expand("SHOW[1|2]"), "2";

# show parameters
is $ms->expand('%DEFINE_SCRIPT SHOW["$Param[0]"]'), "";
is $ms->expand("SHOW[]"), "";
is $ms->expand("SHOW[1]"), "1";
is $ms->expand("SHOW[ 1"), "";
is $ms->expand(" ]"), " 1 ";

# scripts accessing variables with #var and in %Var
$ms = new_ok('Text::MacroScript');
is $ms->expand('%DEFINE_VARIABLE MULT [10]'), "";
is $ms->expand('%DEFINE_SCRIPT SCALE [ #0 * #MULT      ]SCALE[12]'), "120";
is $ms->expand('%DEFINE_SCRIPT SCALE [ #0 * $Var{MULT} ]SCALE[12]'), "120";

# scripts that modify variables in %Var
$ms = new_ok('Text::MacroScript');
is $ms->expand('%DEFINE_VARIABLE COUNT [0]'), "";
is $ms->expand('%DEFINE_SCRIPT INC [ ++$Var{COUNT} ]INC#COUNT'), "11";
is $ms->expand('%DEFINE_SCRIPT INC [ ++$Var{COUNT} ]INC#COUNT'), "22";
is $ms->expand('%DEFINE_SCRIPT INC [ ++$Var{COUNT} ]INC#COUNT'), "33";

done_testing;
