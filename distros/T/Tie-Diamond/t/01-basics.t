#!perl

use 5.010;
use strict;
use warnings;
use syntax 'each_on_array';

use File::Slurp::Tiny qw(write_file);
use File::Temp qw(tempfile);
use Test::More 0.98;
use Tie::Diamond;

my ($fh, $filename) = tempfile();
write_file($filename, "a\n\nc\n");

subtest "basics" => sub {
    local @ARGV = ($filename);
    tie my(@a), "Tie::Diamond" or die;
    my @res;
    while (my ($idx, $item) = each @a) { push @res, [$idx, $item] }
    is_deeply(\@res, [[0, "a\n"], [1, "\n"], [2, "c\n"]], "iterate result");
};

subtest "chomp=1" => sub {
    local @ARGV = ($filename);
    tie my(@a), "Tie::Diamond", {chomp=>1} or die;
    my @res;
    while (my ($idx, $item) = each @a) { push @res, [$idx, $item] }
    is_deeply(\@res, [[0, "a"], [1, ""], [2, "c"]], "iterate result");
};

done_testing;
