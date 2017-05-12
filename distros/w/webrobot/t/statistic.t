#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::Statistic;
use Test::More qw/no_plan/;

my $EPS = 0.00001;
my $test = "1";

t([qw/3 4 5/], "3 4 5",
  mean=>4, quad_mean=>4.08248290463863, standard_deviation=>1);
t([qw/3  6 4 5/], "3 6 4 5",
  mean=>4.5, quad_mean=>4.63680924774785, standard_deviation=>1.29099444873581, median=>4.5);
t([qw/5 4 1 3 2/], "5 4 1 3 2",
  mean=>3, quad_mean=>3.3166247903554, standard_deviation=>1.58113883008419, median=>3);
t([qw/5 10 20/], "(5 10 20) Median: Check that values are taken numerically instead of lexically",
  median=>10);

sub t {
    my ($elem) = shift;
    my ($title) = shift;
    my %result = (@_);
    my $stat = WWW::Webrobot::Statistic->new(extended => (exists $result{median}) ? 1 : 0);
    $stat->add($_) foreach (@$elem);
    foreach (keys %result) {
        ok(abs($stat->$_() - $result{$_}) < $EPS, "($test): $title ($_)") ||
            diag("$_: given=" . $stat->$_() . " expected=$result{$_}");
    }
    $test++;
}

1;
