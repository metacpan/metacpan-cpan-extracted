#!/usr/bin/env perl
use v5.14;
use warnings;
use lib 'lib';

{
    package CoinDeskClient;
    use Moo;
    with 'WebService::Client';
}


my $client = CoinDeskClient->new(base_url => 'https://api.coindesk.com/v1');
say $client->get('/bpi/currentprice.json')->{bpi}{USD}{rate_float};

my $client2 = CoinDeskClient->new();
say $client2->get('https://api.coindesk.com/v1/bpi/currentprice.json')
    ->{bpi}{USD}{rate_float};

my $client3 = CoinDeskClient->new(
    base_url => 'https://api.coindesk.com/v1',
    mode => 'v99',
);
say $client3->get('/bpi/currentprice.json')->data->{bpi}{USD}{rate_float};
