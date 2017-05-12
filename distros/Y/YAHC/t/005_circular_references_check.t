#!/usr/bin/env perl

use strict;
use warnings;

use YAHC;
use Test::More;
use Test::Memory::Cycle;

my $conn;
my ($yahc, $yahc_storage) = YAHC->new();

$yahc->request({
    host => 'localhost',
    callback => sub {
        $yahc->request({ host => 'localhost' });
        $conn->{state} = YAHC::State::INITIALIZED();
    }
});

memory_cycle_ok($yahc);
memory_cycle_ok($conn);
done_testing();
