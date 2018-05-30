use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my $got;

my $api = WebService::RESTCountries->new;

$got = $api->search_by_country_name('Malaysia');
is($got->[0]->{capital}, "Kuala Lumpur", 'expect country found by name');

$got = $api->search_by_country_name("Malays");
is($got->[0]->{capital}, "Kuala Lumpur", 'expect country found by partial name');

$got = $api->search_by_country_name("Korea (Democratic People's Republic of)");
is($got->[0]->{capital}, "Pyongyang", 'expect country found by long multi-words name');

$got = $api->search_by_country_name("São Tomé");
is($got->[0]->{capital}, "São Tomé", 'expect country found by special characters name');

$got = $api->search_by_country_name("Foo Bar");
my $expected = {
    'message' => 'Not Found',
    'status' => 404
};
is_deeply($got, $expected, 'expect no country found');

my $expected_fields = ['capital', 'currencies', 'name'];
$api->fields($expected_fields);
$got = $api->search_by_country_name('Malaysia');
my @got_fields = sort keys %{$got->[0]};
is_deeply(\@got_fields, $expected_fields, 'expect selected fields match');


done_testing;
