use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use JSON::XS;
use WWW::IRail::API qw/irail/;
use WWW::IRail::API::Client::LWP;
use LWP::UserAgent;
use FindBin qw/$Bin/;
  
#########################################################################################################
# setup
#########################################################################################################
use_ok('WWW::IRail::API::Client::LWP');
use_ok('WWW::IRail::API::Stations');

my $irail = new WWW::IRail::API;

#########################################################################################################
# test setup
#########################################################################################################
isa_ok($irail,'WWW::IRail::API');

#########################################################################################################
# standalone station tests
#########################################################################################################

my $ua = new LWP::UserAgent();
   $ua->timeout(20);
   $ua->agent("WWW::IRail::API::_test/0.01");

   my $station_req = WWW::IRail::API::Stations::make_request();
   my $resp = $ua->request($station_req);
   my $result = WWW::IRail::API::Stations::parse_response($resp,'perl');

   ok($result, "result must be defined");
   ok(ref $result eq 'ARRAY', "returned type must be an ARRAY");
   ok(scalar $result, "result must contain more then one element");

   ok( (scalar grep { /brussel/i } @$result) > 1, "result must contain some stations m/brussel/i");



#########################################################################################################
# WWW::IRail::API station tests
#########################################################################################################

my $irail_0 = new WWW::IRail::API;

## lookup all [NL] #####################################################################################
my $stations_0 = $irail_0->lookup_stations(lang => 'nl');

ok(ref $stations_0 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_0 > 100, "there must be at least a hundred stations") or diag "[". (join ", ", @$stations_0) ."]";
ok((grep { /brussel noord/i } (@$stations_0)), "brussel noord (NL) must be one of them") or diag "[". (join ", ", @$stations_0) ."]";

## lookup using sub as filter ...........................................................................
my $stations_1 = $irail_0->lookup_stations(lang => 'nl', filter => sub { /brussel/i } );

ok(ref $stations_1 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_1 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_1) ."]";
ok((grep { /brussel noord/i } (@$stations_1)), "brussel noord (NL) must be in the partial set") or diag "[". (join ", ", @$stations_1) ."]";
ok((not grep { /oostende/i } (@$stations_1)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_1) ."]";

## lookup using qr// as a filter ........................................................................
my $stations_2 = $irail_0->lookup_stations(lang=> 'nl', filter => qr/brussel/i );

ok(ref $stations_2 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_2 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_2) ."]";
ok((grep { /brussel noord/i } (@$stations_2)), "brussel noord (NL) must be in the partial set") or diag "[". (join ", ", @$stations_2) ."]";
ok((not grep { /oostende/i } (@$stations_2)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_2) ."]";

## lookup using string as a filter ......................................................................
my $stations_3 = $irail_0->lookup_stations(lang => 'nl', filter => "brussel" );

ok(ref $stations_3 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_3 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_3) ."]";
ok((grep { /brussel noord/i } (@$stations_3)), "brussel noord (NL) must be in the partial set") or diag "[". (join ", ", @$stations_3) ."]";
ok((not grep { /oostende/i } (@$stations_3)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_3) ."]";




## lookup all [FR] ######################################################################################
my $stations_4 = $irail_0->lookup_stations(lang => 'fr');

ok(ref $stations_4 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_4 > 100, "there must be at least a hundred stations") or diag "[". (join ", ", @$stations_4) ."]";
ok((grep { /bruxelles nord/i } (@$stations_4)), "bruxelles nord (FR) must be one of them") or diag explain $stations_4;

## lookup using sub as filter ...........................................................................
my $stations_5 = $irail_0->lookup_stations(lang => 'fr', filter => sub { /bruxelles/i } );

ok(ref $stations_5 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_5 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_5) ."]";
ok((grep { /bruxelles nord/i } (@$stations_5)), "bruxeles nord (FR) must be in the partial set") or diag "[". (join ", ", @$stations_5) ."]";
ok((not grep { /oostende/i } (@$stations_5)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_5) ."]";

## lookup using qr// as a filter ........................................................................
my $stations_6 = $irail_0->lookup_stations(lang=> 'fr', filter => qr/bruxelles/i );

ok(ref $stations_6 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_6 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_6) ."]";
ok((grep { /bruxelles nord/i } (@$stations_6)), "bruxelles nord (FR) must be in the partial set") or diag "[". (join ", ", @$stations_6) ."]";
ok((not grep { /oostende/i } (@$stations_6)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_6) ."]";

## lookup using string as a filter ......................................................................
my $stations_7 = $irail_0->lookup_stations(lang => 'fr', filter => "bruxelles" );

ok(ref $stations_7 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_7 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_7) ."]";
ok((grep { /bruxelles nord/i } (@$stations_7)), "bruxelles nord (FR) must be in the partial set") or diag "[". (join ", ", @$stations_7) ."]";
ok((not grep { /oostende/i } (@$stations_7)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_7) ."]";


## return type JSON #####################################################################################
my $json = $irail_0->lookup_stations(lang=> 'nl', filter => "brussel", dataType => 'JSON');

my $obj = decode_json ($json);
ok($obj, "object exists");
ok($obj->{station}, "station key exists in json object");
ok(ref $obj->{station} eq "ARRAY", "station key holds an array");

my $stations_99 = [@{$obj->{station}}];
ok(ref $stations_99 eq 'ARRAY', "result must point to array");
ok(scalar @$stations_99 > 2, "there must be at least two stations with brussel in their name") or diag "[". (join ", ", @$stations_99) ."]";
ok((grep { /brussel noord/i } (@$stations_99)), "brussel noord (NL) must be in the partial set") or diag "[". (join ", ", @$stations_99) ."]";
ok((not grep { /oostende/i } (@$stations_99)), "oostende must not be in the set") or diag "[". (join ", ", @$stations_99) ."]";

done_testing();

