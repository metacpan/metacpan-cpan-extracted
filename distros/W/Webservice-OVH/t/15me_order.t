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

    pay_with_registered_payment_mean can't be tested, because ovh doesn't have a sandbox. 
    You need to actually buy something to test this
    available_registered_payment_mean can't be tested, because this works only with not payed orders
    payment_means can't be tested, because you need an unpayed order for it
    payment can't be tested
=cut

my $api = Webservice::OVH->new_from_json($json_dir);
ok( $api, "module ok" );

my $orders = $api->me->orders;
my $order = $orders->[0];
ok( $orders && ref $orders eq 'ARRAY', 'orders ok' );
ok( $orders, 'order ok' );

ok( $order->id, 'id ok' );
ok( $order->properties && ref $order->properties eq 'HASH', 'properties ok' );
ok( $order->date && ref $order->date eq 'DateTime', 'date ok' );
ok( $order->expiration_date && ref $order->expiration_date eq 'DateTime', 'expiration_date ok' );
ok( $order->expiration_date && ref $order->expiration_date eq 'DateTime', 'expiration_date ok' );
ok( $order->password, 'password ok');
ok( $order->pdf_url, 'pdf_url ok');
ok( $order->price_without_tax && ref $order->price_without_tax eq 'HASH', 'price_without_tax ok');
ok( $order->price_with_tax && ref $order->price_with_tax eq 'HASH', 'price_with_tax ok');
ok( $order->tax && ref $order->tax eq 'HASH', 'tax ok');
ok( $order->tax && ref $order->tax eq 'HASH', 'password ok');
ok( $order->url, 'url ok');

my $bill;
eval{$bill = $order->bill;};

if( $bill ) {
    
    ok( ref $order->bill eq 'Webservice::OVH::Me::Bill', 'bill ok' );
}

my $details = $order->details;
my $detail = $details->[0];
my $search_detail = $order->detail( $detail->id );

ok ( $details && ref $details eq 'ARRAY', 'details ok' );
ok ( $detail, 'detail ok' );
ok ( $search_detail, 'found detail ok' );

ok( $order->status, 'status ok' );

done_testing();