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

my $cart = $api->order->new_cart( ovh_subsidiary => 'DE' );
ok( $cart, 'cart ok' );

my $item = $cart->add_domain( 'eine-neue-domain-fuer-mich.de', quantity => 1 );
ok( $item, 'item ok' );

ok( $item->cart->id eq $cart->id, 'cart relation ok' );

ok( $item->properties     && ref $item->properties eq 'HASH',      'properties ok' );
ok( $item->configurations && ref $item->configurations eq 'ARRAY', 'configurations ok' );
ok( $item->duration, 'duration ok' );
ok( $item->offer_id, 'offer_id ok' );
ok( $item->options && ref $item->options eq 'ARRAY', 'options ok' );
ok( $item->prices  && ref $item->prices eq 'ARRAY',  'prices ok' );
ok( $item->product_id, 'product_id ok' );
ok( $item->settings && ref $item->settings eq 'HASH', 'settings ok' );

$item->delete;
ok(!$item->is_valid, 'validity ok');
my $items = $cart->items;
ok( scalar @$items == 0, 'Item list ok' );
;
$cart->delete;
ok( !$cart->is_valid, 'delete ok' );

done_testing();
