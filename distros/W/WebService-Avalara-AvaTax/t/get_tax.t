#!/usr/bin/env perl

use strict;
use warnings;

use Const::Fast;
use English '-no_match_vars';
use Sys::Hostname;
use Test::More tests => 5;
use Test::File::ShareDir::Module 1.000000 {
    'WebService::Avalara::AvaTax::Service::Tax' => 'shares/ServiceTax/'
};
use XML::Compile::Tester;
use XML::Compile::Util;
use WebService::Avalara::AvaTax::Service::Tax;

const my $NAMESPACE_URI => 'http://avatax.avalara.com/services';
const my %AUTH          => (
    username => 'avalara@example.com',
    password => 'sekrit',
);

my $tax_service = WebService::Avalara::AvaTax::Service::Tax->new(%AUTH);
my $type = pack_type( $NAMESPACE_URI, 'GetTax' );

my $writer = writer_create( $tax_service->wsdl, 'get_tax', $type );
my %request_data = _request_data();
my $doc = writer_test( $writer => { GetTaxRequest => \%request_data } );
compare_xml( $doc, join( q{} => <main::DATA> ), 'XML comparison' );

sub _request_data {
    my %get_tax_request = (
        CompanyCode         => 'APITrialCompany',
        DocType             => 'SalesInvoice',
        DocCode             => 'INV001',
        DocDate             => '2014-01-01',
        CustomerCode        => 'ABC4335',
        Discount            => 0,
        OriginCode          => 0,
        DestinationCode     => 1,
        DetailLevel         => 'Tax',
        HashCode            => 0,
        Commit              => 'false',
        ServiceMode         => 'Automatic',
        PaymentDate         => '1900-01-01',
        ExchangeRate        => 1,
        ExchangeRateEffDate => '1900-01-01',
    );

    my @addresses = (
        {   Line1       => '45 Fremont Street',
            City        => 'San Francisco',
            Region      => 'CA',
            PostalCode  => '94105-2204',
            Country     => 'US',
            TaxRegionId => 0,
        },
        {   Line1       => '118 N Clark St',
            Line2       => 'ATTN Accounts Payable',
            City        => 'Chicago',
            Region      => 'IL',
            PostalCode  => '60602-1304',
            Country     => 'US',
            TaxRegionId => 0,
        },
        {   Line1       => '100 Ravine Lane',
            City        => 'Bainbridge Island',
            Region      => 'WA',
            PostalCode  => '98110',
            Country     => 'US',
            TaxRegionId => 0,
        },
    );
    for my $address_code ( 0 .. $#addresses ) {
        push @{ $get_tax_request{Addresses}{BaseAddress} } => {
            AddressCode => $address_code,
            %{ $addresses[$address_code] },
        };
    }

    my @lines = (
        {   OriginCode      => 0,
            DestinationCode => 1,
            ItemCode        => 'N543',
            TaxCode         => 'NT',
            Qty             => 1,
            Amount          => 10,
            Discounted      => 'false',
            Description     => 'Red Size 7 Widget',
        },
        {   OriginCode      => 0,
            DestinationCode => 2,
            ItemCode        => 'T345',
            TaxCode         => 'PC030147',
            Qty             => 3,
            Amount          => 150,
            Discounted      => 'false',
            Description     => 'Size 10 Green Running Shoe',
        },
        {   OriginCode      => 0,
            DestinationCode => 2,
            ItemCode        => 'FREIGHT',
            TaxCode         => 'FR',
            Qty             => 1,
            Amount          => 15,
            Discounted      => 'false',
            Description     => 'Shipping Charge',
        },
    );
    for my $line_no ( 1 .. @lines ) {
        push @{ $get_tax_request{Lines}{Line} } => {
            No => $line_no,
            %{ $lines[ $line_no - 1 ] },
        };
    }

    return %get_tax_request;
}

__DATA__
<tns:GetTax>
  <tns:GetTaxRequest>
    <tns:CompanyCode>APITrialCompany</tns:CompanyCode>
    <tns:DocType>SalesInvoice</tns:DocType>
    <tns:DocCode>INV001</tns:DocCode>
    <tns:DocDate>2014-01-01</tns:DocDate>
    <tns:CustomerCode>ABC4335</tns:CustomerCode>
    <tns:Discount>0</tns:Discount>
    <tns:OriginCode>0</tns:OriginCode>
    <tns:DestinationCode>1</tns:DestinationCode>
    <tns:Addresses>
      <tns:BaseAddress>
        <tns:AddressCode>0</tns:AddressCode>
        <tns:Line1>45 Fremont Street</tns:Line1>
        <tns:City>San Francisco</tns:City>
        <tns:Region>CA</tns:Region>
        <tns:PostalCode>94105-2204</tns:PostalCode>
        <tns:Country>US</tns:Country>
        <tns:TaxRegionId>0</tns:TaxRegionId>
      </tns:BaseAddress>
      <tns:BaseAddress>
        <tns:AddressCode>1</tns:AddressCode>
        <tns:Line1>118 N Clark St</tns:Line1>
        <tns:Line2>ATTN Accounts Payable</tns:Line2>
        <tns:City>Chicago</tns:City>
        <tns:Region>IL</tns:Region>
        <tns:PostalCode>60602-1304</tns:PostalCode>
        <tns:Country>US</tns:Country>
        <tns:TaxRegionId>0</tns:TaxRegionId>
      </tns:BaseAddress>
      <tns:BaseAddress>
        <tns:AddressCode>2</tns:AddressCode>
        <tns:Line1>100 Ravine Lane</tns:Line1>
        <tns:City>Bainbridge Island</tns:City>
        <tns:Region>WA</tns:Region>
        <tns:PostalCode>98110</tns:PostalCode>
        <tns:Country>US</tns:Country>
        <tns:TaxRegionId>0</tns:TaxRegionId>
      </tns:BaseAddress>
    </tns:Addresses>
    <tns:Lines>
      <tns:Line>
        <tns:No>1</tns:No>
        <tns:OriginCode>0</tns:OriginCode>
        <tns:DestinationCode>1</tns:DestinationCode>
        <tns:ItemCode>N543</tns:ItemCode>
        <tns:TaxCode>NT</tns:TaxCode>
        <tns:Qty>1</tns:Qty>
        <tns:Amount>10</tns:Amount>
        <tns:Discounted>false</tns:Discounted>
        <tns:Description>Red Size 7 Widget</tns:Description>
      </tns:Line>
      <tns:Line>
        <tns:No>2</tns:No>
        <tns:OriginCode>0</tns:OriginCode>
        <tns:DestinationCode>2</tns:DestinationCode>
        <tns:ItemCode>T345</tns:ItemCode>
        <tns:TaxCode>PC030147</tns:TaxCode>
        <tns:Qty>3</tns:Qty>
        <tns:Amount>150</tns:Amount>
        <tns:Discounted>false</tns:Discounted>
        <tns:Description>Size 10 Green Running Shoe</tns:Description>
      </tns:Line>
      <tns:Line>
        <tns:No>3</tns:No>
        <tns:OriginCode>0</tns:OriginCode>
        <tns:DestinationCode>2</tns:DestinationCode>
        <tns:ItemCode>FREIGHT</tns:ItemCode>
        <tns:TaxCode>FR</tns:TaxCode>
        <tns:Qty>1</tns:Qty>
        <tns:Amount>15</tns:Amount>
        <tns:Discounted>false</tns:Discounted>
        <tns:Description>Shipping Charge</tns:Description>
      </tns:Line>
    </tns:Lines>
    <tns:DetailLevel>Tax</tns:DetailLevel>
    <tns:HashCode>0</tns:HashCode>
    <tns:Commit>false</tns:Commit>
    <tns:ServiceMode>Automatic</tns:ServiceMode>
    <tns:PaymentDate>1900-01-01</tns:PaymentDate>
    <tns:ExchangeRate>1</tns:ExchangeRate>
    <tns:ExchangeRateEffDate>1900-01-01</tns:ExchangeRateEffDate>
  </tns:GetTaxRequest>
</tns:GetTax>
