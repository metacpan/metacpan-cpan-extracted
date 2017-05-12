package WebService::SOS;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp qw(cluck);
use LWP::UserAgent;
use HTTP::Request::Common;
use URI::Escape;

use WebService::SOS::Capabilities;
use WebService::SOS::SensorDescription;
use WebService::SOS::Observations;
use WebService::SOS::Exception;

our $VERSION = '0.01';

# for extra debugging output
has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# return raw xml instead of an object
has 'rawxml' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'ua' => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    lazy_build => 1,
);

has 'server_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://lighthouse.tamucc.edu/sos',
);

has 'method' => (
    is      => 'ro',
    isa     => enum([qw(post get)]),
    default => 'post',
);

sub _build_ua {
    my ($self) = @_;
    return LWP::UserAgent->new( agent => 'WebService::SOS/' . $VERSION );
}

sub _check_response {
    my ($self, $response) = @_;
    
    unless ($response->is_success) {
        cluck("Error communicating with SOS server: ".$response->code." ".$response->message);
        return ( return => 1, retval => undef );
    }

    return ( return => 1, retval => $response->content ) if $self->rawxml;

    my %args = ( xml => $response->content, namespace_map => { ows => 'http://www.opengis.net/ows/1.1' } );
    # kluge due to bad xml at some sos servers
    $args{namespace_map} = { ows => 'http://www.opengis.net/ows' } if $response->content =~ m|xmlns="http://www.opengis.net/ows"|;

    my $resp = WebService::SOS::Exception->new(%args);
    return ( return => 1, retval => $resp ) if $resp->exception;

    return (return => 0 );
}

sub GetCapabilities {
    my $self = shift;
    my $response;
    if ($self->{method} =~ /^get$/i) {
        my $request = $self->server_url."?request=GetCapabilities&service=SOS&version=1.0.0";
        print STDERR "GetCapabilities: GET $request\n" if $self->debug;
        $response = $self->ua->get($request);
    }
    else {
        my $message = '<?xml version="1.0" encoding="UTF-8"?>
<sos:GetCapabilities
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://schemas.opengis.net/sos/1.0.0/sosAll.xsd"
   xmlns:sos="http://www.opengis.net/sos/1.0"
   xmlns:gml="http://www.opengis.net/gml/3.2"
   xmlns:ogc="http://www.opengis.net/ogc"
   xmlns:om="http://www.opengis.net/om/1.0" service="SOS">
</sos:GetCapabilities>';
        print STDERR "GetCapabilities: POST\n$message\n" if $self->debug > 0;
        $response = $self->ua->request(POST $self->server_url, Content_Type => 'text/xml', Content => $message);
    }

    my %check = _check_response($self,$response);
    return $check{retval} if $check{return};

    return WebService::SOS::Capabilities->new( xml => $response->content );
}

sub DescribeSensor {
    my ($self,$procedure) = @_;
    my $outputFormat = 'text/xml; subtype="sensorML/1.0.1"';
    my $response;
    if ($self->{method} =~ /^get$/i) {
        my $request = sprintf('%s?request=DescribeSensor&service=SOS&version=1.0.0&outputFormat=%s&procedure=%s',
                                    $self->server_url,
                                    uri_escape($outputFormat),
                                    uri_escape($procedure)
                                 );
        print STDERR "DescribeSensor: $request\n" if $self->debug;
        $response = $self->ua->get($request);
    }
    else {
        my $message = sprintf('<?xml version="1.0" encoding="UTF-8"?>
<DescribeSensor
    xmlns="http://www.opengis.net/sos/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.opengis.net/sos/1.0 http://schemas.opengis.net/sos/1.0.0/sosAll.xsd"
    service="SOS"
    outputFormat="text/xml;subtype=&quot;sensorML/1.0.1&quot;"
    version="1.0.0">
        <procedure>%s</procedure>
</DescribeSensor>',$procedure);
        print STDERR "DescribeSensor: POST\n$message\n" if $self->debug;
        $response = $self->ua->request(POST $self->server_url, Content_Type => 'text/xml', Content => $message);
    }

    my %check = _check_response($self,$response);
    return $check{retval} if $check{return};

    return WebService::SOS::SensorDescription->new( xml => $response->content );
}

sub GetObservation {
    my ($self,$offering,$observedProperty,$beginTime,$endTime) = @_;
    my $responseFormat = 'text/xml; subtype="om/1.0.0"';
    my $response;
    if ($self->{method} =~ /^get$/i) {
        my $request = sprintf('%s?request=GetObservation&service=SOS&version=1.0.0&responseFormat=%s&offering=%s&observedProperty=%s&eventTime=%s',
                                    $self->server_url,
                                    uri_escape($responseFormat),
                                    uri_escape($offering),
                                    uri_escape($observedProperty),
                                    uri_escape("$beginTime/$endTime")
                                 );
        print STDERR "GetObservation: $request\n" if $self->debug;
        $response = $self->ua->get($request);
    }
    else {
        my $message = sprintf('<?xml version="1.0" encoding="UTF-8"?>
<sos:GetObservation
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://schemas.opengis.net/sos/1.0.0/sosAll.xsd"
   xmlns:sos="http://www.opengis.net/sos/1.0"
   xmlns:gml="http://www.opengis.net/gml/3.2"
   xmlns:ogc="http://www.opengis.net/ogc"
   xmlns:om="http://www.opengis.net/om/1.0" service="SOS" version="1.0.0">
  <sos:offering>%s</sos:offering>
  <sos:observedProperty>%s</sos:observedProperty>
  <sos:responseFormat>%s</sos:responseFormat>
  <sos:eventTime>
    <ogc:TM_During>
      <ogc:PropertyName>om:samplingTime</ogc:PropertyName>
      <gml:TimePeriod>
        <gml:beginPosition>%s</gml:beginPosition>
        <gml:endPosition>%s</gml:endPosition>
      </gml:TimePeriod>
    </ogc:TM_During>
  </sos:eventTime>
  <result>
    <ogc:PropertyIsEqualTo>
        <ogc:PropertyName>VerticalDatum</ogc:PropertyName>
        <ogc:Literal>urn:ioos:def:datum:noaa::MLLW</ogc:Literal>
    </ogc:PropertyIsEqualTo>
  </result>
</sos:GetObservation>',$offering,$observedProperty,$responseFormat,$beginTime,$endTime);

        print STDERR "GetObservation: POST\n$message\n" if $self->debug;
        $response = $self->ua->request(POST $self->server_url, Content_Type => 'text/xml', Content => $message);
    }

    my %check = _check_response($self,$response);
    return $check{retval} if $check{return};

    return WebService::SOS::Observations->new( xml => $response->content );
}

__PACKAGE__->meta->make_immutable();

1;

__END__
__POD__

=head1 NAME

WebService::SOS - a module for interfacing with an OpenGIS Sensor Observation Service (SOS)

=head1 SYNOPSIS

 use WebService::SOS;

 my $sosclient = WebService::SOS->new( server_url => 'http://someserver.com/path/to/sos/server' );

 my $cap = $sosclient->GetCapabilities();

 my $desc = $sosclient->DescribeSensor($procedure);

 my $obs = $sosclient->GetObservation($offering,$observedProperty,$beginTime,$endTime);

=head1 DESCRIPTION

This module provides methods for interfacing with an OpenGIS Sensor Observation Service (SOS).

=over

=item * 

GetCapabilities

=over

=item *

get the capabillities

=back

=item *

DescribeSensor

=over

=item *

describe a sensor

=back

=item * 

GetObservation

=over

=item *

get an observation

=back

=back

=head1 METHODS

new(%args)

=over

 $sosclient = WebService::SOS->new( server_url => 'http://somehost.com/path/to/sos/server' );

options:

=over

C<server_url> - full url to the sos web service server (required)

C<method> - can be "post" (default) or "get"

C<debug> - set to 1 to get some debugging output on STDERR

=back

=back

GetCapabilities()

=over

 $cap = $sosclient->GetCapabilities();

this method takes no options

=back

DescribeSensor($procedure)

=over

 $desc = $sosclient->DescribeSensor($procedure);

options:

=over

C<$procedure> - the sensor to query (AllowedValues are specified in response from C<GetCapabilities()>)

=back

=back

GetObservation($offering,$observedProperty,$beginTime,$endTime)

=over

options:

=over

C<$offering> - the sensor to query (AllowedValues are specified in response from C<GetCapabilities()>)

C<$observedProperty> - the property to query for (AllowedValues are specified in response from C<GetCapabilities()>)

C<$beginTime> - the start of the time range for which you want to query (in ISO 8601 date and time format)

C<$endTime> - the end of the time range for which you want to query (in ISO 8601 date and time format)

=back

=back

=head1 ERRORS

This module C<cluck>s on all errors.

=head1 SEE ALSO

=over

L<http://www.opengeospatial.org/standards/sos> - documentation on the OpenGIS SOS standard

L<http://www.iso.org/iso/date_and_time_format> - ISO 8601 date and time format

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jamescdavis/WebService-SOS>

=head1 AUTHOR

James C. Davis, E<lt>jdavis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by James C. Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
