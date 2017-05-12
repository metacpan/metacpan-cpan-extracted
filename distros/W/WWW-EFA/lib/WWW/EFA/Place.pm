package WWW::EFA::Place;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides string

=head1 NAME

WWW::EFA::Place - A Place

=head1 DESCRIPTION

A Place object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Location object acquired through an EFA interface

    use WWW::EFA::Location;

    my $location = WWW::EFA::Location->new();
    ...

=head1 ATTRIBUTES

# TODO: RCL 2011-11-06 Document attributes

=cut

has 'id'        => ( is => 'ro', isa => 'Int'               );
has 'state'     => ( is => 'ro', isa => 'Str'               );
has 'type'      => ( is => 'ro', isa => 'Str'               );
has 'name'      => ( is => 'ro', isa => 'Str'               );

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

