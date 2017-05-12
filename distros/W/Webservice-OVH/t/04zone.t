use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ($json_dir && -e $json_dir) {  plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

my $api            = Webservice::OVH->new_from_json($json_dir);
my $example_zone   = $api->domain->zones->[0];
my $example_record = $example_zone->records->[0];

# Check if examples exist and test the _exists methods
ok( $api->domain->zone_exists( $example_zone->name ), "check example zone" );

ok( $example_zone->properties,    "ok properties" );
ok( $example_zone->service_infos, "service_infos ok" );
ok( $example_zone->name,          "name ok" );
ok( $example_zone->records && ref $example_zone->records eq 'ARRAY', "records ok" );
ok( $example_zone->record( $example_record->id ), "single records ok" );
ok( $example_zone->dnssec_supported == 0 || $example_zone->dnssec_supported == 1, "dnssec_supported ok" );
ok( $example_zone->has_dns_anycast == 0  || $example_zone->has_dns_anycast == 1,  "has_dns_anycast ok" );
ok( $example_zone->last_update && ref $example_zone->last_update eq 'DateTime', "last_update ok" );
ok( ref $example_zone->name_servers eq 'ARRAY', "name_servers ok" );

done_testing();
