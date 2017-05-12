package WebService::Edgecast::auto::RealTime::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap;
BEGIN {
  $WebService::Edgecast::auto::RealTime::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap::VERSION = '0.01.00';
}
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require WebService::Edgecast::auto::RealTime::Typemap::EdgeCastWebServices
    if not WebService::Edgecast::auto::RealTime::Typemap::EdgeCastWebServices->can('get_class');

sub START {
    $_[0]->set_proxy('https://api.edgecast.com/v1/RealTime.asmx') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('WebService::Edgecast::auto::RealTime::Typemap::EdgeCastWebServices')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub BandwidthGet {
    my ($self, $body, $header) = @_;
    die "BandwidthGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'BandwidthGet',
        soap_action => 'EC:WebServices/BandwidthGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::RealTime::Element::BandwidthGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub ConnectionsGet {
    my ($self, $body, $header) = @_;
    die "ConnectionsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'ConnectionsGet',
        soap_action => 'EC:WebServices/ConnectionsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::RealTime::Element::ConnectionsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub StreamsGet {
    my ($self, $body, $header) = @_;
    die "StreamsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'StreamsGet',
        soap_action => 'EC:WebServices/StreamsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::RealTime::Element::StreamsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CacheStatusesGet {
    my ($self, $body, $header) = @_;
    die "CacheStatusesGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CacheStatusesGet',
        soap_action => 'EC:WebServices/CacheStatusesGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::RealTime::Element::CacheStatusesGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub StatusCodesGet {
    my ($self, $body, $header) = @_;
    die "StatusCodesGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'StatusCodesGet',
        soap_action => 'EC:WebServices/StatusCodesGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::RealTime::Element::StatusCodesGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

WebService::Edgecast::auto::RealTime::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap - SOAP Interface for the EdgeCastWebServices Web Service

=head1 VERSION

version 0.01.00

=head1 SYNOPSIS

 use WebService::Edgecast::auto::RealTime::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap;
 my $interface = WebService::Edgecast::auto::RealTime::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap->new();

 my $response;
 $response = $interface->BandwidthGet();
 $response = $interface->ConnectionsGet();
 $response = $interface->StreamsGet();
 $response = $interface->CacheStatusesGet();
 $response = $interface->StatusCodesGet();



=head1 DESCRIPTION

SOAP Interface for the EdgeCastWebServices web service
located at https://api.edgecast.com/v1/RealTime.asmx.

=head1 SERVICE EdgeCastWebServices

API for EdgeCast CDN Real-Time Reporting

=head2 Port EdgeCastWebServicesSoap



=head1 METHODS

=head2 General methods

=head3 new

Constructor.

All arguments are forwarded to L<SOAP::WSDL::Client|SOAP::WSDL::Client>.

=head2 SOAP Service methods

Method synopsis is displayed with hash refs as parameters.

The commented class names in the method's parameters denote that objects
of the corresponding class can be passed instead of the marked hash ref.

You may pass any combination of objects, hash and list refs to these
methods, as long as you meet the structure.

List items (i.e. multiple occurences) are not displayed in the synopsis.
You may generally pass a list ref of hash refs (or objects) instead of a hash
ref - this may result in invalid XML if used improperly, though. Note that
SOAP::WSDL always expects list references at maximum depth position.

XML attributes are not displayed in this synopsis and cannot be set using
hash refs. See the respective class' documentation for additional information.



=head3 BandwidthGet

This method call will get the real-time bandwidth (bps = bits per second) for a media type. <br>Bandwidth info is available for Flash (media type 2), HTTP Large Object (media type 3) and HTTP Small Object (media type 8). <br>Data updates every minute.<br>Partners may retrieve the information for any of their own customers. Customers may retrieve the information for themselves.<br><br>

Returns a L<WebService::Edgecast::auto::RealTime::Element::BandwidthGetResponse|WebService::Edgecast::auto::RealTime::Element::BandwidthGetResponse> object.

 $response = $interface->BandwidthGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 ConnectionsGet

This method call will get the real-time connections given the media type. <br>Connections info is available for all media types Flash (2), HTTP Large Object (3), HTTP Small Object (8) and Windows (1). <br>Data updates every minute.<br>Partners may retrieve the information for any of their own customers. Customers may retrieve the information for themselves.<br><br>

Returns a L<WebService::Edgecast::auto::RealTime::Element::ConnectionsGetResponse|WebService::Edgecast::auto::RealTime::Element::ConnectionsGetResponse> object.

 $response = $interface->ConnectionsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 StreamsGet

This method call will get the real-time streams information given the media type. <br>Per-stream info is only available for Windows (media type 1) and Flash (media type 2). <br>Data updates every minute.<br>Partners may retrieve the information for any of their own customers. Customers may retrieve the information for themselves.<br><br>

Returns a L<WebService::Edgecast::auto::RealTime::Element::StreamsGetResponse|WebService::Edgecast::auto::RealTime::Element::StreamsGetResponse> object.

 $response = $interface->StreamsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 CacheStatusesGet

This method call will get the real-time breakdown of cache statuses and hits per second for a media type. <br>Cache Statuses info is available for HTTP Large Object (media type 3) and HTTP Small Object (media type 8). <br>Data updates every minute.<br>Partners may retrieve the information for any of their own customers. Customers may retrieve the information for themselves.<br><br>

Returns a L<WebService::Edgecast::auto::RealTime::Element::CacheStatusesGetResponse|WebService::Edgecast::auto::RealTime::Element::CacheStatusesGetResponse> object.

 $response = $interface->CacheStatusesGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 StatusCodesGet

This method call will get the real-time breakdown of status codes information and hits per second for a media type. <br>Status Codes info is available for HTTP Large Object (media type 3) and HTTP Small Object (media type 8). <br>Data updates every minute.<br>Partners may retrieve the information for any of their own customers. Customers may retrieve the information for themselves.<br><br>

Returns a L<WebService::Edgecast::auto::RealTime::Element::StatusCodesGetResponse|WebService::Edgecast::auto::RealTime::Element::StatusCodesGetResponse> object.

 $response = $interface->StatusCodesGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Dec 22 13:08:28 2010

=cut