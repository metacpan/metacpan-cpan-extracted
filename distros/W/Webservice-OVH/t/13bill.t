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
ok( $api, "module ok" );

my $bills        = $api->me->bills;
my $bill = $bills->[0];
ok( $bills,        'bills ok' );
ok( $bill, 'example_bill ok' );

ok( $bill->properties && ref $bill->properties eq 'HASH', 'properties ok' );
ok( $bill->date && ref $bill->date eq 'DateTime', 'date ok' );
ok( $bill->order( $api ) && ref $bill->order( $api ) eq 'Webservice::OVH::Me::Order', 'order ok' );
ok( $bill->password, 'password ok' );
ok( $bill->price_without_tax, 'price_without_tax ok' );
ok( $bill->price_with_tax, 'price_with_tax ok' );
ok( $bill->tax, 'tax ok' );
ok( $bill->url, 'url ok' );

done_testing();