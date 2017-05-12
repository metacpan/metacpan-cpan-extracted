#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockSleep qw(:with_mocktime);

my $have_mock_time = eval 'use Test::MockTime qw(:all); 1;';
if(!$have_mock_time) {
    plan skip_all => "Can't load Test::MockTime";
    exit(0);
}

my $begin = time();
sleep(5);
my $now = time();
ok($now - $begin >= 4, "MockTime changes time ($begin to $now)");

done_testing();