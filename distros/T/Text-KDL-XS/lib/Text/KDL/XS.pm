package Text::KDL::XS;

use strict;
use warnings;

our $VERSION;

# The XS code is loaded before the class modules below are compiled, so that
# each of them can also be loaded on its own (they all load this module).
BEGIN {
    $VERSION = '0.002';
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
}

use Carp ();
use Exporter 'import';

use Text::KDL::XS::Value;
use Text::KDL::XS::Node;
use Text::KDL::XS::Document;
use Text::KDL::XS::Parser;
use Text::KDL::XS::Emitter;

our @EXPORT_OK = qw(parse_kdl emit_kdl);

# Errors raised anywhere in the distribution are reported at the caller's line.
our @CARP_NOT = qw(
    Text::KDL::XS::Document Text::KDL::XS::Emitter Text::KDL::XS::Node
    Text::KDL::XS::Parser Text::KDL::XS::Value
);

my %VERSION_BY_NAME = (detect => 'detect', 1 => 1, 2 => 2, v1 => 1, v2 => 2);

sub parse_kdl {
    my ($source, @options) = @_;
    my $parser = Text::KDL::XS::Parser->new($source, @options);
    return Text::KDL::XS::Document->_build_from_parser($parser);
}

sub emit_kdl {
    my ($tree, @options) = @_;
    return Text::KDL::XS::Emitter->_emit_tree($tree, @options);
}

# The KDL version selected by a version option: 'detect', 1 or 2. Accepts
# detect, 1, 2, v1 and v2 in any letter case; undef means detect.
sub _normalize_version {
    my ($who, $version) = @_;
    return 'detect' unless defined $version;
    my $normalized = $VERSION_BY_NAME{ lc $version };
    Carp::croak("$who: unknown version '$version' (expected 'detect', '1' or '2')")
        unless defined $normalized;
    return $normalized;
}

# A hash reference of name => value pairs whose names are all allowed. $noun
# ('option' or 'field') names them in the error message.
sub _parse_named_arguments {
    my ($who, $noun, $allowed, @pairs) = @_;
    Carp::croak("$who: expected name => value pairs, got an odd number of arguments") if @pairs % 2;
    my %arguments = @pairs;
    my @unknown = sort grep { !$allowed->{$_} } keys %arguments;
    Carp::croak("$who: unknown $noun" . (@unknown == 1 ? '' : 's') . ' ' . join ', ', map {"'$_'"} @unknown)
        if @unknown;
    return \%arguments;
}

# Raises an error caught around a call into the XS code again. The XS code
# reports errors at the line of $file that called it; such errors are raised
# again at the user's call site. Errors thrown by user code (source callbacks)
# and exception objects pass through unchanged.
sub _rethrow {
    my ($error, $file) = @_;
    die $error if ref $error;
    die $error unless $error =~ s/ at \Q$file\E line \d+(?:, <[^>]*> (?:line|chunk) \d+)?\.\n\z//;
    Carp::croak($error);
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS - KDL Document Language parser and emitter built on libckdl

=head1 SYNOPSIS

=for highlighter language=Perl

  use utf8;                             # this source file is UTF-8
  use Text::KDL::XS qw(parse_kdl emit_kdl);
  binmode STDOUT, ':encoding(UTF-8)';   # parsed strings are Perl characters

  # Parse a character string (or a filehandle, or a code reference returning chunks).
  my $doc = parse_kdl(<<'KDL');
  package "kdl-rs" {
      version "0.4.0"
      author "Kat Marchán" email="kat@example.com"
      keywords "config" "data"
  }
  KDL

  # Walk the tree.
  for my $node (@{ $doc->nodes }) {
      print $node->name, "\n";                              # package
      print $node->args->[0]->as_string, "\n";              # kdl-rs
      for my $child (@{ $node->children }) {
          printf "  %s", $child->name;
          printf " %s", $_->as_string for @{ $child->args };
          printf " %s=%s", $_->[0], $_->[1]->as_string for @{ $child->props };
          print "\n";
      }
  }

  # Look up a property, with type information intact.
  my $email = $doc->nodes->[0]->children->[1]->prop('email');
  print $email->type;        # string
  print $email->as_string;   # kat@example.com

  # Write it back out (tree mode: preserves order, kinds and annotations).
  print emit_kdl($doc);

  # Or serialise plain Perl data (data mode).
  print emit_kdl({ server => { host => 'localhost', port => 8080 } });
  # server {
  #     host localhost
  #     port 8080
  # }

=for highlighter

=head1 DESCRIPTION

C<Text::KDL::XS> reads and writes documents in the
L<KDL Document Language|https://kdl.dev>, a small configuration and data
language that looks like this:

=for highlighter language=KDL

  node "argument" key="value" {
      child 1 2 3
      (type)annotated #true
  }

=for highlighter

It is a thin XS binding to L<ckdl|https://github.com/tjol/ckdl>, a C11
implementation that passes the official KDL test suites. Both KDL
B<2.0.0> (current) and KDL B<1.0.0> (legacy) are supported, and the version
is detected automatically unless you pin it.

The distribution provides:

=over 4

=item * L</parse_kdl>, which turns KDL text into a tree of
L<Text::KDL::XS::Document>, L<Text::KDL::XS::Node> and
L<Text::KDL::XS::Value> objects.

=item * L</emit_kdl>, which turns such a tree, or plain Perl hashes and
arrays, back into KDL text.

=item * L<Text::KDL::XS::Parser>, a streaming (SAX-style) event parser for
documents that should not be held in memory at once.

=back

A tour of every KDL feature with runnable examples is in
L<Text::KDL::XS::Cookbook>. This page is the API reference.

=head1 QUICK REFERENCE

=over 4

=item parse a string, a file, a stream

L</parse_kdl>, L</"Sources">

=item choose KDL v1 or v2, detect the version

L</"parse_kdl options">, L</"KDL VERSIONS">

=item write KDL from Document and Node objects

L</emit_kdl>, L</"Tree mode">

=item write KDL from hashes and arrays

L</"Data mode">, L</"Scalar coercion">

=item control indentation, escaping, quoting

L</"emit_kdl options">

=item read comments and slashdashed elements

L<Text::KDL::XS::Parser>

=item access nodes, arguments, properties, children

L<Text::KDL::XS::Node>

=item strings, numbers, booleans, null, type annotations

L<Text::KDL::XS::Value>

=item big integers, 1e400, #inf, #nan, number kinds

L<Text::KDL::XS::Value/"VALUE MODEL">,
L<Text::KDL::XS::Value/"ARBITRARY PRECISION NUMBERS">

=item UTF-8 and character strings

L</ENCODING>

=item filehandles, STDIN, pipes, in-memory handles

L</"FILEHANDLE SOURCES">

=item untrusted input, nesting limits

L</"parse_kdl options">, L<Text::KDL::XS::Cookbook/"Parse untrusted input">

=item what dies and when

L</ERRORS>

=item threads and fork

L</THREADS>

=item known problems and workarounds

L</"KNOWN ISSUES AND LIMITATIONS">

=item feature-by-feature examples and recipes

L<Text::KDL::XS::Cookbook>

=back

=head1 EXPORTS

Nothing is exported by default. Request the functions you need:

=for highlighter language=Perl

  use Text::KDL::XS qw(parse_kdl emit_kdl);

=for highlighter

Loading C<Text::KDL::XS> also loads L<Text::KDL::XS::Parser>,
L<Text::KDL::XS::Document>, L<Text::KDL::XS::Node>,
L<Text::KDL::XS::Value> and L<Text::KDL::XS::Emitter>. Each of these
modules can also be loaded on its own; it loads C<Text::KDL::XS> itself.

=head1 FUNCTIONS

=head2 parse_kdl

=for highlighter language=Perl

  my $doc = parse_kdl($source);
  my $doc = parse_kdl($source, version => '2');
  my $doc = parse_kdl($source, %options);

=for highlighter

Parses a complete KDL document and returns a L<Text::KDL::XS::Document>.
Dies on malformed input (see L</ERRORS>).

=head3 Sources

C<$source> is one of:

=over 4

=item A string

The document text as a Perl B<character> string: a string literal in a
source file with C<use utf8>, text read through an C<:encoding(UTF-8)>
layer, the result of C<Encode::decode>, or the output of L</emit_kdl>.
This is the fastest source; the string is copied once and ckdl reads from
the copy.

A string of UTF-8 B<bytes> (read through a C<:raw> handle, or a literal
without C<use utf8>) must be decoded first, with C<utf8::decode> or
C<Encode::decode('UTF-8', ...)>, or passed as a filehandle instead;
otherwise every byte is taken as one character. See L</ENCODING>.

=item A filehandle or IO object

A glob (C<*STDIN>), a glob reference (C<\*STDIN>, C<$fh> from C<open>),
an IO object (C<*STDIN{IO}>, L<IO::Handle>, L<IO::File>, L<IO::Socket>),
a tied handle, or any other object with a C<read> or C<sysread> method.
Open handles are read with Perl's C<read>, so every PerlIO layer, data
buffered by earlier reads and in-memory handles work. See
L</"FILEHANDLE SOURCES">.

=item A code reference

Called as C<< $code->($wanted_bytes) >> whenever the parser needs more
input. It returns the next chunk of the document, or an empty string or
C<undef> at the end of the input; after that it is not called again.

Chunks are UTF-8 B<bytes>. A character string (a string with Perl's UTF-8
flag on) is used in its UTF-8 encoding, so returning characters works as
well. C<$wanted_bytes> is only a hint: a longer chunk is kept and handed
to ckdl in pieces, and chunk boundaries need not align with lines, tokens
or even characters.

The first call happens while the parser is created, before C<parse_kdl>
or L<Text::KDL::XS::Parser/new> returns: ckdl reads ahead to look for a
byte order mark. An exception thrown by the code reference propagates
unchanged (an exception object stays the same object) out of the call
that needed the input; a reference returned as a chunk dies.

=back

=head3 parse_kdl options

=over 4

=item version => 'detect' | '1' | '2'

Which KDL syntax to accept. The default C<'detect'> accepts both and
settles on one at the first version-specific construct (C<#true> versus
C<true>, C<#"raw"#> versus C<r"raw">, a bare identifier used as a value).
C<'1'> and C<'2'> accept exactly one version and reject the other's syntax.
C<'v1'> and C<'v2'> are accepted as well, in any letter case. Any other
value dies with C<Text::KDL::XS::Parser: unknown version '...' (expected
'detect', '1' or '2')>.

See L</"KDL VERSIONS"> for how the versions differ.

=item max_depth => $levels

The deepest nesting of nodes allowed; a top-level node is at depth 1.
Default 512; C<0> means unlimited. A document nested deeper dies with
C<KDL parse error: nesting depth exceeds max_depth (512)> as soon as the
parser reaches the extra level, before the tree gets any deeper. This
bounds the recursion of L</emit_kdl>, L<Text::KDL::XS::Node/as_data> and
your own tree walks for documents from untrusted sources.

=item emit_comments => 0 | 1

Accepted for symmetry with L<Text::KDL::XS::Parser>, where it makes the
parser report comments and slashdashed elements. It does not change the
result of C<parse_kdl>: comments and elements commented out with C</->
never become part of the tree.

=back

Unknown options, an odd number of option arguments and invalid values
die. An option whose value is C<undef> is treated as not given.

=head3 Return value

A L<Text::KDL::XS::Document>. Its C<nodes> method returns the top-level
nodes as L<Text::KDL::XS::Node> objects; every argument and property value
is a L<Text::KDL::XS::Value>. Node names, property keys, string values and
type annotations are returned as Perl character strings. An empty or
comment-only document gives a document with no nodes.

=head2 emit_kdl

=for highlighter language=Perl

  my $text = emit_kdl($document);
  my $text = emit_kdl($node);
  my $text = emit_kdl(\@nodes);
  my $text = emit_kdl(\%data);
  my $text = emit_kdl(\@data);
  my $text = emit_kdl($anything, %options);

=for highlighter

Serialises a tree or a plain data structure to KDL and returns the text as
a Perl character string (encode it as UTF-8 before writing it to a file;
see L</ENCODING>). The output ends with a newline; an empty document is a
single newline. Everything is validated before it is written, so
C<emit_kdl> either returns a document that parses back to the same data or
dies.

The mode is chosen from the type of the first argument.

=head3 Tree mode

Selected when the argument is a L<Text::KDL::XS::Document>, a
L<Text::KDL::XS::Node>, or a non-empty array reference whose elements are
all L<Text::KDL::XS::Node> objects; subclasses of these classes are
accepted everywhere. An array that mixes nodes with anything else is data
mode, where the nodes make it die.

Tree mode is faithful: it writes arguments and properties in their stored
order, keeps type annotations on nodes and values, keeps the
integer/float/string distinction of numbers (C<1.0> stays C<1.0>), and
writes repeated properties as often as they occur. It is the mode to use
for round-tripping a parsed document. What it does not preserve (comments,
layout, number spelling) is listed in
L<Text::KDL::XS::Cookbook/"What a round trip loses">.

Argument and property values inside the tree are normally
L<Text::KDL::XS::Value> objects, but plain scalars and objects are
accepted too and are converted as described under L</"Scalar coercion">.
A node that is its own descendant dies with C<emit_kdl: cyclic data
structure>; a node that appears in several places is written in each.

=head3 Data mode

Selected for any other unblessed hash or array reference. Data mode is a
convenience for writing configuration from ordinary Perl data; it is
deterministic but lossy. Every hash key becomes a node; data mode never
writes properties.

  Perl value                       Emitted as
  -------------------------------  ----------------------------------------------
  { key => $scalar }               key <value>
  { key => undef }                 key #null
  { key => [ $s1, $s2, ... ] }     key <s1> <s2> ...      (all elements scalars)
  { key => [] }                    key                    (bare node)
  { key => {} }                    key                    (bare node)
  { key => { ... } }               key { <children> }
  { key => [ {...}, {...} ] }      key { ... }  key { ... }   (one sibling per element)
  { key => [ $s, {...} ] }         key <s>  key { ... }   (mixed: one sibling per element)
  { key => [ [1,2], [3] ] }        key 1 2  key 3         (inner arrays: one sibling each)
  [ $a, $b, ... ]   (top level)    - <a>  - <b>  ...      (nodes named "-")
  {} or []          (top level)    (a single newline)
  boolean object                   #true / #false
  Text::KDL::XS::Value object      as the object says (type, kind, annotation)

Hash keys are emitted in sorted order. Single values are classified by
L</"Scalar coercion">. A hash or array that contains itself dies with
C<emit_kdl: cyclic data structure>; one that is referenced from several
places is written in each.

What data mode cannot express: properties; arguments and children on the
same node; a specific node order (keys are sorted); type annotations on
nodes; and the difference between C<< { key => 'a' } >> and
C<< { key => ['a'] } >> (both give C<key a>). Build a
L<Text::KDL::XS::Node> tree when you need any of these.

=head3 Scalar coercion

Single values that are not L<Text::KDL::XS::Value> objects, in either
mode, are mapped like this:

  Perl value                                      KDL value
  ----------------------------------------------  ----------------------------
  undef                                           #null
  JSON::PP::Boolean, Types::Serialiser::Boolean,
    JSON::Boolean, boolean, Mojo::JSON::_Bool
    (or a subclass)                               #true / #false (by truthiness)
  Text::KDL::XS::Value (or a subclass)            as specified by the object
  a number: a scalar with an integer or floating
    point value and no string value, or one whose
    string value is exactly Perl's rendering of
    that number                                   number (integer or float)
  any other plain scalar                          string
  Math::BigInt, Math::BigFloat                    number, written with its exact digits
  another object with string overloading          string ("$object")
  any other object or reference                   dies

A number with an integer value is written as an integer over the whole
native range (-2**63 to 2**64-1, unsigned values included); any other
number as a float, with the shortest text that reads back as the same
double (C<0.30000000000000004>, C<1e+21>, C<-0.0>, C<123456789.0>; a float
always has a decimal point or an exponent). A scalar that has both an
integer and a floating point value, such as C<3.0> after it has been
compared with C<==>, is written as an integer.

The decision uses the scalar's value, not how it looks. C<'42'> from a
string literal is a string and C<42> is a number. A string that has been
used as a number is a number only when its text is exactly the number
Perl would print: C<'42'> after C<$x + 0> becomes the number C<42>, but
C<'007'>, C<'1.50'>, C<'1e3'>, C<' 42 '> and dualvars stay strings, so no
text is ever changed. Perl's false value C<!!0> is the empty string, as
in L<JSON::PP>. Force one or the other with C<"$x"> or C<0 + $x>. The
strings C<'true'> and C<'false'> are never promoted to booleans.

L<Math::BigInt> and L<Math::BigFloat> objects become numbers with their
exact digits (NaN and infinity die with C<emit_kdl: cannot write the
Math::BigInt NaN as a KDL number>). Any other object with a string
conversion (L<URI>, L<Path::Tiny>, ...) is written as a string. Objects
without one, and references other than the hashes and arrays of data mode
(code, scalar and glob references), die with C<emit_kdl: cannot serialize
Foo object> or C<emit_kdl: cannot serialize CODE ref>.

=head3 emit_kdl options

=over 4

=item version => 'detect' | '1' | '2'

Output syntax. C<'2'> (and C<'detect'>, the default) writes KDL 2.0.0:
C<#true>, C<#null>, bare identifier strings where possible. C<'1'> writes
KDL 1.0.0: C<true>, C<null>, every string value quoted. C<'v1'> and
C<'v2'> are accepted as well, in any letter case. KDL v1 has no spelling
for infinity and NaN, so a non-finite float dies in v1 output with
C<emit_kdl: KDL v1 has no representation for inf/nan>; v2 writes C<#inf>,
C<#-inf> and C<#nan>.

=item indent => $columns

Number of spaces per nesting level, an integer from 0 to 64. Default 4.

=item escape_mode => $bitmask

Which characters inside quoted strings are written as escape sequences.
Values are combinations of the ckdl C<kdl_escape_mode> flags:

  0       minimal: " and \, plus (in v2 output) the characters KDL never
          allows literally: U+0000 to U+0008, U+000E to U+001F, U+007F,
          the bidi controls and U+FEFF, which are always written as \u{...}
  0x10    also escape backspace (\b) and vertical tab
  0x20    also escape newline characters: LF, CR, FF, NEL, LS, PS
  0x40    also escape tabs
  0x70    default (control characters, newlines and tabs)
  0x170   ASCII only: every non-ASCII character becomes \u{...}

C<0x10>, C<0x20> and C<0x40> combine with bitwise or; C<0x170> is a preset
(C<0x100> has an effect only together with all of C<0x70>). Any other bit
dies. KDL v2 does not allow a newline inside a quoted string, so for v2
output (C<'2'> and C<'detect'>) C<0x20> is always added. In v1 output
C<0> really is minimal and writes newlines and control characters
literally.

=item identifier_mode => 0 | 1 | 2

How node names, property keys, type annotations and (in v2) string values
are written:

  0    bare whenever the characters allow it
  1    always quoted
  2    bare only when pure ASCII

Without this option, C<emit_kdl> writes identifiers bare where possible
(mode 0) and switches the whole document to mode 1 when a name, key,
annotation or v2 string value would otherwise be read back as something
else: a keyword (C<true>, C<false>, C<null>; in v2 also C<inf>, C<-inf>,
C<nan>) or a number (C<-1>, C<+1>, C<.5>). So the output always parses
back to the same data. When you pass C<identifier_mode>, it is used as
given: with mode 0 or 2 such strings are written bare and do not
round-trip.

=back

Unknown options, an odd number of option arguments and invalid values
die. An option whose value is C<undef> is treated as not given.

=head1 ENCODING

KDL documents are UTF-8 by definition. The rules for this module are:

=over 4

=item * A string passed to L</parse_kdl> or L<Text::KDL::XS::Parser/new>
is a Perl B<character> string.

=item * Filehandles and code references deliver the document as UTF-8
B<bytes>. A handle with an C<:encoding(UTF-8)> or C<:utf8> layer and a
code reference returning character strings work too: characters are
encoded to UTF-8 before they reach the parser.

=item * Everything the parser returns (names, keys, strings, annotations,
comment text) is a Perl B<character> string.

=item * L</emit_kdl> takes Perl character strings and returns a character
string. Encode it when writing it out, either explicitly
(C<encode('UTF-8', $text)>) or through an C<:encoding(UTF-8)> output
layer. Printing it to a handle without a layer writes a string whose
non-ASCII characters are all below U+0100 as Latin-1 bytes (wrong for a
UTF-8 consumer), and a string containing a character above U+00FF as
UTF-8 with a "Wide character" warning.

=back

So C<parse_kdl(emit_kdl($data))> always works, and so does parsing text
read through an C<:encoding(UTF-8)> layer. A string of UTF-8 bytes, such
as a heredoc in a source file without C<use utf8> or data slurped through
a C<:raw> handle, must be decoded first:

=for highlighter language=Perl

  my $doc = parse_kdl(Encode::decode('UTF-8', $bytes));
  utf8::decode($bytes) or die "not UTF-8";   # in place, no module needed
  my $doc = parse_kdl($bytes);

=for highlighter

Text::KDL::XS 0.001 read string sources as UTF-8 bytes; code that relied
on that has to decode as shown above (or pass the filehandle).

Only Unicode text is accepted, in both directions. Input that is not
well-formed UTF-8, or that encodes a surrogate (U+D800 to U+DFFF) or a
code point above U+10FFFF, dies with C<KDL parse error: input is not
valid UTF-8>; a C<\u{...}> escape that produces such a code point dies
with C<KDL parse error: string contains a surrogate or a code point above
U+10FFFF>. C<emit_kdl> dies when a name, key, annotation or string value
contains one (C<emit_kdl: string value contains a surrogate or a code
point above U+10FFFF>) instead of writing something else.

=head1 FILEHANDLE SOURCES

An open filehandle is read with Perl's C<read>, in chunks of the size the
underlying library asks for (a few kilobytes). Consequences:

=over 4

=item * Any PerlIO layer works. A C<:raw> handle delivers UTF-8 bytes, an
C<:encoding(UTF-8)> or C<:utf8> handle delivers characters, which are
encoded again; C<:crlf> is harmless because KDL accepts CRLF line ends.

=item * Reading continues where the handle stands: lines read with
C<< <$fh> >> before are not seen by the parser, and nothing that PerlIO
has buffered is lost.

=item * In-memory handles (C<< open my $fh, '<', \$string >>), tied
handles and bare globs such as C<*STDIN> work.

=item * C<read> waits until it has the requested number of bytes or the
input ends. On a pipe or socket the first events can therefore arrive
later than the data they describe. When latency matters, pass a code
reference that uses C<sysread> (see
L<Text::KDL::XS::Cookbook/"Read from STDIN, a socket or a pipe">).

=item * A read error dies with C<Text::KDL::XS::Parser: read failed: ...>
(the text of C<$!>); a closed filehandle dies with
C<Text::KDL::XS::Parser: filehandle is not open>.

=back

An object that is not a filehandle but has a C<read> method (or, failing
that, C<sysread>) is read through it. The method is called like Perl's
C<read>, as C<< $object->read($buffer, $length) >>, and must return the
number of bytes or characters read, C<0> at the end of the input, or
C<undef> on error.

=head1 KDL VERSIONS

KDL 1.0.0 (2021) and KDL 2.0.0 (2024) share most of their syntax, and any
document that parses under both versions has the same meaning under both.
The differences that matter most when reading or writing with this module
are the C<#> prefix on C<#true>, C<#false> and C<#null>; bare identifier
strings as values (v2 only); raw strings C<#"..."#> (v2) versus
C<r"..."> (v1); multi-line strings C<"""> (v2) versus literal newlines
inside quotes (v1); and the keyword numbers C<#inf>, C<#-inf> and C<#nan>
(v2 only). The complete table is in
L<Text::KDL::XS::Cookbook/"Differences between KDL v1 and v2">.

With the default C<< version => 'detect' >>, the parser accepts either
until the first construct that only exists in one version, and then
requires that version for the rest of the document. To reject the other
version outright, pin C<version>. The parser does not report which version
it detected; L<Text::KDL::XS::Cookbook/"Version detection"> shows how to
find out.

C<emit_kdl> defaults to v2 output. Pass C<< version => '1' >> to write
legacy documents; the parsed data is identical either way, so converting a
document between versions is a parse followed by an emit
(L<Text::KDL::XS::Cookbook/"Converting between versions">). A document
containing C<#inf>, C<#-inf> or C<#nan> cannot be converted to v1.

=head1 ERRORS

All errors are exceptions (C<die>). Messages end with the location of the
call in your code (C<at script.pl line 12.>), not a line inside this
distribution. The exception is an exception thrown by a source code
reference, which is passed through exactly as thrown.

=head2 Parsing

=over 4

=item C<KDL parse error: REASON>

The input is not valid KDL for the selected version. C<REASON> is the
explanation of the underlying library, for example C<Unexpected end of
data (unclosed lists of children)>, C<Dangling slashdash (/-)>,
C<Whitespace required before argument or property> or C<Bare identifier
not allowed here>. There is no line or column: the library does not track
positions. Raised by C<parse_kdl> and by
L<Text::KDL::XS::Parser/next_event>. After an error the parser is
finished: every further C<next_event> dies with the same error.

=item C<KDL parse error: input is not valid UTF-8>

=item C<KDL parse error: string contains a surrogate or a code point above U+10FFFF>

See L</ENCODING>. The second message names the field: C<node name>,
C<property key>, C<type annotation>, C<string> or C<comment>.

=item C<KDL parse error: nesting depth exceeds max_depth (512)>

The document is nested deeper than the C<max_depth> option allows.

=item C<Text::KDL::XS::Parser: source is required>

C<parse_kdl(undef)>.

=item C<Text::KDL::XS::Parser: unsupported source ref type 'X'>

The source was a reference that is neither a code reference nor a
filehandle nor an object with a C<read> or C<sysread> method (for example
an array or hash reference).

=item C<Text::KDL::XS::Parser: filehandle is not open>

=item C<Text::KDL::XS::Parser: read failed: ...>

See L</"FILEHANDLE SOURCES">.

=item C<Text::KDL::XS::Parser: the source callback must return a string or undef, not a reference>

A code reference source returned a reference.

=item C<Text::KDL::XS::Parser: next_event called from inside the parser's own source callback>

A source code reference called C<next_event> on the parser it feeds.

=item C<Text::KDL::XS::Parser: unknown version 'X' (expected 'detect', '1' or '2')>

=item C<Text::KDL::XS::Parser: unknown option 'X'>

=item C<Text::KDL::XS::Parser: expected name =E<gt> value pairs, got an odd number of arguments>

=item C<Text::KDL::XS::Parser: max_depth must be a non-negative integer, got 'X'>

Bad options to C<parse_kdl> or L<Text::KDL::XS::Parser/new>.

=back

=head2 Emitting

=over 4

=item C<emit_kdl: expected Document, Node, ARRAY ref, or HASH ref>

C<emit_kdl> was given a plain scalar, a code reference or an object that
is not a document or node.

=item C<emit_kdl: cannot serialize X object>, C<emit_kdl: cannot serialize X ref>

A value that L</"Scalar coercion"> does not accept: an object without a
string conversion, or a reference other than the hashes and arrays of
data mode.

=item C<emit_kdl: cyclic data structure>

A hash, array or node contains itself.

=item C<emit_kdl: tree mode expects Text::KDL::XS::Node, got X>

An element of C<< $node->children >> or C<< $doc->nodes >> is not a node.

=item C<emit_kdl: a property must be a [ key =E<gt> value ] pair>

An element of C<< $node->props >> is not an array reference.

=item C<emit_kdl: node name must be defined>, C<emit_kdl: property key must be defined>

A hand-built node without a name, or a property with an undefined key.

=item C<emit_kdl: node name contains a surrogate or a code point above U+10FFFF>

See L</ENCODING>; the message names the field.

=item C<emit_kdl: KDL v1 has no representation for inf/nan>

A non-finite float in C<< version => '1' >> output.

=item C<emit_kdl: cannot write the Math::BigInt NaN as a KDL number>

A L<Math::BigInt> or L<Math::BigFloat> that is NaN or infinite.

=item C<emit_kdl: unknown version 'X' (expected 'detect', '1' or '2')>

=item C<emit_kdl: indent must be an integer from 0 to 64, got 'X'>

=item C<emit_kdl: escape_mode must be a combination of 0x10, 0x20, 0x40 and 0x170, got 'X'>

=item C<emit_kdl: identifier_mode must be an integer from 0 to 2, got 'X'>

=item C<emit_kdl: unknown option 'X'>

Bad options to C<emit_kdl>.

=item C<emit_kdl: 'X' is not a KDL number>, C<emit_kdl: unknown number kind 'X' ...>, C<emit_kdl: unknown value type 'X' ...>

A L<Text::KDL::XS::Value> whose hash was changed by hand to something
that L<Text::KDL::XS::Value/new> would have refused. The emitter checks
every value again, so that nothing but valid KDL is ever written.

=back

=head2 Constructors

L<Text::KDL::XS::Value/new>, L<Text::KDL::XS::Node/new> and
L<Text::KDL::XS::Document/new> die with messages starting with their class
name, for example C<Text::KDL::XS::Value-E<gt>new: unknown type 'Number'
(expected null, bool, number or string)>; see the class documentation.
Calling a method of L<Text::KDL::XS::Parser> on something that is not a
parser object made by its constructor dies with C<not a valid
Text::KDL::XS::Parser object>.

=head2 Warnings

L<Text::KDL::XS::Value/as_number> on a string value that is not numeric
warns C<Argument "..." isn't numeric>, like any numeric use of such a
string.

=head1 KNOWN ISSUES AND LIMITATIONS

The remaining limitations come from the underlying ckdl library or from
KDL itself.

=over 4

=item Parse errors carry no position

ckdl does not track lines or columns, so errors have a reason but no
location in the document.

=item Keyword-like strings switch the whole document to quoted identifiers

ckdl would write a string such as C<true> or C<-1> without quotes, which
reads back as a keyword or a number. C<emit_kdl> detects this and writes
the document with every identifier quoted (see
L</"emit_kdl options">), which is correct but more verbose than needed.

=item A children block needs whitespace before it

KDL 2.0.0 requires it, so C<node{}> is correctly rejected in v2, but ckdl
rejects it in v1 mode as well although KDL 1.0.0 allows it. Write
C<node {}>.

=item Detect mode is not a complete KDL v1 parser

ckdl documents the hybrid mode as exact for v2 and for I<almost> all v1
documents. Pin C<< version => '1' >> for strict v1.

=item Detect mode accepts C<.5> as an identifier

C<.5>, C<-.5> and C<+.5> are rejected by both C<< version => '1' >> and
C<< version => '2' >> but accepted as strings by the default detection.

=item Unicode escapes are parsed leniently

C<\u{}> with no digits is accepted and yields U+0000, and more than six
hex digits are accepted and wrap around (C<\u{1000000041}> is C<A>).
Escapes that produce a surrogate or a code point above U+10FFFF are
rejected (see L</ENCODING>).

=item Parsing leaks a few bytes per property

When ckdl reports a property it replaces an internal string (the node
name or the previous key) without freeing it, so every property of a
parsed document leaks one small allocation (about 32 bytes). Documents
without properties are not affected. This only matters for long-running
processes that parse many documents (about 30 MB per million
properties); the fix belongs in ckdl.

=item Vertical tab is whitespace, not a newline

KDL 2.0.0 lists U+000B as a newline; ckdl treats it as whitespace.

=item Special numbers cannot be written as KDL v1

KDL 1.0.0 has no spelling for infinity and NaN; C<emit_kdl> dies instead
of writing invalid v1.

=item Number spelling is not preserved

Numbers are written in a canonical form: C<0xFF> comes back as C<255>,
C<1_000> as C<1000>, C<1e3> as C<1000.0>. Only numbers kept as text (kind
C<string>, see L<Text::KDL::XS::Value/"VALUE MODEL">) keep their digits.
ckdl's own float parser is up to one unit in the last place off; the
values this module returns are rounded correctly.

=item Duplicate properties are all written

C<node a=1 a=2> is written back as C<node a=1 a=2>, the way it was read;
other implementations write C<node a=2>. Both parse to the same data.

=back

=head1 THREADS

Parser and emitter objects hold C state and are never copied into a new
thread: in a thread created while such an object exists, the copy is an
unblessed, unusable reference. Create parsers inside the thread that uses
them; C<parse_kdl> and C<emit_kdl> can be called from any thread.
Document, node and value objects are plain Perl data and are cloned like
any other. After C<fork>, each process has its own copy of everything and
may use it.

=head1 PERFORMANCE NOTES

Parsing from a string is the fastest path: the document is handed to ckdl
as a single buffer and each event is converted to Perl objects once.
Filehandle and code reference sources cost one Perl callback per chunk.
The streaming parser avoids building the tree and is the right tool for
very large documents or for extracting a few values from a big file.

Values are created as small blessed hashes; a document with a million
values needs about 500 MB as a tree. Use L<Text::KDL::XS::Parser> for
anything of that size.

The module requires Perl 5.12 or newer built with 64-bit integers
(C<ivsize> 8, the default on 64-bit platforms).

=head1 SEE ALSO

=over 4

=item L<Text::KDL::XS::Cookbook>

Every KDL feature with KDL and Perl examples, plus recipes.

=item L<Text::KDL::XS::Parser>, L<Text::KDL::XS::Document>, L<Text::KDL::XS::Node>, L<Text::KDL::XS::Value>

The classes that make up the API.

=item L<Text::KDL::XS::Emitter>

Internal; documented for completeness.

=item L<Alien::ckdl>

Builds and provides the ckdl library this module links against; its
C<alienfile> pins the ckdl commit that is compiled.

=item L<https://kdl.dev>, L<https://github.com/kdl-org/kdl>

The KDL specification and reference test suite.

=item L<https://github.com/tjol/ckdl>

The C library doing the actual parsing and emitting.

=back

=head1 AUTHOR

Davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 LICENSE

Copyright (C) 2026 Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.
The bundled C<ckdl> library (linked statically via L<Alien::ckdl>) is
MIT-licensed.

=cut
