#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

# -comment
$ms = new_ok('Text::MacroScript' => [ -comment => 1 ]);
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";

# %DEFINE
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE %% []"), "";
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";

# define()
$ms = new_ok('Text::MacroScript');
$ms->define_macro("%%", "");
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";

# %CASE
$ms = new_ok('Text::MacroScript');
is $ms->expand("hello\n"), 		"hello\n";
is $ms->expand("%CASE[0]\n"),	"";
is $ms->expand("this is\n"),	"";
is $ms->expand("a comment\n"),	"";
is $ms->expand("%END_CASE\n"),	"";
is $ms->expand("world\n"), 		"world\n";

# -comment and %UNDEFINE_ALL
$ms = new_ok('Text::MacroScript' => [ -comment => 1 ]);
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";
$ms->undefine_all_macro;
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";

$ms = new_ok('Text::MacroScript' => [ -comment => 1 ]);
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";
is $ms->expand("%UNDEFINE_ALL"), "";
is $ms->expand("hello%%[this|is|a|comment]world\n"), "helloworld\n";

done_testing;
