package WWW::TypePad::ApiKeys;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::api_keys { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::ApiKeys - ApiKeys API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->api_keys->get($id);

Get basic information about the selected API key, including what application it belongs to.

Returns ApiKey which contains following properties.

=over 8

=item apiKey

(string) The actual API key string. Use this as the consumer key when making an OAuth request.

=item owner

(Application) The application that owns this API key.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/api-keys/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
