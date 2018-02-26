
package URI::Fast;
# ABSTRACT: A fast(er) URI parser
$URI::Fast::VERSION = '0.03';
use common::sense;
use URI::Split qw(uri_split);
use URI::Encode::XS qw(uri_decode uri_encode);
use Carp;

use overload
  '""' => sub{
    "$_[0]->{scheme}://$_[0]->{auth}$_[0]->{path}"
      . ($_[0]->{query} ? ('?' . $_[0]->{query}) : '')
      . ($_[0]->{frag}  ? ('#' . $_[0]->{frag})  : '');
  };

use parent 'Exporter';
our @EXPORT_OK = qw(uri);

# Regexes used to validate characters present in string when attributes are
# updated.
our %LEGAL = (
  scheme => qr/^[a-zA-Z][-.+a-zA-Z0-9]*$/,
  port   => qr/^[0-9]+$/,
);

sub uri ($) {
  my $self = bless {}, __PACKAGE__;
  @{$self}{qw(scheme auth path query frag)} = uri_split $_[0];
  $self->{scheme} //= 'file';
  $self;
}

# Build a simple accessor for basic attributes
foreach my $attr (qw(scheme auth query frag)) {
  *{__PACKAGE__ . "::$attr"} = sub {
    if (@_ == 2) {
      !exists($LEGAL{$attr}) || $_[1] =~ $LEGAL{$attr} || croak "illegal chars in $attr";
      $_[0]->{$attr} = $_[1];
      undef $_[0]->{'_' . $attr};
    }

    $_[0]->{$attr};
  };
}

# Path is slightly more complicated as it can parse the path
sub path {
  if (@_ == 2) {
    local $" = '/';           # Set list separator for string interpolation
    $_[0]->{path} = ref $_[1] # Check whether setting with list or string
      ? "/@{$_[1]}"           # List ref
      : $_[1];                # Scalar
  }

  if (wantarray) {
    local $_ = $_[0]->{path};
    s/^\///;
    split /\//;
  }
  else {
    $_[0]->{path};
  }
}

# For bits of the auth string, build a lazy accessor that calls _auth, which
# parses the auth string.
foreach my $attr (qw(usr pwd host port)) {
  *{__PACKAGE__ . "::$attr"} = sub {
    $_[0]->{auth} && $_[0]->{_auth} || $_[0]->_auth;

    # Set new value, then regenerate authorization section string
    if (@_ == 2) {
      !exists($LEGAL{$attr}) || $_[1] =~ $LEGAL{$attr} || croak "illegal chars in $attr";
      $_[0]->{_auth}{$attr} = $_[1];
      $_[0]->_reauth;
    }

    $_[0]->{_auth}{$attr};
  };
}

# Parses auth section
sub _auth {
  my ($self) = @_;
  $self->{_auth} = {};                                     # Set a flag to prevent reparsing

  if (local $_ = $self->auth) {
    my ($cred, $loc) = split /@/;                          # usr:pwd@host:port

    if ($loc) {
      @{$self->{_auth}}{qw(usr pwd)}   = split ':', $cred; # Both credentials and location are present
      @{$self->{_auth}}{qw(host port)} = split ':', $loc;
    }
    else {
      @{$self->{_auth}}{qw(host port)} = split ':', $cred; # Only location is present
    }
  }
}

# Regenerates auth section
sub _reauth {
  my $self = shift;
  $self->{auth} = '';

  if ($self->{_auth}{usr}) {                                           # Add the credentials block (usr:pwd)
    $self->{auth} = $self->{_auth}{usr};                               # Add user
    $self->{auth} .= ':' . $self->{_auth}{pwd} if $self->{_auth}{pwd}; # Add :pwd if pwd present
    $self->{auth} .= '@';
  }

  if ($self->{_auth}{host}) {
    $self->{auth} .= $self->{_auth}{host};                             # Add host if present (may not be for, e.g. file://)

    if ($self->{_auth}{port}) {
      $self->{auth} .= ':' . $self->{_auth}{port};                     # Port only valid if host is present
    }
  }
}

sub param {
  my ($self, $key, $val) = @_;
  $self->{query} || $val || return;

  if (!$self->{_query}) {
    $self->{_query} = {};                                       # Somewhere to set our things

    if (local $_ = $self->{query}) {                            # Faster access via a dynamic variable
      tr/\+/ /;                                                 # Seriously, dfarrell?
      local @_ = split /[&=]/;                                  # Tokenize

      while (my $k = uri_decode(shift // '')) {                 # Decode the next self->{_query}eter
        if ($val && $k eq $key) {                               # We'll be setting this shortly, so ignore
          shift;
          next;
        }

        if (exists $self->{_query}{$k}) {                       # Multiple self->{_query}eters exist with the same key
          $self->{_query}{$k} = [$self->{_query}{$k}]           # Reinitialize as array ref to store multiple values
            unless ref $self->{_query}{$k};

          push @{$self->{_query}{$k}}, uri_decode(shift // ''); # Add to the array
        }
        else {                                                  # First or only use of key
          $self->{_query}{$k} = uri_decode(shift // '');
        }
      }
    }
  };

  if ($val) {                                                   # Modifying this value
    $self->{_query}{$key} = $val;                               # Update the pre-parsed hash ref

    $key = uri_encode($key);                                    # Encode the key
    $self->{query} =~ s/\b$key=[^&]+&?//;                       # Remove from the query string

    if (ref $val) {                                             # If $val is an array, each element gets its own place in the query
      foreach (@$val) {
        $self->{query} .= '&' if $self->{query};
        $self->{query} .= $key . '=' . uri_encode($_);
      }
    }
    else {                                                      # Otherwise, just add the encoded pair
      $self->{query} .= '&' if $self->{query};
      $self->{query} .= $key . '=' . uri_encode($val);
    }
  }

  $self->{_query}{$key} if defined $key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Fast - A fast(er) URI parser

=head1 VERSION

version 0.03

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

Accepts a string, minimally parses it (using L<URI::Split>), and returns a
L<URI::Fast> object.

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

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
