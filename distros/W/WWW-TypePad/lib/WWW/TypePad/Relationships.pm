package WWW::TypePad::Relationships;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::relationships { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Relationships - Relationships API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->relationships->get($id);

Get basic information about the selected relationship.

Returns Relationship which contains following properties.

=over 8

=item id

(string) A URI that serves as a globally unique identifier for the relationship.

=item urlId

(string) A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same relationship is returned in response to different requests, and as a mapping key for an application's local data store.

=item source

(Entity) The source entity of the relationship.

=item target

(Entity) The target entity of the relationship.

=item status

(RelationshipStatus) An object describing all the types of relationship that currently exist between the source and target objects.

=item created

(mapE<lt>datetimeE<gt>) A mapping of the relationship types present between the source and target objects to the times those types of relationship were established. The keys of the map are the relationship type URIs present in the relationship's ME<lt>statusE<gt> property; the values are W3CDTF timestamps for the times those relationship edges were created.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/relationships/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item get_status

  my $res = $tp->relationships->get_status($id);

Get the status information for the selected relationship, including its types.

Returns RelationshipStatus which contains following properties.

=over 8

=item types

(arrayE<lt>stringE<gt>) A list of relationship type URIs describing the types of the related relationship.


=back

=cut

sub get_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/relationships/%s/status.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub status {
    my $self = shift;
    Carp::carp("'status' is deprecated. Use 'get_status' instead.");
    $self->get_status(@_);
}

=pod



=item put_status

  my $res = $tp->relationships->put_status($id);

Change the status information for the selected relationship, including its types.

Returns RelationshipStatus which contains following properties.

=over 8

=item types

(arrayE<lt>stringE<gt>) A list of relationship type URIs describing the types of the related relationship.


=back

=cut

sub put_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/relationships/%s/status.json', @args;
    $api->base->call("PUT", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
