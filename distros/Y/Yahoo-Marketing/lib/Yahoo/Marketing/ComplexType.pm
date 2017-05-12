package Yahoo::Marketing::ComplexType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::DateTimeAccessor Yahoo::Marketing /;

use Carp;
use Scalar::Util qw/ blessed /;
use SOAP::Lite;


=head1 NAME

Yahoo::Marketing::ComplexType - a base class for complex types.

=cut

=head1 SYNOPSIS

See L<http://searchmarketing.yahoo.com/developer/docs/V7/reference/dataObjects.php> for documentation of the various data objects.

This module is not intended to be used directly.   Documentation for each of the complex types is in the appropriate module.  

See perldoc Yahoo::Marketing::Account
                         ...::Ad
                         ...::AdEditorialReasons
                         ...::AdGroup
                         ...::AdGroupOptimizationGuidelines
                         ...::Address
                         ...::AmbiguousGeoMatch
                         ...::ApiFault
                         ...::Authorization
                         ...::BasicReportRequest
                         ...::BidInformation
                         ...::BucketType
                         ...::Campaign
                         ...::CampaignOptimizationGuidelines
                         ...::Capability
                         ...::ComplexType
                         ...::CreditCardInfo
                         ...::ErrorType
                         ...::ExcludedWord
                         ...::FileOutputFormat
                         ...::ForecastKeyword
                         ...::ForecastKeywordResponse
                         ...::ForecastRequestData
                         ...::ForecastResponse
                         ...::ForecastResponseData
                         ...::Keyword
                         ...::KeywordOptimizationGuidelines
                         ...::KeywordRejectionReasons
                         ...::MasterAccount
                         ...::PageRelatedKeywordRequestType
                         ...::PendingAd
                         ...::PendingKeyword
                         ...::RangeDefinitionRequestType
                         ...::RangeDefinitionResponseType
                         ...::RangeDefinitionType
                         ...::RangeValueType
                         ...::RelatedKeywordRequestType
                         ...::RelatedKeywordResponseType
                         ...::RelatedKeywordType
                         ...::ReportInfo
                         ...::ResponseStatusType
                         ...::Role
                         ...::Serializer
                         ...::SetGeographicLocationResponse
                         ...::Term
                         ...::User
                         ...::UserAuthorization

=head2 user_setable_attributes

Returns the name of all attributes that are not read-only in EWS

=head2 read_only_attributes

Returns the name of all attributes that are read-only in EWS



=cut 


sub _type {
    my $self = shift;

    return (split /::/, ref $self)[-1] ;
}


sub _new_from_hash {
    my ( $self, $hash ) = @_;

    $self = $self->new unless blessed( $self ); # allow this to be called w/o new() first

    my $obj_type = ref $self;

    my $new_obj = $obj_type->new;

    foreach my $key ( keys %$hash ){
        $new_obj->$key( $hash->{ $key } );
    }
    return $new_obj;
}

sub user_setable_attributes {
    return shift->_user_setable_attributes;
}

sub read_only_attributes {
    return shift->_read_only_attributes;
}

sub _user_setable_attributes {
    confess "Must implement _user_setable_attributes in child class!\n";
}

sub _read_only_attributes {
    confess "Must implement _read_only_attributes in child class!\n";
}


1;
