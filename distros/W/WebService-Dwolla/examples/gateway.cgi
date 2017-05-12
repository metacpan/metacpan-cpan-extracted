#! /usr/bin/perl

use WebService::Dwolla;
use CGI;
use Data::Dumper;

my $redirect_url = 'http://192.168.11.14/cgi-bin/dwolla.cgi'; 

my $api = WebService::Dwolla->new(undef,undef,$redirect_url);

$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

my $q = new CGI->new;
my $params = $q->Vars;

print $q->header();
print $q->h2('Example #1: Simple Checkout');

$api->start_gateway_session();

$api->add_gateway_product('Test 1',10);

my $url = $api->get_gateway_url('812-713-9234');
if (!$url) {
    print $q->pre(Dumper($api->get_errors()));
} else {
    print $q->a({-href => $url},$url);
}

print $q->h2('Example #2: In-Depth Checkout');

$api->set_mode('test');

$api->start_gateway_session();

$api->add_gateway_product('Test 1',10,1,'Test Product');
$api->add_gateway_product('Test 2',10,2,'Another Test Product');

my $url2 = $api->get_gateway_url('812-713-9234', '10001', 24.85, 0.99, 1.87, 'This is a great purchase', 'http://requestb.in/1fy628r1');
if (!$url2) {
    print $q->pre(Dumper($api->get_errors()));
} else {
    print $q->a({-href => $url2},$url2);
}

print $q->h2('Example #3: Verifying an offsite gateway signature');

my $signature  = $params->{'signature'};
my $checkoutid = $params->{'checkoutId'};
my $amount     = $params->{'amount'};

my $verified = $api->verify_gateway_signature($signature,$checkoutid,$amount);

if ($verified) {
    print $q->p("Dwolla's signature verified successfully. You should go ahead and process the order.");
} else {
    print $q->p("Dwolla's signature failed to verify. You shouldn't process the order before some manual verification.");
}
