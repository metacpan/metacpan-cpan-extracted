package WWW::TypePad::Events;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::events { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Events - Events API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->events->get($id);

Get basic information about the selected event.

Returns Event which contains following properties.

=over 8

=item id

(string) A URI that serves as a globally unique identifier for the event.

=item urlId

(string) A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same event is returned in response to different requests, and as a mapping key for an application's local data store.

=item verb

(string) A keyword identifying the type of event this is.

=item verbs

(setE<lt>stringE<gt>) BE<lt>DeprecatedE<gt> An array of verb identifier URIs. This set will contain one verb identifier URI.

=item actor

(Entity) The user who performed the action described by this event.

=item object

(Base) The object to which the action described by this event was performed.

=item published

(datetime) The time at which the event was performed, as a W3CDTF timestamp.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/events/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
