package mb::JSON;
######################################################################
#
# mb::JSON - JSON encode/decode for multibyte (UTF-8) strings
#
# https://metacpan.org/dist/mb-JSON
#
# Copyright (c) 2021, 2022, 2026 INABA Hitoshi <ina.cpan@gmail.com>
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
# The stub above is the distribution-wide boilerplate, and it is skipped
# whenever something else installed a warnings stub first -- every t/*.t
# installs an import-only one before loading this module.  This file also
# uses `no warnings 'recursion'`, which compiles to warnings->unimport on
# a perl without lexical warnings, so unimport is ensured separately and
# under its own guard rather than as part of the block above.
BEGIN { if ($] < 5.006 && !defined(&warnings::unimport)) {
        eval 'package warnings; sub unimport {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION);
$VERSION = '0.07';
$VERSION = $VERSION;

use Carp qw(croak);

######################################################################
# Configuration
######################################################################

use vars qw($MAX_DEPTH $STRICT);

# Maximum nesting depth for decode() and encode().
# A false value disables the check (not recommended for untrusted input).
$MAX_DEPTH = 512;

# When true, decode() rejects raw control characters and malformed UTF-8
# inside strings.  Default is false (bytes are passed through unchanged).
$STRICT = 0;

######################################################################
# Boolean type objects
######################################################################

package mb::JSON::Boolean;
use vars qw($VERSION);
$VERSION = '0.07';
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
# Well-formed UTF-8 byte sequence (used by $STRICT validation only).
# The lax (default) decoder does not validate UTF-8 at all; bytes that
# are not '"' and not '\' are copied through unchanged.
######################################################################

my $UTF8_VALID = join '|', (
    '[\x00-\x7F]',
    '[\xC2-\xDF][\x80-\xBF]',
    '[\xE0][\xA0-\xBF][\x80-\xBF]',
    '[\xE1-\xEC][\x80-\xBF][\x80-\xBF]',
    '[\xED][\x80-\x9F][\x80-\xBF]',
    '[\xEE-\xEF][\x80-\xBF][\x80-\xBF]',
    '[\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]',
    '[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]',
    '[\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]',
);

sub _is_valid_utf8 {
    my ($s) = @_;
    my $len = length $s;
    pos($s) = 0;
    while (pos($s) < $len) {
        return 0 unless $s =~ /\G(?:$UTF8_VALID)/gcs;
    }
    return 1;
}

######################################################################
# decode -- JSON text -> Perl data
# parse  -- alias for decode()
#
# The scanner never modifies the buffer.  It advances pos() with \G
# and the /gc modifiers, so decoding is linear in the input length.
######################################################################

sub decode {
    # Perl warns "Deep recursion on subroutine" once a sub is entered more
    # than 100 times recursively.  That fixed threshold is well below the
    # default $MAX_DEPTH of 512, so input this module decodes correctly
    # could still print the warning, and a caller cannot silence it: it
    # comes from the lexical `use warnings` in this file, not the
    # caller's.  From perl 5.006 the 'recursion' category is switched off
    # lexically in the recursive subs below.  Before lexical warnings
    # existed there is no such category and $^W is the only control, so it
    # is turned off for the extent of the parse on those perls.  On 5.006
    # and later this localizes $^W to the value it already had.
    local $^W = ($] < 5.006) ? 0 : $^W;
    my $json = defined $_[0] ? $_[0] : $_;
    $json = '' unless defined $json;
    $json =~ s/\A\xEF\xBB\xBF//s;
    pos($json) = 0;
    my $val = _parse_value(\$json, 0);
    $json =~ /\G[\x20\x09\x0A\x0D]+/gc;
    croak "mb::JSON::decode: trailing garbage: " . substr($json, pos($json), 20)
        if pos($json) < length($json);
    return $val;
}

sub parse {    # alias for decode()
    # Delegating in one hop rather than copying the argument into a
    # lexical first: decode() already resolves an omitted or undefined
    # argument to $_, and already takes the one copy it needs.  Copying
    # here as well duplicated the whole document for nothing.
    return decode(@_ ? $_[0] : $_);
}

# Whitespace is skipped inline with /\G[\x20\x09\x0A\x0D]+/gc.  The four
# bytes are spelled out rather than written \s on purpose.  RFC 8259
# allows exactly space, tab, LF and CR between tokens, while perl's \s
# also matches form feed on every perl and, from perl 5.18, vertical tab
# as well.  Using \s would therefore both accept input JSON forbids and
# make this module answer differently on perl 5.16 and perl 5.18 for the
# same document, which is the one thing a distribution targeting
# 5.005_03 through the latest perl must not do.
#
# The + quantifier means the pattern either consumes at least one
# character or fails outright, so it never records an empty match and is
# safe to repeat at the same position; /c keeps pos() on failure.

sub _parse_value {
    no warnings 'recursion';
    my ($r, $depth) = @_;
    $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
    croak "mb::JSON::decode: unexpected end of input"
        if pos($$r) >= length($$r);

    my $c = substr($$r, pos($$r), 1);

    if    ($c eq '{') { return _parse_object($r, $depth) }
    elsif ($c eq '[') { return _parse_array($r, $depth)  }
    elsif ($c eq '"') { return _parse_string($r)         }
    elsif ($$r =~ /\Gnull(?![a-zA-Z0-9_])/gcs)  { return undef   }
    elsif ($$r =~ /\Gtrue(?![a-zA-Z0-9_])/gcs)  { return $true   }
    elsif ($$r =~ /\Gfalse(?![a-zA-Z0-9_])/gcs) { return $false  }
    elsif ($$r =~ /\G(-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?)/gcs) {
        my $literal = $1;
        my $n = $literal + 0;
        # A finite JSON number literal can still overflow perl's NV range
        # (e.g. 1e400) and become Inf.  Detect it the same way encode()
        # detects Inf/NaN: by the spelling perl prints for it, since no
        # portable numeric test exists on perl 5.005 (see encode() below).
        croak "mb::JSON::decode: number out of range: $literal"
            if $n =~ /\A-?(?:inf(?:inity)?|nan|1\.#[a-z]+)\z/is;
        # The same literal can underflow to zero at the other end of the
        # range (e.g. 1e-400).  A literal whose mantissa has a nonzero
        # digit yet converts to exactly zero lost every significant digit
        # it had, so it is rejected too rather than quietly returning 0.
        # Only the mantissa is examined: "0e-400" is a legitimate zero,
        # and the digits of its exponent are not significant digits.
        my $mantissa = $literal;
        $mantissa =~ s/[eE].*\z//s;
        croak "mb::JSON::decode: number out of range: $literal"
            if $n == 0 && $mantissa =~ /[1-9]/;
        return $n;
    }
    else {
        croak "mb::JSON::decode: unexpected token: "
            . substr($$r, pos($$r), 20);
    }
}

sub _parse_object {
    no warnings 'recursion';
    my ($r, $depth) = @_;
    croak "mb::JSON::decode: nesting too deep (max $MAX_DEPTH)"
        if $MAX_DEPTH && $depth >= $MAX_DEPTH;
    $$r =~ /\G\{/gcs;
    my %obj;
    $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
    if ($$r =~ /\G\}/gcs) { return { %obj } }
    while (1) {
        $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
        croak "mb::JSON::decode: expected string key in object"
            unless substr($$r, pos($$r), 1) eq '"';
        my $key = _parse_string($r);
        $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
        $$r =~ /\G:/gcs
            or croak "mb::JSON::decode: expected ':' after key '$key'";
        my $val = _parse_value($r, $depth + 1);
        $obj{$key} = $val;
        $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
        if    ($$r =~ /\G,/gcs)  { next }
        elsif ($$r =~ /\G\}/gcs) { last }
        else { croak "mb::JSON::decode: expected ',' or '}' in object" }
    }
    return { %obj };
}

sub _parse_array {
    no warnings 'recursion';
    my ($r, $depth) = @_;
    croak "mb::JSON::decode: nesting too deep (max $MAX_DEPTH)"
        if $MAX_DEPTH && $depth >= $MAX_DEPTH;
    $$r =~ /\G\[/gcs;
    my @arr;
    $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
    if ($$r =~ /\G\]/gcs) { return [ @arr ] }
    while (1) {
        push @arr, _parse_value($r, $depth + 1);
        $$r =~ /\G[\x20\x09\x0A\x0D]+/gc;
        if    ($$r =~ /\G,/gcs)  { next }
        elsif ($$r =~ /\G\]/gcs) { last }
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
    $$r =~ /\G"/gcs;
    my $s = '';
    while (1) {
        if ($$r =~ /\G"/gcs) { last }

        # Fast path: a run of ordinary characters, copied verbatim.
        if ($STRICT) {
            if ($$r =~ /\G([^"\\\x00-\x1F]+)/gcs) { $s .= $1; next }
        }
        else {
            if ($$r =~ /\G([^"\\]+)/gcs) { $s .= $1; next }
        }

        if ($$r =~ /\G\\(["\\\/bfnrt])/gcs) { $s .= $UNESC{$1}; next }

        if ($$r =~ /\G\\u([0-9a-fA-F]{4})/gcs) {
            my $cp = hex($1);
            if ($cp >= 0xD800 && $cp <= 0xDBFF) {
                # high surrogate: a low surrogate \uDC00-\uDFFF must follow
                if ($$r =~ /\G\\u([0-9a-fA-F]{4})/gcs) {
                    my $lo = hex($1);
                    if ($lo >= 0xDC00 && $lo <= 0xDFFF) {
                        $cp = 0x10000
                            + (($cp - 0xD800) << 10)
                            + ($lo - 0xDC00);
                        $s .= _cp_to_utf8($cp);
                    }
                    else {
                        croak "mb::JSON::decode: invalid low surrogate in Unicode escape sequence";
                    }
                }
                else {
                    croak "mb::JSON::decode: lone high surrogate in Unicode escape sequence";
                }
            }
            elsif ($cp >= 0xDC00 && $cp <= 0xDFFF) {
                croak "mb::JSON::decode: lone low surrogate in Unicode escape sequence";
            }
            else {
                $s .= _cp_to_utf8($cp);
            }
            next;
        }

        my $p = pos($$r);
        if ($p >= length($$r)) {
            croak "mb::JSON::decode: unterminated string";
        }
        if (substr($$r, $p, 1) eq "\\") {
            croak "mb::JSON::decode: invalid escape sequence: "
                . substr($$r, $p, 2);
        }
        croak "mb::JSON::decode: raw control character in string";
    }
    if ($STRICT && $s =~ /[\x80-\xFF]/ && !_is_valid_utf8($s)) {
        croak "mb::JSON::decode: malformed UTF-8 in string";
    }
    return $s;
}

sub _cp_to_utf8 {
    my ($cp) = @_;
    return chr($cp) if $cp <= 0x7F;
    if ($cp <= 0x7FF) {
        return chr(0xC0|($cp>>6)) . chr(0x80|($cp&0x3F));
    }
    if ($cp <= 0xFFFF) {
        return chr(0xE0|($cp>>12))
             . chr(0x80|(($cp>>6)&0x3F))
             . chr(0x80|($cp&0x3F));
    }
    # U+10000 .. U+10FFFF : 4-byte sequence.  Codepoint is decomposed into
    # bytes so every chr() argument stays <= 0xFF (safe on perl 5.005_03).
    return chr(0xF0|($cp>>18))
         . chr(0x80|(($cp>>12)&0x3F))
         . chr(0x80|(($cp>>6)&0x3F))
         . chr(0x80|($cp&0x3F));
}

######################################################################
# encode -- Perl data -> JSON text
# stringify -- alias for encode()
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
    # See the comment in decode() for why $^W is localized here.
    local $^W = ($] < 5.006) ? 0 : $^W;
    my $data = @_ ? $_[0] : $_;
    return _enc_value($data, 0, {});
}

sub stringify {    # alias for encode()
    # One hop, for the same reason as parse() above.
    return encode(@_ ? $_[0] : $_);
}

sub _enc_value {
    no warnings 'recursion';
    my ($v, $depth, $seen) = @_;
    return 'null' unless defined $v;

    if (ref $v eq 'mb::JSON::Boolean') { return $$v ? 'true' : 'false' }

    # The depth limit is applied where _parse_object() and _parse_array()
    # apply it: on entering a container, with >=.  Testing every value
    # with > instead let encode() accept one more level of nesting than
    # decode() would read back, and counted a leaf scalar as a level of
    # its own, which the decoder never does.  Both directions now stop at
    # the same $MAX_DEPTH containers.
    if (ref $v eq 'ARRAY') {
        croak "mb::JSON::encode: nesting too deep (max $MAX_DEPTH)"
            if $MAX_DEPTH && $depth >= $MAX_DEPTH;
        my $id = "$v";
        croak "mb::JSON::encode: circular reference detected" if $seen->{$id};
        $seen->{$id} = 1;
        my $out = '['
                . join(',', map { _enc_value($_, $depth + 1, $seen) } @$v)
                . ']';
        delete $seen->{$id};
        return $out;
    }

    if (ref $v eq 'HASH') {
        croak "mb::JSON::encode: nesting too deep (max $MAX_DEPTH)"
            if $MAX_DEPTH && $depth >= $MAX_DEPTH;
        my $id = "$v";
        croak "mb::JSON::encode: circular reference detected" if $seen->{$id};
        $seen->{$id} = 1;
        my @pairs = map {
            _enc_string($_) . ':' . _enc_value($v->{$_}, $depth + 1, $seen)
        } sort keys %$v;
        my $out = '{' . join(',', @pairs) . '}';
        delete $seen->{$id};
        return $out;
    }

    # number: matches JSON number pattern exactly
    if ($v =~ /\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\z/s) {
        return $v;
    }

    # Inf / NaN have no JSON representation and would silently become the
    # strings "Inf" / "NaN".  A finite number always matches the pattern
    # above, so anything reaching here that still spells one of the forms
    # perl prints for a non-finite value is one.  This is a plain string
    # test on purpose: asking the scalar whether it holds a number needs
    # B, whose constants are AUTOLOADed on perl 5.005 and cannot be called
    # as functions there, and a numeric test alone is not portable either
    # because from perl 5.22 the string "Inf" numifies to Inf.  The cost
    # is that a string spelling exactly "Inf" or "NaN" is rejected too;
    # see LIMITATIONS.
    if ($v =~ /\A-?(?:inf(?:inity)?|nan|1\.#[a-z]+)\z/is) {
        croak "mb::JSON::encode: cannot encode Inf or NaN";
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

Version 0.07

=head1 SYNOPSIS

  use mb::JSON;

  # decode: JSON text -> Perl data
  my $decoded = mb::JSON::decode("{\"name\":\"\\u7530\\u4e2d\",\"age\":30}");

  # parse: alias for decode()
  my $parsed = mb::JSON::parse("{\"key\":\"value\"}");

  # encode: Perl data -> JSON text
  my $json = mb::JSON::encode({ name => 'Tanaka', age => 30 });
  # -> '{"age":30,"name":"Tanaka"}'

  # stringify: alias for encode()
  my $text = mb::JSON::stringify({ name => 'Tanaka', age => 30 });
  # -> '{"age":30,"name":"Tanaka"}'

  # Boolean values
  my $flags = mb::JSON::encode({
      active => mb::JSON::true,
      locked => mb::JSON::false,
  });
  # -> '{"active":true,"locked":false}'

  # null
  my $empty = mb::JSON::encode({ value => undef });
  # -> '{"value":null}'

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</FUNCTIONS>

=item * L</CONFIGURATION>

=item * L</BOOLEAN VALUES>

=item * L</ENCODING RULES>

=item * L</DECODING RULES>

=item * L</LIMITATIONS>

=item * L</DIAGNOSTICS>

=item * L</INCOMPATIBLE CHANGES>

=item * L</PERFORMANCE>

=item * L</SEE ALSO>

=item * L</BUGS>

=back

=head1 DESCRIPTION

C<mb::JSON> is a simple, dependency-free JSON encoder and decoder
designed for Perl 5.005_03 and later.  It handles UTF-8 multibyte
strings correctly, making it suitable for environments where standard
JSON modules requiring Perl 5.8+ are unavailable.

C<mb::JSON> provides two pairs of symmetric functions:
C<decode()>/C<parse()> convert JSON text to Perl data, and
C<encode()>/C<stringify()> convert Perl data to JSON text.
Within each pair, both names are aliases and produce identical output.

The decoder scans its input with C<pos()> and the C<\G> anchor and never
modifies the buffer, so decoding time is linear in the length of the
input.  See L</PERFORMANCE>.

=head1 FUNCTIONS

=head2 decode( $json_text )

Converts a JSON text string to a Perl data structure.
If the argument is omitted or undefined, C<$_> is used.
A leading UTF-8 byte order mark is ignored.

  my $data = mb::JSON::decode($json_text);

=head2 parse( $json_text )

Alias for C<decode()>.  Both names are interchangeable.

  my $data = mb::JSON::parse($json_text);

=head2 encode( $data )

Converts a Perl data structure to a JSON text string.
Returns a byte string encoded in UTF-8.
If called with no argument at all, C<$_> is used; note that
C<encode(undef)> still returns C<null>.

  my $json = mb::JSON::encode($data);

=head2 stringify( $data )

Alias for C<encode()>.  Both names are interchangeable.
Mirrors the C<JSON.stringify()> function in JavaScript.

  my $json = mb::JSON::stringify($data);

=head2 true

Returns the singleton C<mb::JSON::Boolean> object representing JSON
C<true>.  Numifies to C<1>, stringifies to C<"true">.

=head2 false

Returns the singleton C<mb::JSON::Boolean> object representing JSON
C<false>.  Numifies to C<0>, stringifies to C<"false">.

=head1 CONFIGURATION

Two package variables tune the behaviour of the module.  Both are
ordinary globals, so C<local> works as expected.

=head2 $mb::JSON::MAX_DEPTH

Maximum nesting depth accepted by C<decode()> and produced by
C<encode()>.  The default is C<512>.  Deeply nested input would
otherwise exhaust the Perl stack, so the limit matters when decoding
untrusted data.  Setting the variable to a false value disables the
check entirely.

The limit counts objects and arrays, not values, and both directions
stop at the same number of them, so any document C<decode()> accepts can
be handed straight back to C<encode()>.

  local $mb::JSON::MAX_DEPTH = 64;
  my $data = mb::JSON::decode($untrusted);

=head2 $mb::JSON::STRICT

When false (the default), C<decode()> copies string bytes through
unchanged: raw control characters are accepted and UTF-8 is not
validated.  This keeps the module usable as a byte-transparent filter.

When true, C<decode()> rejects a raw control character C<U+0000>-C<U+001F>
inside a string, and rejects a string whose bytes are not well-formed
UTF-8.

  local $mb::JSON::STRICT = 1;
  my $data = mb::JSON::decode($untrusted);

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

C<stringify()> behaves identically to C<encode()> for boolean values.

=head1 ENCODING RULES

Applies to both C<encode()> and C<stringify()>.

=over 4

=item undef -> null

=item mb::JSON::true -> true, mb::JSON::false -> false

=item Number

A scalar matching the JSON number pattern is encoded as a bare number.
C<Inf> and C<NaN> have no JSON representation and are rejected with an
error rather than silently emitted as the strings C<"Inf"> and C<"NaN">.

=item String

Encoded as a double-quoted JSON string.  UTF-8 multibyte bytes are
output as-is (not C<\uXXXX>-escaped).  Control characters U+0000-U+001F
are escaped.

=item ARRAY reference -> JSON array C<[...]>

=item HASH reference -> JSON object C<{...}>

Hash keys are sorted alphabetically for deterministic output.

=item Nesting

A structure nested deeper than C<$mb::JSON::MAX_DEPTH> is rejected, and
a reference that contains itself is reported as a circular reference
instead of recursing forever.

=back

=head1 DECODING RULES

Applies to both C<decode()> and C<parse()>.

=over 4

=item null -> undef

=item true -> mb::JSON::Boolean (numifies to 1)

=item false -> mb::JSON::Boolean (numifies to 0)

=item Number -> Perl number

=item String -> Perl string (\uXXXX converted to UTF-8)

A C<\uXXXX> escape in the Basic Multilingual Plane is converted to its
UTF-8 byte sequence.  A UTF-16 surrogate pair
(C<\uD800>-C<\uDBFF> followed by C<\uDC00>-C<\uDFFF>) is combined into
the single code point it represents and emitted as 4-byte UTF-8, so
characters above U+FFFF (e.g. emoji) decode correctly.

=item Object -> hash reference

When the same key appears more than once, the last occurrence wins.

=item Array -> array reference

=item Byte order mark

A leading UTF-8 byte order mark (C<EF BB BF>) is skipped before parsing.

=item Whitespace

Space, tab, line feed and carriage return are allowed between tokens,
which is exactly the set RFC 8259 defines.  Form feed and vertical tab
are not whitespace and are reported as an unexpected token.  The set is
spelled out rather than written as perl's C<\s>, so it is the same on
every supported perl; C<\s> matches form feed everywhere and, from perl
5.18, vertical tab as well.

=item Nesting

Input nested deeper than C<$mb::JSON::MAX_DEPTH> is rejected.  The limit
counts containers, so a scalar inside the deepest allowed object or
array is not a further level.  C<encode()> applies the same rule, and
therefore can always write back out whatever C<decode()> accepted.

=back

=head1 LIMITATIONS

=over 4

=item *

References other than ARRAY and HASH (e.g. code references, blessed
objects other than C<mb::JSON::Boolean>) are stringified rather than
raising an error.  A blessed hash or array reference is stringified
too, because C<ref()> returns the class name rather than C<HASH> or
C<ARRAY>.

=item *

A scalar that matches the JSON number pattern is encoded as a number
even when it was intended as a string, so C<"30"> becomes C<30>.
Leading-zero strings such as C<"007"> are preserved as strings because
they do not match the JSON number pattern.

=item *

Numbers are decoded through Perl's own numeric conversion, so an
integer wider than the platform's floating point mantissa loses
precision, and C<1.0> or C<1e2> is re-encoded as C<1> or C<100>.

=item *

By default the decoder does not validate UTF-8 and accepts raw control
characters inside strings.  Set C<$mb::JSON::STRICT> to enable those
checks.

=item *

C<Inf> and C<NaN> are recognised by how they print, so a string that
spells exactly C<"Inf">, C<"-Inf">, C<"Infinity">, C<"NaN"> or one of the
C<"1.#INF"> forms is rejected as well, even when it was meant as text.
Longer words are unaffected: C<"Info"> and C<"nano"> encode normally.
Perl offers no portable way to tell a numeric C<Inf> from a string
spelling it -- from perl 5.22 even C<"Info"> numifies to C<Inf> -- so the
module prefers a rule that behaves identically on every supported perl.

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

=item C<mb::JSON::decode: invalid escape sequence: E<lt>textE<gt>>

A backslash inside a string was followed by a character that is not a
recognized escape (C<\">, C<\\>, C</>, C<\b>, C<\f>, C<\n>, C<\r>,
C<\t>) or a C<\uXXXX> sequence.

=item C<mb::JSON::decode: trailing garbage: E<lt>textE<gt>>

Extra text was found after a successfully parsed top-level value.

=item C<mb::JSON::decode: lone high surrogate in Unicode escape sequence>

A high surrogate C<\uD800>-C<\uDBFF> was not followed by a C<\uXXXX> escape.

=item C<mb::JSON::decode: invalid low surrogate in Unicode escape sequence>

A high surrogate was followed by a C<\uXXXX> escape that was not a low
surrogate C<\uDC00>-C<\uDFFF>.

=item C<mb::JSON::decode: lone low surrogate in Unicode escape sequence>

A low surrogate C<\uDC00>-C<\uDFFF> appeared without a preceding high surrogate.

=item C<mb::JSON::decode: raw control character in string>

C<$mb::JSON::STRICT> is set and an unescaped character in the range
U+0000-U+001F appeared inside a string.

=item C<mb::JSON::decode: malformed UTF-8 in string>

C<$mb::JSON::STRICT> is set and a decoded string is not a well-formed
UTF-8 byte sequence.

=item C<mb::JSON::decode: number out of range: E<lt>textE<gt>>

A JSON number literal is finite JSON syntax but outside the range of
this perl's floating point type.  Too large and converting it would
silently produce C<Inf>, C<-Inf>, or C<NaN>; too small and it would
silently produce C<0>, having lost every significant digit the literal
carried.  C<decode()> rejects both instead, mirroring C<encode()>'s
refusal to write a non-finite value out (see
C<mb::JSON::encode: cannot encode Inf or NaN> above).  Where that range
ends depends on how perl was built: an ordinary double runs out around
C<1e308>, so C<1e400> and C<1e-400> are rejected there, while a perl
built C<-Duselongdouble> or C<-Dusequadmath> accepts both and rejects
only far more extreme literals.  A literal that is genuinely zero is
unaffected on every build: only the mantissa is examined, so C<0>,
C<0.000> and C<0e-400> all decode to C<0>.

=item C<mb::JSON::decode: nesting too deep (max E<lt>NE<gt>)>

The JSON text nests objects or arrays deeper than
C<$mb::JSON::MAX_DEPTH>.

=item C<mb::JSON::encode: nesting too deep (max E<lt>NE<gt>)>

The Perl data structure nests deeper than C<$mb::JSON::MAX_DEPTH>.

=item C<mb::JSON::encode: circular reference detected>

The Perl data structure contains a reference to one of its own
ancestors, which has no JSON representation.

=item C<mb::JSON::encode: cannot encode Inf or NaN>

A numeric value was C<Inf>, C<-Inf>, or C<NaN>.  JSON has no syntax for
these; encode them as C<null> or as a string yourself if you need them.

=back

=head1 INCOMPATIBLE CHANGES

These changes in 0.07 can alter the behaviour of code written against
0.06.

=over 4

=item *

C<decode()>/C<parse()> reject an unrecognized backslash escape inside a
string with C<mb::JSON::decode: invalid escape sequence>.  Earlier
releases passed the backslash through literally.

=item *

C<encode()> croaks on C<Inf>/C<NaN>, and on a string spelling one of
them exactly, rather than emitting C<"Inf"> or C<"NaN"> as a JSON
string.  See L</LIMITATIONS>.

=item *

C<encode()> croaks on a circular reference instead of recursing until
the process runs out of stack.

=item *

C<decode()> and C<encode()> croak on nesting deeper than
C<$mb::JSON::MAX_DEPTH>, which defaults to 512.  Earlier releases had no
limit.

=item *

C<decode()> skips a leading UTF-8 byte order mark instead of reporting
an unexpected token.

=item *

C<encode()> called with no argument at all encodes C<$_> instead of
returning C<null>.  An explicit C<encode(undef)> still returns C<null>.

=item *

C<decode()>/C<parse()> croak on a number literal outside perl's floating
point range instead of silently converting it.  Too large (C<1e400>)
used to return C<Inf>, which C<encode()> would then refuse to re-encode;
too small (C<1e-400>) used to return C<0>.

=item *

C<decode()>/C<parse()> accept only the four whitespace bytes RFC 8259
allows between tokens.  Earlier releases used perl's C<\s>, which also
accepted form feed on every perl and vertical tab on perl 5.18 and
later -- so a document containing one of those decoded on some perls and
not on others.

=item *

C<encode()>/C<stringify()> apply C<$mb::JSON::MAX_DEPTH> to objects and
arrays only, and stop at the same count C<decode()> does.  Earlier
releases counted leaf scalars as a level of their own and allowed one
container more than C<decode()> would read back.

=back

=head1 PERFORMANCE

Up to 0.06 the decoder consumed its input by repeatedly deleting the
front of the buffer, which copies the remainder of the text on every
token and makes decoding quadratic in the input length.  Since 0.07 the
scanner advances C<pos()> instead, so decoding is linear.  On one
reference machine an 800 KB document took over 12 seconds to decode
with the old scanner and about 0.2 seconds with the new one.  Documents
of a few kilobytes are too small for the difference to matter.

C<parse()> and C<stringify()> hand their argument straight to
C<decode()> and C<encode()>.  Up to 0.06 each copied it into a lexical
first, so calling the alias rather than the primary name duplicated the
whole document for nothing.

C<encode()> is roughly 20% slower than before.  That is the cost of
tracking the current path so that a circular reference can be reported
instead of recursing until the process runs out of stack.

=head1 SEE ALSO

L<JSON::PP>, L<JSON::XS>

=head1 BUGS

Please report bugs to C<ina.cpan@gmail.com>.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021, 2022, 2026 INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
See L<perlartistic>.

=cut
