package WWW::MySociety::Gaze;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::Tiny;
use Text::CSV;

use constant SERVICE => 'http://gaze.mysociety.org/gaze-rest';

=head1 NAME

WWW::MySociety::Gaze - An interface to MySociety.org's Gazetteer service

=head1 VERSION

This document describes WWW::MySociety::Gaze version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::MySociety::Gaze;

=head1 DESCRIPTION

MySociety.org Gaze is a REST based gazetteer service. You can find out
more about it here:

L<http://www.mysociety.org/2005/09/15/gaze-web-service/>

C<WWW::MySociety::Gaze> is a Perl wrapper around Gaze.

=head1 INTERFACE

=head2 C<< new >>

Create a new C<WWW::MySociety::Gaze>.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 C<< get_country_from_ip( $ip ) >>

Guess the country of location of a host from its dotted quad IP address.
Returns an ISO country code or C<undef> if the country code is unknown.

    my $gaze = WWW::MySociety::Gaze->new;
    my $country = $gaze->get_country_from_ip( '82.152.157.85' );

=cut

sub get_country_from_ip {
    my $self = shift;

    croak "Need an IP address"
      unless @_ == 1;

    my $ip = shift;
    croak "IP address must be a dotted quad"
      unless $ip =~ /^(?:\d{1,3}\.){3}\d{1,3}$/;

    my $answer = $self->_request( 'get_country_from_ip', ip => $ip );
    chomp $answer;
    return $answer eq '' ? undef : $answer;
}

=head2 C<< get_find_places_countries >>

Return the list of countries for which C<find_places> has a gazetteer
available.

Takes no arguments, returns a list of ISO country codes.

    my $gaze = WWW::MySociety::Gaze->new;
    my @countries = $gaze->get_find_places_countries;

=cut

sub get_find_places_countries {
    my $self = shift;
    return $self->_lines(
        $self->_request( 'get_find_places_countries' ) );
}

=head2 C<< find_places >>

Lookup a location in the gazetteer. Takes a number of key, value pairs
as follows:

=head3 Parameters

=over

=item C<country>

ISO country code of country in which to search for places

=item C<state>

State in which to search for places; presently this is only meaningful
for country=US (United States), in which case it should be a
conventional two-letter state code (AZ, CA, NY etc.); optional

=item C<query>

Query term input by the user; must be at least two characters long

=item C<maxresults>

Largest number of results to return, from 1 to 100 inclusive; optional;
default 10

=item C<minscore>

Minimum match score of returned results, from 1 to 100 inclusive;
optional; default 0

=back

Returns a list of hash references. Each hash has the following fields:

=over

=item C<Name>

Name of the place described by this row

=item C<In>

Blank, or the name of an administrative region in which this place lies
(for instance, a county)

=item C<Near>

A reference to a (possibly empty) array of nearby placenames.

=item C<Latitude>

WGS-84 latitude of place in decimal degrees, north-positive

=item C<Longitude>

WGS-84 longitude of place in decimal degrees, east-positive

=item C<State>

Blank, or containing state code for US

=item C<Score>

Match score for this place, from 0 to 100 inclusive

=back

=cut

sub find_places {
    my $self = shift;
    croak "Need arguments as key, value pairs"
      unless @_ and ( @_ % 2 == 0 );
    return $self->_csv_to_hashes(
        $self->_request( 'find_places', @_ ),
        sub {
            my $rec = shift;
            $rec->{Near} = [ split /\s*,\s*/, $rec->{Near} ];
            return $rec;
        }
    );
}

=head2 C<< get_population_density( $lat, $lon ) >>

Given a latitude, longitude pair return an estimate of the population
density at (lat, lon), in persons per square kilometer.

=cut

sub get_population_density {
    my ( $self, $lat, $lon ) = @_;

    my @density = $self->_lines(
        $self->_request(
            'get_population_density',
            lat => $lat,
            lon => $lon
        )
    );

    return shift @density;
}

=head2 C<< get_radius_containing_population >>

Return an estimate of the smallest radius around (lat, lon) containing
at least number persons, or maximum, if that value is smaller. Takes key
value parameters:

=over

=item C<lat>

WGS84 latitude, in decimal degrees

=item C<lon>

WGS84 longitude, in decimal degrees

=item C<number>

number of persons

=item C<maximum>

largest radius returned, in kilometers; optional; default 150

=back

=cut

sub get_radius_containing_population {
    my $self = shift;
    croak "Need arguments as key, value pairs"
      unless @_ and ( @_ % 2 == 0 );

    my @radius = $self->_lines(
        $self->_request( 'get_population_density', @_ ) );

    return shift @radius;
}

=head2 C<< get_country_bounding_coords >>

Get the bounding box of a country given its ISO country code. Returns a
four element list containing max_lat, min_lat, max_lon, min_lon.

    my @bb = $gaze->get_country_bounding_coords( 'GB' );

=cut

sub get_country_bounding_coords {
    my ( $self, $country ) = @_;
    my @bb = $self->_lines(
        $self->_request(
            'get_country_bounding_coords', country => $country
        )
    );

    return split /\s+/, shift @bb;
}

=head2 C<< get_places_near >>

Get a list of places near a specific location. Takes a list of name,
value pairs like this:

=over

=item C<lat>

WGS84 latitude, in north-positive decimal degrees

=item C<lon>

WGS84 longitude, in east-positive decimal degrees

=item C<distance>

distance in kilometres

=item C<number>

number of persons to calculate circle radius

=item C<maximum>

maximum radius to return (default 150km)

=item C<country>

ISO country code of country to limit results to (optional)

=back

Returns a list of hash references like this:

=over

=item C<Name>

Name of the nearby place.

=item C<Distance>

Distance from the base place.

=item C<Latitude>

Latitude of the nearby place.

=item C<Longitude>

Longitude of the nearby place.

=item C<Country>

Country of the nearby place.

=item C<State>

State of the nearby place (currently US only).

=back

=cut

sub get_places_near {
    my $self = shift;
    croak "Need arguments as key, value pairs"
      unless @_ and ( @_ % 2 == 0 );

    return $self->_csv_to_hashes(
        $self->_request( 'get_places_near', @_ ),
        sub {
            my $rec = shift;
            $rec->{Distance} ||= 0;
            return $rec;
        }
    );
}

sub _request {
    my $self = shift;
    croak
      "Need a verb and optionally a list of argument key value pairs"
      unless @_ >= 1 and @_ % 2;
    my ( $verb, %args ) = @_;
    my $ua = $self->{_ua} ||= LWP::UserAgent->new;
    my $uri = SERVICE . '?'
      . HTML::Tiny->new->query_encode( { %args, f => $verb } );
    my $resp = $ua->get( $uri );
    croak $resp->status_line if $resp->is_error;
    return $resp->content;
}

sub _lines {
    my ( $self, $text ) = @_;
    $text =~ s/\r//g;
    chomp $text;
    return split /\n/, $text;
}

sub _csv_to_hashes {
    my ( $self, $text, $cook ) = @_;
    my @lines = $self->_lines( $text );
    my $csv   = Text::CSV->new;

    my $csv_line = sub {
        return unless @lines;
        my $line   = shift @lines;
        my $status = $csv->parse( $line );
        croak "Can't parse $line: " . $csv->error_diag
          unless $status;
        return $csv->fields;
    };

    $cook ||= sub { shift };

    my @names = $csv_line->();
    my @data  = ();

    while ( my @fields = $csv_line->() ) {
        my %row;
        @row{@names} = @fields;
        push @data, $cook->( \%row );
    }

    return @data;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT

WWW::MySociety::Gaze requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-mysociety-gaze@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=begin html

<div class="perlads">
<script type="text/javascript" src="http://adserver.szabgab.com/ads/direct_link.js"></script>
</div>

=end html

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
