#!/usr/bin/perl

use strict;
use warnings;
use WebService::MyAffiliates;
use Test::More;
use Test::Exception;
use Test::MockModule;

my $aff = WebService::MyAffiliates->new(
    user => 'user',
    pass => 'pass',
    host => 'host'
);

my $mock_http_tiny = Test::MockModule->new('HTTP::Tiny');

$mock_http_tiny->mock(
    'get',
    sub {

        return +{
            'headers' => {'content-type' => 'text/xml'},
            'success' => 1,
            'content' => '<PLAYERS><PLAYER AFFILIATE_ID="1234"/></PLAYERS>'
        };

    });

my $args = {
    'AFFILIATE_ID' => '1234',
};

my $res = $aff->get_customers($args);
is($res->[0]->{AFFILIATE_ID}, '1234', 'Affiliate customer is retrieved correctly');

done_testing();

1;
