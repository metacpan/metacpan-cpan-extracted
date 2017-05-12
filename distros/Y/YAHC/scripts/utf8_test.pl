#!/bin/env perl

# nc -l -k 6000 > /dev/null

use strict;
use warnings;

use YAHC;
use Time::HiRes qw/time/;

$SIG{PIPE} = 'IGNORE';

my ($yahc, $yahc_storage) = YAHC->new({
    # debug         => 1,
    # keep_timeline => 1,
});

my $body = 'a' x (10 * 1024 * 1024);
my $conn1 = $yahc->request({
    host => '127.0.0.1:6000',
    body => $body,
});

my $start = time;
$yahc->run(YAHC::State::READING);
printf "elapsed without utf8 flag: %.3fs\n", time - $start;

$yahc->drop($conn1);
utf8::upgrade($body);

$yahc->request({
    host => '127.0.0.1:6000',
    body => $body,
});

$start = time;
$yahc->run(YAHC::State::READING);
printf "elapsed with utf8 flag: %.3fs\n", time - $start;
exit 0;
