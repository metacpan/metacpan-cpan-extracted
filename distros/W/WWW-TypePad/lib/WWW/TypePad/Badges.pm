package WWW::TypePad::Badges;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::badges { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Badges - Badges API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->badges->get($id);

Get basic information about the selected badge.

Returns Badge which contains following properties.

=over 8

=item id

(string) The canonical identifier that can be used to identify this badge in URLs.  This can be used to recognise where the same badge is returned in response to different requests, and as a mapping key for an application's local data store.

=item displayName

(string) A human-readable name for this badge.

=item description

(string) A human-readable description of what a user must do to win this badge.

=item imageLink

(ImageLink) A link to the image that depicts this badge to users.

=item isLearning

(boolean) A learning badge is given for a special achievement a user accomplishes while filling out a new account. CE<lt>trueE<gt> if this is a learning badge, or CE<lt>falseE<gt> if this is a normal badge.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/badges/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
