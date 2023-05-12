#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Capture::Tiny 'capture';
use Test::Differences;
use Test::More;

my $ms;
my($out,$err,@res);

use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

sub void(&) { $_[0]->(); () }

#------------------------------------------------------------------------------
# define
$ms = new_ok('Text::MacroScript' => [ 
				-macro => [ 
					[ "hello" => "Hallo" ],
					[ "world" => "Welt" ],
				]]);
$ms->define(-macro => "N1" => "25");
$ms->define_macro("N2", 26);
is $ms->expand('%DEFINE N3[27]'), "";

is $ms->expand("\n"), 		"\n";
is $ms->expand("helloN1N2N3world\n"), 	"Hallo252627Welt\n";

is $ms->expand("%DEFINE ZZ [zx]\n"), 	"";
is $ms->expand("%DEFINE zx [spectrum]\n"),"";

is $ms->expand("hello ZZ\n"), 			"Hallo spectrum\n";

is $ms->expand("%DEFINE Z1 [hel]\n"),	"";
is $ms->expand("%DEFINE Z2 [lo]\n"),	"";
is $ms->expand("%DEFINE EVAL [#0]\n"),	"";

is $ms->expand("Z1\n"),	 				"hel\n";
is $ms->expand("EVAL[Z1]\n"),			"hel\n";
is $ms->expand("Z1Z2\n"),	 			"hello\n";
diag 'Issue #1: expansion depends on size of macro name';
#is $ms->expand("EVAL[Z1Z2]\n"),			"Hallo\n";


#------------------------------------------------------------------------------
# undefine
is $ms->expand("N1N2N3"), 			"252627";

$ms->undefine(-macro => "N1");
$ms->undefine_macro("N2");
is $ms->expand('%UNDEFINE N3'), "";

is $ms->expand("N1N2N3"), 			"N1N2N3";

is $ms->expand("%DEFINE N [nn]\nNN\n%UNDEFINE N\nNN\n"), "nnnn\nNN\n";


#------------------------------------------------------------------------------
# list
$ms = new_ok('Text::MacroScript' => [ 
				-macro => [ 
					[ N1 => 1 ],
					[ N2 => 2 ],
				]]);
my @output;

@output = $ms->list(-macro, -namesonly);
is_deeply \@output, ["%DEFINE N1\n", 
					 "%DEFINE N2\n"];

@output = $ms->list(-macro);
is_deeply \@output, ["%DEFINE N1 [1]\n", 
					 "%DEFINE N2 [2]\n"];

($out,$err,@res) = capture { void { $ms->list(-macro, -namesonly); } };
eq_or_diff $out, "%DEFINE N1\n".
				 "%DEFINE N2\n";
is $err, "";
is_deeply \@res, [];

($out,$err,@res) = capture { void { $ms->list(-macro); } };
eq_or_diff $out, "%DEFINE N1 [1]\n".
				 "%DEFINE N2 [2]\n";
is $err, "";
is_deeply \@res, [];

@output = $ms->list_macro(-namesonly);
is_deeply \@output, ["%DEFINE N1\n", 
					 "%DEFINE N2\n"];

@output = $ms->list_macro();
is_deeply \@output, ["%DEFINE N1 [1]\n", 
					 "%DEFINE N2 [2]\n"];

($out,$err,@res) = capture { void { $ms->list_macro(-namesonly); } };
eq_or_diff $out, "%DEFINE N1\n".
				 "%DEFINE N2\n";
is $err, "";
is_deeply \@res, [];

($out,$err,@res) = capture { void { $ms->list_macro(); } };
eq_or_diff $out, "%DEFINE N1 [1]\n".
				 "%DEFINE N2 [2]\n";
is $err, "";
is_deeply \@res, [];

#------------------------------------------------------------------------------
# undefine_all
for (1..3) {
	$ms->define_macro("N$_", $_);
}
is $ms->expand("N1N2N3"), 			"123";
$ms->undefine_all(-macro);
is $ms->expand("N1N2N3"), 			"N1N2N3";

for (1..3) {
	$ms->define_macro("N$_", $_);
}
is $ms->expand("N1N2N3"), 			"123";
$ms->undefine_all_macro;
is $ms->expand("N1N2N3"), 			"N1N2N3";

for (1..3) {
	$ms->define_macro("N$_", $_);
}
is $ms->expand("N1N2N3"), 			"123";
is $ms->expand("%UNDEFINE_ALL"), 	"";
is $ms->expand("N1N2N3"), 			"N1N2N3";

#------------------------------------------------------------------------------
diag 'Issue #1: expansion depends on size of macro name';
$ms = new_ok('Text::MacroScript' => [ 
				-macro => [ 
					[ "hello"	=> "Hallo" ],
					[ "Z1"		=> "hel" ],
					[ "Z2"		=> "lo" ],
				]]);
is $ms->expand("hello Z1 Z2\n"),	 	"Hallo hel lo\n";
#is $ms->expand("Z1Z2\n"),	 			"Hallo\n";
$ms = new_ok('Text::MacroScript' => [ 
				-macro => [ 
					[ "ZZZZZ1"	=> "hel" ],
					[ "ZZZZZ2"	=> "lo" ],
					[ "hello"	=> "Hallo" ],
				]]);
is $ms->expand("hello ZZZZZ1 ZZZZZ2\n"),"Hallo hel lo\n";
is $ms->expand("ZZZZZ1ZZZZZ2\n"),		"hello\n";

#------------------------------------------------------------------------------
# macros with regexp-special-chars
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE * [star]\n"),"";
is $ms->expand("2*4\n"),			"2star4\n";

#------------------------------------------------------------------------------
# macros with arguments
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE * [#0+#1+#2+#3+#4+#5+#6+#7+#8+#9+#10]\n"),	"";
eval {$ms->expand("*\n")};
is $@, "Error at file - line 1: Missing parameters\n";
is $ms->expand("%DEFINE * [#0+#1]\n"),	"";
is $ms->expand("*[0|1]\n"),				"0+1\n";
is $ms->expand("*[ 0 | 1 ]\n"),			" 0 + 1 \n";
is $ms->expand("*[0|1|2]\n"),			"0+1\n";

is $ms->expand("%DEFINE * [#0+\#ffff]\n"),	"";
is $ms->expand("*[1]\n"),				"1+#ffff\n";

#------------------------------------------------------------------------------
# multi-line define
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE *\n"),			"";
is $ms->expand("line 1: #0\n"),			"";
is $ms->expand("line 2: #1\n"),			"";
is $ms->expand("line 3: #2\n"),			"";
is $ms->expand("%END_DEFINE\n"),		"";
is $ms->expand("*[a|b|c]\n"),			"line 1: a\nline 2: b\nline 3: c\n\n";

#------------------------------------------------------------------------------
# expand variables in all input text
$ms = new_ok('Text::MacroScript');
$ms->define_variable(YEAR => 2015);
is $ms->expand('\\#YEAR = #YEAR'), "#YEAR = 2015";


#------------------------------------------------------------------------------
# expand variables in macros
$ms = new_ok('Text::MacroScript');
$ms->define_variable(YEAR => 2015);
$ms->define_macro(SHOW => '\\#YEAR = #YEAR');
is $ms->expand("SHOW"), "#YEAR = 2015";

done_testing;
