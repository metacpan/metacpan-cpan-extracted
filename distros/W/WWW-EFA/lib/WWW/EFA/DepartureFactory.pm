package WWW::EFA::DepartureFactory;
use Moose;
use Class::Date qw/date/;
use WWW::EFA::Departure;
use WWW::EFA::DateFactory;
=head1 NAME

A Factory for creating L<WWW::EFA::Departure> objects.

=head1 SYNOPSIS

  my $factory = WWW::EFA::DepartureFactory->new();

=head1 VERSION

    Version 0.01

=cut

our $VERSION = '0.01';

=head1 ATTRIBUTES

# TODO: RCL 2012-01-22 Document attributes

=cut

has 'map_departure' => ( is => 'ro', isa => 'HashRef', required => 1,
    default => sub {
        {
            stopID          => 'stop_id',
            area            => 'area',
            platform        => 'platform',
            platform_name   => 'platform_name',
            countdown       => 'countdown',
        }
    },
);

has 'date_factory' => (
    is          => 'ro',
    isa         => 'WWW::EFA::DateFactory',
    required    => 1,
    lazy        => 1,
    default     => sub{ WWW::EFA::DateFactory->new() },
    );


=head1 METHODS

=head2 departure_from_itdDeparture 

Returns a L<WWW::EFA::Departure> object

  my $departure = $factory->departure_from_itdDeparture( $itd_odv->findnodes( '/itdDeparture' ) );

Expects an XML::LibXML::Element of XML like this:

  
<itdDeparture stopID="8" x="11536492.00000" y="48142609.00000" mapName="WGS84" area="1"
    platform="S-RiW" platformName="" stopName="Donnersbergerbrücke" 
    nameWO="Donnersbergerbrücke" countdown="1">
  <itdDateTime>
    <itdDate year="2011" month="11" day="4" weekday="6"/>
    <itdTime hour="15" minute="9" ap=""/>
  </itdDateTime>
  <itdServingLine key="1424" code="2" number="S8" symbol="S8" 
    motType="1" realtime="0" direction="Herrsching" destID="5410" 
    stateless="mvv:01008:B:R:s11">
    <itdNoTrain name="S-Bahn"/>
    <motDivaParams line="01008" project="s11" direction="R" supplement="B" network="mvv"/>
  </itdServingLine>
</itdDeparture>


=cut
sub departure_from_itdDeparture {
    my $self    = shift;
    my $element = shift;

    my %dep_params =
        map { $self->map_departure->{ $_ } => $element->getAttribute( $_ ) }
        grep { $element->hasAttribute( $_ ) and $element->getAttribute( $_ ) }
        keys %{ $self->map_departure };
    
    my( $date_elem ) = $element->findnodes( 'itdDateTime' );
    if( $date_elem ){
        $dep_params{time} = $self->date_factory->date_from_itdDateTime( $date_elem );
    }

    my( $line_elem ) = $element->findnodes( 'itdServingLine' );
    $dep_params{line_id} = $line_elem->getAttribute( 'stateless' );

    my $departure = WWW::EFA::Departure->new( %dep_params );
    return $departure;
}


1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

