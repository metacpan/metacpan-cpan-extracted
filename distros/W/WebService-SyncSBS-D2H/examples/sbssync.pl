#!/usr/bin/perl

use strict;
use lib './lib';
use WebService::SyncSBS::D2H;


my $delicious_user = '';
my $delicious_pass = '';
my $hatena_user = '';
my $hatena_pass = '';
my $delicious_recent_num = 20;

my $sbsync = WebService::SyncSBS::D2H->new({
    delicious_user => $delicious_user,
    delicious_pass => $delicious_pass,
    hatena_user => $hatena_user,
    hatena_pass => $hatena_pass,
    delicious_recent_num => $delicious_recent_num,
});


$sbsync->sync;
