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
				-variable => [ 
					[ N1 => 1 ],
					[ N2 => 2 ],
				],
				-script => [ 
					[ ADD => '#0+#1' ],
				]]);

$ms->define(-script => "ADD1" => "#0+1");
$ms->define_script("ADD2", "#0+2");
is $ms->expand('%DEFINE_SCRIPT ADD3[#0+3]'), "";

is $ms->expand("ADD[ADD1[ADD2[ADD3[4]]] | 10]"), "20";

is $ms->expand("ADD[1|2] ADD1[3] ADD2[4] ADD3[5]"), "3 4 6 8";

$ms->define_variable( N3 => 3 );
$ms->define( -script => SUM => 'my $s=0;for(@Param){$s+=$_||0};$s' );
#is $ms->expand("N1 #N1 N2 #N2 N3 #N3"),	"N1 #N1 N2 #N2 N3 #N3";
is $ms->expand("N1 #N1 N2 #N2 N3 #N3"),	"N1 1 N2 2 N3 3";

is $ms->expand("%DEFINE_SCRIPT SHOW\n"),	"";
is $ms->expand("join(',', \@Param, eval('#N1')||0, eval('#N2')||0, eval('#N3')||0, ".
			   "\$Var{N1}||0, \$Var{N2}||0, \$Var{N3}||0 )\n"),	"";
is $ms->expand("%END_DEFINE\n"),			"";

is $ms->expand("SHOW\n"),					"1,2,3,1,2,3\n";
is $ms->expand("SHOW[4]\n"),				"4,1,2,3,1,2,3\n";
is $ms->expand("SHOW[4|5]\n"),				"4,5,1,2,3,1,2,3\n";

$ms->undefine_variable("N3");

is $ms->expand("SHOW\n"),					"1,2,0,1,2,0\n";
is $ms->expand("%UNDEFINE_VARIABLE N2"), "";

is $ms->expand("SHOW\n"),					"1,0,0,1,0,0\n";

is $ms->expand("%DEFINE_VARIABLE N2[2]"), "";
is $ms->expand("%DEFINE_VARIABLE N3[3]"), "";

is $ms->expand("SHOW\n"),					"1,2,3,1,2,3\n";

is $ms->expand("%UNDEFINE_ALL_VARIABLE"), "";
is $ms->expand("SHOW\n"),					"0,0,0,0,0,0\n";

$ms->define_variable( N1 => 4 );
$ms->define_variable( N2 => 5 );
$ms->define_variable( N3 => 6 );

is $ms->expand("SHOW\n"),					"4,5,6,4,5,6\n";

$ms->undefine_all(-variable);
is $ms->expand("SHOW\n"),					"0,0,0,0,0,0\n";

#------------------------------------------------------------------------------
# undefine
is $ms->expand("ADD[1|2] ADD1[3] ADD2[4] ADD3[5]"), "3 4 6 8";

$ms->undefine(-script => "ADD");
$ms->undefine(-script => "ADD1");
$ms->undefine_script("ADD2");
is $ms->expand('%UNDEFINE_SCRIPT ADD3'), "";

is $ms->expand("ADD[1|2] ADD1[3] ADD2[4] ADD3[5]"), "ADD[1|2] ADD1[3] ADD2[4] ADD3[5]";

is $ms->expand("SUM"),		"0";
is $ms->expand("SUM[]"),	"0";
is $ms->expand("SUM[1]"),	"1";
is $ms->expand("SUM[1|2]"),	"3";
is $ms->expand("SUM[1|2|3]"),"6";
is $ms->expand("%UNDEFINE_SCRIPT SUM\n"), "";
is $ms->expand("SUM"),	"SUM";

#------------------------------------------------------------------------------
# undefine_all
$ms->define(-script => S1 => 1);
$ms->define(-script => S2 => 2);
$ms->define(-script => S3 => 3);
is $ms->expand("S1S2S3"),	"123";
$ms->undefine_all('-script');
is $ms->expand("S1S2S3"),	"S1S2S3";

$ms->define(-script => S1 => 1);
$ms->define(-script => S2 => 2);
$ms->define(-script => S3 => 3);
is $ms->expand("S1S2S3"),	"123";
is $ms->expand("%UNDEFINE_ALL_SCRIPT\n"),	"";
is $ms->expand("S1S2S3"),	"S1S2S3";

#------------------------------------------------------------------------------
# list
$ms = new_ok('Text::MacroScript' => [ 
				-script => [ 
					[ N1 => 1 ],
					[ N2 => 2 ],
				]]);
my @output;

@output = $ms->list(-script, -namesonly);
is_deeply \@output, ["%DEFINE_SCRIPT N1\n", 
					 "%DEFINE_SCRIPT N2\n"];

@output = $ms->list(-script);
is_deeply \@output, ["%DEFINE_SCRIPT N1 [1]\n", 
					 "%DEFINE_SCRIPT N2 [2]\n"];

($out,$err,@res) = capture { void { $ms->list(-script, -namesonly); } };
eq_or_diff $out, "%DEFINE_SCRIPT N1\n".
				 "%DEFINE_SCRIPT N2\n";
is $err, "";
is_deeply \@res, [];

($out,$err,@res) = capture { void { $ms->list(-script); } };
eq_or_diff $out, "%DEFINE_SCRIPT N1 [1]\n".
				 "%DEFINE_SCRIPT N2 [2]\n";
is $err, "";
is_deeply \@res, [];

@output = $ms->list_script(-namesonly);
is_deeply \@output, ["%DEFINE_SCRIPT N1\n", 
					 "%DEFINE_SCRIPT N2\n"];

@output = $ms->list_script();
is_deeply \@output, ["%DEFINE_SCRIPT N1 [1]\n", 
					 "%DEFINE_SCRIPT N2 [2]\n"];

($out,$err,@res) = capture { void { $ms->list_script(-namesonly); } };
eq_or_diff $out, "%DEFINE_SCRIPT N1\n".
				 "%DEFINE_SCRIPT N2\n";
is $err, "";
is_deeply \@res, [];

($out,$err,@res) = capture { void { $ms->list_script(); } };
eq_or_diff $out, "%DEFINE_SCRIPT N1 [1]\n".
				 "%DEFINE_SCRIPT N2 [2]\n";
is $err, "";
is_deeply \@res, [];

#------------------------------------------------------------------------------
# undefine_all
for (1..3) {
	$ms->define_script("N$_", $_);
}
is $ms->expand("N1N2N3"), 			"123";
$ms->undefine_all(-script);
is $ms->expand("N1N2N3"), 			"N1N2N3";

for (1..3) {
	$ms->define_script("N$_", $_);
}
is $ms->expand("N1N2N3"), 			"123";
$ms->undefine_all_script;
is $ms->expand("N1N2N3"), 			"N1N2N3";

for (1..3) {
	$ms->define_script("N$_", $_);
}
is $ms->expand("N1N2N3"), 			"123";
is $ms->expand("%UNDEFINE_ALL_SCRIPT"), "";
is $ms->expand("N1N2N3"), 			"N1N2N3";

#------------------------------------------------------------------------------
diag 'Issue #7: expansion depends on size of script name';
$ms = new_ok('Text::MacroScript' => [ 
				-script => [ 
					[ "hello"	=> "'Hallo'" ],
					[ "Z1"		=> "'hel'" ],
					[ "Z2"		=> "'lo'" ],
				]]);
is $ms->expand("hello Z1 Z2\n"),	 	"Hallo hel lo\n";
is $ms->expand("Z1Z2\n"),	 			"hello\n";
$ms = new_ok('Text::MacroScript' => [ 
				-script => [ 
					[ "ZZZZZ1"	=> "'hel'" ],
					[ "ZZZZZ2"	=> "'lo'" ],
					[ "hello"	=> "'Hallo'" ],
				]]);
is $ms->expand("hello ZZZZZ1 ZZZZZ2\n"),"Hallo hel lo\n";
is $ms->expand("ZZZZZ1ZZZZZ2\n"),		"hello\n";

#------------------------------------------------------------------------------
# scripts with regexp-special-chars
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT MUL ['*']\n"),"";
is $ms->expand("2MUL4\n"), "2*4\n";

#------------------------------------------------------------------------------
# scripts with arguments
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT * [#0+#1+#2+#3+#4+#5+#6+#7+#8+#9+#10]\n"),	"";
eval {$ms->expand("*\n")};
is $@, "Error at file - line 1: Missing parameters\n";
is $ms->expand("%DEFINE_SCRIPT * [#0+#1]"),	"";
is $ms->expand("*[0|1]"),				"1";
is $ms->expand("*[ 0 | 1 ]"),			"1";
is $ms->expand("*[0|1|2]"),				"1";

is $ms->expand("%DEFINE_SCRIPT * [\"#0+\\#ffff\"]"),	"";
is $ms->expand("*[1]\n"),				"1+#ffff\n";

#------------------------------------------------------------------------------
# multi-line define
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT *"),			"";
is $ms->expand("\"line 1: #0 \"."),			"";
is $ms->expand("\"line 2: #1 \"."),			"";
is $ms->expand("\"line 3: #2 \";"),			"";
is $ms->expand("%END_DEFINE"),				"";
is $ms->expand("*[a|b|c]"),					"line 1: a line 2: b line 3: c ";

#------------------------------------------------------------------------------
# escape # inside script
$ms = new_ok('Text::MacroScript');
is $ms->expand("%DEFINE_SCRIPT * ['\\#0']\n"),"";
is $ms->expand("2*4\n"),			"2#04\n";

#------------------------------------------------------------------------------
# expand variables in scripts
$ms = new_ok('Text::MacroScript');
$ms->define_variable(YEAR => 2015);
$ms->define(-script => SHOW => '"\\#YEAR = #YEAR"');
is $ms->expand("SHOW"), "#YEAR = 2015";

done_testing;
