use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ($json_dir && -e $json_dir) {  plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

=head2

    checkout can't be testet, because it creates an order
    add_transfer can't be completly tested, because an unlocked domain ist necessary

=cut

my $api = Webservice::OVH->new_from_json($json_dir);
ok($api, "module ok");

my $cart = $api->order->new_cart( ovh_subsidiary => 'DE' );

my $carts = $api->order->carts;
my @found_cart = grep { $_->id eq $cart->id } @$carts;
my $search_cart = $api->order->cart($cart->id);

ok( $cart, 'new cart ok');
ok( $carts && ref $carts eq 'ARRAY', 'new cart ok');
ok( scalar @found_cart > 0, 'cart in list ok' );
ok( $search_cart, 'found cart ok' );

ok( $cart->id, 'id ok' );
ok( $cart->properties, 'properties ok' );
ok( $cart->description, 'description ok' );
ok( $cart->expire, 'expire ok' );

my $dt_expire = DateTime->now->add(days => 1);
$cart->change( description => 'Ein Einkaufswagen', expire => Webservice::OVH::Helper->format_datetime($dt_expire) );

ok( $cart->description eq 'Ein Einkaufswagen', 'change description ok' );
ok( $cart->expire, 'change expire ok' );

my $offers = $cart->offers_domain('eine-neue-domain-fuer-mich.de');
ok( $offers && ref $offers eq 'ARRAY', 'offers domain ok');
my $offers_transfer = $cart->offers_domain_transfer('test.de');
ok( $offers_transfer && ref $offers_transfer eq 'ARRAY', 'offers domain_transfer ok');

my $item = $cart->add_domain('eine-neue-domain-fuer-mich.de', quantity => 1);
ok( $item, 'adding domain ok');
my $nitem;
eval {$nitem = $cart->add_transfer('test.de');};
ok( !$nitem, 'no transfer ok' );

my $checkout = $cart->info_checkout;
ok ( $checkout && ref $checkout eq 'HASH', 'info_checkout ok' );

my $items = $cart->items;
my $example_item = $items->[0];
my $search_item = $cart->item($example_item->id);

ok( scalar @$items == 1, 'item count ok' );
ok( $example_item, 'example_item ok' );
ok( $search_item, 'item found ok' );

$cart->clear;

my $items_empty = $cart->items;
ok( scalar @$items_empty == 0, 'no items ok' );

$cart->delete;

ok( !$cart->is_valid, 'validity ok' );

done_testing();