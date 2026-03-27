package mb::JSON;
######################################################################
#
# mb::JSON - JSON encode/decode for multibyte (UTF-8) strings
#
# https://metacpan.org/dist/mb-JSON
#
# Copyright (c) 2021, 2022, 2026 INABA Hitoshi <ina@cpan.org>
######################################################################
#
# Compatible: Perl 5.005_03 and later
# Platform:   Windows and UNIX/Linux
#
######################################################################

use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION);
$VERSION = '0.04';
$VERSION = $VERSION;

use Carp qw(croak);

######################################################################
# Boolean type objects
######################################################################

package mb::JSON::Boolean;
use vars qw($VERSION);
$VERSION = '0.04';
$VERSION = $VERSION;

use overload
    '0+'     => sub { ${ $_[0] } },
    '""'     => sub { ${ $_[0] } ? 'true' : 'false' },
    'bool'   => sub { ${ $_[0] } },
    fallback => 1;

package mb::JSON;

use vars qw($true $false);
{
    my $_t = 1; $true  = bless \$_t, 'mb::JSON::Boolean';
    my $_f = 0; $false = bless \$_f, 'mb::JSON::Boolean';
}

sub true  { $true  }
sub false { $false }

######################################################################
# UTF-8 multibyte pattern
######################################################################

my $utf8_pat = join '|', (
    '[\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]',
    '[\xC2-\xDF][\x80-\xBF]',
    '[\xE0][\xA0-\xBF][\x80-\xBF]',
    '[\xE1-\xEC][\x80-\xBF][\x80-\xBF]',
    '[\xED][\x80-\x9F][\x80-\xBF]',
    '[\xEE-\xEF][\x80-\xBF][\x80-\xBF]',
    '[\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]',
    '[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]',
    '[\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]',
    '[\x00-\xFF]',
);

######################################################################
# decode -- JSON text -> Perl data
######################################################################

sub decode {
    my $json = defined $_[0] ? $_[0] : $_;
    my $r    = \$json;
    my $val  = _parse_value($r);
    $$r =~ s/\A\s+//s;
    croak "mb::JSON::decode: trailing garbage: " . substr($$r, 0, 20)
        if length $$r;
    return $val;
}

sub parse {    # backward-compatible alias for decode()
    my $json = defined $_[0] ? $_[0] : $_;
    return decode($json);
}

sub _parse_value {
    my ($r) = @_;
    $$r =~ s/\A\s+//s;
    croak "mb::JSON::decode: unexpected end of input" unless length $$r;

    my $c = substr($$r, 0, 1);

    if    ($c eq '{') { return _parse_object($r) }
    elsif ($c eq '[') { return _parse_array($r)  }
    elsif ($c eq '"') { return _parse_string($r) }
    elsif ($$r =~ s/\Anull(?=[^a-zA-Z0-9_]|$)//s)  { return undef   }
    elsif ($$r =~ s/\Atrue(?=[^a-zA-Z0-9_]|$)//s)  { return $true   }
    elsif ($$r =~ s/\Afalse(?=[^a-zA-Z0-9_]|$)//s) { return $false  }
    elsif ($$r =~ s/\A(-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?)//s) {
        return $1 + 0;
    }
    else {
        croak "mb::JSON::decode: unexpected token: " . substr($$r, 0, 20);
    }
}

sub _parse_object {
    my ($r) = @_;
    $$r =~ s/\A\{//s;
    my %obj;
    $$r =~ s/\A\s+//s;
    if ($$r =~ s/\A\}//s) { return { %obj } }
    while (1) {
        $$r =~ s/\A\s+//s;
        croak "mb::JSON::decode: expected string key in object"
            unless $$r =~ /\A"/;
        my $key = _parse_string($r);
        $$r =~ s/\A\s+//s;
        $$r =~ s/\A://s
            or croak "mb::JSON::decode: expected ':' after key '$key'";
        my $val = _parse_value($r);
        $obj{$key} = $val;
        $$r =~ s/\A\s+//s;
        if    ($$r =~ s/\A,//s)  { next }
        elsif ($$r =~ s/\A\}//s) { last }
        else { croak "mb::JSON::decode: expected ',' or '}' in object" }
    }
    return { %obj };
}

sub _parse_array {
    my ($r) = @_;
    $$r =~ s/\A\[//s;
    my @arr;
    $$r =~ s/\A\s+//s;
    if ($$r =~ s/\A\]//s) { return [ @arr ] }
    while (1) {
        push @arr, _parse_value($r);
        $$r =~ s/\A\s+//s;
        if    ($$r =~ s/\A,//s)  { next }
        elsif ($$r =~ s/\A\]//s) { last }
        else { croak "mb::JSON::decode: expected ',' or ']' in array" }
    }
    return [ @arr ];
}

my %UNESC = (
    '"' => '"', '\\' => '\\', '/' => '/',
    'b'  => "\x08", 'f' => "\x0C",
    'n'  => "\n",   'r' => "\r",   't' => "\t",
);

sub _parse_string {
    my ($r) = @_;
    $$r =~ s/\A"//s;
    my $s = '';
    while (1) {
        if    ($$r =~ s/\A"//s)             { last }
        elsif ($$r =~ s/\A\\(["\\\/bfnrt])//s) { $s .= $UNESC{$1} }
        elsif ($$r =~ s/\A\\u([0-9a-fA-F]{4})//s) {
            $s .= _cp_to_utf8(hex($1));
        }
        elsif ($$r =~ s/\A($utf8_pat)//s)  { $s .= $1 }
        else  { croak "mb::JSON::decode: unterminated string" }
    }
    return $s;
}

sub _cp_to_utf8 {
    my ($cp) = @_;
    return chr($cp) if $cp <= 0x7F;
    if ($cp <= 0x7FF) {
        return chr(0xC0|($cp>>6)) . chr(0x80|($cp&0x3F));
    }
    return chr(0xE0|($cp>>12))
         . chr(0x80|(($cp>>6)&0x3F))
         . chr(0x80|($cp&0x3F));
}

######################################################################
# encode -- Perl data -> JSON text
#
# Encoding rules:
#   undef                 -> null
#   mb::JSON::true        -> true
#   mb::JSON::false       -> false
#   number-like scalar    -> number (no quotes)
#   other scalar          -> "string" (UTF-8 kept as-is)
#   ARRAY ref             -> [...]
#   HASH ref              -> {...} (keys sorted alphabetically)
######################################################################

sub encode {
    my ($data) = @_;
    return _enc_value($data);
}

sub _enc_value {
    my ($v) = @_;
    return 'null'  unless defined $v;
    if (ref $v eq 'mb::JSON::Boolean') { return $$v ? 'true' : 'false' }
    if (ref $v eq 'ARRAY')  { return '[' . join(',', map { _enc_value($_) } @$v) . ']' }
    if (ref $v eq 'HASH') {
        my @pairs = map { _enc_string($_) . ':' . _enc_value($v->{$_}) }
                    sort keys %$v;
        return '{' . join(',', @pairs) . '}';
    }
    # number: matches JSON number pattern exactly
    if (!ref $v && $v =~ /\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\z/s) {
        return $v;
    }
    return _enc_string($v);
}

sub _enc_string {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\x08/\\b/g;
    $s =~ s/\x0C/\\f/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/([\x00-\x1F])/sprintf('\\u%04X', ord($1))/ge;
    return '"' . $s . '"';
}

1;

=head1 NAME

mb::JSON - JSON encode/decode for multibyte (UTF-8) strings

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  use mb::JSON;

  # decode: JSON text -> Perl data
  my $data = mb::JSON::decode('{"name":"\u7530\u4e2d","age":30}');
  my $data = mb::JSON::decode('{"name":"Tanaka","age":30}');

  # encode: Perl data -> JSON text
  my $json = mb::JSON::encode({ name => 'Tanaka', age => 30 });
  # -> '{"age":30,"name":"Tanaka"}'

  # Boolean values
  my $json = mb::JSON::encode({
      active => mb::JSON::true,
      locked => mb::JSON::false,
  });
  # -> '{"active":true,"locked":false}'

  # null
  my $json = mb::JSON::encode({ value => undef });
  # -> '{"value":null}'

  # parse() -- backward-compatible alias for decode()
  my $data = mb::JSON::parse('{"key":"value"}');

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</FUNCTIONS>

=item * L</BOOLEAN VALUES>

=item * L</ENCODING RULES>

=item * L</DECODING RULES>

=item * L</LIMITATIONS>

=item * L</DIAGNOSTICS>

=item * L</BUGS AND LIMITATIONS>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

C<mb::JSON> is a simple, dependency-free JSON encoder and decoder
designed for Perl 5.005_03 and later.  It handles UTF-8 multibyte
strings correctly, making it suitable for environments where standard
JSON modules requiring Perl 5.8+ are unavailable.

Version 0.04 adds C<encode()> (Perl data to JSON text) and the Boolean
type objects C<mb::JSON::true> and C<mb::JSON::false>, complementing
the existing C<decode()>/C<parse()>.

=head1 FUNCTIONS

=head2 encode( $data )

Converts a Perl data structure to a JSON text string.
Returns a byte string encoded in UTF-8.

  my $json = mb::JSON::encode($data);

=head2 decode( $json_text )

Converts a JSON text string to a Perl data structure.
If no argument is given, C<$_> is used.

  my $data = mb::JSON::decode($json_text);

=head2 parse( $json_text )

Alias for C<decode()>.  Retained for backward compatibility with 0.03.

  my $data = mb::JSON::parse($json_text);

=head2 true

Returns the singleton C<mb::JSON::Boolean> object representing JSON
C<true>.  Numifies to C<1>, stringifies to C<"true">.

=head2 false

Returns the singleton C<mb::JSON::Boolean> object representing JSON
C<false>.  Numifies to C<0>, stringifies to C<"false">.

=head1 BOOLEAN VALUES

Perl has no native boolean type.  To represent JSON C<true> and
C<false> unambiguously, C<mb::JSON> provides two singleton objects:

  mb::JSON::true   -- stringifies as "true",  numifies as 1
  mb::JSON::false  -- stringifies as "false", numifies as 0

Use these when encoding a boolean value:

  my $json = mb::JSON::encode({ flag => mb::JSON::true });
  # -> '{"flag":true}'

A plain C<1> or C<0> encodes as a JSON number, not a boolean:

  my $json = mb::JSON::encode({ count => 1 });
  # -> '{"count":1}'

When decoding, JSON C<true> and C<false> are returned as
C<mb::JSON::Boolean> objects, which behave as C<1> and C<0>
in numeric and boolean context.

=head1 ENCODING RULES

=over 4

=item undef -> null

=item mb::JSON::true -> true, mb::JSON::false -> false

=item Number

A scalar matching the JSON number pattern is encoded as a bare number.

=item String

Encoded as a double-quoted JSON string.  UTF-8 multibyte bytes are
output as-is (not C<\uXXXX>-escaped).  Control characters U+0000-U+001F
are escaped.

=item ARRAY reference -> JSON array C<[...]>

=item HASH reference -> JSON object C<{...}>

Hash keys are sorted alphabetically for deterministic output.

=back

=head1 DECODING RULES

=over 4

=item null -> undef

=item true -> mb::JSON::Boolean (numifies to 1)

=item false -> mb::JSON::Boolean (numifies to 0)

=item Number -> Perl number

=item String -> Perl string (\uXXXX converted to UTF-8)

=item Object -> hash reference

=item Array -> array reference

=back

=head1 LIMITATIONS

=over 4

=item *

Surrogate pairs (C<\uD800>-C<\uDFFF>) in C<\uXXXX> sequences are not
supported.

=item *

Circular references in C<encode()> are not detected and will cause
infinite recursion.

=item *

References other than ARRAY and HASH (e.g. code references, blessed
objects other than C<mb::JSON::Boolean>) are stringified rather than
raising an error.

=item *

A scalar that matches the JSON number pattern (e.g. C<"1.0">, C<"007">)
is encoded as a number if it looks like one, and as a string otherwise.
Leading-zero strings such as C<"007"> are preserved as strings because
they do not match the JSON number pattern.

=back

=head1 DIAGNOSTICS

=over 4

=item C<mb::JSON::decode: unexpected end of input>

The JSON text ended before a complete value was parsed.

=item C<mb::JSON::decode: unexpected token: E<lt>textE<gt>>

An unrecognised token was encountered while parsing.

=item C<mb::JSON::decode: expected string key in object>

An object key was not a quoted string.

=item C<mb::JSON::decode: expected ':' after key 'E<lt>keyE<gt>'>

The colon separator was missing after an object key.

=item C<mb::JSON::decode: expected ',' or '}' in object>

A JSON object was not properly terminated or separated.

=item C<mb::JSON::decode: expected ',' or ']' in array>

A JSON array was not properly terminated or separated.

=item C<mb::JSON::decode: unterminated string>

A JSON string was not closed with a double-quote.

=item C<mb::JSON::decode: trailing garbage: E<lt>textE<gt>>

Extra text was found after a successfully parsed top-level value.

=back

=head1 BUGS AND LIMITATIONS

Please report bugs to C<ina@cpan.org>.

=head1 SEE ALSO

L<JSON::PP>, L<JSON::XS>

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021, 2022, 2026 INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
See L<perlartistic>.

=cut
