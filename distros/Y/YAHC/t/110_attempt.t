#!/usr/bin/env perl

use strict;
use warnings;

use YAHC qw/yahc_conn_attempt yahc_conn_attempts_left/;
use Test::More;

my ($yahc, $yahc_storage) = YAHC->new;

# here we tell YAHC to do do accual work, that's why we should get 11 attempts
my $c = $yahc->request({ host => "localhost:1000", retries => 10, _test => 1 });
cmp_ok(yahc_conn_attempts_left($c), "==", 11, "got expected amount of attempts left");
cmp_ok(yahc_conn_attempt($c), "==", 0, "got expected attempt");

# here we tell YAHC to work as usual, so it does first attempt immideatly
my $c1 = $yahc->request({
    host => [ "localhost:1000" ],
    retries => 10,
    callback => sub {
        cmp_ok(yahc_conn_attempt($_[0]), "==", 11, "got expected attempt in callback");
        cmp_ok(yahc_conn_attempts_left($_[0]), "==", 0, "got 0 attempts left in callback")
    }
});

cmp_ok(yahc_conn_attempt($c1), "==", 1, "got expected attempt");
cmp_ok(yahc_conn_attempts_left($c1), "==", 10, "got expected amount of attempts left");

$yahc->run;

cmp_ok(yahc_conn_attempt($c1), "==", 11, "got expected attempt in the end");
cmp_ok(yahc_conn_attempts_left($c1), "==", 0, "got 0 attempts left in the end");

done_testing;
