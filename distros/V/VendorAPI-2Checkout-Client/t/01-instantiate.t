#!perl -T

use strict;
use warnings;

use Test::More ;
use VendorAPI::2Checkout::Client;

my $tco = VendorAPI::2Checkout::Client->get_client();
ok(!defined $tco, "get_client: username and password are required - got undef");

$tco = VendorAPI::2Checkout::Client->get_client('len');
ok(!defined $tco, "get_client: username and password are required - got undef");

$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd');
ok(!defined $tco, "get_client: username and password are required - got object");

$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd', 'ML');
ok(!defined $tco, "get_client: bad format - no object");

$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd', 'XML');
ok(defined $tco, "get_client: username, password, and format are required - got object");
isa_ok($tco,'VendorAPI::2Checkout::Client');
isa_ok($tco,'VendorAPI::2Checkout::Client::NoMoose');
object_tests($tco);

$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd', 'XML', VendorAPI::2Checkout::Client->VAPI_NO_MOOSE);
ok(defined $tco, "get_client: got object");
isa_ok($tco,'VendorAPI::2Checkout::Client');
isa_ok($tco,'VendorAPI::2Checkout::Client::NoMoose');
is($tco->_accept(), 'application/xml', 'accept param XML good');
object_tests($tco);
$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd', 'JSON', VendorAPI::2Checkout::Client->VAPI_NO_MOOSE);
is($tco->_accept(), 'application/json', 'accept param JSON good');
object_tests($tco);

$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd', 'XML', VendorAPI::2Checkout::Client->VAPI_MOOSE);
ok(defined $tco, "get_client: got object");
isa_ok($tco,'VendorAPI::2Checkout::Client::Moose');
is($tco->accept(), 'application/xml', 'accept param XML good');
object_tests($tco);
$tco = VendorAPI::2Checkout::Client->get_client('len', 'somepwd', 'JSON', VendorAPI::2Checkout::Client->VAPI_MOOSE);
is($tco->accept(), 'application/json', 'accept param JSON good');
object_tests($tco);

done_testing();

sub object_tests {
  my $tco = shift;
  can_ok($tco, 'list_sales');
  can_ok($tco, 'detail_sale');
  can_ok($tco, 'list_coupons');
  can_ok($tco, 'detail_coupon');
  can_ok($tco, 'list_payments');
  can_ok($tco, 'list_products');
  can_ok($tco, 'list_options');
}

