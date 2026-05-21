package Text::KDL::XS;

use strict;
use warnings;

our $VERSION = '0.001';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Text::KDL::XS::Parser;
use Text::KDL::XS::Value;
use Text::KDL::XS::Node;
use Text::KDL::XS::Document;

use Exporter 'import';
our @EXPORT_OK = qw(parse_kdl emit_kdl);

# parse_kdl($source, %opts) -> Text::KDL::XS::Document
#   $source : string | filehandle | coderef
#   %opts   : version => 'detect'|'1'|'2', emit_comments => 0|1
sub parse_kdl {
    my ($source, %opts) = @_;
    my $parser = Text::KDL::XS::Parser->new($source, %opts);
    return Text::KDL::XS::Document->_build_from_parser($parser);
}

# emit_kdl($tree, %opts) -> string
#   $tree : Text::KDL::XS::Document | Text::KDL::XS::Node | arrayref of Nodes
sub emit_kdl {
    my ($tree, %opts) = @_;
    require Text::KDL::XS::Emitter;
    return Text::KDL::XS::Emitter->_emit_tree($tree, %opts);
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS - Fast KDL parser and emitter via libckdl

=head1 SYNOPSIS

  use Text::KDL::XS qw(parse_kdl emit_kdl);

  my $doc = parse_kdl(<<'KDL');
  package "kdl-rs" {
      version "0.4.0"
      author "Kat Marchán" email="kat@example.com"
  }
  KDL

  for my $node (@{ $doc->nodes }) {
      print $node->name, "\n";
  }

  my $kdl_text = emit_kdl($doc);

=head1 DESCRIPTION

C<Text::KDL::XS> is a Perl XS binding to L<ckdl|https://github.com/tjol/ckdl>,
a C11 library for reading and writing the KDL Document Language. Both
KDL B<v1.0.0> and B<v2.0.0> are supported (auto-detected by default).

The module exposes two layers:

=over 4

=item *

A high-level tree API (L</parse_kdl>, L</emit_kdl>) that returns blessed
L<Text::KDL::XS::Document>, L<Text::KDL::XS::Node>, and
L<Text::KDL::XS::Value> objects.

=item *

A streaming event API via L<Text::KDL::XS::Parser> for advanced consumers
who want SAX-like access without building a tree.

=back

=head1 FUNCTIONS

=head2 parse_kdl( $source, %opts )

Parse a KDL document. C<$source> may be one of:

=over 4

=item * a string (parsed in-memory)

=item * an open file handle / IO object (read in chunks)

=item * a code reference returning chunks of bytes (or C<undef>/empty at EOF)

=back

Options:

=over 4

=item C<< version => 'detect' | '1' | '2' >> (default C<'detect'>)

=item C<< emit_comments => 0 | 1 >> (default C<0>)

=back

Returns a L<Text::KDL::XS::Document>. Throws on malformed input.

=head2 emit_kdl( $tree, %opts )

Serialize a tree (or plain Perl data) to a KDL string. The emitter operates
in one of two modes, chosen automatically from the input:

=head3 Tree mode (full fidelity)

Used when C<$tree> is one of:

=over 4

=item * a L<Text::KDL::XS::Document>

=item * a L<Text::KDL::XS::Node>

=item * an array reference whose elements are B<all> L<Text::KDL::XS::Node>
objects

=back

Tree mode preserves property order, type annotations, and the
integer/float/bigint/string distinction on numbers.

=head3 Data mode (plain Perl convenience)

Used when C<$tree> is any other C<HASH> or C<ARRAY> reference. The mapping is:

=over 4

=item * Hash ref - each key becomes a sibling node, in sorted-key order for
deterministic output.

=item * Array ref - each element becomes an anonymous node named C<-> (the
JSON-in-KDL convention).

=item * Scalar / undef / boolean value - emitted as a single argument.

=item * Empty array C<[]> - emitted as a bare node with no args.

=item * Array of scalars - emitted as multiple args of one node.

=item * Hash ref value - emitted as a child block.

=item * Array containing complex elements - repeated as sibling nodes, one
per element.

=back

Data mode is lossy: property order is sorted, and the array-vs-single-arg
distinction does not round-trip exactly. Use tree mode when fidelity matters.

=head3 Scalar coercion

Argument and property values may be L<Text::KDL::XS::Value> objects or plain
Perl scalars. Plain scalars are coerced as follows:

  undef                                  -> KDL null
  JSON::PP::true / Types::Serialiser::*  -> KDL bool
  integer-flagged SV                     -> KDL number (integer)
  float-flagged SV                       -> KDL number (float)
  any other scalar                       -> KDL string

Strings like C<"true"> and C<"false"> are B<not> heuristically promoted to
booleans - pass an explicit C<JSON::PP::true>/C<JSON::PP::false> if you need
booleans. Other reference types in value position raise an error.

Options:

=over 4

=item C<< version => 'detect' | '1' | '2' >>

=item C<< indent => $integer >>

=item C<< escape_mode => $integer >>      (see C<kdl_escape_mode> in ckdl)

=item C<< identifier_mode => $integer >>  (see C<kdl_identifier_emission_mode>)

=back

Returns the emitted KDL string.

=head1 SEE ALSO

L<Text::KDL::XS::Parser>, L<Text::KDL::XS::Document>,
L<Text::KDL::XS::Node>, L<Text::KDL::XS::Value>, L<Alien::ckdl>,
L<https://github.com/kdl-org/kdl>, L<https://github.com/tjol/ckdl>.

=head1 LICENSE

Copyright (C) Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.
The bundled C<ckdl> library (linked statically via L<Alien::ckdl>) is
MIT-licensed.

=cut
