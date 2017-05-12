package WWW::TypePad::AuthTokens;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::auth_tokens { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::AuthTokens - AuthTokens API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->auth_tokens->get($id);

Get basic information about the selected auth token, including what object it grants access to.

Returns AuthToken which contains following properties.

=over 8

=item authToken

(string) The actual auth token string. Use this as the access token when making an OAuth request.

=item targetObject

(Base) BE<lt>DeprecatedE<gt> The root object to which this auth token grants access. This is a legacy field maintained for backwards compatibility with older clients, as auth tokens are no longer scoped to specific objects.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/auth-tokens/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
