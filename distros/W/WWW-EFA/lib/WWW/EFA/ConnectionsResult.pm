package WWW::EFA::ConnectionsResult;
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use Carp;
with 'WWW::EFA::Roles::Printable'; # provides method 'string'

subtype 'ValidConnectionStatus',
      as 'Str',
      where { $_ =~ m/^(OK|AMBIGUOUS|TOO_CLOSE|UNRESOLVABLE_ADDRESS|NO_CONNECTIONS|INVALID_DATE|SERVICE_DOWN)$/ },
      message { "Invalid connection status" };



=head1 NAME

WWW::EFA::ConnectionsResult - Store the results from a connection query

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

# TODO: RCL 2011-08-23 Complete

=head1 PARAMS/ACCESSORS

=cut

has 'status' => (
    is          => 'rw',
    isa         => 'ValidConnectionStatus',
    );

has 'ambiguous_from' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub{ [] },
    );

has 'ambiguous_via' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub{ [] },
    );

has 'ambiguous_to' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub{ [] },
    );

has 'request' => (
    is          => 'rw',
    isa         => 'WWW::EFA::Request',
    required    => 1,
    );

has 'request_id' => (
    is          => 'rw',
    isa         => 'Int',
    );

has 'origin_location' => (
    is          => 'rw',
    isa         => 'WWW::EFA::Location',
    );

has 'via_location' => (
    is          => 'rw',
    isa         => 'WWW::EFA::Location',
    );

has 'destination_location' => (
    is          => 'rw',
    isa         => 'WWW::EFA::Location',
    );

has 'routes' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub{ [] },
    );

=head1 METHODS

=head2 add_route( $route )

Add a L<WWW::EFA::Route> to the result

=cut
sub add_route {
    my $self = shift;
    my ( $route ) = pos_validated_list(
        \@_,
        { isa => 'WWW::EFA::Route' },
    );
    my @routes = @{ $self->routes };
    push( @routes, $route );
    @routes = sort{ $a->departure_time <=> $b->departure_time } @routes;
    $self->routes( \@routes );
}


1;

