#!/usr/bin/perl -w

use Test::More tests => 18;

use File::Spec;
use File::Compare;
use File::Copy;

use_ok(Text::Modify);

my $input = File::Spec->catfile("t","03-modify.in");
my $tmpfile = File::Spec->catfile("t","03-modify.tmp");
my $output = File::Spec->catfile("t","03-modify.out");

print "Using file: $input $output $tmpfile\n";

my $text = new Text::Modify( file => $input, writeto => $tmpfile, 
							dryrun => 0, backup => 0, debug => 0);
isa_ok($text,"Text::Modify","Instantiate Text::Modify object");

ok($text->replace("sad","funny"),"add rule (simple)");
# Debug(2,"Error: $text->getError()") if $text->isError();
ok($text->replace("Multi","Muli"),"add rule (string multi)");
# Debug(2,"Error: $text->getError()") if $text->isError();
ok($text->replace("^#.*remove.*",""),"add rule (regex simple)");
# Debug(2,"Error: $text->getError()") if $text->isError();
ok($text->delete('removed$'),"delete line rule");
# Debug(2,"Error: $text->getError()") if $text->isError();
ok($text->defineRule(replace => '10.10.(\d+).100\s+(\w+)', with => '10.10.10.100	$2'),"add rule (regex with vars)");
# Debug(2,"Error: $text->getError()") if $text->isError();
ok($text->defineRule(replace=>'127\.0\.0\.1\s+',with=>"127.0.0.1		localhost\n",ifmissing=>'insert'),"add rule (regex + insert if missing)");
ok($text->process());
my $comp = File::Compare::compare_text($tmpfile,$output, \&compareText );
ok($comp == 0,"Comparing $tmpfile with expected output $output");
unlink($tmpfile);

my $inputtxt = <<__TXTINPUT__;
This is a first line without foo and bar
Little foobar was here hitting  foo    with a bar
/dev/null need more beer
a * is born without a .! Really?
goto /pub/; more beer

__TXTINPUT__

my $comptxt = <<__TXTCOMP__;
This is a first line without bar and bar
Big foobar was here hitting bar with a bar
/dev/null need nothing
a star is born without a dot, Really?
goto /pub/; nothing

__TXTCOMP__

my $infile = "$tmpfile.in.tmp";
my $cmpfile = "$tmpfile.cmp.tmp";
if (open(TMP,">$cmpfile")) { print TMP $comptxt; close(TMP); }
if (open(TMP,">$infile")) { print TMP $inputtxt; close(TMP); }

$text = new Text::Modify( file => $infile, writeto => $tmpfile, 
							dryrun => 0, backup => 0, debug => 1);
ok($text,"Instantiation of second test");
ok($text->replaceWildcard("more*","nothing"),"replace wildcard rule");	
ok($text->replaceString("*","star"),"replace string rule");	
ok($text->replaceString(".!","dot,"),"replace string rule");	
ok($text->replaceRegex("\\s+foo\\s+"," bar "),"replace regex rule");	
ok($text->replaceRegex("^Little","Big"),"replace regex rule");	
ok($text->process(),"Processing of rules");

$comp = File::Compare::compare_text($tmpfile,$cmpfile, \&compareText );
ok($comp == 0,"Comparing $tmpfile with expected output $output");
unlink("$tmpfile");
unlink("$infile");
unlink("$cmpfile");

sub compareText {
	my $a = shift;
	my $b = shift;
	$a =~ s/[\r\n]+$//;
	$b =~ s/[\r\n]+$//;
	# if ($a ne $b) { Debug(1,"Expected: '$a'  --> Got: '$b'"); }
	return $a ne $b;
}