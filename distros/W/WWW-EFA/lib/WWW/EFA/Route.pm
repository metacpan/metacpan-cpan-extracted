package WWW::EFA::Route;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::Route - A Route

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

TODO: RCL 2011-11-10 

=head1 ATTRIBUTES

=cut
# TODO: RCL 2011-11-06 Document attributes

has 'changes'           => ( is => 'ro', isa => 'Int',          );
has 'vehicle_time'      => ( is => 'ro', isa => 'Int',          );
has 'partial_routes'    => ( is => 'rw', isa => 'ArrayRef[WWW::EFA::PartialRoute]' );
has 'departure_time'    => ( is => 'rw', isa => 'Class::Date'   );
has 'arrival_time'      => ( is => 'rw', isa => 'Class::Date'   );

1;


=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

