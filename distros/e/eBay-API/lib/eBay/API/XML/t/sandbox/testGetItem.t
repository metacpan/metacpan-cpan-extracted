#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

use Scalar::Util 'blessed';

print "Test GetItem call.\n";
use_ok('eBay::API::XML::Call::GetItem');

use HTTP::Response;
use HTTP::Status;

use eBay::API::XML::DataType::Enum::AckCodeType;
use eBay::API::XML::DataType::Enum::DetailLevelCodeType;

my $sItemId = 4076537994;
my $sSiteId = 203;

my $pCall = eBay::API::XML::Call::GetItem->new();

    # 1. set site id
$pCall->setSiteID($sSiteId);

    # 2. set itemId
my $pItemIDType = eBay::API::XML::DataType::ItemIDType->new();
$pItemIDType->setValue($sItemId);
$pCall->setItemID($pItemIDType);

    # 3. set detail level
    my $raDetailLevel = [
 eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll
,eBay::API::XML::DataType::Enum::DetailLevelCodeType::ItemReturnDescription
,eBay::API::XML::DataType::Enum::DetailLevelCodeType::ItemReturnAttributes
                        ];
$pCall->setDetailLevel( $raDetailLevel);

    # 4. execute the call
        # Do not execute the call.
        # Set it response from a file.
$pCall->execute();

is($pCall->getResponseAck(), 'Success', 'Successful response received.');
#print $pCall->getResponseRawXml();

my $pItem = $pCall->getItem();
my $pShippingDetails = $pItem->getShippingDetails();

my $raNewShippingServiceOptions = $pShippingDetails->getShippingServiceOptions();
#print Dumper( $raNewShippingServiceOptions);
foreach my $pNewShippingServiceOption (@$raNewShippingServiceOptions) {
   #print "pNewShippingServiceOption=|" . Dumper($pNewShippingServiceOption) . "|\n";
}

print "\n=====================================\n\n";

my $raNewInternationalShippingServiceOptions = 
                $pShippingDetails->getInternationalShippingServiceOption();
#print Dumper( $raNewInternationalShippingServiceOptions);
foreach my $pNewShippingServiceOption (@$raNewInternationalShippingServiceOptions) {
   #print "pNewInternationalShippingServiceOption=|" . Dumper($pNewShippingServiceOption) . "|\n";
}

#processAttributes_option_one( $pItem );

processAttributes_option_two( $pItem );

=head2  processAttributes_option_two()

This one propery handles a case when an attribute has more than one value.

=cut

sub processAttributes_option_two {

    my $pItem = shift;

    my @LocalAttributes = ();
    my @LocalAttributeSetIds = ();

    my $pAttributeSetArray = $pItem->getAttributeSetArray();
    my $raAttributes = $pAttributeSetArray->getAttributeSet();

    foreach my $pAttributeSet ( @$raAttributes ) {

    #    print Dumper( $pAttribute );
        my $sSetId = $pAttributeSet->getAttributeSetID();
        push @LocalAttributeSetIds, $sSetId;

        my $raNewAttributes = $pAttributeSet->getAttribute();
        foreach my $pAttribute ( @$raNewAttributes) {

                
            #print Dumper($pAttribute);
            my $raValType  = $pAttribute->getValue();
            #print Dumper($pValType);
            foreach my $pValType (@$raValType) {  
                my $rhAttr = {};   #{ id => 10244, value => "New", set_id => 2299 } 
                $rhAttr->{'set_id'} = $sSetId;
                $rhAttr->{'id'}     = $pAttribute->getAttributeID();
                $rhAttr->{'value'}  = $pValType->getValueLiteral();
                push @LocalAttributes, $rhAttr;
            }
        }
    }

    #print "LocalAttributeSetIds=|" . Dumper(\@LocalAttributeSetIds) . "\n";
    #print "LocalAttributes=|" . Dumper(\@LocalAttributes) . "\n";
}

=head2  processAttributes_option_one()

I think this processing has a bug in case we have 
more than one attribute value.

=cut

sub processAttributes_option_one {

    my $pItem = shift;

    my @LocalAttributes = ();
    my @LocalAttributeSetIds = ();

    my $pAttributeSetArray = $pItem->getAttributeSetArray();
    my $raAttributes = $pAttributeSetArray->getAttributeSet();

    foreach my $pAttributeSet ( @$raAttributes ) {

    #    print Dumper( $pAttribute );
        my $sSetId = $pAttributeSet->getAttributeSetID();
        push @LocalAttributeSetIds, $sSetId;

        my $raNewAttributes = $pAttributeSet->getAttribute();
        foreach my $pAttribute ( @$raNewAttributes) {

                
            my $rhAttr = {};   #{ id => 10244, value => "New", set_id => 2299 } 
            $rhAttr->{'set_id'} = $sSetId;
            $rhAttr->{'id'}     = $pAttribute->getAttributeID();
            $rhAttr->{'value'}  = undef;  # string
            push @LocalAttributes, $rhAttr;
            #print Dumper($pAttribute);

            my $raValType  = $pAttribute->getValue();
            #print Dumper($pValType);
            foreach my $pValType (@$raValType) {  # there should be only one element
                $rhAttr->{'value'} = $pValType->getValueLiteral();
            }
        }
    }

    print "LocalAttributeSetIds=|" . Dumper(\@LocalAttributeSetIds) . "\n";
    print "LocalAttributes=|" . Dumper(\@LocalAttributes) . "\n";
}


