#!perl -T

use strict;
use warnings;

use Test::More ;
use XML::Simple qw(:strict);
use JSON::Any;

use VendorAPI::2Checkout::Client;

sub test_XML {
  my $moosage = shift;

  # xml
  my $tco = VendorAPI::2Checkout::Client->get_client( $ENV{VAPI_2CO_UID}, $ENV{VAPI_2CO_PWD}, 'XML', $moosage );
  my $details = eval { $tco->detail_sale(); };
  like($@, qr/detail_sale requires sale_id or invoice_id/, 'caught empty param list error');

  my $sale_id;
  SKIP:  {
     skip "VAPI_HAS_SALES not set in environment. No sales to retrieve", 2
         unless (defined $ENV{VAPI_HAS_SALES} && $ENV{VAPI_HAS_SALES} > 0) ;

     my $r = $tco->list_sales();
     my $salelistxml = XMLin($r->content(), ForceArray => 1, KeyAttr => {});
     my $sale =  $salelistxml->{sale_summary}[0];
     $sale_id =  $sale->{sale_id}[0];

     $details = $tco->detail_sale(sale_id => $sale_id);
     ok($details->is_success(), 'got detail');
     my $salexml = XMLin($details->content(), ForceArray => 1, KeyAttr => {});
     is( $salexml->{sale}[0]->{invoices}[0]->{sale_id}[0], $sale_id, "sale detail looks ok");

     my $invoice_id = $salexml->{sale}[0]->{invoices}[0]->{invoice_id}[0];
     $details = $tco->detail_sale(invoice_id => $invoice_id);

     ok($details->is_success(), 'got detail');
     my $invoicexml = XMLin($details->content(), ForceArray => 1, KeyAttr => {});
     is( $invoicexml->{sale}[0]->{invoices}[0]->{invoice_id}[0], $invoice_id, "sale detail looks ok");

     is($invoicexml->{sale}[0]->{invoices}[0]->{sale_id}[0], $sale_id, "sale id in voice sale as in sale_id query");
  }

  $sale_id = 42;  # should fail;
  $details = $tco->detail_sale(sale_id => $sale_id);
  ok($details->is_error, "got an error");
  my $errorxml = XMLin($details->content(), ForceArray => 1, KeyAttr => {});
  is($errorxml->{errors}[0]{code}[0], 'RECORD_NOT_FOUND', "Sale $sale_id not found");
}



sub test_JSON {
  my $moosage = shift;
  # json
  my $tco = VendorAPI::2Checkout::Client->get_client( $ENV{VAPI_2CO_UID}, $ENV{VAPI_2CO_PWD}, 'JSON', $moosage );
  my $details = eval { $tco->detail_sale(); };
  like($@, qr/detail_sale requires sale_id or invoice_id/, 'caught empty param list error');
  my $sale_id;

  my $J = JSON::Any->new();
  SKIP:  {
     skip "VAPI_HAS_SALES not set in environment. No sales to retrieve", 2
         unless (defined $ENV{VAPI_HAS_SALES} && $ENV{VAPI_HAS_SALES} > 0) ;

     my $r = $tco->list_sales();
     my $salelistJ = $J->decode($r->content());
     my $sale =  $salelistJ->{sale_summary}[0];
     $sale_id =  $sale->{sale_id};

     $details = $tco->detail_sale(sale_id => $sale_id);
     ok($details->is_success(), 'got detail');
     my $saleJ = $J->decode($details->content());
     is( $saleJ->{sale}{invoices}[0]{sale_id}, $sale_id, "sale detail looks ok");

     my $invoice_id = $saleJ->{sale}{invoices}[0]{invoice_id};
     $details = $tco->detail_sale(invoice_id => $invoice_id);

     ok($details->is_success(), 'got detail');
     my $invoiceJ = $J->decode($details->content());
     is( $invoiceJ->{sale}{invoices}[0]{invoice_id}, $invoice_id, "sale detail looks ok");

     is($invoiceJ->{sale}{invoices}[0]{sale_id}, $sale_id, "sale id in voice sale as in sale_id query");
  }

  $sale_id = 42;  # should fail;
  $details = $tco->detail_sale(sale_id => $sale_id);
  ok($details->is_error, "got an error");
  my $errorJ = $J->decode($details->content());
  is($errorJ->{errors}[0]{code}, 'RECORD_NOT_FOUND', "Sale $sale_id not found");
}

SKIP: {
    skip "VAPI_2CO_UID && VAPI_2CO_PWD not set in environment" , 4
        unless $ENV{VAPI_2CO_UID} && $ENV{VAPI_2CO_PWD};

    foreach my $moosage (1, 0) {
      test_XML($moosage);
      test_JSON($moosage);
    }

}

done_testing();
