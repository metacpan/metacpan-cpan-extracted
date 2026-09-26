package Text::KDL::XS::Document;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Text::KDL::XS ();
use Text::KDL::XS::Node;

our @CARP_NOT = qw(
    Text::KDL::XS Text::KDL::XS::Emitter Text::KDL::XS::Node
    Text::KDL::XS::Parser Text::KDL::XS::Value
);

my %IS_FIELD = (nodes => 1);

sub new {
    my ($class, @fields) = @_;
    my $fields = Text::KDL::XS::_parse_named_arguments(__PACKAGE__ . '->new', 'field', \%IS_FIELD, @fields);
    my $nodes  = $fields->{nodes} // [];
    Carp::croak(__PACKAGE__ . "->new: 'nodes' must be an ARRAY reference")
        unless (Scalar::Util::reftype($nodes) // '') eq 'ARRAY';
    return bless { nodes => $nodes }, $class;
}

sub nodes { $_[0]->{nodes} }

sub as_data {
    my ($self) = @_;
    return [ map { $_->as_data } @{ $self->{nodes} } ];
}

# Builds the document from a parser's events. Slashdashed elements and
# comments, which the parser reports only with emit_comments, carry
# commented => 1 and are not part of the document.
sub _build_from_parser {
    my ($class, $parser) = @_;
    my $document = $class->new;
    my @open_nodes;

    eval {
        while (defined(my $event = $parser->_next_event)) {
            next if $event->{commented};
            my $kind = $event->{event};

            if ($kind eq 'argument') {
                push @{ $open_nodes[-1]{args} }, $event->{value};
            }
            elsif ($kind eq 'property') {
                push @{ $open_nodes[-1]{props} }, [ $event->{name}, $event->{value} ];
            }
            elsif ($kind eq 'start_node') {
                my $node = Text::KDL::XS::Node->_new_parsed($event->{name}, $event->{type});
                push @{ @open_nodes ? $open_nodes[-1]{children} : $document->{nodes} }, $node;
                push @open_nodes, $node;
            }
            elsif ($kind eq 'end_node') {
                pop @open_nodes;
            }
            else {
                Carp::croak(__PACKAGE__ . ": unexpected parser event '$kind'");
            }
        }
        1;
    } or Text::KDL::XS::_rethrow($@, __FILE__);

    return $document;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Document - A parsed KDL document: the list of top-level nodes

=head1 SYNOPSIS

=for highlighter language=Perl

  use Text::KDL::XS qw(parse_kdl emit_kdl);

  my $doc = parse_kdl($text);

  for my $node (@{ $doc->nodes }) {          # Text::KDL::XS::Node objects
      print $node->name, "\n";
  }

  my ($server) = grep { $_->name eq 'server' } @{ $doc->nodes };

  my $plain = $doc->as_data;                 # arrayref of plain hashes
  print emit_kdl($doc);                      # back to KDL text

  # Build one by hand from Text::KDL::XS::Node objects:
  my $new = Text::KDL::XS::Document->new(nodes => [ $node, Text::KDL::XS::Node->new(name => 'extra') ]);

=for highlighter

=head1 DESCRIPTION

A C<Text::KDL::XS::Document> is what L<Text::KDL::XS/parse_kdl> returns.
It is a thin container: an ordered list of the document's top-level
L<Text::KDL::XS::Node> objects. Everything else (arguments, properties,
children) hangs off the nodes.

Objects are plain blessed hashes and are meant to be modified in place:
push nodes onto C<< $doc->nodes >>, splice them out, reorder them, then
pass the document to L<Text::KDL::XS/emit_kdl>.

Comments and elements commented out with a slashdash (C</->) are never
part of a document, whatever options the parser was given.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=Perl

  my $doc = Text::KDL::XS::Document->new;
  my $doc = Text::KDL::XS::Document->new(nodes => \@nodes);

=for highlighter

Creates a document holding the given L<Text::KDL::XS::Node> objects, or an
empty one. The array reference is stored as is, not copied. C<nodes> must
be an array reference (C<Text::KDL::XS::Document-E<gt>new: 'nodes' must be
an ARRAY reference>); any other field, or an odd number of arguments,
dies. C<new> may be called on a subclass.

=head1 METHODS

=head2 nodes

=for highlighter language=Perl

  my $nodes = $doc->nodes;   # arrayref of Text::KDL::XS::Node, in document order

=for highlighter

The top-level nodes. Always an array reference, empty for an empty
document. It is the document's own array, so modifying it modifies the
document.

=head2 as_data

=for highlighter language=Perl

  my $data = $doc->as_data;  # [ { name => ..., args => [...], ... }, ... ]

=for highlighter

Returns the whole document as plain Perl data: an array reference with one
hash per top-level node, in the shape described in
L<Text::KDL::XS::Node/as_data>. This is convenient for dumping, comparing
in tests, or converting to JSON, but it is lossy: value type annotations,
number kinds, repeated properties and the boolean/number distinction are
not represented. Use the node objects when those matter.

=head1 SEE ALSO

L<Text::KDL::XS>, L<Text::KDL::XS::Node>, L<Text::KDL::XS::Value>.

=head1 AUTHOR

Davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 LICENSE

Copyright (C) 2026 Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.

=cut
