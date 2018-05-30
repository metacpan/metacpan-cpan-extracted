use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my ($got, $expected);

my $api = WebService::RESTCountries->new;

$got = $api->search_by_language_code('ms');
is(scalar @$got, 2, 'expect countries found by language code');

$got = $api->search_by_language_code('mss');
$expected = {
    'message' => 'Not Found',
    'status' => 404
};
is_deeply($got, $expected, 'expect bad request');

my $expected_fields = ['capital', 'currencies', 'name'];
$api->fields($expected_fields);
$got = $api->search_by_language_code('ms');
my @got_fields = sort keys %{$got->[0]};
is_deeply(\@got_fields, $expected_fields, 'expect selected fields match');

done_testing;
