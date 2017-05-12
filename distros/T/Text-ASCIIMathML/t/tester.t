#!/usr/local/bin/perl5.8.8

use strict;
use warnings;

use Test::More;
use lib '../blib/lib';
use lib 'blib/lib';
use Text::ASCIIMathML;
use lib 't';
use Entities;

use vars qw($opt_l);

use Getopt::Long;
Getopt::Long::config('no_ignore_case');
exit unless GetOptions qw(l);

@ARGV = <*.math t/*.math> unless @ARGV;

my @lines = <>;
my $lines = join '', grep(! /^\s*\#/, @lines);
my @tests = split /^\?[ \t]*/m, $lines;
shift @tests;
my @latex_tests = grep /\$/, @tests;

plan tests => @tests+@latex_tests;

my @attr = (mathcolor=>"red", displaystyle=>"true", fontfamily=>"serif");
# Do the tests
my $parser = new Text::ASCIIMathML;
$parser->SetAttribute(ForMoz=>1);
TEST:
foreach my $test (@tests) {
    my ($input, $outputs) = split /\n/, $test, 2;
    my ($mathml, $latex) = $outputs =~ /(.*?)(\$.*)?$/s;
    $mathml =~ s/\n *//g;
    $mathml = MathML::Entities::name2numbered($mathml);
    $mathml =~ s/(&\#x)0([\da-f]{4};)/$1$2/ig;
    is ($parser->TextToMathML($input, [title=>$input], \@attr),
	$mathml, qq(mathml "$input"));
    if ($latex) {
	$latex =~ s/\n+$//;
	my $t = $parser->TextToMathMLTree($input, undef, \@attr);
	is ($t->latex($parser), $latex, qq(latex "$input"));
    }
    elsif ($opt_l) {
	my $t = $parser->TextToMathMLTree($input, undef, \@attr);
	print STDERR qq($input\n);
	print STDERR $t->latex(),"\n" if $t;
    }
}
