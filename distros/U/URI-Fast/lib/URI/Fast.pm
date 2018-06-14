package URI::Fast;

use strict;
use warnings;
no strict 'refs';

our $VERSION = '0.32';

use Carp;
use Exporter;

require XSLoader;
XSLoader::load('URI::Fast', $VERSION);

use Exporter 'import';
our @EXPORT_OK = qw(uri iri uri_split encode decode);

use overload '""' => sub{ $_[0]->to_string };

sub uri { URI::Fast->new($_[0]) }
sub iri { URI::Fast::IRI->new_iri($_[0]) }
sub as_string { goto \&to_string }

# Build a simple accessor for basic attributes
foreach my $attr (qw(scheme usr pwd host port frag)) {
  my $s = "set_$attr";
  my $g = "get_$attr";

  *{__PACKAGE__ . "::$attr"} = sub {
    if (@_ == 2) {
      $_[0]->$s( $_[1] );
    }

    if (defined wantarray) {
      # It turns out that it is faster to call decode here than directly in
      # url_fast.c due to the overhead of decoding utf8 and flipping the
      # internal utf8 switch.
      return decode( $_[0]->$g() );
    }
  };
}

sub auth {
  my ($self, $val) = @_;

  if (@_ == 2) {
    if (ref $val) {
      $self->set_usr($val->{usr}   // '');
      $self->set_pwd($val->{pwd}   // '');
      $self->set_host($val->{host} // '');
      $self->set_port($val->{port} // '');
    }
    else {
      $self->set_auth($val);
    }
  }

  return $self->get_auth
    if defined wantarray;
}

# Path is slightly more complicated as it can parse the path
sub path {
  my ($self, $val) = @_;

  if (@_ == 2) {
    $val = '/' . join '/', @$val if ref $val;
    $self->set_path($val);
  }

  if (wantarray) {
    @{ $self->split_path };
  }
  elsif (defined wantarray) {
    decode($self->get_path);
  }
}

# Queries may be set with either a string or a hash ref
sub query {
  my ($self, $val, $sep) = @_;

  if (@_ > 1) {
    if (ref $val) {
      $self->clear_query;
      $self->param($_, $val->{$_}, $sep)
        foreach keys %$val;
    }
    else {
      $self->set_query($val);
    }
  }

  return unless defined(wantarray);         # void context
  return $self->get_query unless wantarray; # scalar context
  return %{ $self->query_hash };            # list context
}

sub query_keys {
  keys %{ $_[0]->get_query_keys };
}

sub param {
  my ($self, $key, $val, $sep) = @_;
  $sep ||= '&';

  if (@_ > 2) {
    $val = ref     $val ? $val
         : defined $val ? [$val]
         : [];

    $self->set_param($key, $val, $sep);
  }

  # No return value in void context
  return unless defined(wantarray) && $key;

  my $params = $self->get_param($key);
  return unless @$params;

  return wantarray     ? @$params
       : @$params == 1 ? $params->[0]
       : croak("param: multiple values encountered for query parameter '$key' when called in SCALAR context");
}

=encoding UTF8

=head1 NAME

URI::Fast - A fast(er) URI parser

=head1 SYNOPSIS

  use URI::Fast qw(uri);

  my $uri = uri 'http://www.example.com/some/path?fnord=slack&foo=bar';

  if ($uri->scheme =~ /http(s)?/) {
    my @path  = $uri->path;
    my $fnord = $uri->param('fnord');
    my $foo   = $uri->param('foo');
  }

  if ($uri->path =~ /\/login/ && $uri->scheme ne 'https') {
    $uri->scheme('https');
    $uri->param('upgraded', 1);
  }

=head1 DESCRIPTION

C<URI::Fast> is a faster alternative to L<URI>. It is written in C and provides
basic parsing and modification of a URI.

L<URI> is an excellent module; it is battle-tested, robust, and handles many
edge cases. As a result, it is rather slower than it would otherwise be for
more trivial cases, such as inspecting the path or updating a single query
parameter.

=head1 EXPORTED SUBROUTINES

Subroutines are exported on demand.

=head2 uri

Accepts a URI string, minimally parses it, and returns a C<URI::Fast> object.

=head2 iri

Similar to L</uri>, but returns a C<URI::Fast::IRI> object. A C<URI::Fast::IRI>
differs from a C<URI::Fast> in that UTF-8 characters are permitted and will not
be percent-encoded when modified.

=head2 uri_split

Behaves (hopefully) identically to L<URI::Split>, but roughly twice as fast.

=head2 encode/decode

See L</ENCODING>.

=head1 ATTRIBUTES

Unless otherwise specified, all attributes serve as full accessors, allowing
the URI segment to be both retrieved and modified.

Each attribute further has a matching clearer method (C<clear_*>) which unsets
its value.

=head2 scheme

Gets or sets the scheme portion of the URI (e.g. C<http>), excluding C<://>.

=head2 auth

The authorization section is composed of the username, password, host name, and
port number:

  hostname.com
  someone@hostname.com
  someone:secret@hostname.com:1234

Setting this field may be done with a string (see the note below about
L</ENCODING>) or a hash reference of individual field names (C<usr>, C<pwd>,
C<host>, and C<port>). In both cases, the existing values are completely
replaced by the new values and any values not present are deleted.

=head3 usr

The username segment of the authorization string. Updating this value alters
L</auth>.

=head3 pwd

The password segment of the authorization string. Updating this value alters
L</auth>.

=head3 host

The host name segment of the authorization string. May be a domain string or an
IP address. Updating this value alters L</auth>.

=head3 port

The port number segment of the authorization string. Updating this value alters
L</auth>.

=head2 path

In scalar context, returns the entire path string. In list context, returns a
list of path segments, split by C</>.

The path may also be updated using either a string or an array ref of segments:

  $uri->path('/foo/bar');
  $uri->path(['foo', 'bar']);

=head2 query

In scalar context, returns the complete query string, excluding the leading
C<?>. The query string may be set in several ways.

  $uri->query("foo=bar&baz=bat"); # note: no percent-encoding performed
  $uri->query({foo => 'bar', baz => 'bat'}); # foo=bar&baz=bat
  $uri->query({foo => 'bar', baz => 'bat'}, ';'); # foo=bar;baz=bat

In list context, returns a hash ref mapping query keys to array refs of their
values (see L</query_hash>).

=head3 query_keys

Does a fast scan of the query string and returns a list of unique parameter
names that appear in the query string.

=head3 query_hash

Scans the query string and returns a hash ref of key/value pairs. Values are
returned as an array ref, as keys may appear multiple times.

=head3 param

Gets or sets a parameter value. Setting a parameter value will replace existing
values completely; the L</query> string will also be updated. Setting a
parameter to C<undef> deletes the parameter from the URI.

  $uri->param('foo', ['bar', 'baz']);
  $uri->param('fnord', 'slack');

  my $value_scalar    = $uri->param('fnord'); # fnord appears once
  my @value_list      = $uri->param('foo');   # foo appears twice
  my $value_scalar    = $uri->param('foo');   # croaks; expected single value but foo has multiple

  # Delete 'foo'
  $uri->param('foo', undef);

An optional third parameter may be specified to control the character used to
separate key/value pairs.

  $uri->param('foo', 'bar', ';'); # foo=bar
  $uri->param('baz', 'bat', ';'); # foo=bar;baz=bat

=head2 frag

The fragment section of the URI, excluding the leading C<#>.

=head1 ENCODING

C<URI::Fast> tries to do the right thing in most cases with regard to reserved
and non-ASCII characters. C<URI::Fast> will fully encode reserved and non-ASCII
characters when setting C<individual> values. However, the "right thing" is a
bit ambiguous when it comes to setting compound fields like L</auth>, L</path>,
and L</query>.

When setting these fields with a string value, reserved characters are expected
to be present, and are therefore accepted as-is. However, any non-ASCII
characters will be percent-encoded (since they are unambiguous and there is no
risk of double-encoding them).

  $uri->auth('someone:secret@Ῥόδος.com:1234');
  print $uri->auth; # "someone:secret@%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82.com:1234"

On the other hand, when setting these fields with a I<reference> value, each
field is fully percent-encoded:

  $uri->auth({usr => 'some one', host => 'somewhere.com'});
  print $uri->auth; # "some%20one@somewhere.com"

The same goes for return values. For compound fields returning a string,
non-ASCII characters are decoded but reserved characters are not. When
returning a list or reference of the deconstructed field, individual values are
decoded of both reserved and non-ASCII characters.

=head2 encode

Percent-encodes a string for use in a URI. By default, both reserved and UTF-8
chars (C<! * ' ( ) ; : @ & = + $ , / ? # [ ] %>) are encoded.

A second (optional) parameter provides a string containing any characters the
caller does not wish to be encoded. An empty string will result in the default
behavior described above.

For example, to encode all characters in a query-like string I<except> for
those used by the query:

  my $encoded = URI::Fast::encode($some_string, '?&=');

=head2 decode

Decodes a percent-encoded string.

  my $decoded = URI::Fast::decode($some_string);

=head1 SPEED

See L<URI::Fast::Benchmarks>.

=head1 SEE ALSO

=over

=item L<URI>

The de facto standard.

=item L<Panda::URI>

Written in C++ and purportedly very fast, but appears to only support Linux.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com> for encouraging their
employees to contribute back to the open source ecosystem. Without their
dedication to quality software development this distribution would not exist.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;

package URI::Fast::IRI;
our @ISA = qw(URI::Fast);
1;
