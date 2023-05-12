#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;

use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
$ms->define_variable( YEAR => 2015 );
$ms->define_variable( MONTH => 'April' );
is $ms->expand("%CASE["), "";
is $ms->expand("0"), "";
is $ms->expand("]\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("yyy\n"), "";
is $ms->expand("zzz\n"), "";
is $ms->expand("%END_CASE\n"), "";

is $ms->expand("%CASE["), "";
is $ms->expand("1"), "";
is $ms->expand("]\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("yyy\n"), "";
is $ms->expand("zzz\n"), "";
is $ms->expand("%END_CASE\n"), "xxx\nyyy\nzzz\n";

is $ms->expand("%CASE[1]\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("yyy\n"), "";
is $ms->expand("zzz\n"), "";
is $ms->expand("%CASE[1]\n"), "xxx\nyyy\nzzz\n";
is $ms->expand("xxx\n"), "";
is $ms->expand("yyy\n"), "";
is $ms->expand("zzz\n"), "";
is $ms->expand("%END_CASE\n"), "xxx\nyyy\nzzz\n";

is $ms->expand("%CASE[#YEAR == 2015]\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("%END_CASE\n"), "xxx\n";

is $ms->expand("%CASE[#YEAR != 2015]\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("%END_CASE\n"), "";

is $ms->expand("%CASE[\$Var{MONTH} eq 'April']\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("%END_CASE\n"), "xxx\n";

is $ms->expand("%CASE[\$Var{MONTH} ne 'April']\n"), "";
is $ms->expand("xxx\n"), "";
is $ms->expand("%END_CASE\n"), "";

# syntax errors
$ms = new_ok('Text::MacroScript');
eval { $ms->expand("%CASE 1\n%END_CASE") };
is $@, "Error at file - line 1: Expected [EXPR]\n";

$ms = new_ok('Text::MacroScript');
eval { $ms->expand("%CASE [1+]\n%END_CASE") };
is $@, "Error at file - line 1: Eval error: syntax error\n";

$ms = new_ok('Text::MacroScript');
is $ms->expand("%CASE[1]"), "";
eval { $ms->DESTROY };
is $@, "Error at file - line 1: Unbalanced open structure at end of file\n";

done_testing;
