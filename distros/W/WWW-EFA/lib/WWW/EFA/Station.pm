package WWW::EFA::Station;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::Station - Store a station with its location, departures and lines

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Station object acquired through an EFA interface

    use WWW::EFA::Station;

    my $station = WWW::EFA::Station->new();
    ...

=head1 ATTRIBUTES

# TODO: RCL 2011-11-06 Document attributes

=cut

has 'location' => (
    is          => 'ro',
    isa         => 'WWW::EFA::Location',
    required    => 1,
    );

has 'departures' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub{ [] },
    );

has 'lines' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub{ [] },
    );

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>
