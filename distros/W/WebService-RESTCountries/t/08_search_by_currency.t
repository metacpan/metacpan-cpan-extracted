use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my ($got, $expected);

my $api = WebService::RESTCountries->new;

$got = $api->search_by_currency('MYR');
is($got->{name}, 'Malaysia', 'expect country found by currency code');

$got = $api->search_by_currency('RM');
$expected = {
    'message' => 'Bad Request',
    'status' => 400
};
is_deeply($got, $expected, 'expect bad request');
is($got->{name}, undef, 'expect country not found by invalid currency code');

my $expected_fields = ['capital', 'currencies', 'name'];
$api->fields($expected_fields);
$got = $api->search_by_currency('MYR');
my @got_fields = sort keys %{$got};
is_deeply(\@got_fields, $expected_fields, 'expect selected fields match');

done_testing;
