use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my ($got, $expected);

my $api = WebService::RESTCountries->new;

$got = $api->search_all();
is(scalar @$got, 250, 'expect 250 countries found');

my $expected_fields = ['capital', 'currencies', 'name'];
$api->fields($expected_fields);
$got = $api->search_all();
my @got_fields = sort keys %{$got->[0]};
is_deeply(\@got_fields, $expected_fields, 'expect selected fields match');

done_testing;
