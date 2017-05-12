#!perl -T

use strict;
use warnings;

use Test::More ;
use XML::Simple qw(:strict);
use JSON::Any;

sub HAS_FORBIDDEN_BUG { 1 }

BEGIN {
    use_ok( 'VendorAPI::2Checkout::Client' ) || print "Bail out!\n";
}

SKIP: {
    skip "VAPI_2CO_UID && VAPI_2CO_PWD not set in environment" , 4
        unless $ENV{VAPI_2CO_UID} && $ENV{VAPI_2CO_PWD};

    foreach my $moosage (1, 0) {

       # XML
       my $tco = VendorAPI::2Checkout::Client->get_client( $ENV{VAPI_2CO_UID}, $ENV{VAPI_2CO_PWD}, 'XML', $moosage);
       SKIP:  {
          skip "VAPI_HAS_COUPONS not set in environment. No coupons to retrieve", 2
              unless (defined $ENV{VAPI_HAS_COUPONS} && $ENV{VAPI_HAS_COUPONS} > 0) ;

          my $r = $tco->list_coupons();
          my $couponlistxml = XMLin($r->content(), ForceArray => 1, KeyAttr => {});

          foreach my $coupon ( @{ $couponlistxml->{coupon} } ) {
              my $r = $tco->detail_coupon(coupon_code => $coupon->{coupon_code}[0]);
              ok($r->is_success(), 'got detail');
              my $couponxml = XMLin($r->content(), ForceArray => 1, KeyAttr => {});

              my $coupon2 = $couponxml->{coupon}[0];
              delete $coupon2->{product};     # API list_coupons/detail_coupon bug
              is_deeply( $coupon2, $coupon, "coupon from detail_coupon() matches coupon from list_coupons()" );
          }
       }

       my $coupon_code = '42';  # should fail;
       my $r = $tco->detail_coupon(coupon_code => $coupon_code);
       ok($r->is_error, "got an error");
       my $errorxml = XMLin($r->content(), ForceArray => 1, KeyAttr => {});
       is($errorxml->{errors}[0]{code}[0], (HAS_FORBIDDEN_BUG() ? 'FORBIDDEN' : 'RECORD_NOT_FOUND'), "Coupon $coupon_code not found");

       # JSON
       $tco = VendorAPI::2Checkout::Client->get_client( $ENV{VAPI_2CO_UID}, $ENV{VAPI_2CO_PWD}, 'JSON', $moosage );
       my $J = JSON::Any->new();
       SKIP:  {
          skip "VAPI_HAS_COUPONS not set in environment. No coupons to retrieve", 2
              unless (defined $ENV{VAPI_HAS_COUPONS} && $ENV{VAPI_HAS_COUPONS} > 0) ;

          my $r = $tco->list_coupons();
          my $couponlistJ = $J->decode($r->content(), ForceArray => 1, KeyAttr => {});

          foreach my $coupon ( @{ $couponlistJ->{coupon} } ) {
              my $r = $tco->detail_coupon(coupon_code => $coupon->{coupon_code});
              ok($r->is_success(), 'got detail');
              my $couponJ = $J->decode($r->content(), ForceArray => 1, KeyAttr => {});

              my $coupon2 = $couponJ->{coupon};
              delete $coupon2->{product};               # API list_coupons/detail_coupon bug
              is_deeply( $coupon2, $coupon, "coupon from detail_coupon() matches coupon from list_coupons()" );
          }
       }

       $coupon_code = 42;  # should fail;
       $r = $tco->detail_coupon(coupon_code => $coupon_code);
       ok($r->is_error, "got an error");
       my $errorJ = $J->decode($r->content(), ForceArray => 1, KeyAttr => {});
       is($errorJ->{errors}[0]{code}, (HAS_FORBIDDEN_BUG() ? 'FORBIDDEN' : 'RECORD_NOT_FOUND'), "Coupon $coupon_code not found");
    }
}

done_testing();

