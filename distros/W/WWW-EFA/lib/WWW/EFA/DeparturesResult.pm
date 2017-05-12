package WWW::EFA::DeparturesResult;
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use Carp;
=head1 NAME

WWW::EFA::DeparturesResult - Store the results from a departures query

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

TODO: RCL 2012-01-22 Documentation 

=cut

with 'WWW::EFA::Roles::Printable'; # provides string

subtype 'ValidDepartureStatus',
      as 'Str',
      where { $_ =~ m/^(OK|INVALID_STATION|SERVICE_DOWN)$/  },
      message { "Invalid departure status" };

=head1 ATTRIBUTES

TODO: RCL 2012-01-22 Documentation

=cut

has 'status' => (
    is          => 'rw',
    isa         => 'ValidDepartureStatus',
    );

has 'departure_stations' => (
    is          => 'rw',
    isa         => 'HashRef[WWW::EFA::Station]',
    default     => sub{ {} },
    );

has 'departures' => (
    is          => 'rw',
    isa         => 'ArrayRef[WWW::EFA::Departure]',
    default     => sub{ [] },
    );


has 'lines' => (
    is          => 'rw',
    isa         => 'HashRef[WWW::EFA::Line]',
    default     => sub{ {} },
    );

=head1 METHODS

=head2 add_departure_station

=head3 Params

=over 4

=item L<WWW::EFA::Station>

=back

Add a single L<WWW::EFA::Station> to the departure stations of this result

=cut
sub add_departure_station {
    my $self = shift;
    my ( $station ) = pos_validated_list(
        \@_,
        { isa => 'WWW::EFA::Station' },
      );
    if( not $station->location->id ){
        # TODO: RCL 2011-11-20 Make a debug output here when logging enabled
        # carp( "Cannot add_departure_station with a location without an id" );
        return;
    }

    # Make sure we don't add the same location twice
    if( not $self->departure_stations->{ $station->location->id } ){
        $self->departure_stations->{ $station->location->id } = $station;
    }
    
    return;
}

=head2 get_departure_station

Returns a L<WWW::EFA::Station> if found, else undef

=head3 Params

=over 4

=item I<$station_id> (integer)

=back

=cut
sub get_departure_station {
    my $self        = shift;
    my ( $station_id ) = pos_validated_list(
        \@_,
        { isa => 'Int' },
      );
    return $self->departure_stations->{ $station_id };
}

=head2 add_line

=head3 Params

=over 4

=item L<WWW::EFA::Line>

=back

Add a single L<WWW::EFA::Line> to this result

=cut
sub add_line {
    my $self = shift;
    my ( $line ) = pos_validated_list(
        \@_,
        { isa => 'WWW::EFA::Line' },
      );

    # Make sure we don't add the same line twice
    if( not $self->lines->{ $line->id } ){
        $self->lines->{ $line->id } = $line;
    }
    return;
}

=head2 get_line

Returns a L<WWW::EFA::line> from this result by its id

=head3 Params

=over 4

=item I<$integer>

=back

=cut
sub get_line {
    my $self    = shift;
    my $line_id = shift;
    return $self->lines->{ $line_id };
}

=head2 add_departure

Add a L<WWW::EFA::Departure> to this result

=head3 Params

=over 4

=item L<WWW::EFA::Departure>

=back

=cut
sub add_departure {
    my $self = shift;
    my ( $departure ) = pos_validated_list(
        \@_,
        { isa => 'WWW::EFA::Departure' },
    );

    if( not $self->get_departure_station( $departure->stop_id ) ){
        # TODO: RCL 2011-11-20 Make this a debug message
        # carp( sprintf "Cannot add departure because I don't know the stop_id: %s", $departure->stop_id );
        return;
    }
    
    if( not $self->get_line( $departure->line_id ) ){
        # TODO: RCL 2011-11-20 Make this a debug message
        # carp( sprintf 'Cannot add departure. Line id unknown: "%s"', $departure->line_id );
        return;
    }
    
    push( @{ $self->departures }, $departure );
    # TODO: RCL 2011-11-09 Sort departures by departure time?
}

1;
=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>


