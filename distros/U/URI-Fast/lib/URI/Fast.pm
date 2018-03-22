package URI::Fast;
$URI::Fast::VERSION = '0.18';
# ABSTRACT: A fast(er) URI parser

use utf8;
use strict;
use warnings;
no strict 'refs';
use Carp;
use Inline;
use Exporter;
use Inline C => 'DATA', optimize => '-O2';

use parent 'Exporter';
our @EXPORT_OK = qw(uri uri_split);

use overload '""' => sub{ $_[0]->to_string };

sub uri ($) {
  my $self = URI::Fast->new($_[0]);
  $self->set_scheme('file') unless $self->get_scheme;
  $self;
}

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
    return @{ $self->split_path };
  }
  elsif (defined wantarray) {
    return decode($self->get_path);
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
                       : $params;
}


1;

=pod

=encoding UTF-8

=head1 NAME

URI::Fast - A fast(er) URI parser

=head1 VERSION

version 0.18

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

C<URI::Fast> is a faster alternative to L<URI>. It is written in C and provides
basic parsing and modification of a URI.

L<URI> is an excellent module; it is battle-tested, robust, and handles many
edge cases. As a result, it is rather slower than it would otherwise be for
more trivial cases, such as inspecting the path or updating a single query
parameter.

=head1 EXPORTED SUBROUTINES

=head2 uri

Accepts a URI string, minimally parses it, and returns a L<URI::Fast> object.

=head1 ATTRIBUTES

Unless otherwise specified, all attributes serve as full accessors, allowing
the URI segment to be both retrieved and modified.

=head2 scheme

Defaults to C<file> if not present in the URI string.

=head2 auth

The authorization section is composed of the username, password, host name, and
port number:

  hostname.com
  someone@hostname.com
  someone:secret@hostname.com:1234

Setting this field may be done with a string (see the note below about
L</ENCODING>) or a hash reference of individual field names (C<usr>, C<pwd>,
C<host>, and C<sport>). In both cases, the existing values are completely
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

Returns the complete query string. Does not include the leading C<?>. The query
string may be set in several ways.

  $uri->query("foo=bar&baz=bat"); # note: no percent-encoding performed
  $uri->query({foo => 'bar', baz => 'bat'}); # foo=bar&baz=bat
  $uri->query({foo => 'bar', baz => 'bat'}, ';'); # foo=bar;baz=bat

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
  my $value_array_ref = $uri->param('foo');   # foo appears twice
  my @value_list      = $uri->param('foo');   # list context always yields a list

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
caller does not wish to be decoded. An empty string will result in the default
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

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__C__

#ifndef URI

// return uri_t* from blessed pointer ref
#define URI(obj) ((uri_t*) SvIV(SvRV(obj)))

// expands to member reference
#define URI_MEMBER(obj, member) (URI(obj)->member)

// quick sugar for calling uri_encode
#define URI_ENCODE_MEMBER(uri, mem, val, allow, alen) uri_encode(val, min(strlen(val), URI_SIZE(mem)), URI_MEMBER(uri, mem), allow, alen)

// size constats
#define URI_SIZE_scheme 32
#define URI_SIZE_path   1024
#define URI_SIZE_query  2048
#define URI_SIZE_frag   64
#define URI_SIZE_usr    64
#define URI_SIZE_pwd    64
#define URI_SIZE_host   256
#define URI_SIZE_port   8

// enough to fit all pieces + 3 chars for separators (2 colons + @)
#define URI_SIZE_auth (3 + URI_SIZE_usr + URI_SIZE_pwd + URI_SIZE_host + URI_SIZE_port)
#define URI_SIZE(member) (URI_SIZE_##member)

#endif

/*
 * Allocate memory with Newx if it's
 * available - if it's an older perl
 * that doesn't have Newx then we
 * resort to using New.
 */
#ifndef Newx
#define Newx(v,n,t) New(0,v,n,t)
#endif

// av_top_index not available on Perls < 5.18
#ifndef av_top_index
#define av_top_index(av) av_len(av)
#endif

// min of two numbers
#ifndef min
#define min(a, b) (a <= b ? a : b)
#endif

/*
 * Percent encoding
 */
static inline
char is_allowed(char c, const char* allowed, size_t len) {
  size_t i;
  for (i = 0; i < len; ++i) {
    if (c == allowed[i]) {
      return 1;
    }
  }

  return 0;
}

// Taken with respect from URI::Escape::XS. Adapted to accept a configurable
// string of permissible characters.
#define _______ "\0\0\0\0"
static const char uri_encode_tbl[ sizeof(U32) * 0x100 ] = {
/*  0       1       2       3       4       5       6       7       8       9       a       b       c       d       e       f                        */
    "%00\0" "%01\0" "%02\0" "%03\0" "%04\0" "%05\0" "%06\0" "%07\0" "%08\0" "%09\0" "%0A\0" "%0B\0" "%0C\0" "%0D\0" "%0E\0" "%0F\0"  /* 0:   0 ~  15 */
    "%10\0" "%11\0" "%12\0" "%13\0" "%14\0" "%15\0" "%16\0" "%17\0" "%18\0" "%19\0" "%1A\0" "%1B\0" "%1C\0" "%1D\0" "%1E\0" "%1F\0"  /* 1:  16 ~  31 */
    "%20\0" "%21\0" "%22\0" "%23\0" "%24\0" "%25\0" "%26\0" "%27\0" "%28\0" "%29\0" "%2A\0" "%2B\0" "%2C\0" _______ _______ "%2F\0"  /* 2:  32 ~  47 */
    _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ "%3A\0" "%3B\0" "%3C\0" "%3D\0" "%3E\0" "%3F\0"  /* 3:  48 ~  63 */
    "%40\0" _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______  /* 4:  64 ~  79 */
    _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ "%5B\0" "%5C\0" "%5D\0" "%5E\0" _______  /* 5:  80 ~  95 */
    "%60\0" _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______  /* 6:  96 ~ 111 */
    _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ "%7B\0" "%7C\0" "%7D\0" _______ "%7F\0"  /* 7: 112 ~ 127 */
    "%80\0" "%81\0" "%82\0" "%83\0" "%84\0" "%85\0" "%86\0" "%87\0" "%88\0" "%89\0" "%8A\0" "%8B\0" "%8C\0" "%8D\0" "%8E\0" "%8F\0"  /* 8: 128 ~ 143 */
    "%90\0" "%91\0" "%92\0" "%93\0" "%94\0" "%95\0" "%96\0" "%97\0" "%98\0" "%99\0" "%9A\0" "%9B\0" "%9C\0" "%9D\0" "%9E\0" "%9F\0"  /* 9: 144 ~ 159 */
    "%A0\0" "%A1\0" "%A2\0" "%A3\0" "%A4\0" "%A5\0" "%A6\0" "%A7\0" "%A8\0" "%A9\0" "%AA\0" "%AB\0" "%AC\0" "%AD\0" "%AE\0" "%AF\0"  /* A: 160 ~ 175 */
    "%B0\0" "%B1\0" "%B2\0" "%B3\0" "%B4\0" "%B5\0" "%B6\0" "%B7\0" "%B8\0" "%B9\0" "%BA\0" "%BB\0" "%BC\0" "%BD\0" "%BE\0" "%BF\0"  /* B: 176 ~ 191 */
    "%C0\0" "%C1\0" "%C2\0" "%C3\0" "%C4\0" "%C5\0" "%C6\0" "%C7\0" "%C8\0" "%C9\0" "%CA\0" "%CB\0" "%CC\0" "%CD\0" "%CE\0" "%CF\0"  /* C: 192 ~ 207 */
    "%D0\0" "%D1\0" "%D2\0" "%D3\0" "%D4\0" "%D5\0" "%D6\0" "%D7\0" "%D8\0" "%D9\0" "%DA\0" "%DB\0" "%DC\0" "%DD\0" "%DE\0" "%DF\0"  /* D: 208 ~ 223 */
    "%E0\0" "%E1\0" "%E2\0" "%E3\0" "%E4\0" "%E5\0" "%E6\0" "%E7\0" "%E8\0" "%E9\0" "%EA\0" "%EB\0" "%EC\0" "%ED\0" "%EE\0" "%EF\0"  /* E: 224 ~ 239 */
    "%F0\0" "%F1\0" "%F2\0" "%F3\0" "%F4\0" "%F5\0" "%F6\0" "%F7\0" "%F8\0" "%F9\0" "%FA\0" "%FB\0" "%FC\0" "%FD\0" "%FE\0" "%FF"    /* F: 240 ~ 255 */
};
#undef _______

size_t uri_encode(const char* in, size_t len, char* out, const char* allow, size_t allow_len) {
  size_t i = 0;
  size_t j = 0;
  char   octet;
  U32    code;

  while (i < len) {
    octet = in[i++];

    if (is_allowed(octet, allow, allow_len)) {
      out[j++] = octet;
    }
    else {
      code = ((U32*) uri_encode_tbl)[(unsigned char) octet];

      if (code) {
        *((U32*) &out[j]) = code;
        j += 3;
      }
      else {
        out[j++] = octet;
      }
    }
  }

  out[j] = '\0';

  return j;
}

#define __ 0xFF
static const unsigned char hex[0x100] = {
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 00-0F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 10-1F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 20-2F */
   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,__,__,__,__,__,__, /* 30-3F */
  __,10,11,12,13,14,15,__,__,__,__,__,__,__,__,__, /* 40-4F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 50-5F */
  __,10,11,12,13,14,15,__,__,__,__,__,__,__,__,__, /* 60-6F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 70-7F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 80-8F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 90-9F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* A0-AF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* B0-BF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* C0-CF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* D0-DF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* E0-EF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* F0-FF */
};
#undef __

size_t uri_decode(const char *in, size_t len, char *out) {
  size_t i = 0, j = 0;
  unsigned char v1, v2;
  int copy_char;

  if (len == 0) {
    len = strlen((char*) in);
  }

  while (i < len) {
    copy_char = 1;

    if (in[i] == '+') {
      out[j] = ' ';
      ++i;
      ++j;
      copy_char = 0;
    }
    else if (in[i] == '%' && i + 2 < len) {
      v1 = hex[ (unsigned char)in[i+1] ];
      v2 = hex[ (unsigned char)in[i+2] ];

      /* skip invalid hex sequences */
      if ((v1 | v2) != 0xFF) {
        out[j] = (v1 << 4) | v2;
        ++j;
        i += 3;
        copy_char = 0;
      }
    }
    if (copy_char) {
      out[j] = in[i];
      ++i;
      ++j;
    }
  }

  out[j] = '\0';

  return j;
}

// EOT (end of theft)

SV* encode(SV* in, ...) {
  size_t ilen, olen, alen;
  const char *allowed;
  SV* out;

  SvGETMAGIC(in);
  const char *src = SvPV_nomg_const(in, ilen);
  char dest[(ilen * 3) + 1];

  Inline_Stack_Vars;

  if (Inline_Stack_Items > 1) {
    allowed = SvPV_nomg_const(Inline_Stack_Item(1), alen);
  } else {
    allowed = "";
    alen = 0;
  }

  Inline_Stack_Done;

  olen = uri_encode(src, ilen, dest, allowed, alen);
  out  = newSVpv(dest, olen);
  sv_utf8_downgrade(out, FALSE);

  return out;
}

SV* decode(SV* in) {
  size_t ilen, olen;
  const char* src;
  SV* out;

  SvGETMAGIC(in);

  if (SvUTF8(in)) {
    in = sv_mortalcopy(in);

    SvUTF8_on(in);

    if (!sv_utf8_downgrade(in, TRUE)) {
      croak("decode: wide character in octet string");
    }

    src = SvPV_nomg_const(in, ilen);
  }
  else {
    src = SvPV_nomg_const(in, ilen);
  }

  char dest[ilen + 1];

  olen = uri_decode(src, ilen, dest);
  out  = newSVpv(dest, olen);
  SvUTF8_on(out);

  return out;
}

/*
 * Internal API
 */
typedef char uri_scheme_t [URI_SIZE_scheme + 1];
typedef char uri_path_t   [URI_SIZE_path + 1];
typedef char uri_query_t  [URI_SIZE_query + 1];
typedef char uri_frag_t   [URI_SIZE_frag + 1];
typedef char uri_usr_t    [URI_SIZE_usr + 1];
typedef char uri_pwd_t    [URI_SIZE_pwd + 1];
typedef char uri_host_t   [URI_SIZE_host + 1];
typedef char uri_port_t   [URI_SIZE_port + 1];

typedef struct {
  uri_scheme_t scheme;
  uri_path_t   path;
  uri_query_t  query;
  uri_frag_t   frag;
  uri_usr_t    usr;
  uri_pwd_t    pwd;
  uri_host_t   host;
  uri_port_t   port;
} uri_t;

/*
 * Clearers
 */
void clear_scheme(SV* uri_obj) { memset(&((URI(uri_obj))->scheme), '\0', sizeof(uri_scheme_t)); }
void clear_path(SV* uri_obj)   { memset(&((URI(uri_obj))->path),   '\0', sizeof(uri_path_t));   }
void clear_query(SV* uri_obj)  { memset(&((URI(uri_obj))->query),  '\0', sizeof(uri_query_t));  }
void clear_frag(SV* uri_obj)   { memset(&((URI(uri_obj))->frag),   '\0', sizeof(uri_frag_t));   }
void clear_usr(SV* uri_obj)    { memset(&((URI(uri_obj))->usr),    '\0', sizeof(uri_usr_t));    }
void clear_pwd(SV* uri_obj)    { memset(&((URI(uri_obj))->pwd),    '\0', sizeof(uri_pwd_t));    }
void clear_host(SV* uri_obj)   { memset(&((URI(uri_obj))->host),   '\0', sizeof(uri_host_t));   }
void clear_port(SV* uri_obj)   { memset(&((URI(uri_obj))->port),   '\0', sizeof(uri_port_t));   }

void clear_auth(SV* uri_obj) {
  clear_usr(uri_obj);
  clear_pwd(uri_obj);
  clear_host(uri_obj);
  clear_port(uri_obj);
}

/*
 * Scans the authorization portion of the URI string
 */
void uri_scan_auth(uri_t* uri, const char* auth, const size_t len) {
  size_t idx  = 0;
  size_t brk1 = 0;
  size_t brk2 = 0;
  size_t i;

  memset(&uri->usr,  '\0', sizeof(uri_usr_t));
  memset(&uri->pwd,  '\0', sizeof(uri_pwd_t));
  memset(&uri->host, '\0', sizeof(uri_host_t));
  memset(&uri->port, '\0', sizeof(uri_port_t));

  if (len > 0) {
    // Credentials
    brk1 = min(len, strcspn(&auth[idx], "@"));

    if (brk1 > 0 && brk1 != len) {
      brk2 = min(len - idx, strcspn(&auth[idx], ":"));

      if (brk2 > 0 && brk2 < brk1) {
        strncpy(uri->usr, &auth[idx], min(brk2, URI_SIZE_usr));
        idx += brk2 + 1;

        strncpy(uri->pwd, &auth[idx], min(brk1 - brk2 - 1, URI_SIZE_pwd));
        idx += brk1 - brk2;
      }
      else {
        strncpy(uri->usr, &auth[idx], min(brk1, URI_SIZE_usr));
        idx += brk1 + 1;
      }
    }

    // Location
    brk1 = min(len - idx, strcspn(&auth[idx], ":"));

    if (brk1 > 0 && brk1 != (len - idx)) {
      strncpy(uri->host, &auth[idx], min(brk1, URI_SIZE_host));
      idx += brk1 + 1;

      for (i = 0; i < (len - idx) && i < URI_SIZE_port; ++i) {
        if (!isdigit(auth[i + idx])) {
          memset(&uri->port, '\0', URI_SIZE_port + 1);
          break;
        }
        else {
          uri->port[i] = auth[i + idx];
        }
      }
    }
    else {
      strncpy(uri->host, &auth[idx], min(len - idx, URI_SIZE_host));
    }
  }
}

/*
 * Scans a URI string and populates the uri_t struct.
 */
void uri_scan(uri_t* uri, const char* src, size_t len) {
  size_t idx = 0;
  size_t brk = 0;

  // Scheme
  brk = min(len, strcspn(&src[idx], ":/@?#"));
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    strncpy(uri->scheme, &src[idx], min(brk, URI_SIZE_scheme));
    uri->scheme[brk] = '\0';
    idx += brk + 3;

    // Authority
    brk = min(len - idx, strcspn(&src[idx], "/?#"));
    if (brk > 0) {
      uri_scan_auth(uri, &src[idx], brk);
      idx += brk;
    }
  }

  // path
  brk = min(len - idx, strcspn(&src[idx], "?#"));
  if (brk > 0) {
    strncpy(uri->path, &src[idx], min(brk, URI_SIZE_path));
    uri->path[brk] = '\0';
    idx += brk;
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = min(len - idx, strcspn(&src[idx], "#"));
    if (brk > 0) {
      strncpy(uri->query, &src[idx], min(brk, URI_SIZE_query));
      uri->query[brk] = '\0';
      idx += brk;
    }
  }

  // fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      strncpy(uri->frag, &src[idx], min(brk, URI_SIZE_frag));
      uri->frag[brk] = '\0';
    }
  }
}

/*
 * Perl API
 */

/*
 * Getters
 */
const char* get_scheme(SV* uri_obj) { return URI_MEMBER(uri_obj, scheme); }
const char* get_path(SV* uri_obj)   { return URI_MEMBER(uri_obj, path);   }
const char* get_query(SV* uri_obj)  { return URI_MEMBER(uri_obj, query);  }
const char* get_frag(SV* uri_obj)   { return URI_MEMBER(uri_obj, frag);   }
const char* get_usr(SV* uri_obj)    { return URI_MEMBER(uri_obj, usr);    }
const char* get_pwd(SV* uri_obj)    { return URI_MEMBER(uri_obj, pwd);    }
const char* get_host(SV* uri_obj)   { return URI_MEMBER(uri_obj, host);   }
const char* get_port(SV* uri_obj)   { return URI_MEMBER(uri_obj, port);   }

SV* get_auth(SV* uri_obj) {
  uri_t* uri = URI(uri_obj);
  SV* out = newSVpv("", 0);

  if (uri->usr[0] != '\0') {
    if (uri->pwd[0] != '\0') {
      sv_catpvf(out, "%s:%s@", uri->usr, uri->pwd);
    } else {
      sv_catpvf(out, "%s@", uri->usr);
    }
  }

  if (uri->host[0] != '\0') {
    if (uri->port[0] != '\0') {
      sv_catpvf(out, "%s:%s", uri->host, uri->port);
    } else {
      sv_catpv(out, uri->host);
    }
  }

  return out;
}

SV* split_path(SV* uri) {
  size_t brk, idx = 0;
  AV* arr = newAV();
  SV* tmp;

  size_t path_len = strlen(URI_MEMBER(uri, path));
  char str[path_len + 1];
  size_t len = uri_decode(URI_MEMBER(uri, path), path_len, str);

  if (str[0] == '/') {
    ++idx; // skip past leading /
  }

  while (idx < len) {
    brk = strcspn(&str[idx], "/");
    tmp = newSVpvn(&str[idx], brk);
    SvUTF8_on(tmp);
    av_push(arr, tmp);
    idx += brk + 1;
  }

  return newRV_noinc((SV*) arr);
}

SV* get_query_keys(SV* uri) {
  const char* src;
  size_t vlen, idx;
  HV* out = newHV();

  for (src = URI_MEMBER(uri, query); src != NULL && src[0] != '\0'; src = strstr(src, "&")) {
    if (src[0] == '&' || src[0] == ';') {
      ++src;
    }

    idx = strcspn(src, "=");
    char tmp[idx + 1];
    vlen = uri_decode(src, idx, tmp);
    hv_store(out, tmp, vlen, &PL_sv_undef, 0);
  }

  return newRV_noinc((SV*) out);
}

SV* query_hash(SV* uri) {
  const char* src = URI_MEMBER(uri, query);
  size_t idx = 0, brk, klen, vlen, slen = min(URI_SIZE_query, strlen(src));
  SV** ref;
  SV* tmp;
  AV* arr;
  HV* out = newHV();

  while (idx < slen) {
    tmp = NULL;

    // Scan key
    brk = strcspn(&src[idx], "=");

    // Missing key (e.g. query is "?=foo")
    if (brk == 0) {
      // Skip past value since there is no key to store it
      idx += strcspn(&src[idx], "&;") + 1;
      continue;
    }

    // Decode key
    char key[brk + 1];
    klen = uri_decode(&src[idx], brk, key);
    idx += brk + 1;

    // Scan value
    brk = strcspn(&src[idx], "&;");

    // Create SV of value
    if (brk > 0) {
      char val[brk + 1];
      vlen = uri_decode(&src[idx], brk, val);

      // Create new sv to store value
      tmp = newSVpv(val, vlen);
      SvUTF8_on(tmp);
    }

    // Move to next key
    idx += brk + 1;

    if (!hv_exists(out, key, klen)) {
      arr = newAV();
      hv_store(out, key, klen, newRV_noinc((SV*) arr), 0);
    }
    else {
      ref = hv_fetch(out, key, klen, 0);
      if (ref == NULL) {
        croak("query_form: something went wrong");
      }
      arr = (AV*) SvRV(*ref);
    }

    if (tmp != NULL) {
      av_push(arr, tmp);
    }
  }

  return newRV_noinc((SV*) out);
}

SV* get_param(SV* uri, SV* sv_key) {
  const char* src = URI_MEMBER(uri, query);
  size_t idx = 0, brk = 0, klen, elen, vlen, len = min(URI_SIZE_query, strlen(src));
  AV* out = newAV();
  SV* value;

  SvGETMAGIC(sv_key);
  const char* key = SvPV_nomg_const(sv_key, klen);

  char enc_key[(klen * 3) + 2];
  elen = uri_encode(key, klen, enc_key, "", 0);
  enc_key[elen] = '=';
  enc_key[++elen] = '\0';

  while (idx < len) {
    if (strncmp(&src[idx], enc_key, elen) == 0) {
      idx += elen;
      brk = strcspn(&src[idx], "&;");

      char val[brk + 1];
      vlen = uri_decode(&src[idx], brk, val);

      idx += brk + 1;

      value = newSVpv(val, vlen);
      SvUTF8_on(value);
      av_push(out, value);
    }
    else {
      idx += strcspn(&src[idx], "&;") + 1;
    }
  }

  return newRV_noinc((SV*) out);
}

/*
 * Setters
 */
const char* set_scheme(SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, scheme, value, "", 0);
  return URI_MEMBER(uri_obj, scheme);
}

SV* set_auth(SV* uri_obj, const char* value) {
  char auth[URI_SIZE_auth];
  size_t len = uri_encode(value, strlen(value), (char*) &auth, ":@", 2);
  uri_scan_auth(URI(uri_obj), auth, len);
  return newSVpv(auth, len);
}

const char* set_path(SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, path, value, "/", 1);
  return URI_MEMBER(uri_obj, path);
}

const char* set_query(SV* uri_obj, const char* value) {
  strncpy(URI_MEMBER(uri_obj, query), value, min(strlen(value) + 1, URI_SIZE_query));
  return value;
}

const char* set_frag(SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, frag, value, "", 0);
  return URI_MEMBER(uri_obj, frag);
}

const char* set_usr(SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, usr, value, "", 0);
  return URI_MEMBER(uri_obj, usr);
}

const char* set_pwd(SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, pwd, value, "", 0);
  return URI_MEMBER(uri_obj, pwd);
}

const char* set_host(SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, host, value, "", 0);
  return URI_MEMBER(uri_obj, host);
}

const char* set_port(SV* uri_obj, const char* value) {
  size_t len = min(strlen(value), URI_SIZE_port);
  size_t i;

  for (i = 0; i < len; ++i) {
    if (isdigit(value[i])) {
      URI_MEMBER(uri_obj, port)[i] = value[i];
    }
    else {
      clear_port(uri_obj);
      break;
    }
  }

  return URI_MEMBER(uri_obj, port);
}

void set_param(SV* uri, SV* sv_key, SV* sv_values, const char* separator) {
  char   dest[1024];
  const  char *key, *src = URI_MEMBER(uri, query), *strval;
  const  char sep = separator[0];
  size_t klen, vlen, slen, qlen = strlen(src), avlen, i = 0, j = 0, brk = 0;
  AV*    av_values;
  SV**   ref;

  SvGETMAGIC(sv_key);
  key = SvPV_nomg_const(sv_key, klen);
  char enckey[(3 * klen) + 1];
  klen = uri_encode(key, strlen(key), enckey, "", 0);

  SvGETMAGIC(sv_values);
  if (!SvROK(sv_values) || SvTYPE(SvRV(sv_values)) != SVt_PVAV) {
    croak("set_param: expected array of values");
  }

  av_values = (AV*) SvRV(sv_values);
  avlen = av_top_index(av_values);

  // Copy the old query, skipping the key to be updated
  while (i < qlen) {
    // If the string does not begin with the key, advance until it does,
    // copying into dest as idx advances.
    while (strncmp(&src[i], enckey, klen) != 0) {
      // Find the end of this key=value section
      brk = strcspn(&src[i], separator);

      // If this is not the first key=value section written to dest, add an
      // ampersand to separate the pairs.
      if (j > 0) dest[j++] = src[i + brk];

      // Copy up to our break point
      strncpy(&dest[j], &src[i], brk);
      j += brk;
      i += brk;

      if (i >= qlen) break;
      if (strcspn(&src[i], separator) == 0) ++i;
    }

    // The key was found; skip past to the next key=value pair
    i += strcspn(&src[i], separator);

    // Skip the '&', too, since it will already be there
    if (strcspn(&src[i], separator) == 0) ++i;
  }

  // Add the new values to the query
  for (i = 0; i <= avlen; ++i) {
    // Fetch next value from the array
    ref = av_fetch(av_values, (SSize_t) i, 0);
    if (ref == NULL) break;
    if (!SvOK(*ref)) break;

    // Add ampersand if needed to separate pairs
    if (j > 0) dest[j++] = sep;

    // Copy key over
    strncpy(&dest[j], enckey, klen);
    j += klen;

    dest[j++] = '=';

    // Copy value over
    SvGETMAGIC(*ref);
    strval = SvPV_nomg_const(*ref, slen);

    vlen = uri_encode(strval, slen, &dest[j], "", 0);
    j += vlen;
  }

  clear_query(uri);
  strncpy(URI_MEMBER(uri, query), dest, j);
}

/*
 * Other stuff
 */

SV* to_string(SV* uri_obj) {
  uri_t* uri = URI(uri_obj);
  SV*    out = newSVpv("", 0);

  sv_catpv(out, uri->scheme);
  sv_catpv(out, "://");
  sv_catsv(out, sv_2mortal(get_auth(uri_obj)));
  sv_catpv(out, uri->path);

  if (uri->query[0] != '\0') {
    sv_catpv(out, "?");
    sv_catpv(out, uri->query);
  }

  if (uri->frag[0] != '\0') {
    sv_catpv(out, "#");
    sv_catpv(out, uri->frag);
  }

  return out;
}

void explain(SV* uri_obj) {
  printf("scheme: %s\n",  URI_MEMBER(uri_obj, scheme));
  printf("auth:\n");
  printf("  -usr: %s\n",  URI_MEMBER(uri_obj, usr));
  printf("  -pwd: %s\n",  URI_MEMBER(uri_obj, pwd));
  printf("  -host: %s\n", URI_MEMBER(uri_obj, host));
  printf("  -port: %s\n", URI_MEMBER(uri_obj, port));
  printf("path: %s\n",    URI_MEMBER(uri_obj, path));
  printf("query: %s\n",   URI_MEMBER(uri_obj, query));
  printf("frag: %s\n",    URI_MEMBER(uri_obj, frag));
}

SV* new(const char* class, SV* uri_str) {
  const char* src;
  size_t len;
  uri_t* uri;
  SV*    obj;
  SV*    obj_ref;

  Newx(uri, 1, uri_t);
  memset(uri, '\0', sizeof(uri_t));

  obj = newSViv((IV) uri);
  obj_ref = newRV_noinc(obj);
  sv_bless(obj_ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  SvGETMAGIC(uri_str);

  if (!SvOK(uri_str)) {
    src = "";
    len = 0;
  }
  else {
    src = SvPV_nomg_const(uri_str, len);
  }

  uri_scan(uri, src, len);

  return obj_ref;
}

void DESTROY(SV* uri_obj) {
  uri_t* uri = (uri_t*) SvIV(SvRV(uri_obj));
  Safefree(uri);
}

/*
 * Extras
 */
void uri_split(SV* uri) {
  const char* src;
  size_t idx = 0;
  size_t brk = 0;
  size_t len;

  SvGETMAGIC(uri);

  if (!SvOK(uri)) {
    src = "";
    len = 0;
  }
  else {
    src = SvPV_nomg_const(uri, len);
  }

  Inline_Stack_Vars;
  Inline_Stack_Reset;

  // Scheme
  brk = strcspn(&src[idx], ":/@?#");
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
    idx += brk + 3;

    // Authority
    brk = strcspn(&src[idx], "/?#");
    if (brk > 0) {
      Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
      idx += brk;
    } else {
      Inline_Stack_Push(sv_2mortal(newSVpv("",0)));
    }
  }
  else {
    Inline_Stack_Push(&PL_sv_undef);
    Inline_Stack_Push(&PL_sv_undef);
  }

  // path
  brk = strcspn(&src[idx], "?#");
  if (brk > 0) {
    Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
    idx += brk;
  } else {
    Inline_Stack_Push(sv_2mortal(newSVpv("",0)));
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strcspn(&src[idx], "#");
    if (brk > 0) {
      Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
      idx += brk;
    } else {
      Inline_Stack_Push(&PL_sv_undef);
    }
  } else {
    Inline_Stack_Push(&PL_sv_undef);
  }

  // fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
    } else {
      Inline_Stack_Push(&PL_sv_undef);
    }
  } else {
    Inline_Stack_Push(&PL_sv_undef);
  }

  Inline_Stack_Done;
}

//__EOC__
