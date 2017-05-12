#!/usr/bin/env perl

use feature qw(say);

use VM::JiffyBox;
use Data::Dumper;

unless ($ARGV[0]) {
    say 'Token as first argument needed!';
}

my $jiffy = VM::JiffyBox->new(token => $ARGV[0]);
my $dists = $jiffy->get_distributions;

print Dumper $dists;

