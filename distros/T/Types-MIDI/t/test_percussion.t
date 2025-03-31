#!/usr/bin/env perl

use Test2::V0;
use FindBin qw($Bin);
use lib "$Bin/./lib";
use TestPercussion;

plan 2;

subtest snare => sub {
    my $drum = TestPercussion->new();
    isa_ok $drum, ['TestPercussion'], 'test object wants to work';
    can_ok $drum, ['hit'], 'we can bang its drum all day';

    is $drum->hit, 38, 'hit an acoustic snare by default';
    $drum->percussion('Electric Snare');
    is $drum->hit, 40, 'now hitting an electric snare';
};

subtest cowbell => sub {
    my $funky_cowbell
        = TestPercussion->new( percussion => 'cOwBeLl' );
    is $funky_cowbell->hit, 56, 'gotta have more cowbell';
};
