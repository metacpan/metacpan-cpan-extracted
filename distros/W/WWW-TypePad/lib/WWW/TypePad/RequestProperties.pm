package WWW::TypePad::RequestProperties;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::request_properties { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::RequestProperties - RequestProperties API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->request_properties->get();

Retrieve some request properties. This can be useful for debugging authentication issues.

Returns RequestProperties which contains following properties.

=over 8

=item userId

(string) The ME<lt>urlIdE<gt> of the authenticated user for this request. Ommitted if there is no authenticated user.

=item applicationId

(string) The ME<lt>urlIdE<gt> of the authenticated application for this request. Ommitted if there is no authenticated application.

=item apiKey

(string) The API key that was used for this request, if the request is using OAuth. Ommitted if the request is not using OAuth.

=item canModifyApplicationContent

(boolean) True if the caller for this request could modify content connected to the authenticated application, or false otherwise.

=item canModifyTypepadContent

(boolean) True if the caller for this request could modify content that is part of the main TypePad application, or false otherwise.

=item clientIsInternal

(boolean) True if this request came in on a channel that has access to internal-only API features.

=item remoteIpAddress

(string) The IP address of the requesting client, expressed in dotted-decimal notation.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    my $uri = sprintf '/request-properties.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
