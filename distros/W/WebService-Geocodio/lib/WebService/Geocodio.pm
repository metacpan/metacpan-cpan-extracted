use 5.014;

use strict;
use warnings;

package WebService::Geocodio;
$WebService::Geocodio::VERSION = '0.05';
use Moo;
use strictures 2;
use Carp qw(confess);
use Scalar::Util qw(blessed);
with('WebService::Geocodio::Request');

# ABSTRACT: A Perl interface to Geocod.io



has 'api_key' => (
    is => 'ro',
    isa => sub { confess "$_[0] doesn't look like a valid api key\n" unless $_[0] =~ /[0-9a-f]+/ },
    required => 1,
);


has 'locations' => (
    is => 'rw',
    default => sub { [] },
);


has 'fields' => (
    is => 'rw',
    predicate => 1,
    default => sub { [] },
);


sub add_location {
    my $self = shift;

    push @{ $self->locations }, @_;
}


sub show_locations {
    my $self = shift;

    return @{ $self->locations };
}


sub clear_locations {
    my $self = shift;

    $self->locations([]);
}


sub add_field {
    my $self = shift;

    push @{ $self->fields }, grep { /cd|cd113|cd114|cd115|stateleg|timezone|school|census/ } @_;
}


sub geocode {
    my $self = shift;

    $self->add_location(@_) if scalar @_;

    return undef if scalar @{$self->locations} < 1;

    my @r = $self->send_forward( $self->_format('forward') );

    wantarray ? return @r : return \@r;
}


sub reverse_geocode {
    my $self = shift;

    $self->add_location(@_) if scalar @_;

    return undef if scalar @{$self->locations} < 1;

    my @r = $self->send_reverse( $self->_format('reverse') );

    wantarray ? return @r : return \@r;
}

sub _format {
    my $self = shift;
    my $direction = shift;

    my $method = $direction eq 'forward' ? '_forward_formatting'
        : '_reverse_formatting';

    return [ map {; blessed $_ ? $_->$method : $_ } @{$self->locations} ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Geocodio - A Perl interface to Geocod.io

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use 5.014;
    use WebService::Geocodio;
    use WebService::Geocodio::Location;

    my $geo = WebService::Geocodio->new(
        api_key => $ENV{GEOCODIO_API_KEY}
    );

    # Wrigley Field
    my $loc = WebService::Geocodio::Location->new(
        number => 1060,
        postdirection => 'W',
        street => 'Addison',
        suffix => 'Street',
        city => 'Chicago',
        state => 'IL',
    );

    # Could add more than one thing here, even bare strings are OK
    # 20050 = zip code in Washington DC
    $geo->add_location($loc, '20050');

    $geo->add_field('timezone');

    # prints:
    # Chicago: 41.947205791667, -87.656316875, CST
    # Chicago: 41.947180613636, -87.657167363636, CST
    # Washington: 38.893311, -77.014647, EST
    map { say $_->city, ": ", $_->lat, ", ", $_->lng, ", " $_->fields->timezone->name } $geo->geocode();

=head1 OVERVIEW

This module is a fairly thin wrapper around the L<Geocod.io|http://geocod.io>
geocoding web service.  This service currently supports US and many Canadian based
addresses at the moment.  Both forward and reverse geocoding is supported.

In my testing, the service is somewhat finicky about how addresses are
presented and stored; please read the service API documentation thoroughly 
to make sure you're getting the best quality results from the service.

You will need to obtain a free API key to use this library.

All errors are fatal and reported by C<confess>.  If you want more graceful
error handling, you might want to try using L<Try::Tiny>.

=head1 ATTRIBUTES

=head2 api_key

This is the geocod.io API key. It is required.

=head2 locations

The list of locations you want to geocode.  These can be bare strings (if you like) or
you can use a fancy object like L<WebService::Geocodio::Location> which will serialize
itself to JSON automatically.

=head2 fields

You may request the following fields be included in the results:

=over 4

=item * cd

Congressional District (for the current Congress). This will return detailed
biographical information about the Senators and Congressional representative
from this district in the C<current_legislators> field which is structured
as an array where the member of Congress is first, followed by the Senators
for the entire state.

It's possible there may be overlaps in a given location, so this field is
structured as an array since there may be 2 or more possible districts
for a given location. See the official docs for more information.

=item * cd113

Congressional District (for the 113th Congress which ran through 2015)

=item * cd114

Congressional District (for the 114th Congress which ran through 2017)

=item * cd115

Congressional District (for the 115th Congress which runs through 2019)

=item * stateleg

The state legislative divisions for this location. The results include both
House and Senate, unless the location is unicameral like Nebraska or Washington
D.C., then only a senate result is given.

=item * timezone

The timezone of this location, UTC offset and whether it observes daylight
saving time.

=item * school

The unified or elementary/secondary school district identifiers for this location.

=item * census

Appends various U.S. Census statistical codes to your lookup. See the API docs
for more information about these codes and how they can be used with other
census data sets.

=back

=head1 METHODS

=head2 add_location

This method takes one or more locations and stores it in the locations attribute.

=head2 show_locations

Show the locations currently set for geocoding.

=head2 clear_locations

If you want to clear the current list of locations, use this method.

=head2 add_field

This method takes one or more fields to include in a result set. Valid fields are:

=over 4

=item * cd (current Congress)

=item * cd113

=item * cd114

=item * cd115

=item * stateleg

=item * timezone

=item * school

=item * census

=back

Fields that do not match these valid names are silently discarded.

=head2 geocode

Send the current list of locations to the geocod.io service.

Returns undef if there are no locations stored.

In a list context, returns a list of L<WebService::Geocodio::Location> objects.
In a scalar context, returns an arrayref of L<WebService::Geocodio::Location>
objects. The list of objects is presented in descending order of accuracy.

=head2 reverse_geocode

Send the current list of latitude, longitude pairs to the geocod.io service.

Returns undef if there are no locations stored.

In a list context, returns a list of L<WebService::Geocodio::Location> objects.
In scalar context, returns an arrayref of L<WebService::Geocodio::Location> 
objects.  The list of objects is presented in descending order of accuracy.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
