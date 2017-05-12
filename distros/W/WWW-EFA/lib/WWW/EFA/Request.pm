package WWW::EFA::Request;
use Moose;
use HTTP::Request;
use MooseX::Params::Validate;
use Digest::SHA qw/sha256_hex/;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::Request - A request which can be passed around, and built up

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

URI request extended with some useful methods

    use WWW::EFA::Location;

    my $location = WWW::EFA::Location->new();
    ...

=head1 ATTRIBUTES

TODO: RCL 2012-01-22 Documentation

=cut

has 'arguments' => (
    is        => 'rw',
    isa       => 'HashRef',
    required  => 1,
    default   => sub{ 
        return 
            {
                outputFormat      => 'XML',
                coordOutputFormat => 'WGS84',
            };
        },
    );

has 'base_url' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    );

has 'can_accept_poid' => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 1,
    );
has 'service' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    );

=head1 METHODS

=head2 url

Returns $string

Get the URL for the request.  Concatenation of base_url and service after common_params are set.

=cut
sub url {
    my $self = shift;
    $self->set_common_params();
    return $self->base_url . $self->service;
}

=head2 set_common_params

Set common parameters for the request

=cut
sub set_common_params {
    my $self = shift;
    
    # These are common to all services
    $self->set_argument( 'locationServerActive' ,  1  );
    $self->set_argument( 'SpEncId'              , '0' );

    # Set service specific parameters
    my $service = $self->service;
    if( $service eq 'XSLT_TRIP_REQUEST2' ){
        $self->set_argument( 'coordListOutputFormat' , 'STRING'  );
        $self->set_argument( 'calcNumberOfTrips'     , '4'       );
    }
}

=head2 add_location( $suffix, $location )

Add a location to the request.

e.g.

  
$request->add_location( 'origin', $location );

$location is a L<WWW::EFA::Location> object

=cut
sub add_location {
    my $self = shift;
    my ( $suffix, $location ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'WWW::EFA::Location' },
        );
    if( $location->id ){
        $self->set_argument( 'type_' . $suffix,  'stop' );
        $self->set_argument( 'name_' . $suffix,  $location->id );
    } elsif ( $self->can_accept_poid and $location->poi_id ){
        $self->set_argument( 'type_' . $suffix,  'poiID' );
        $self->set_argument( 'name_' . $suffix,  $location->poi_id );
    }elsif( $location->coordinates ){
        $self->set_argument( 'type_' . $suffix,  'coord' );
        $self->set_argument( 'name_' . $suffix, 
            sprintf( "%.6f:%.6f:WGS84", 
                $location->coordinates->longitude,
                $location->coordinates->latitude,
                ) );
    }else{
        die( "Incomplete Location\n" );
    }
}

=head2 set_argument( $key, $value )

Set an argument for the request.

e.g.

  
$request->set_argument( 'inclMOT_0', 'on' );

=cut
sub set_argument {
    my $self = shift;
    my ( $key, $value ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'Str' },
      );
    $self->arguments->{ $key } = $value;
}

=head2 del_argument( $key )

Added an argument you didn't mean to?  Remove it here!

e.g.

  
$request->del_argument( $key );

=cut
sub del_argument {
    my $self = shift;
    my ( $key ) = validated_list(
        \@_,
        key   => { isa => 'Str' },
      );
    delete( $self->arguments->{ $key } );
}

=head2 digest

Returns $string

Generate a sha256_hex digest of this request.

=cut
sub digest {
    my $self = shift;
    my $string = $self->url . "\n";
    my %arguments = %{ $self->{arguments} };
    foreach( sort keys( %arguments ) ){
        $string .= "$_=$arguments{$_}\n";
    }
    return sha256_hex( $string );
}

1;
