package WWW::EFA::LineFactory;
use Moose;
use WWW::EFA::Line;
use WWW::EFA::Location;
use YAML;

=head1 NAME

A Factory for creating L<WWW::EFA::Line> objects.

=head1 VERSION

    Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  my $factory = WWW::EFA::LineFactory->new();

=head1 ATTRIBUTES

TODO: RCL 2012-01-22 Documentation

=cut

has 'mot_mapping' => ( is => 'ro', isa => 'HashRef', required => 1,
    default => sub {
        {
            1   => 'S',
            2   => 'U',
            3   => 'T',
            4   => 'T',
            5   => 'B',
            6   => 'B',
            7   => 'B',
            10  => 'B',
            8   => 'C',
            9   => 'F',
            11  => '?',
            -1  => '?',
        }
    }
);

has 'train_name_mapping' => ( is => 'ro', isa => 'HashRef', required => 1,
    default => sub {
        {
            'S-Bahn'                => 'S',
            'U-Bahn'                => 'U',
            'Straßenbahn'           => 'T',
            # TODO: RCL 2011-11-07 Complete this list from AbstractEfaProvider...
        }
    }
);

has 'mot0_mapping' => ( is => 'ro', isa => 'HashRef', required => 1,
    default => sub {
        {
            'EC'    => 'I', # Eurocity
            'EN'    => 'I', # Euronight
            'IC'    => 'I', # Intercity
            'ICE'   => 'I', # Intercity Express
            'IR'    => 'R', # Interregio
            'IRE'   => 'R', # Interregio-Express
            'RE'    => 'R', # Regional-Express
            # TODO: RCL 2011-11-07 Complete this list from AbstractEfaProvider
        }
    }
);


=head1 METHODS

=head2 line_from_itdServingLine

Returns a L<WWW::EFA::Line> object

  my $location = $factory->line_from_itdServingLine( $doc->findnodes( 'itdServingLine' ) );

Expects an XML::LibXML::Element of XML like this:

  
<itdServingLine selected="1" code="2" number="S1" symbol="S1" motType="1" realtime="0" direction="Ostbahnhof" valid="Fahrplan (2011)" compound="0" TTB="0" STT="0" ROP="0" type="unknown" spTr="" destID="5" stateless="mvv:01001: :H:s11" trainName="" index="1:0">
  <itdNoTrain name="S-Bahn"/>
  <motDivaParams line="01001" project="s11" direction="H" supplement=" " network="mvv"/>
  <itdRouteDescText>Freising - Neufahrn - Hauptbahnhof - Ostbahnhof</itdRouteDescText>
  <itdOperator>
    <code>01</code>
    <name>DB Regio AG </name>
  </itdOperator>
</itdServingLine>

=cut
sub line_from_itdServingLine {
    my $self    = shift;
    my $element = shift;

    my( $diva_params_elem ) = $element->findnodes( 'motDivaParams[position()=1]' );
    my( $route_desc_elem )  = $element->findnodes( 'itdRouteDescText[position()=1]' );
    my( $no_train_elem )    = $element->findnodes( 'itdNoTrain[position()=1]' );

    my %location_params = (
        id      => $element->getAttribute( 'destID' ),
        name    => $element->getAttribute( 'direction' ),
    );

    my $destination = undef;
    if( $location_params{id} ){
        $destination = WWW::EFA::Location->new( %location_params );
    }

    my $label = $self->_label_for_line(
        mot             => $element->getAttribute( 'motType' ),
        name            => $element->getAttribute( 'number' ),
        name_long       => $element->getAttribute( 'number' ),
        no_train_name   => $no_train_elem->getAttribute( 'name' ),
        );

    my $colour = '>no colour<'; # TODO: RCL 2011-11-09 Find real colour

    my %line_params = ( 
        id                  => $element->getAttribute( 'stateless' ),
        mot                 => $element->getAttribute( 'motType' ),
        realtime            => $element->getAttribute( 'realtime' ),
        number              => $element->getAttribute( 'number' ),
        symbol              => $element->getAttribute( 'symbol' ),
        code                => $element->getAttribute( 'code' ),
        label               => $label,
#        colour          => $colour, # TODO: RCL 2011-11-07 when real colour available, reactivate
        direction           => $diva_params_elem->getAttribute( 'direction' ),
        line                => $diva_params_elem->getAttribute( 'line' ),
        );
    $line_params{destination}       = $destination if $destination;
    $line_params{route_description} = $route_desc_elem->textContent() if( $route_desc_elem );


    my $line = WWW::EFA::Line->new( %line_params );

    return $line;
}

# Generate a standardised line description
# Expect some combination of
#   %params = (
#     mot           => 'motType',
#     name          => 'name',
#     long_name     => 'name',
#     no_train_name => 'no_train_name,
#     );
sub _label_for_line {
    my $self = shift;
    my %params = @_;
    if( not $params{mot} ){
        if( not $params{no_train_name} 
            or not $self->train_name_mapping->{ $params{no_train_name} } ){
            croak( "Cannot normalise mot: " . Dump( \%params ) );
        }
        return sprintf( '%s%s', $self->train_name_mapping->{ $params{no_train_name} },
            ( $params{name} || '' ) );
    }
    
    if( $params{mot} eq '0' ){
        # TODO: RCL 2011-11-07 Test this in the wild and refine - no data tested yet...
        my @parts = split( ' ', $params{long_name} );
        my $type = $parts[0];
        my $num = ( scalar( @parts ) >= 2 ? $parts[1] : undef );
        my $str = sprintf( '%s%s', $type, ( $num || '' ) );
        if( not $self->mot0_mapping->{ $type } ){
            croak( "Cannot normalise mot: " . Dump( \%params ) );
        }
        return sprintf( '%s%s', $self->mot0_mapping->{ $type }, $str );
    }

    # TODO: RCL 2011-11-09 use $self->mot_mapping
    if( $params{mot} eq '1' ){
        if( $params{name} =~ m/^(S\d+)/ ){
            return $1;
        }
        return 'S' . $params{name};
    }

    if( $params{mot} eq '2' ){
        if( $params{name} =~ m/^(U\d+)/ ){
            return $1;
        }        
        return 'U' . $params{name};
    }

    if( $params{mot} eq '3' or $params{mot} eq '4' ){
        return 'T' . $params{name};
    }

    if( $params{mot} eq '5' or $params{mot} eq '6' or $params{mot} eq '7' or $params{mot} eq '10' ){
        if( $params{name} eq 'Schienenersatzverkehr' ){
            return 'BSEV';
        }else{
            return 'B' . $params{name};
        }
    }

    if( $params{mot} eq '8' ){
        return 'C' . $params{name};
    }

    if( $params{mot} eq '9' ){
        return 'F' . $params{name};
    }

    if( $params{mot} eq '11' or $params{mot} eq '-1' ){
        return '?' . $params{name};
    }

    croak( "Cannot normalise mot: " . Dump( \%params ) );
}

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

