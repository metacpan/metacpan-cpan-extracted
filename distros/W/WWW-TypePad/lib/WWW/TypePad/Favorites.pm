package WWW::TypePad::Favorites;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::favorites { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Favorites - Favorites API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item delete

  my $res = $tp->favorites->delete($id);

Delete the selected favorite.

Returns Favorite which contains following properties.

=over 8

=item id

(string) A URI that serves as a globally unique identifier for the favorite.

=item urlId

(string) A string containing the canonical identifier that can be used to identify this favorite in URLs. This can be used to recognise where the same favorite is returned in response to different requests, and as a mapping key for an application's local data store.

=item author

(User) The user who saved this favorite. That is, this property is the user who saved the target asset as a favorite, not the creator of that asset.

=item inReplyTo

(AssetRef) A reference to the target asset that has been marked as a favorite.

=item published

(datetime) The time that the favorite was created, as a W3CDTF timestamp.


=back

=cut

sub delete {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/favorites/%s.json', @args;
    $api->base->call("DELETE", $uri, @_);
}


=pod



=item get

  my $res = $tp->favorites->get($id);

Get basic information about the selected favorite, including its owner and the target asset.

Returns Favorite which contains following properties.

=over 8

=item id

(string) A URI that serves as a globally unique identifier for the favorite.

=item urlId

(string) A string containing the canonical identifier that can be used to identify this favorite in URLs. This can be used to recognise where the same favorite is returned in response to different requests, and as a mapping key for an application's local data store.

=item author

(User) The user who saved this favorite. That is, this property is the user who saved the target asset as a favorite, not the creator of that asset.

=item inReplyTo

(AssetRef) A reference to the target asset that has been marked as a favorite.

=item published

(datetime) The time that the favorite was created, as a W3CDTF timestamp.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/favorites/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
