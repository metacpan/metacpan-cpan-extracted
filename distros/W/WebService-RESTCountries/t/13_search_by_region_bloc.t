use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my ($got, $expected);

my $api = WebService::RESTCountries->new;

my $countries_counts_per = {
    AL => 22,
    ASEAN => 10,
    AU => 60,
    CAIS => 8,
    CARICOM => 15,
    CEFTA => 7,
    EEU => 5,
    EFTA => 4,
    EU => 33,
    NAFTA => 3,
    PA => 4,
    SAARC => 8,
    USAN => 15,
};

foreach my $regional_bloc (keys %$countries_counts_per) {
    $got = $api->search_by_regional_bloc($regional_bloc);
    is(scalar @$got, $countries_counts_per->{$regional_bloc}, "expect countries counts per regional bloc: $regional_bloc match");
}

$got = $api->search_by_regional_bloc('andromeda');
$expected = {
    'message' => 'Not Found',
    'status' => 404
};
is_deeply($got, $expected, 'expect not found');

my $expected_fields = ['capital', 'currencies', 'name'];
$api->fields($expected_fields);
$got = $api->search_by_regional_bloc('NAFTA');
my @got_fields = sort keys %{$got->[0]};
is_deeply(\@got_fields, $expected_fields, 'expect selected fields match');

done_testing;
