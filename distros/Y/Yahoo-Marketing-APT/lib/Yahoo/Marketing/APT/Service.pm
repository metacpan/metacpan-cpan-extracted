package Yahoo::Marketing::APT::Service;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;
use Carp;
use YAML qw/DumpFile LoadFile Dump/;

use base qw/Yahoo::Marketing::APT Yahoo::Marketing::Service/;


# need to override @simple_type_exceptions!
sub simple_type_exceptions {
return (qw/
AccountDescriptorType
AccountStatus
AccountType
AdBehavior
AdFormat
AdjustmentInboundFeedStatus
AdjustmentInboundFeedType
AdLinkingType
AdSecurity
AdStatus
AdType
AgreementStatus
ApprovalCategory
ApprovalObjectType
ApprovalStatus
ApprovalTaskContext
ApprovalTaskStatus
ApprovalTrigger
ApprovalType
ApprovalWorkflowExecutionType
ApprovalWorkflowNotificationType
ApprovalWorkflowStatus
ApproverType
AudienceSegmentStatus
BuyType
ColumnFormatType
ComplaintStatus
Context
Country
CreativeStatus
CreativeType
Currency
CustomGeoAreaStatus
CustomTargetingAttributeOwnership
DataGrouping
DayOfTheWeek
DealApprovalStatus
DeliveryLevel
DeliveryMethod
DeliveryModel
DeliveryType
DiscountFormat
DiscountType
DistanceUnits
EditorialStatus
EndDateChangeType
FileType
FolderItemType
FolderType
ImpressionChangeType
Language
LibraryAdStatus
LinkedCompanyType
LinkType
Locale
Month
OperationResult
OptimizationMetric
OrderContactType
OrderCreditStatus
OrderFeeStatus
OrderFeeType
OrderStatus
Origin
PixelCodeType
PixelFrequencyType
PlacementEditQtyChangeType
PlacementEditQtyType
PlacementStatus
PlacementTargetType
PriceChangeType
PricingType
ProcessingStatus
PublisherSelectorType
RateCardStatus
ReconciliationAction
ReportCurrency
ReportDateRange
ReportExecutionStatus
ReportFrequency
RevenueModel
SearchAccountType
SellingRuleType
ServiceContext
SiteAccessMethod
SiteStatus
SourceOwnerType
TagStatus
TagType
TargetingAttributeType
TemplateStatus
TimePeriodType
TimeZone
UserStatus
VideoCreativeProcessingStatus
WindowTarget
YahooPremiumBehavioralSegmentTargetingProgram
			      /);
}

# override parse_config to use yahoo-marketing-apt.yml as the default config file
sub parse_config {
    my ( $self, %args ) = @_;

    $args{ path }    = 'yahoo-marketing-apt.yml' unless defined $args{ path };
    $args{ section } = 'default'             unless defined $args{ section };

    my $config = LoadFile( $args{ path } );

    foreach my $config_setting ( qw/ username password license endpoint uri version / ){
        my $value = $config->{ $args{ 'section' } }->{ $config_setting };
        croak "no configuration value found for $config_setting in $args{ path }\n"
            unless $value;
        $self->$config_setting( $value );
    }

    foreach my $config_setting ( qw/ default_account default_on_behalf_of_username default_on_behalf_of_password / ){
        my $value = $config->{ $args{ 'section' } }->{ $config_setting };
        my $setting_name = $config_setting;
        $setting_name =~ s/^default_//;
        # Maybe we should let the default overwrite ???
        $self->$setting_name( $value ) if defined $value and not defined $self->$setting_name;
    }

    return $self;
}

# override _location, since we cache endpoint with accountID now, instead of masterAccountID.
sub _location {
    my $self = shift;

    unless( $self->use_location_service ){
        return $self->endpoint.'/'.$self->version;
    }

    my $locations = $self->cache->get( 'locations' );

    if( $locations
	and $locations->{ $self->version }->{ $self->endpoint }
	and $locations->{ $self->version }->{ $self->endpoint }->{ $self->account } ){
        return $locations->{ $self->version }->{ $self->endpoint }->{ $self->account };
    }

    my $som = $self->_soap( $self->endpoint
                           .'/'
                           .$self->version
                           .'/LocationService'
                          )
	->getAccountLocation( $self->_headers() );

    if( $som->fault ){
        $self->fault( $self->_get_api_fault_from_som( $som ) );
        $self->_die_with_soap_fault( $som ) unless $self->immortal;
        warn "we could not determine the correct location endpoint, trying with default";
        return $self->endpoint.'/'.$self->version;
    }

    my $location = $som->valueof( '/Envelope/Body/getAccountLocationResponse/out' );

    die "failed to get Account Location!" unless $location;

    $location .= '/'.$self->version;

    $locations->{ $self->version }->{ $self->endpoint }->{ $self->account } = $location ;

    $self->cache->set( 'locations', $locations, $self->cache_expire_time );

    return $location;
}

sub _add_account_to_header { return 1; }  # default to true

sub _add_master_account_to_header { return 0; }  # default to false

sub _class_name {
    __PACKAGE__ =~ /^(.+)Service/;
    return $1;
}


# since APT web service v4.0, the wsdl has changed structure,
# so we have to override some methods from Service.pm in parent class.
sub _parse_wsdl {
    my ( $self, ) = @_;

    if( my $wsdl_data = $self->cache->get( $self->_wsdl ) ){
        $Yahoo::Marketing::Service::service_data->{ $self->_wsdl } = $wsdl_data;
        return;
    }

    my $xpath = XML::XPath->new(
        xml => SOAP::Schema->new(schema_url => $self->_wsdl )->access
	);

    foreach my $node ( $xpath->find( q{/wsdl:definitions/wsdl:types/xsd:schema/* } )->get_nodelist ){
        my $name = $node->getName;
        if( $name eq 'xsd:complexType' ){
            if( $node->getAttribute('name') and ($node->getAttribute('name') =~ /^[a-z].+Response(Type)?$/) ){
                $self->_parse_response_type( $node, $xpath );
            }elsif( $node->getAttribute('name') and ($node->getAttribute('name') =~ /^[a-z]/) ) {
                $self->_parse_request_type( $node, $xpath );
            }else{
                $self->_parse_complex_type( $node, $xpath );
            }
        }
    }

    $self->cache->set( $self->_wsdl, $Yahoo::Marketing::Service::service_data->{ $self->_wsdl }, $self->cache_expire_time );
    return;
}

sub _parse_request_type {
    my ( $self, $node, $xpath ) = @_;
    my $type_name = $node->getAttribute( 'name' );

    return unless $type_name;

    my $def = $xpath->find( qq{/wsdl:definitions/wsdl:types/xsd:schema/xsd:complexType[\@name='$type_name']/xsd:sequence/xsd:element} );

    return unless $def;

    foreach my $def_node ( $def->get_nodelist ){

        my $name = $def_node->getAttribute( 'name' );
        my $type = $def_node->getAttribute( 'type' );

        $Yahoo::Marketing::Service::service_data->{ $self->_wsdl }->{ type_map }->{ $type_name }->{ _name } = $name ;
        $Yahoo::Marketing::Service::service_data->{ $self->_wsdl }->{ type_map }->{ $type_name }->{ $name } = $type ;
    }

    return;
}

sub _parse_response_type {
    my ( $self, $node, $xpath ) = @_;
    my $type_name = $node->getAttribute( 'name' );
    $type_name =~ s/(^tns:)|(^xsd:)//;

    my $def = $xpath->find( qq{/wsdl:definitions/wsdl:types/xsd:schema/xsd:complexType[\@name='$type_name']/xsd:sequence/xsd:element[\@name='out']} );
    return unless $def;

    my $def_node = ($def->get_nodelist)[0];   # there's always just one

    ( my $name = $def_node->getAttribute( 'name' ) ) =~ s/^tns://;
    ( my $type = $def_node->getAttribute( 'type' ) ) =~ s/^tns://;

    $Yahoo::Marketing::Service::service_data->{ $self->_wsdl }->{ type_map }->{ $type_name }->{ _name } = $name ;
    $Yahoo::Marketing::Service::service_data->{ $self->_wsdl }->{ type_map }->{ $type_name }->{ $name } = $type ;

    return;
}


1; # end of Yahoo::Marketing::APT::Service


=head1 NAME

Yahoo::Marketing::APT::Service - a sub-class of Yahoo::Marketing::Service, and the base class of APT service modules

=head1 SYNOPSIS

This module is a base class for various Service modules (SiteService,
FolderService, ReportService, etc) to inherit from.  It should not be used directly.

Please see the Yahoo APT API docs at

http://help.yahoo.com/l/us/yahoo/ewsapt/webservices/reference/index.html

for details about what methods are available from each of the Services.

=head1 SEE ALSO

Yahoo::Marketing::Service L<http://search.cpan.org/dist/Yahoo-Marketing/lib/Yahoo/Marketing/Service.pm>

