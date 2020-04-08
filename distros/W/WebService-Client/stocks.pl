#!/usr/bin/env perl
package Client;
use Moo;
with 'WebService::Client';
use lib 'lib';

my $client = Client->new();
my $btc_url = 'https://api.coindesk.com/v1/bpi/currentprice.json';
say $client->get($btc_url)->{bpi}{USD}{rate_float};

my $token = 'pk_da8de08f10a04315b26641ed3fa53235';
my $stocks = 'iau,spy,ge,tsla';
my $params = { token  => $token, symbols => $stocks };
my $stocks_url = "https://cloud.iexapis.com/stable/tops/last";
my $res_data = $client->get($stocks_url, $params);
for my $stock (@$res_data) { say "$stock->{symbol}: $stock->{price}" }
