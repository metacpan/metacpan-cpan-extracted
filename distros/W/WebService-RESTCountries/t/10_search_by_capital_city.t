use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my ($got, $expected);

my $api = WebService::RESTCountries->new;

$got = $api->search_by_capital_city('Kuala Lumpur');
is($got->{name}, 'Malaysia', 'expect country found by full capital city name');

$got = $api->search_by_capital_city("Saint John's");
is($got->{name}, 'Antigua and Barbuda', 'expect country found by full capital city name with symbol');

$got = $api->search_by_capital_city('');
is(%$got, 0, 'expect no country found by capital city');

$got = $api->search_by_capital_city('Kuala');
is($got->{name}, 'Malaysia', 'expect country found by partial capital city name');

my $expected_fields = ['capital', 'currencies', 'name'];
$api->fields($expected_fields);
$got = $api->search_by_capital_city('Kuala Lumpur');
my @got_fields = sort keys %{$got};
is_deeply(\@got_fields, $expected_fields, 'expect selected fields match');

done_testing;
