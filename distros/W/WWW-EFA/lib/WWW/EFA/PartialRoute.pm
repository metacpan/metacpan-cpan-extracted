package WWW::EFA::PartialRoute;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::PartialRoute - A Partial route

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

TODO: RCL 2011-11-10 

=head1 ATTRIBUTES

=cut
# TODO: RCL 2011-11-06 Document attributes

has 'departure_location'    => ( is => 'ro', isa => 'WWW::EFA::Location' );
has 'arrival_location'      => ( is => 'ro', isa => 'WWW::EFA::Location' );
has 'departure_time'        => ( is => 'ro', isa => 'Class::Date'        );
has 'arrival_time'          => ( is => 'ro', isa => 'Class::Date'        );
has 'stops'                 => ( is => 'ro', isa => 'ArrayRef[WWW::EFA::Stop]' );

1;


=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

