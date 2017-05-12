#!/usr/local/bin/perl

use strict;
use lib qw(../blib/lib);

use Text::BibTeX::BibStyle qw($LATEX);
use Test::More;
use FindBin;
chdir $FindBin::RealBin;

my @bsts = <bibstyle/*.bst>;
s!bibstyle/(.*)\.bst!$1! foreach @bsts;

my @tests = grep -f "latex/$_.bbl", @bsts;

@tests = @ARGV if @ARGV;

plan tests => 0+@tests unless $ENV{OUTPUT};

my %options;
$options{debug} = 1 if $ENV{DEBUG};
my $bibstyle = Text::BibTeX::BibStyle->new(%options);

$ENV{BIBINPUTS} = 'bibs';
$ENV{BSTINPUTS}  = 'bibstyle';

foreach my $test (@tests) {
    $bibstyle->read_bibstyle($test);
    {
	local $SIG{__WARN__} = sub {
	    my ($str) = @_;
	    die $str unless @{$bibstyle->{warnings}} && do{
		my $warn = $bibstyle->{warnings}[-1];
		chomp $warn;
		index($str, $warn) == 0;
	    }
	    };
	$bibstyle->execute([qw(xampl)]);
    }
    my @warns     = $bibstyle->warnings;
    my $warns     = join '', @warns;
    my $exp_warns = `grep Warning latex/$test.blg`;
    $exp_warns    =~ s/^\# //gm;
    my $output    = $bibstyle->get_output($LATEX);
    if ($ENV{OUTPUT}) {
	print $output;
	exit;
    }
    my $exp_outs  = `cat latex/$test.bbl`;
    my @stack     = map $bibstyle->_format_token($_), @{$bibstyle->{stack}};
    is ("$warns\n$output", "$exp_warns\n$exp_outs", $test);
}
