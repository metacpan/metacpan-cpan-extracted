package WWW::AzimuthAero::Flight;
$WWW::AzimuthAero::Flight::VERSION = '0.31';

# ABSTRACT: Flight representation

use strict;
use warnings;
use utf8;

use Class::Tiny qw(
  from_city
  to_city
  flight_num
  flight_date
  departure_time
  arrival_time
  trip_duration
  fares
  has_stops
  stop_at_city
);

use List::Compare;


sub as_hashref {
    my ( $self, %params ) = @_;

    # if defined $params{skip_undef};

    my @fields_to_return =
        ( defined $params{only} )
      ? ( @{ $params{only} } )
      : ( Class::Tiny->get_all_attributes_for( ref($self) ) );

    my $result = {};
    for my $x (@fields_to_return) {
        if ( $self->can($x) && not _in_array( $params{skip}, $x ) ) {

            #$result->{$x} = $self->$x;
            if ( $params{skip_undef} ) {
                $result->{$x} = $self->$x if defined $self->$x;
            }
            else {
                $result->{$x} = $self->$x;
            }
        }
    }
    return $result;
}


sub as_string {
    my ( $self, %params ) = @_;

    my $hash = $self->as_hashref( skip_undef => 1 );

    # ref($hash->{$k}) eq '' for skipping fares
    my @str = ();
    if ( $params{order} ) {
        for my $k ( @{ $params{order} } ) {
            push @str, $hash->{$k}            if ( ref( $hash->{$k} ) eq '' );
            push @str, $hash->{fares}{lowest} if ( $k eq 'fares' );
        }

        my $lc    = List::Compare->new( $params{order}, [ keys %$hash ] );
        my @Ronly = $lc->get_Ronly;
        for my $k (@Ronly) {
            push @str, $hash->{$k}            if ( ref( $hash->{$k} ) eq '' );
            push @str, $hash->{fares}{lowest} if ( $k eq 'fares' );
        }

        # compare diff and push others
    }
    else {
        for my $k ( sort keys %$hash ) {
            push @str, $hash->{$k}            if ( ref( $hash->{$k} ) eq '' );
            push @str, $hash->{fares}{lowest} if ( $k eq 'fares' );
        }
    }

    my $sep = ( defined $params{separator} ) ? $params{separator} : ' ';

    return join( $sep, @str );
}

sub _in_array {
    my ( $array_ref, $pattern ) = @_;
    no if ( $] >= 5.018 ), warnings => 'experimental';
    $array_ref //= [];
    return $pattern ~~ @{$array_ref};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero::Flight - Flight representation

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    my $flight = WWW::AzimuthAero::Flight->new(
        from_city => 'ROV',
        to_city   => 'KLF',
        flight_date => '16.06.2019'
    );

=head1 DESCRIPTION

Object representation of data on pages like L<https://booking.azimuth.aero/!/ROV/LED/21.06.2019/1-0-0/>

=head1 METHODS

=head2 new

    my $az = WWW::AzimuthAero::Flight->new(date => '16.06.2019', from => 'ROV', to => 'KLF');

=head1 PROPERTIES

=head2 from_city

Departure city IATA code

Example:

    LED

=head2 to_city

Arrival city IATA code

Example:

    ROV

=head2 flight_num

Return string with flight number

Example:

    A4 203

=head2 flight_date

String in %d.%m.%Y format

Example:

    24.06.2019

=head2 departure_time

Example: 

    07:20

=head2 arrival_time

Example:

    10:00

=head2 trip_duration

Example:

    5ч 35м

=head2 fares

Contain hash with different tariffs

{
    'lowest'     => '10680',
    'optimalnyy' => '10680',
    'svobodnyy'  => '11980'
}

Possible keys are 

    qw/legkiy vygodnyy optimalnyy svobodnyy/

lowest key always contains lowest price

=head2 has_stops

Return true if flight consist of two flights

Like at L<https://booking.azimuth.aero/!/ROV/PKV/26.06.2019/1-0-0/>

=head2 stop_at_city

Return IATA code of transit city

=head2 as_hashref

Return particular properties as hash

    $f->as_hash;
    $f->as_hash( skip => [ qw/fares/ ] )
    $flight->as_hash( only => [ qw/from_city to_city flight_date/ ] )

If class has such method but it's not set - will return undef in value

Convenient when inserting data to database, especially with L<DBIx::Class::ResultSet>

    $schema->resultset('Flight')->create( $f->as_hash( skip => [ qw/fares/ ] ) )

Params:

only - Which fields to return only

skip - Which fields skip from result = 'all except'

skip_undef - To skip or not undef values (useful to supress warning in concatenation)

=head2 as_string

Return flight info as string

Support same parameters as L<WWW::AzimuthAero::Flight> (in facts it's wrapper on it)

    $f->as_string;
    $f->as_string( skip => [ qw/fares/ ] )
    $flight->as_string( only => [ qw/from_city to_city flight_date/ ] )

Additional parameters

order

    $f->as_string( order => [ qw/price flight_date/ ] )

By default (in order not specified) prints parameters in alphabetic order

Method could be useful for logging

separator

    $f->as_string( separator => "\t" )

Useful when you create a table

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
