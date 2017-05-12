#!/usr/local/bin/perl

use strict;
use lib qw(../blib/lib);

use Text::BibTeX::BibStyle qw($RST);
use Test::More;
use FindBin;
chdir $FindBin::RealBin;

my @bbls = <latex/*.bbl>;
s!latex/(.*)\.bbl!$1! foreach @bbls;

my @tests = grep -f "rst/$_.rst", @bbls;

@tests = @ARGV if @ARGV;

plan tests => 0+@tests unless $ENV{OUTPUT};

my %options;
$options{debug} = 1 if $ENV{DEBUG};
my $bibstyle = Text::BibTeX::BibStyle->new(%options);

foreach my $test (@tests) {
    my $latex  = `cat latex/$test.bbl`;
    $latex =~ s/\n  / /g;	# Undo wrapping
    my $output = $bibstyle->convert_format($latex, $RST);
    if ($ENV{OUTPUT}) {
	print $output;
	exit;
    }
    my $exp_outs  = `cat rst/$test.rst`;
    is ($output, $exp_outs, $test);
}
