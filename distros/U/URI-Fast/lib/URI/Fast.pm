package URI::Fast;

our $XS_VERSION = our $VERSION = '0.38';
$VERSION =~ tr/_//;

use utf8;
use strict;
use warnings;
no strict 'refs';

use Carp;
use Exporter;

require XSLoader;
XSLoader::load('URI::Fast', $XS_VERSION);

use Exporter 'import';

our @EXPORT_OK = qw(
  uri iri uri_split
  encode url_encode
  decode url_decode
);

require URI::Fast::IRI;

use overload '""' => sub{ $_[0]->to_string },
             'eq' => sub{ $_[0]->compare($_[1]) };

sub uri { URI::Fast->new($_[0]) }
sub iri { URI::Fast::IRI->new_iri($_[0]) }

# Aliases
sub as_string  { goto \&to_string }
sub url_encode { goto \&encode    }
sub url_decode { goto \&decode    }

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
      $self->set_usr($val->{usr}   || '');
      $self->set_pwd($val->{pwd}   || '');
      $self->set_host($val->{host} || '');
      $self->set_port($val->{port} || '');
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
    if (ref $val) {
      $self->set_path_array($val);
    } else {
      $self->set_path($val);
    }
  }

  if (wantarray) {
    @{ $self->split_path };
  } elsif (defined wantarray) {
    $self->get_path;
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

sub query_hash {
  my $self = shift;
  $self->query(@_) if @_;
  $self->get_query_hash;
}

sub query_keys {
  keys %{ $_[0]->get_query_keys };
}

sub query_keyset {
  $_[0]->update_query_keyset($_[1], $_[2] || '&');
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

sub add_param {
  my ($self, $key, $val, $sep) = @_;
  $self->param($key, [$self->param($key), $val], $sep);
}

sub _cmp ($$) {
  if (defined $_[0]) {
    return if !defined $_[1];
    return if $_[0] ne $_[1];
  }
  elsif (defined $_[1]) {
    return;
  }

  return 1;
}

sub compare {
  my ($self, $other) = @_;
  $other = uri $other;

  return unless _cmp($self->scheme, $other->scheme)
    && _cmp($self->usr,  $other->usr)
    && _cmp($self->pwd,  $other->pwd)
    && _cmp($self->host, $other->host)
    && _cmp($self->port, $other->port)
    && _cmp($self->frag, $other->frag);

  my @spath = $self->path;
  my @opath = $other->path;
  return unless @spath == @opath;

  foreach (0 .. $#spath) {
    return unless _cmp($spath[$_], $opath[$_]);
  }

  my $sparam = $self->query_hash;
  my $oparam = $other->query_hash;

  foreach my $k (keys %$sparam) {
    return unless exists $oparam->{$k};
    return unless @{$sparam->{$k}} == @{$oparam->{$k}};

    foreach (0 .. $#{$sparam->{$k}}) {
      return unless _cmp($sparam->{$k}[$_], $oparam->{$k}[$_]);
    }
  }

  return 1;
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

=head2 encode/decode/url_encode/url_decode

See L</ENCODING>.

=head1 ATTRIBUTES

Unless otherwise specified, all attributes serve as full accessors, allowing
the URI segment to be both retrieved and modified.

Each attribute further has a matching clearer method (C<clear_*>) which unsets
its value.

Note that because URIs are parsed into a fixed size struct, any method
(including the constructor) attempting to set a value larger than the max
allowable size cause the value to be truncated before croaking. If this error
is caught in an eval, the URI will remain nominally usable in its updated,
truncated state.

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
IP address. If the host is an IPV6 address, it must be surrounded by square
brackets (per spec), which are included in the host string. Updating this value
alters L</auth>.

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

Both '&' and ';' are treated as separators for key/value parameters.

=head2 frag

The fragment section of the URI, excluding the leading C<#>.

=head1 METHODS

=head2 query_keys

Does a fast scan of the query string and returns a list of unique parameter
names that appear in the query string.

Both '&' and ';' are treated as separators for key/value parameters.

=head2 query_hash

Scans the query string and returns a hash ref of key/value pairs. Values are
returned as an array ref, as keys may appear multiple times. Both '&' and ';'
are treated as separators for key/value parameters.

May optionally be called with a new hash of parameters to replace the query
string with, in which case keys may map to scalar values or arrays of scalar
values. As with all query setter methods, a third parameter may be used to
explicitly specify the separator to use when generating the new query string.

=head2 param

Gets or sets a parameter value. Setting a parameter value will replace existing
values completely; the L</query> string will also be updated. Setting a
parameter to C<undef> deletes the parameter from the URI.

  $uri->param('foo', ['bar', 'baz']);
  $uri->param('fnord', 'slack');

  my $value_scalar = $uri->param('fnord'); # fnord appears once
  my @value_list   = $uri->param('foo');   # foo appears twice
  my $value_scalar = $uri->param('foo');   # croaks; expected single value but foo has multiple

  # Delete 'foo'
  $uri->param('foo', undef);

Both '&' and ';' are treated as separators for key/value parameters when
parsing the query string. An optional third parameter explicitly selects the
character used to separate key/value pairs.

  $uri->param('foo', 'bar', ';'); # foo=bar
  $uri->param('baz', 'bat', ';'); # foo=bar;baz=bat

When unspecified, '&' is chosen as the default. I<In either case, all
separators in the query string will be normalized to the chosen separator>.

  $uri->param('foo', 'bar', ';'); # foo=bar
  $uri->param('baz', 'bat', ';'); # foo=bar;baz=bat
  $uri->param('fnord', 'slack');  # foo=bar&baz=bat&fnord=slack

=head2 add_param

Updates the query string by adding a new value for the specified key. If the
key already exists in the query string, the new value is appended without
altering the original value.

  $uri->add_param('foo', 'bar'); # foo=bar
  $uri->add_param('foo', 'baz'); # foo=bar&foo=baz

This method is simply sugar for calling:

  $uri->param('key', [$uri->param('key'), 'new value']);

As with L</param>, the separator character may be specified as the final
parameter. The same caveats apply with regard to normalization of the query
string separator.

  $uri->add_param('foo', 'bar', ';'); # foo=bar
  $uri->add_param('foo', 'baz', ';'); # foo=bar;foo=baz

=head2 query_keyset

Allows modification of the query string in the manner of a set, using keys
without C<=value>, e.g. C<foo&bar&baz>. Accepts a hash ref of keys to update.
A truthy value adds the key, a falsey value removes it. Any keys not mentioned
in the update hash are left unchanged.

  my $uri = uri '&baz&bat';
  $uri->query_keyset({foo => 1, bar => 1}); # baz&bat&foo&bar
  $uri->query_keyset({baz => 0, bat => 0}); # foo&bar

If there are key-value pairs in the query string as well, the behavior of
this method becomes a little more complex. When a key is specified in the
hash update hash ref, a positive value will leave an existing key/value pair
untouched. A negative value will remove the key and value.

  my $uri = uri '&foo=bar&baz&bat';
  $uri->query_keyset({foo => 1, baz => 0}); # foo=bar&bat

An optional second parameter may be specified to control the separator
character used when updating the query string. The same caveats apply with
regard to normalization of the query string separator.

=head2 to_string

=head2 as_string

=head2 "$uri"

Stringifies the URI, encoding output as necessary. String interpolation is
overloaded.

=head2 compare

=head2 $uri eq $other

Compares the URI to another, returning true if the URIs are equivalent.
Overloads the C<eq> operator.

=head1 ENCODING

C<URI::Fast> tries to do the right thing in most cases with regard to reserved
and non-ASCII characters. C<URI::Fast> will fully encode reserved and non-ASCII
characters when setting I<individual> values. However, the "right thing" is a
bit ambiguous when it comes to setting compound fields like L</auth>, L</path>,
and L</query>.

When setting these fields with a string value, reserved characters are expected
to be present, and are therefore accepted as-is. However, any non-ASCII
characters will be percent-encoded (since they are unambiguous and there is no
risk of double-encoding them). Thus,

  $uri->auth('someone:secret@Ῥόδος.com:1234');
  print $uri->auth; # "someone:secret@%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82.com:1234"

On the other hand, when setting these fields with a I<reference> value (assumed
to be a hash ref for L</auth> and L</query> or an array ref for L</path>; see
individual methods' docs for details), each field is fully percent-encoded:

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

=head2 url_encode

=head2 url_decode

These are aliases of L</encode> and L</decode>, respectively. They were added
to make L<BLUEFEET|https://metacpan.org/author/BLUEFEET> happy after he made
fun of me for naming L</encode> and L</decode> too generically.

=head1 SPEED

See L<URI::Fast::Benchmarks>.

=head1 FUTURE PLANS

=over

=item Zero-copy strategy for parsing and updating query string

L</uri> does a single, fast pass over the input string and copies portions into
the struct members. Some compound fields, such as the query and path, are only
parsed as needed. Switching to a zero-copy strategy could make the initial pass
faster, reduce time spent zeroing out the struct, and make better use of the
cache.

=item Support for arbitrary binary data in query string

Currently, queries are restricted to keys or key/value pairs and decoded into
utf8 strings.

=item Compat module

Add a compatibility layer with URI that implements what functionality is
possible and croaks loudly otherwise.

=back

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

=head1 CONTRIBUTORS

The following people have contributed to this module with patches, bug reports,
API advice, identifying areas where the documentation is unclear, or by making
fun of me for naming certain methods too generically.

=over

=item Andy Ruder

=item Aran Deltac (BLUEFEET)

=item Dave Hubbard (DAVEH)

=item James Messrie

=item Randal Schwartz (MERLYN)

=item Sara Siegal (SSIEGAL)

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober. This is free software; you
can redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself.

=cut

1;
