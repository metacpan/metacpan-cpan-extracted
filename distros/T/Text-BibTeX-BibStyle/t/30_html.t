#!/usr/local/bin/perl

use strict;
use lib qw(../blib/lib);

use Text::BibTeX::BibStyle qw($HTML);
use Test::More;
use FindBin;
chdir $FindBin::RealBin;

my @bbls = <latex/*.bbl>;
s!latex/(.*)\.bbl!$1! foreach @bbls;

my @tests = grep -f "html/$_.html", @bbls;

@tests = @ARGV if @ARGV;

plan tests => 0+@tests unless $ENV{OUTPUT};

my %options;
$options{debug} = 1 if $ENV{DEBUG};
my $bibstyle = Text::BibTeX::BibStyle->new(%options);

foreach my $test (@tests) {
    my $latex  = `cat latex/$test.bbl`;
    $latex =~ s/\n  / /g;	# Undo wrapping
    my $output = $bibstyle->convert_format($latex, $HTML);
    if ($ENV{OUTPUT}) {
	print $output;
	exit;
    }
    my $exp_outs  = `cat html/$test.html`;
    is ($output, $exp_outs, $test);
}
