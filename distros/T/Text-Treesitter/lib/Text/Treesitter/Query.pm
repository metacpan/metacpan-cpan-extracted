#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::Query 0.03;

use v5.14;
use warnings;

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::Query> - represents a set of F<tree-sitter> query patterns

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Instances of this class represent a set of query patterns that can be
performed against a node tree. Each pattern describes a shape of nodes in the
tree by their type, and assigns certain nodes within that subtree to named
captures. This is somewhat analogous to named captures in regexp matches.

Typically an application will load just one of these for the lifetime of its
operation; or at least, just one per type of language being parsed and query
being performed against it.

Queries are specified in a the form of a string containing a list of patterns
expressed in S-expressions. The full format is described in the F<tree-sitter>
documentation at
L<https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries>

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $query = Text::Treesitter::Query->new( $lang, $src );

Returns a new query instance associated with the given
L<Text::Treesitter::Language> instance, by reading query specifications from
the given source string.

=cut

=head1 METHODS

=cut

=head2 pattern_count

   $count = $query->pattern_count;

Returns the number of query patterns defined by the query source.

=head2 capture_count

   $count = $query->capture_count;

Returns the number of capture names.

=head2 string_count

   $count = $query->string_count;

Returns the number of string values.

=head2 capture_name_for_id

   $name = $query->capture_name_for_id( $id );

Returns the name of the capture at the given capture index.

=head2 string_value_for_id

   $value = $query->string_value_for_id( $id );

Returns the value of a string at the given string index.

=cut

=head1 TODO

The following C library functions are currently unhandled:

   ts_query_start_byte_for_pattern
   ts_query_predicates_for_pattern
   ts_query_is_pattern_rooted
   ts_query_is_pattern_guaranteed_at_step
   ts_query_capture_quantifier_for_id
   ts_query_disable_capture
   ts_query_disable_pattern

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
