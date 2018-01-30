package WebService::SSLLabs;

use strict;
use warnings;
use JSON();
use URI::Escape();
use LWP::UserAgent();
use WebService::SSLLabs::Info();
use WebService::SSLLabs::Host();
use WebService::SSLLabs::Endpoint();
use WebService::SSLLabs::StatusCodes();

our $VERSION = '0.30';

sub _MINIMUM_ETA_TIME { return 10; }

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    $self->{url} = 'https://api.ssllabs.com/api/v2/';
    $self->{ua}  = LWP::UserAgent->new();
    $self->{ua}->env_proxy();
    return $self;
}

sub _parse_success {
    my ( $self, $response ) = @_;
    $self->{max_assessments} =
      $response->headers()->header('X-Max-Assessments');
    $self->{current_assessments} =
      $response->headers()->header('X-Current-Assessments');
    return;
}

sub max_assessments {
    my ($self) = @_;
    return $self->{max_assessments};
}

sub current_assessments {
    my ($self) = @_;
    return $self->{current_assessments};
}

sub info {
    my ($self)   = @_;
    my $url      = $self->{url} . 'info';
    my $response = $self->{ua}->get($url);
    if ( $response->is_success() ) {
        $self->_parse_success($response);
        return WebService::SSLLabs::Info->new(
            JSON::decode_json( $response->decoded_content() ) );
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub _translate_params {
    my ( $self, %params ) = @_;
    my %translated_params;
    foreach my $key ( sort { $a cmp $b } sort keys %params ) {
        if ( defined $params{$key} ) {
            my $translated_key = $key;
            $translated_key =~ s/_([[:lower:]])/uc $1/egsmx;
            $translated_params{$translated_key} = $params{$key};
        }
    }
    return %translated_params;
}

sub analyze {
    my ( $self, %params ) = @_;
    my %translated_params = $self->_translate_params(%params);
    my $url               = $self->{url} . 'analyze?' . (
        join q[&],
        map {
                URI::Escape::uri_escape_utf8($_) . q[=]
              . URI::Escape::uri_escape_utf8( $translated_params{$_} )
        } sort _sort_ssllabs_params keys %translated_params
    );
    my $response = $self->{ua}->get($url);
    if ( $response->is_success() ) {
        $self->_parse_success($response);
        my $host = WebService::SSLLabs::Host->new(
            JSON::decode_json( $response->decoded_content() ) );
        $self->{_previous_host} = $host;
        return $host;
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
    return;
}

sub previous_eta {
    my ($self) = @_;
    my $eta = _MINIMUM_ETA_TIME();
    if ( $self->{_previous_host} ) {
        my $host_eta = $self->{_previous_host}->eta();
        if (   ( defined $host_eta )
            && ( $host_eta =~ /^\d+$/smx )
            && ( $host_eta >= $eta ) )
        {
            $eta = $host_eta;
        }
    }
    return $eta;
}

sub _sort_ssllabs_params {
    if ( $a eq 'host' ) {
        return -1;
    }
    elsif ( $b eq 'host' ) {
        return 1;
    }
    if ( $a eq 's' ) {
        return -1;
    }
    elsif ( $b eq 's' ) {
        return 1;
    }
    else {
        return $a cmp $b;
    }
}

sub get_endpoint_data {
    my ( $self, %params ) = @_;
    my %translated_params = $self->_translate_params(%params);
    my $url               = $self->{url} . 'getEndpointData?' . (
        join q[&],
        map {
                URI::Escape::uri_escape_utf8($_) . q[=]
              . URI::Escape::uri_escape_utf8( $translated_params{$_} )
        } sort _sort_ssllabs_params keys %translated_params
    );
    my $response = $self->{ua}->get($url);
    if ( $response->is_success() ) {
        $self->_parse_success($response);
        return WebService::SSLLabs::Endpoint->new(
            JSON::decode_json( $response->decoded_content() ) );
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub get_status_codes {
    my ($self)   = @_;
    my $url      = $self->{url} . 'getStatusCodes';
    my $response = $self->{ua}->get($url);
    if ( $response->is_success() ) {
        $self->_parse_success($response);
        return WebService::SSLLabs::StatusCodes->new(
            JSON::decode_json( $response->decoded_content() ) );
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

sub get_root_certs_raw {
    my ($self)   = @_;
    my $url      = $self->{url} . 'getRootCertsRaw';
    my $response = $self->{ua}->get($url);
    if ( $response->is_success() ) {
        $self->_parse_success($response);
        return $response->decoded_content();
    }
    else {
        Carp::croak( "Failed to retrieve $url:" . $response->status_line() );
    }
}

1;    # End of WebService::SSLLabs
__END__

=head1 NAME

WebService::SSLLabs - Analyze the configuration of any SSL web server on the public Internet via ssllabs.com

=head1 VERSION

Version 0.30

=head1 SYNOPSIS

Check the security of your TLS services

    use WebService::SSLLabs;
    use v5.10;

    my $labs = WebService::SSLLabs->new();
    my $host;
    while(not $host = $labs->analyze(host => 'ssllabs.com')->complete()) {
        sleep $labs->previous_eta();
    }
    if ($host->ready()) {
        foreach my $endpoint ($host->endpoints()) {
           if ($endpoint->ready()) {
              say $host->host() . ' at ' . $endpoint->ip_address() . ' gets a ' . $endpoint->grade();
           } else {
              warn $host->host() . ' at ' . $endpoint->ip_address() . ' returned an error:' . $endpoint->status_message();
           }  
        }
    } else {
        warn $host->host() . ' returned an error:' . $host->status_message();
    }

=head1 DESCRIPTION

This is a client module for the L<https://www.ssllabs.com/ssltest> API, which provides a deep analysis
of the configuration of any SSL/TLS web server on the public Internet

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs> object, ready to process TLS services

=head2 info

This call should be used to check the availability of the SSL Labs servers, retrieve the engine and criteria version, and initialize the maximum number of concurrent assessments. Returns one L<Info|WebService::SSLLabs::Info> object on success.

=head2 analyze

This call is used to initiate an assessment, or to retrieve the status of an assessment in progress or in the cache. It will return a single L<Host|WebService::SSLLabs::Host> object on success. The L<Endpoint|WebService::SSLLabs::Endpoint> object embedded in the L<Host|WebService::SSLLabs::Host> object will provide partial endpoint results.

Parameters:

=over 4

=item * host - host name; required.

=item * publish - set to "on" if assessment results should be published on the public results boards; optional, defaults to "off".

=item * start_new - if set to "on" then cached assessment results are ignored and a new assessment is started. However, if there's already an assessment in progress, its status is delivered instead. This parameter should be used only once to initiate a new assessment; further invocations should omit it to avoid causing an assessment loop.

=item * from_cache - always deliver cached assessment reports if available; optional, defaults to "off". This parameter is intended for when you don't want to wait for assessment results. Can't be used at the same time as the start_new parameter.

=item * max_age - maximum report age, in hours, if retrieving from cache (from_cache parameter set).

=item * all - by default this call results only summaries of individual endpoints. If this parameter is set to "on", full information will be returned. If set to "done", full information will be returned only if the assessment is L<complete|WebService::SSLLabs::Host/"complete"> (L<status|WebService::SSLLabs::Host/"status"> is READY or ERROR).

=item * ignore_mismatch - set to "on" to proceed with assessments even when the server certificate doesn't match the assessment host name. Set to "off" by default. Please note that this parameter is ignored if a cached report is returned.

=back 

=head2 previous_eta

will return the highest of either 10 seconds or the L<eta|WebService::SSLLabs::Host/"eta"> values from the available L<endpoints|WebService::SSLLabs::Host/"endpoints"> from the previous L<analyze|WebService::SSLLabs/"analyze"> call.  This value is intended to act as the correct number of seconds to wait before calling L<analyze|WebService::SSLLabs/"analyze"> again

=head2 get_endpoint_data

This call is used to retrieve detailed endpoint information. It will return a single L<Endpoint|WebService::SSLLabs::Endpoint> object on success. The object will contain complete assessment information. This call does not initiate new assessments, even when a cached report is not found.

Parameters:

=over 4

=item * host - as above

=item * s - endpoint IP address

=item * from_cache - see above.

=back 

=head2 get_status_codes

This call will return one L<StatusCodes|WebService::SSLLabs::StatusCodes> instance.

=head2 max_assessments

This call will return the maximum number of concurrent assessments the client is allowed to initiate.  This information is only available after a L<analyze|WebService::SSLLabs/"analyze">, L<get_endpoint_data|WebService::SSLLabs/"get_endpoint_data">, L<info|WebService::SSLLabs/"info"> or L<get_status_codes|WebService::SSLLabs/"get_status_codes"> call has been made.  It is retrieved from the X-Max-Assessments header from a successful API call.

=head2 current_assessments

This call will return the number of ongoing assessments submitted by this client.  This information is only available after a L<analyze|WebService::SSLLabs/"analyze">, L<get_endpoint_data|WebService::SSLLabs/"get_endpoint_data">, L<info|WebService::SSLLabs/"info"> or L<get_status_codes|WebService::SSLLabs/"get_status_codes"> call has been made.  It is retrieved from the X-Current-Assessments header in a successful API call.

=head2 get_root_certs_raw

This call will return a scalar containing the root certificates used for trust validation.

=head1 DIAGNOSTICS

=over

=item C<< Failed to retrieve %s >>

The URL could not be retrieved. Check network and proxy settings.

=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs requires no configuration files or environment variables.  However, it will use the values of C<$ENV{no_proxy}> and C<$ENV{HTTP_PROXY}> as defaults for calls to the L<https://www.ssllabs.com/ssltest> API via the LWP::UserAgent module.

=head1 DEPENDENCIES

WebService::SSLLabs requires the following non-core modules

  JSON
  LWP::UserAgent
  URI
  URI::Escape

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-ssllabs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-SSLLabs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::SSLLabs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-SSLLabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-SSLLabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-SSLLabs>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-SSLLabs/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ivan Ristic and the team at L<https://www.qualys.com> for providing the service at L<https://www.ssllabs.com>

POD was extracted from the API help at L<https://github.com/ssllabs/ssllabs-scan/blob/stable/ssllabs-api-docs.md>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
