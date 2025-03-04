package Zonemaster::Engine::Exception;

use v5.16.0;
use warnings;

use version; our $VERSION = version->declare("v1.0.3");

use Class::Accessor "antlers";

use overload '""' => \&string;

has 'message' => ( is => 'ro', isa => 'Str', required => 1 );

sub string {
    my ( $self ) = @_;

    return $self->message;
}

1;

=head1 NAME

Zonemaster::Engine::Exception -- base class for Zonemaster::Engine exceptions

=head1 SYNOPSIS

   die Zonemaster::Engine::Exception->new({ message => "This is an exception" });

=head1 ATTRIBUTES

=over

=item message

A string attribute holding a message for possible human consumption.

=back

=head1 METHODS

=over

=item string()

Method that stringifies the object by returning the C<message> attribute.
Stringification is overloaded to this.

=back

=cut
