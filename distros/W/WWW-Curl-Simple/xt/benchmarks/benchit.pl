#!/usr/bin/perl

use strict;
use warnings;

use Benchmark::Apps;
use File::Basename qw(basename);

my $b = Benchmark::Apps->new( pretty_print => 1, iters => shift || 10 );

my $scripts = {};
my $folder = 'xt/benchmarks/i';

opendir(I, $folder) or die "Cannot opendir $folder: $!";

my @files = grep { !/^\./ } readdir(I);
foreach (@files) {
    my $k = basename($_);
    $scripts->{$k} = $folder . "/" . $_;
}
$b->run(%$scripts);

