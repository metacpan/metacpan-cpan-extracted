use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ($json_dir && -e $json_dir) {  plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

my $api = Webservice::OVH->new_from_json($json_dir);

my $example_zone    = $api->domain->zones->[0];
my $example_records = $example_zone->records;
my $example_record  = $example_records->[0];

ok( $example_record->id, "id ok" );
ok( $example_record->properties && ref $example_record->properties eq 'HASH', "properties ok" );
ok( $example_record->field_type, "field_type ok" );

my $record;
eval { $record = $example_zone->new_record; };
ok( !$record, "Missing Parameter ok" );

eval { $record = $example_zone->new_record( field_type => 'TXT' ); };
ok( !$record, "Missing Parameter ok" );

eval { $record = $example_zone->new_record( field_type => 'WRONG', target => "" ); };
ok( !$record, "Wrong Parameter ok" );

$record = $example_zone->new_record( field_type => 'TXT', target => "testrecord" );
ok( $record,                         "record creation ok" );
ok( $record->field_type eq 'TXT',    "new record type ok" );
ok( $record->target eq 'testrecord', "new record target ok" );
ok( $record->id,                     "new record id ok" );
ok( !$record->sub_domain,            "new record subDomain ok" );

$record->change( sub_domain => 'www', target => 'test_new_record' );

ok( $record->target eq 'test_new_record', "changed record target ok" );
ok( $record->sub_domain eq 'www',         "changed record subDomain ok" );

$record->delete;

ok( !$record->is_valid, "record object validity ok" );

my $recheck_records = $example_zone->records;

my @record = grep { $_->id eq $record->id } @$recheck_records;

ok( !@record, "record is not in list ok" );

done_testing();
