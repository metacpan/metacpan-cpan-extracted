package WWW::EFA::Stop;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::Stop - A stop in a trip sequence

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS


=head1 ATTRIBUTES

=cut
# TODO: RCL 2011-11-06 Document attributes

has 'location'          => ( is => 'ro', isa => 'WWW::EFA::Location', );
has 'arrival_time'      => ( is => 'ro', isa => 'Class::Date',  );
has 'departure_time'    => ( is => 'ro', isa => 'Class::Date',  );

1;
