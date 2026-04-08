#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Timer::Wheel;

subtest 'group tagging' => sub {
    my $tw = new Timer::Wheel;
    my @fired;

    $tw->at(100, sub { push @fired, 'net1' }, group => 'network');
    $tw->at(200, sub { push @fired, 'net2' }, group => 'network');
    $tw->at(150, sub { push @fired, 'disk' }, group => 'disk');
    $tw->at(175, sub { push @fired, 'none' });

    is($tw->pending, 4, '4 timers');

    my $count = $tw->cancel_group('network');
    is($count, 2, 'cancel_group returns 2');
    is($tw->pending, 2, '2 remaining');

    $tw->tick(300);
    is_deeply(\@fired, [qw(disk none)], 'only non-network timers fire');
};

subtest 'cancel_group with no matches' => sub {
    my $tw = new Timer::Wheel;
    $tw->at(100, sub {}, group => 'a');
    is($tw->cancel_group('zzz'), 0, 'cancel_group returns 0 for unknown group');
    is($tw->pending, 1, 'timer still there');
};

subtest 'cancel_group on ungrouped timers' => sub {
    my $tw = new Timer::Wheel;
    $tw->at(100, sub {});
    $tw->at(200, sub {});
    is($tw->cancel_group('any'), 0, 'ungrouped timers unaffected');
    is($tw->pending, 2, 'both still pending');
};

done_testing;
