#!/usr/bin/env perl

use strict;
use warnings;

use EV;

use YAHC;
use Test::More;
use Time::HiRes qw/time/;
use Scalar::Util qw/weaken/;

my $loop = EV::default_loop();
my ($yahc, $yahc_storage) = YAHC->new({ loop => $loop });

my $called = 0;

my $weakloop = $loop;
weaken($weakloop);
my $c1 = $yahc->request({
    host => [ "localhost:1000" ],
    callback => sub {
        $called++;
        $weakloop->break;
    },
});

my $iterations = 0;
$loop->run(EV::RUN_ONCE) until $called || $iterations++ > 1000;

is($called, 1, "Running the default eventloop ran YAHC");

done_testing;
