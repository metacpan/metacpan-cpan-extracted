package WWW::EFA::Coordinates;
use Moose;
use MooseX::Aliases;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::Coordinates - Longitude/Latitude

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Coordinates object acquired through an EFA interface

    use WWW::EFA::Coordinates;

    my $coord = WWW::EFA::Coordinates->new(
        longitude => 12.1234,
        latitude  => 48.1234,
        );
    ...

=head1 ATTRIBUTES

=cut
# TODO: RCL 2011-11-06 Document attributes

# Latitude and Longitude.
has 'latitude'  => ( is => 'ro', isa => 'Num', required => 1, alias => 'lat' );
has 'longitude' => ( is => 'ro', isa => 'Num', required => 1, alias => 'lon' );
has 'map_name'  => ( is => 'ro', isa => 'Str' );    

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

