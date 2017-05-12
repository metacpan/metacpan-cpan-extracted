use strict;
use warnings;

package WebService::Geocodio::Location;
{
  $WebService::Geocodio::Location::VERSION = '0.04';
}

use WebService::Geocodio::Fields;
use Moo::Lax;
use Carp qw(confess);

# ABSTRACT: Location object for use with Geocod.io service.


has [qw(number street suffix postdirection city state zip formatted lat lng accuracy fields)] => (
    is => 'ro',
    predicate => 1,
);


sub BUILDARGS {
    my ( $class, @args ) = @_;

    my $out;
    if (ref($args[0]) eq "HASH") {
        my $hr = $args[0];
        $out->{accuracy} = $hr->{accuracy} if exists $hr->{accuracy};
        $out->{formatted} = $hr->{formatted_address} if exists $hr->{formatted_address};
        $out->{fields} = WebService::Geocodio::Fields->new($hr->{fields}) if exists $hr->{fields};
        map { $out->{$_} = $hr->{address_components}->{$_} if exists $hr->{address_components}->{$_} } qw(number street suffix postdirection city state zip);
        map { $out->{$_} = $hr->{location}->{$_} if exists $hr->{location}->{$_} } qw(lat lng);
    }
    elsif ( @args % 2 == 1 ) {
        $out->{formatted} = $args[0];
    }
    else {
        $out = { @args };
    }

    return $out;
}

sub _forward_formatting {
    my $self = shift;

    return $self->formatted if $self->has_formatted;

    if ( ( not $self->has_zip ) && ( not ( $self->has_city && $self->has_state ) ) ) {
        confess "A zip or city-state pair is required.\n";
    }

    my $s;
    if ( $self->has_number && $self->has_street && $self->suffix ) {
        my @f;
        if ( $self->has_postdirection ) {
            @f = qw(number postdirection street suffix);
        }
        else {
            @f = qw(number street suffix);
        }

        $s .= join " ", (map {; $self->$_ } @f);
        $s .= ", ";
    }

    if ( $self->has_zip ) {
        $s .= $self->zip
    }
    else {
        $s .= join ", ", (map {; $self->$_ } qw(city state));
    }

    return $s;
}

sub _reverse_formatting {
    my $self = shift;

    if ( not ( $self->has_lat && $self->has_lng ) ) {
        confess "lat-lng pair is required\n";
    }

    return join ",", ( map {; $self->$_ } qw(lat lng) );
}


1;

__END__

=pod

=head1 NAME

WebService::Geocodio::Location - Location object for use with Geocod.io service.

=head1 VERSION

version 0.04

=head1 ATTRIBUTES

=head2 number

Buiding number

=head2 street

A street name identifier

=head2 postdirection

A address direction like 'SW' or 'S'

=head2 suffix

The type of street 'Ave', 'St', etc.

=head2 city

The city where the streets have no name.

=head2 state

State wherein city is located

=head2 zip

The postal zip code

You B<must> have either a zip code OR a city/state pair.

=head2 lat

The latitude of the location

=head2 lng

The longitude of the location

=head2 accuracy

A float from 0 -> 1 representing the confidence of the lookup results

=head2 formatted

The full address as formatted by the service.

=head2 fields

Any requested fields are available here.

=head1 METHODS

=head2 new

The constructor accepts either a bare string OR a list of key/value pairs where
the keys are the attribute names.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
