use strict;
use warnings FATAL => 'all';
use Test::More;
use Weather::WWO;

my $api_key = '7dafjkpc6rtdmqws27ew2spr';
my $location = '90230';
my $wwo = Weather::WWO->new(
    api_key           => $api_key,
    use_new_api       => 1,
    location          => $location,
    temperature_units => 'F',
    wind_units        => 'Miles',
);
ok(scalar keys %{$wwo->data->{current_condition}->[0]}, 'Have keys for current conditions');

#use Data::Dumper::Concise;
#warn Dumper $wwo->data->{current_condition}->[0];


done_testing();
