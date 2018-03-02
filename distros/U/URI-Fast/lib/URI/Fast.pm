package URI::Fast;
# ABSTRACT: A fast(er) URI parser
$URI::Fast::VERSION = '0.06';

use Carp;
use URI::Encode::XS qw(uri_encode);
use Inline C => 'lib/uri_fast.c';

require Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw(uri uri_split);

use overload '""' => sub{ $_[0]->to_string };

sub uri ($) {
  my $self = URI::Fast->new($_[0]);
  $self->set_scheme('file') unless $self->get_scheme;
  $self;
}

# Regexes used to validate characters present in string when attributes are
# updated.
my %LEGAL = (
  scheme => qr/^[a-zA-Z][-.+a-zA-Z0-9]*$/,
  port   => qr/^[0-9]+$/,
);

# Build a simple accessor for basic attributes
foreach my $attr (qw(scheme auth query frag host port)) {
  my $s = "set_$attr";
  my $g = "get_$attr";

  *{__PACKAGE__ . "::$attr"} = sub {
    if (@_ == 2) {
      if (exists $LEGAL{$attr} && $_[1] !~ $LEGAL{$attr}) {
        croak "illegal chars in $attr";
      }

      $_[0]->$s( $_[1] );
    }

    $_[0]->$g();
  };
}

foreach my $attr (qw(usr pwd)) {
  my $s = "set_$attr";
  my $g = "get_$attr";

  *{__PACKAGE__ . "::$attr"} = sub {
    if (@_ == 2) {
      if (exists $LEGAL{$attr} && $_[1] !~ $LEGAL{$attr}) {
        croak "illegal chars in $attr";
      }

      $_[0]->$s( uri_encode( $_[1] ) );
    }

    uri_decode( $_[0]->$g() );
  };
}

# Path is slightly more complicated as it can parse the path
sub path {
  my ($self, $val) = @_;

  if (@_ == 2) {
    $self->set_path(ref $val ? '/' . join('/', @$val) : $val);
  }

  if (wantarray) {
    return $self->split_path;
  }
  else {
    $self->get_path;
  }
}

sub param {
  my ($self, $key, $val) = @_;
  $key = uri_encode($key);

  if (@_ == 3) {
    my $query = $self->get_query;

    # Wipe out current values for $key
    $query =~ s/\b$key=[^&#]+&?//g;
    $query =~ s/^&//;
    $query =~ s/&$//;

    # If $val is undefined, the parameter is deleted
    if (defined $val) {
      # Encode and attach values for param to query string
      foreach (ref $val ? @$val : ($val)) {
        $query .= '&' if $query;
        $query .= $key . '=' . uri_encode($_);
      }
    }

    $self->set_query($query);
  }

  my @params = $_[0]->get_param(uri_encode($_[1]))
    or return;

  return @params == 1
    ? uri_decode($params[0])
    : [ map{ uri_decode($_) } @params ];
}

sub uri_decode ($) {
  $_[0] =~ tr/+/ /;
  URI::Encode::XS::uri_decode($_[0]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Fast - A fast(er) URI parser

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use URI::Fast qw(uri);

  my $uri = uri 'http://www.example.com/some/path?a=b&c=d';

  if ($uri->scheme =~ /http(s)?/) {
    my @path = $uri->path;
    my $a = $uri->param('a');
    my $b = $uri->param('b');
  }

  if ($uri->path =~ /\/login/ && $uri->scheme ne 'https') {
    $uri->scheme('https');
    $uri->param('upgraded', 1);
  }

=head1 DESCRIPTION

L<URI> is an excellent module. It is battle-tested, robust, and at this point
handles nearly every edge case imaginable. It is often the case, however, that
one just needs to grab the path string out of a URL. Or validate some query
parameters. Et cetera. In those cases, L<URI> may seem like overkill and may,
in fact, be much slower than a simpler solution, like L<URI::Split>.
Unfortunately, L<URI::Split> is so bare bones that it does not even parse the
authorization section or access or update query parameters.

C<URI::Fast> aims to bridge the gap between the two extremes. It provides fast
parsing without many of the frills of L<URI> while at the same time providing
I<slightly> more than L<URI::Split> by returning an object with methods to
access and update portions of the URI.

=head1 EXPORTED SUBROUTINES

=head2 uri

Accepts a string, minimally parses it, and returns a L<URI::Fast> object.

When initially created, only the scheme, authorization section, path, query
string, and fragment are split out. Thesea are broken down in a lazy fashion
as needed when a related attribute accessor is called.

=head1 ATTRIBUTES

Unless otherwise specified, all attributes serve as full accessors, allowing
the URI segment to be both retrieved and modified.

=head2 scheme

Defaults to C<file> if not present in the uri string.

=head2 auth

The authorization section is composed of the username, password, host name, and
port number:

  hostname.com
  someone@hostname.com
  someone:secret@hostname.com:1234

Accessing the following attributes may incur a small amount of extra overhead
the first time they are called and the auth string is parsed.

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

The complete query string. Does not include the leading C<?>.

=head3 param

Gets or sets a parameter value. The first time this is called, it incurs the
overhead of parsing and decoding the query string.

If the key appears more than once in the query string, the value returned will
be an array ref of each of its values.

Setting the parameter will update the L</query> string.

=head2 frag

The fragment section of the URI, excluding the leading C<#>.

=head1 SPEED

See L<URI::Fast::Benchmarks>.

=head1 SEE ALSO

=over

=item L<URI>

The de facto standard.

=item L<Panda::URI>

Written in C++ and purportedly very fast, but appears to only support Linux.

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
