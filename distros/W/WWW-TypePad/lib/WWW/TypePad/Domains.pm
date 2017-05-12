package WWW::TypePad::Domains;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::domains { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Domains - Domains API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->domains->get($id);

Get basic information about the selected domain.

Returns Domain which contains following properties.

=over 8

=item domain

(string) The domain that this object describes.

=item owner

(User) The user that owns this domain in TypePad.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/domains/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item resolve_path

  my $res = $tp->domains->resolve_path($id);

Given a URI path, find the blog and asset, if any, that the path matches.

Returns hash reference which contains following properties.

=over 8

=item blog

(Blog) The blog that the given URL belongs to, if any.

=item asset

(Asset) The asset that the given URL is for, if any.

=item isFullMatch

(boolean) CE<lt>trueE<gt> if the given path matched a blog or asset directly, or CE<lt>falseE<gt> if this is only a prefix match. If using this endpoint to implement an alternative blog renderer, a client should return 404 if this flag is not set.


=back

=cut

sub resolve_path {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/domains/%s/resolve-path.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
