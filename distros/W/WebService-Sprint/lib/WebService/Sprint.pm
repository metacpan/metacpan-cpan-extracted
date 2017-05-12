package WebService::Sprint;

use warnings;
use strict;

=head1 NAME

WebService::Sprint - an interface to Sprint's web services

=head1 VERSION

Version 0.50

=cut

our $VERSION = '0.50';

use DateTime;
use Digest::MD5 qw(md5_hex);
use LWP::Simple;
use LWP::UserAgent;
use JSON;
use URI;

my %DEFAULTS = (
    base_url =>
      "http://sprintdevelopersandbox.com/developerSandbox/resources/v1/",
    user_agent => "WebService::Sprint",
);

my %SERVICES = (
    location  => 'location.json',
    presence  => 'presence.json',
    perimeter => 'geofence/checkPerimeter.json',
    devices   => 'devices.json',
    device    => 'device.json',
);

=head1 DESCRIPTION

Provides an object-oriented interface to Sprint's developer web services, including geolocation of devices on Sprint's CDMA network in the United States.

Disclaimer: I am not affiliated with Sprint. This is an implementation of their publicly-available specifications. Sprint is probably a registered trademark, and is used here to highlight that this implementation is specific to the Sprint network.

Implements some features of Sprint's developer web services. For more information, see:

=over 4

=item * L<http://developer.sprint.com/site/global/sandbox/home.jsp>

=item * L<http://developer.sprint.com/site/global/sandbox/sprint_services/sprint_services.jsp>

=item * L<https://developer.sprint.com/dynamicContent/sprintservices/devtools/>

=back

Currently supports:

=over 4

=item * Presence

=item * Location (3G)

=item * Geofence perimeter check

=item * User management -- retrieving list of devices, adding or removing devices

=back

Does not support:

=over 4

=item * All other geofence operations

=item * SMS

=item * iDen Content Uploader

=back

=head1 SYNOPSIS

    use WebService::Sprint;

    my $ws = WebService::Sprint->new(
      key    => '0123456789abcdef',
      secret => 'fedcba98765432100123456789abcdef',
    );

    # Get the list of devices associated with your developer account
    my $devices = $ws->get_devices(

      # Optionally limit to devices in a particular state
      type   => 'approved',
    );

    # Request addition of a device to your account (requires user approval
    # via SMS)
    my $device = $ws->add_device(
      mdn    => '2225551212',
    );

    # Remove a device from your account
    my $device = $ws->del_device(
      mdn    => '2225551212',
    );

    # Check whether a given device is present on the network
    my $presence = $ws->get_presence(
      mdn    => '2225551212',
    );

    # Fetch the network location of a single device
    my $location = $ws->get_location(
      mdn    => '2225551212',
    );

    # Fetch the location of multiple devices (issues multiple queries
    # behind the scenes, serially)
    my @locations = $ws->get_location(
      mdn    => [qw(2225551212 8885551234)],
    );

    # Check whether a device is within a given geofence
    my $location = $ws->check_perimeter(
      mdn       => '2225551212',

      # Geofence coordinates in Decimal Degrees
      latitude  => 45.000,
      longitude => -120.000,

      # Radius in meters (server requires at least 2000 meters)
      radius    => 5000,
    );

=head1 METHODS

=head2 new

Instantiates a Web Service object. Named arguments include:
    B<key>: Your Sprint-assigned developer key
    B<secret>: Your Sprint-assigned shared secret
    B<base_url>: The base URL for Sprint services (defaults to L<http://sprintdevelopersandbox.com/developerSandbox/resources/v1/>)
    B<user_agent>: HTTP user agent used (defaults to L<WebService::Sprint>)

=cut

sub new {
    die "Arguments must be valid name-value pairs"
      unless @_ % 2;
    my ( $class, %args ) = @_;

    my $self = {};

    _get_defaults( $self, \%args );

    bless $self, $class;

    return $self;

}

sub _get_defaults {
    my ( $dst, $src ) = @_;

    if (  !defined $dst
        || ref $dst ne 'HASH'
        || !defined $src
        || ref $src ne 'HASH' )
    {
        die "Invalid parameters";
    }

    while ( my ( $name, $value ) = each %DEFAULTS ) {
        $dst->{$name} = $value;
    }

    while ( my ( $name, $value ) = each %{$src} ) {
        $dst->{$name} = $value;
    }

    return;
}

=head2 get_devices

Given no arguments, returns a hashref of devices associated with your developer account, indicating status.
Given the argument B<mdn> with a valid 10-digit phone number, returns information about that device only.
Given the argument B<type> (I<pending>, I<declined>, I<deleted>, I<approved>, I<all>), returns information about only that subset of devices associated with your account.

=cut

sub get_devices {
    my ( $self, %args ) = @_;

    my %params;

    my $mdn;
    if ( defined $args{mdn} ) {
        if ( $mdn = _clean_mdn( $args{mdn} ) ) {
            $params{type} = 'mdn';
            $params{mdn}  = $mdn;
        }
        else {
            die "Invalid MDN: $args{mdn}\n";
        }
    }
    else {
        if ( defined $args{type} ) {
            $params{type} =
                ( $args{type} =~ m/^p(?:ending)?/i )  ? 'p'
              : ( $args{type} =~ m/^dec(?:lined)?/i ) ? 'x'
              : ( $args{type} =~ m/^del(?:eted)?/i )  ? 'd'
              : ( $args{type} =~ m/^ap(?:proved)/i )  ? 'a'
              : ( $args{type} =~ m/^al(?:l)/i )       ? 'null'
              :   die "Invalid type: $args{type}\n";
        }
    }

    my $devices = $self->issue_query(
        service => 'devices',
        params  => \%params,
    );

    my %devices = (
        original  => $devices,
        timestamp => time,
    );
    my @devices;

    $devices{auth_status} = lc _best_match( $devices, qr/^auth.?status/i );
    my $device_list = $devices->{devices};
    if ( defined $device_list ) {
        if ( ref $device_list eq 'HASH' ) {
            while ( my ( $status, $list ) = each %{$device_list} ) {
                if ( defined $list && ref $list eq 'ARRAY' ) {
                    foreach my $mdn ( @{$list} ) {
                        push(
                            @devices,
                            {
                                mdn    => $mdn,
                                status => lc $status,
                            },
                        );
                    }
                }
            }
        }
        elsif ( ref $device_list eq 'ARRAY' ) {
            foreach my $mdn ( @{$device_list} ) {
                push(
                    @devices,
                    {
                        mdn    => $mdn,
                        status => $devices{auth_status},
                    },
                );
            }
        }
        else {
            $devices{devices} = $device_list;
        }
    }

    $devices{devices}  = \@devices;
    $devices{username} = _best_match( $devices, qr/^username/i );
    $devices{error}    = _best_match( $devices, qr/^error/i );

    return \%devices;
}

=head2 add_device

Given the argument B<mdn> with a valid 10-digit phone number, attempts to add the user to your account. Returns a hashref including status of the request.

=cut

sub add_device {
    my ( $self, %args ) = @_;

    my %params = ( method => 'add', );

    my $mdn;
    if ( defined $args{mdn} ) {
        if ( $mdn = _clean_mdn( $args{mdn} ) ) {
            $params{mdn} = $mdn;
        }
        else {
            die "Invalid MDN: $args{mdn}\n";
        }
    }
    else {
        return;
    }

    my $device = $self->issue_query(
        service => 'device',
        params  => \%params,
    );

    my %device = (
        original  => $device,
        timestamp => time,
    );

    $device{mdn} = lc _best_match( $device, qr/^mdn$/i ) || $params{mdn};
    $device{status} = lc _best_match( $device, qr/^message/i );
    $device{error} = _best_match( $device, qr/^error/i );

    return \%device;
}

=head2 del_device

Given the argument B<mdn> with a valid 10-digit phone number, attempts to remove the user from your account. Returns a hashref including status of the request.

=cut

sub del_device {
    my ( $self, %args ) = @_;

    my %params = ( method => 'delete', );

    my $mdn;
    if ( defined $args{mdn} ) {
        if ( $mdn = _clean_mdn( $args{mdn} ) ) {
            $params{mdn} = $mdn;
        }
        else {
            die "Invalid MDN: $args{mdn}\n";
        }
    }
    else {
        return;
    }

    my $device = $self->issue_query(
        service => 'device',
        params  => \%params,
    );

    my %device = (
        original  => $device,
        timestamp => time,
    );

    $device{mdn} = lc _best_match( $device, qr/^mdn$/i ) || $params{mdn};
    $device{status} = lc _best_match( $device, qr/^message/i );
    $device{error} = _best_match( $device, qr/^error/i );

    return \%device;
}

=head2 get_presence

Given the argument B<mdn> as a single or list of 10-digit phone numbers, returns a hashref (or list of hashrefs) with detailed information about the presence of the requested device on the Sprint network.

This call should not use your credits.

=cut

sub get_presence {
    my ( $self, %args ) = @_;

    if ( !defined $args{mdn} ) {
        return;
    }

    if ( ref $args{mdn} eq 'ARRAY' ) {
        my @response;
        foreach my $mdn ( @{ $args{mdn} } ) {
            push( @response, $self->get_presence( mdn => $mdn ) );
        }
        return @response;
    }

    if ( my $mdn = _clean_mdn( $args{mdn} ) ) {
        my $presence = $self->issue_query(
            service => 'presence',
            params  => { mdn => $mdn, },
        );

        my %presence = (
            original  => $presence,
            mdn       => $mdn,
            timestamp => time,
        );

        $presence{error} = _best_match( $presence, qr/^error/i );

        my $reachable = _best_match( $presence, qr/^status/i );
        $presence{reachable} =
          ( $reachable && $reachable =~ m/^reachable/i ) ? 1 : 0;

        my $response_mdn = _best_match( $presence, qr/^mdn/i );
        if ( defined $response_mdn && $mdn ne $response_mdn ) {
            die "Response received for incorrect MDN: $response_mdn\n";
        }

        return \%presence;
    }
    else {
        die "Invalid MDN: $args{mdn}\n";
    }
}

=head2 get_location

Given the argument B<mdn> as a single or list of 10-digit phone numbers, returns a hashref (or list of hashrefs) with detailed information about the location of the requested device. This usually returns a network-determined low-precision location for the device, and completes within about 5 seconds. It usually does I<not> activate the device's GPS receiver.

B<WARNING: This uses credits (3 per device query, last I checked)!>

=cut

sub get_location {
    my ( $self, %args ) = @_;

    if ( !defined $args{mdn} ) {
        return;
    }

    if ( ref $args{mdn} eq 'ARRAY' ) {
        my @response;
        foreach my $mdn ( @{ $args{mdn} } ) {
            push( @response, $self->get_location( mdn => $mdn ) );
        }
        return @response;
    }

    if ( my $mdn = _clean_mdn( $args{mdn} ) ) {
        my $location = $self->issue_query(
            service => 'location',
            params  => { mdn => $mdn, },
        );

        my %location = (
            original  => $location,
            mdn       => $mdn,
            timestamp => time,
        );

        $location{error}     = _best_match( $location, qr/^error/i );
        $location{latitude}  = _best_match( $location, qr/^lat/i );
        $location{longitude} = _best_match( $location, qr/^lon/i );
        $location{accuracy}  = _best_match( $location, qr/^accuracy/i );
        if ( _best_match( $location, qr/^old/i ) ) {
            $location{old}++;
        }

        my $response_mdn = _best_match( $location, qr/^mdn/i );
        if ( defined $response_mdn && $mdn ne $response_mdn ) {
            die "Response received for incorrect MDN: $response_mdn\n";
        }

        return \%location;
    }
    else {
        die "Invalid MDN: $args{mdn}\n";
    }
}

=head2 check_perimeter

Works similarly to C<get_location>, but is intended to determine whether a given device is within a specified geofence. Takes the additional (required) parameters B<latitude>, B<longitude> (both in decimal degrees), and B<radius> (in meters). Returns location information, the specified geofence, and whether the device is inside the defined fence.

This is a distinctly different service call to Sprint, even though it could be implemented with some geo-math around C<get_location>. Specifically, this service call attempts to obtain a higher-precision location, and consequently, Sprint charges more credits for its use. Usually it will trigger a GPS location request on the device itself, and may take around 40 seconds to complete.

B<WARNING: This uses credits (6 per device query, last I checked)!>

=cut

sub check_perimeter {
    my ( $self, %args ) = @_;

    if ( !defined $args{mdn} ) {
        return;
    }

    my $latitude = _find_defined( @args{qw(lat latitude)} )
      or die "Latitude not provided";

    if ( !_in_range( $latitude, -90, 90 ) ) {
        die "Invalid latitude: $latitude\n";
    }

    my $longitude = _find_defined( @args{qw(lon longitude long)} )
      or die "Longitude not provided";

    if ( !_in_range( $longitude, -180, 180 ) ) {
        die "Invalid longitude: $longitude\n";
    }

    my $radius = _find_defined( @args{qw(rad radius range)} )
      or die "Radius not provided";

    if ( !_in_range( $radius, 2000, undef ) ) {
        die "Invalid radius: $radius\n";
    }

    if ( ref $args{mdn} eq 'ARRAY' ) {
        my @mdns = @{ $args{mdn} };

        my @response;

        foreach my $mdn (@mdns) {
            push( @response, $self->check_perimeter( %args, mdn => $mdn, ), );
        }
        return @response;
    }

    if ( my $mdn = _clean_mdn( $args{mdn} ) ) {
        my $status = $self->issue_query(
            service => 'perimeter',
            params  => {
                mdn  => $mdn,
                lat  => $latitude,
                long => $longitude,
                rad  => $radius,
            },
        );

        my %status = (
            original  => $status,
            mdn       => $mdn,
            timestamp => time,
        );

        $status{error}     = _best_match( $status, qr/^error/i );
        $status{latitude}  = _best_match( $status, qr/^lat/i );
        $status{longitude} = _best_match( $status, qr/^lon/i );
        $status{accuracy}  = _best_match( $status, qr/^accuracy/i );
        $status{comment}   = _best_match( $status, qr/^comment/i );

        my $inside = _best_match( $status, qr/^currentlocation/i );
        $status{inside} = ( $inside && $inside =~ m/inside/i ) ? 1 : 0;

        if ( !$status{error} && $inside =~ qr/fail/i ) {
            $status{error} = $inside;
        }

        $status{perimeter} = {
            radius    => _best_match( $status, qr/^radius/i ) || undef,
            latitude  => _best_match( $status, qr/^glat/i )   || undef,
            longitude => _best_match( $status, qr/^glong/i )  || undef,
        };

        my $response_mdn = _best_match( $status, qr/^mdn/i );
        if ( defined $response_mdn && $mdn ne $response_mdn ) {
            die "Response received for incorrect MDN: $response_mdn\n";
        }

        return \%status;
    }
    else {
        die "Invalid MDN: $args{mdn}\n";
    }
}

=head1 EXTRA METHODS

These are underlying methods that may be useful to extend this module for use with additional services.

=head2 issue_query

Given a list of named arguments, issues a web service request. Calling this method takes care of timestamp and authentication/hashing requirements for you.
Provided for your convenience to access herein-unimplemented services.

=cut

sub issue_query {
    my ( $self, %args ) = @_;

    my $url = $self->build_url(%args);

    #warn "URL: $url\n";

    my $response = $self->fetch_url( url => $url, );

    #warn "Response: $response\n";

    my $output = $self->decode_response( json => $response, );

    return $output;
}

=head2 build_url

Given a list of named arguments, constructs the service URL, adding the timestamp and hash. Called by issue_query, and provided for your convenience.

=cut

sub build_url {
    my ( $self, %args ) = @_;

    if ( !defined $SERVICES{ $args{service} } ) {
        die "Invalid service $args{service}\n";
    }

    my $dt = DateTime->now( time_zone => 'local', );

    my %params = (
        key       => $self->get_key,
        timestamp => $dt->iso8601 . $dt->time_zone_short_name,
    );

    while ( my ( $key, $value ) = each %{ $args{params} } ) {
        $params{$key} = $value;
    }

    my $hash = $self->get_hash(%params);

    my $uri = URI->new( $self->{base_url} . $SERVICES{ $args{service} } );

    $uri->query_form( %params, sig => $hash, );

    return $uri;
}

=head2 fetch_url

Given a named argument url, retrieves the URL. If successful, returns the content. If failed, returns the status message. Called by issue_query, and provided for your convenience.

=cut

sub fetch_url {
    my ( $self, %args ) = @_;

    my $url = $args{url}
      or die "No URL to fetch";

    my $ua = LWP::UserAgent->new
      or die "Failed to create a User Agent\n";

    $ua->agent( $self->{user_agent} );

    my $req = HTTP::Request->new( GET => $url );

    my $res = $ua->request($req);

    if ( $res->is_success ) {
        return $res->content;
    }
    else {
        die $res->status_line;
    }
}

=head2 decode_response

Given a named argument json containing the JSON response from a web service query, attempts to decode the JSON into a hash ref. Attempts to remove the extraneous line feeds that appear in some responses.

=cut

sub decode_response {
    my ( $self, %args ) = @_;

    if ( !defined $args{json} ) {
        die "No response found";
    }

    my $output;

  DECODE_JSON:
    {
        eval { $output = decode_json( $args{json} ); };
        if ($@) {
            if ( $args{json} =~ tr/\n\r//d ) {

  # This happens reliably on certain requests, so we just handle it silently now
  # warn
  #   "Trimmed line feeds from JSON response for compatibility\n";
                redo DECODE_JSON;
            }
            else {
                die "$@\nRaw JSON: $args{json}\n";
            }
        }
    }

    return $output;
}

=head2 get_hash

Given a named argument list, orders the keys and calculates the authentication hash, based on the shared secret. This method is called internally when building a request URI, but is provided for your convenience.

=cut

sub get_hash {
    my ( $self, %args ) = @_;

    my $secret = $self->get_secret
      or die "No secret available";

    my @hash_data;
    foreach my $key ( sort keys %args ) {
        push( @hash_data, $key, $args{$key} );
    }
    my $hash = md5_hex( join( '', @hash_data, $secret ) );

    return $hash;
}

=head2 get_key

Returns the object's stored key. Provided for your convenience.

=cut

sub get_key {
    my ($self) = @_;

    if ( !defined $self->{key} ) {
        die "Key must be defined!\n";
    }

    return $self->{key};
}

=head2 get_secret

Returns the object's stored shared secret. Provided for your convenience.

=cut

sub get_secret {
    my ($self) = @_;

    if ( !defined $self->{secret} ) {
        die "Secret must be defined!\n";
    }

    return $self->{secret};
}

=head1 AUTHOR

Brett T. Warden, C<< <bwarden at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-sprint at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Sprint>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Sprint


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Sprint>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Sprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Sprint>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Sprint/>

=back


=head1 ACKNOWLEDGMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Brett T. Warden.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

# Sanitizes an mdn
sub _clean_mdn {
    my ($orig_mdn) = @_;

    # Strip unseemly characters
    $orig_mdn =~ s/[\s()]//g;

    if (
        my @parts = (
            $orig_mdn =~
              m/^(?:\+?1)?[\-\.]?(\d{3})[\-\.]?(\d{3})[\-\.]?(\d{4})$/
        )
      )
    {
        return join( '', @parts );
    }
    else {
        return;
    }
}

# Returns the first defined argument in the argument list
sub _find_defined {
    foreach my $arg (@_) {
        if ( defined $arg ) {
            return $arg;
        }
    }
    return;
}

# Determines whether the supplied number is in the supplied range.
sub _in_range {
    my ( $number, $lower, $upper ) = @_;

    if ( $number !~ m/^-?\d+(\.\d*)?$/ ) {
        die "Not a floating point number: $number\n";
    }

    if ( defined $lower ) {
        if ( $number < $lower ) {
            return;
        }
    }

    if ( defined $upper ) {
        if ( $number > $upper ) {
            return;
        }
    }

    return 1;
}

# Returns the value from the supplied hashref whose key best matches the supplied regex
sub _best_match {
    my ( $h, $re ) = @_;

    if ( ref $h ne 'HASH' ) {
        return;
    }

    if ( ref $re ne 'Regexp' ) {
        die "$re is not a Regular Expression";
    }

  KEY:
    foreach my $key ( sort _by_length keys %{$h} ) {
        if ( $key =~ $re ) {
            return $h->{$key};
        }
    }

    return;
}

# Sorting helper function to order arguments by length
sub _by_length {
    my $a_len = 0;
    my $b_len = 0;

    if ( defined $a ) {
        $a_len = length $a;
    }
    if ( defined $b ) {
        $b_len = length $b;
    }

    return $a_len <=> $b_len;
}

1;    # End of WebService::Sprint
