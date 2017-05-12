use strict;
use warnings;
use List::Util qw(first);
use DateTime;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";
use Webservice::OVH;

my $api = Webservice::OVH->new_from_json("../credentials.json");

my $carts = $api->order->carts;

foreach my $cart (@$carts) {

    $cart->delete;
}

$carts = $api->order->carts;
