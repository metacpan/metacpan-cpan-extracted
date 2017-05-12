#!perl

BEGIN {
    unless ($ENV{'ZOOPLA_API_KEY'}) {
        require Test::More;
        Test::More::plan(skip_all =>
              'Set the following environment variables or these tests are skipped: '
              . qw/ $ENV{'ZOOPLA_API_KEY'} /);
    }
}

use strict;
use warnings;

use Test::Most tests => 17;
use lib 'lib';
use Data::Dumper;
use_ok('WebService::Zoopla::API');


my $zoopla = WebService::Zoopla::API->new(api_key => $ENV{'ZOOPLA_API_KEY'});

isa_ok($zoopla, 'WebService::Zoopla::API', 'Create a new instance');

can_ok($zoopla, qw ( new api session_id specification api_key));

foreach my $method (
    qw (
    zed_index area_value_graphs richlist average_area_sold_price
    zed_indices zoopla_estimates property_listings get_session_id
    refine_estimate arrange_viewing average_sold_prices )
  )
{
    ok((grep { $_ eq $method } @{$zoopla->api->meta->local_spore_methods}),
        "Testing method $method");
}

my $result = $zoopla->zed_index({area => 'SE4', output_type => "outcode"});


is($result->{country},  'England', 'Correct country returned');
is($result->{county},   'London',  'Correct county returned');
is($result->{postcode}, 'SE4',     'Correct postcode returned');
