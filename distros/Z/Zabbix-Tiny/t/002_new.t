#!/usr/bin/env perl
use strict;
use warnings;
use Test::LWP::UserAgent;
use JSON;

use Test::Most;
use Test::Exception;

use_ok('Zabbix::Tiny');

my $url      = 'http://zabbix.domain.com/zabbix/api_jsonrpc.php';
my $username = 'username';
my $badpass  = 'badpass';
my $goodpass = 'goodpass';

my $useragent = Test::LWP::UserAgent->new;

# Create a new Zabbix::Tiny object
my $zabbix = new_ok(
    'Zabbix::Tiny',
    [
        server   => $url,
        password => $goodpass,
        user     => $username,
        ua       => $useragent,
    ],
    '$zabbix'
);

done_testing();
