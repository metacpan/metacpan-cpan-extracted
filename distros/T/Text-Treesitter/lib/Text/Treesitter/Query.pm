#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::Query 0.12;

use v5.14;
use warnings;
use experimental qw( signatures );
use Syntax::Keyword::Match;

use List::Util qw( any );

require Text::Treesitter::_XS;

use Exporter 'import';
our @EXPORT_OK = qw(
   TSQuantifierZero TSQuantifierZeroOrOne TSQuantifierZeroOrMore
   TSQuantifierOne  TSQuantifierOneOrMore
);

=head1 NAME

C<Text::Treesitter::Query> - represents a set of F<tree-sitter> query patterns

=head1 SYNOPSIS

Usually accessed indirectly, via C<Text::Treesitter>.

   use Text::Treesitter;

   my $ts = Text::Treesitter->new(
      lang_name => "perl",
   );

   my $query = $ts->load_query_string( "path/to/query.scm" );

   ...

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

=head2 predicates_for_pattern

   @predicates = $query->predicates_for_pattern( $id );

Returns a list representing the predicates in the query pattern at the given
index. Each predicate test will be represented by one arrayref in the returned
list. The array will start with a string giving the predicate's name, followed
by its arguments. String arguments are stored as strings. Capture arguments
are stored as references to integers, giving the capture index.

For example, a query containing the predicate

   (#match? @name "[A-Z]+")

Will be represented by a list of one arrayref:

   [ "match?", \123, "[A-Z]+" ]

where, in this case, the C<@name> capture had the capture index 123.

=head2 test_predicates_for_match

   $ok = $query->test_predicates_for_match( $match );

An older form is also accepted:

   $ok = $query->test_predicates_for_match( $tree, $match );

The I<$tree> argument is ignored if it is C<undef> or a
C<Text::Treesitter::Tree> instance.

Returns true if all the predicate tests in the given query match instance are
successful (or if there are no predicates). Returns false if any predicate
rejected it. Directives in the query are also processed at the same time.

This method needs the list of captures from the match instance. As it is
likely that the caller will need this too, an optional additional arrayref
argument can be passed containing it, for efficient reuse and avoiding
creating a second copy of the list.

   my @captures = $match->captures;
   my $ok = $query->test_predicates_for_match( $match, \@captures );

I<Since version 0.11>, in order to implement the C<#set!> directive, a hashref
can be passed as the third argument, into which metadata will be placed.

   my $ok = $query->test_predicates_for_match( $match, \@captures, \%metadata );

The following predicate and directive functions are recognised. Each predicate
also has an inverted variant whose name is preceeded by C<not-> to invert the
logic.

=head3 eq? / not-eq?

   (#eq? @capture "string")
   (#eq? @capture1 @capture2)

Accepts if the arguments are exactly the same string.

=head3 match? / not-match?

   (#match? @capture "RE-PATTERN")

Accepts if the first argument matches the regexp given by the second. Note
that the regexp is not anchored and could match anywhere within the capture.
To match only the entire capture make sure to use the C<^> and C<$> anchors.

   (#match? @name "[A-Z]+")   ; matches any name that contains a capital letter
   (#match? @name "^[A-Z]+$") ; matches any name entirely composed of capitals

When writing a query file, remember that although this implementation will use
Perl regexps, other highlighters will use their own engine for it. Try not to
use any fancy features that are not commonly available (such as look arounds,
etc..)

=head3 contains? / not-contains?

   (#contains? @capture "some" "values")

Accepts if the first argument contains (by an C<index()> test) any of the
string values given in the subsequent arguments.

(This predicate is inspired by F<nvim>.)

=head3 any-of? / not-any-of?

   (#any-of? @capture "some" "values")

Accepts if the first argument is exactly the same as any of the subsequent
string values.

(This predicate is inspired by F<nvim>.)

=head3 has-parent?

   (#has-parent? @capture type names)

Accepts if the immediate parent of first argument (which must be a node
capture) has a type that is any of the subsequent type names.

(This predicate is inspired by F<nvim>.)

=head3 has-ancestor?

   (#has-ancestor? @capture type names)

Accepts if any ancestor of the first argument (which mus be a node capture)
has a type that is any of the subsequent type names.

(This predicate is inspired by F<nvim>.)

=head3 set!

   (#set! meta-key "value")

Sets a metadata key in the metadata hash to the given value.

(This directive is inspired by F<nvim>.)

=cut

# Not documented as a method but handy for unit testing
sub test_predicate ( $self, $func, @args )
{
   my $invert = $func =~ s/^not-//;

   # Convert args to text
   my @argtext = map { ref($_) eq "Text::Treesitter::Node" ? $_->text : $_ } @args;

   match( $func : eq ) {
      case( "eq?" ) {
         return $invert ^ ($argtext[0] eq $argtext[1]);
      }
      case( "match?" ) {
         # This is an unanchored match; use ^ and $ to anchor it if required
         return $invert ^ ($argtext[0] =~ m/$argtext[1]/);
      }
      case( "contains?" ) {
         my $str = shift @argtext;
         return $invert ^ any { index( $str, $_ ) > -1 } @argtext;
      }
      case( "any-of?" ) {
         my $str = shift @argtext;
         return $invert ^ any { $str eq $_ } @argtext;
      }
      case( "has-parent?" ) {
         my $node = $args[0]->parent; shift @argtext;
         $node or return $invert;
         $node->is_named or return $invert;
         my $type = $node->type;
         return $invert ^ any { $type eq $_ } @argtext;
      }
      case( "has-ancestor?" ) {
         my $node = $args[0]->parent; shift @argtext;
         while( $node ) {
            $node->is_named or next;
            my $type = $node->type;
            return !$invert if any { $type eq $_ } @argtext;
            $node = $node->parent;
         }
         return $invert;
      }
      default {
         warn "Unrecognised predicate test '$func'";
         return 0;
      }
   }
}

sub test_predicates_for_match
{
   my $self = shift;
   shift if !defined $_[0] or $_[0]->isa( "Text::Treesitter::Tree" );
   my ( $match, $_captures, $metadata ) = @_;

   my @predicates = $self->predicates_for_pattern( $match->pattern_index ) 
      or return 1;

   my @captures = $_captures ? @$_captures : $match->captures;

   my %captures_by_id;
   foreach my $capture ( @captures ) {
      my $id   = $capture->capture_id;
      my $node = $capture->node;

      $captures_by_id{ $id } = $node;
   }

   foreach my $predicate ( @predicates ) {
      my ( $func, @args ) = @$predicate;
      ref $_ and $_ = $captures_by_id{ $$_ } for @args;

      if( $func =~ m/\?$/ ) {
         $self->test_predicate( $func, @args ) or return 0;
      }
      elsif( $func eq "set!" ) {
         my ( $name, $value ) = @args;
         $metadata->{$name} = $value;
      }
      else {
         warn "Unrecognised query directive '#$func'";
      }
   }

   return 1;
}

=head2 capture_quantifier_for_id

   $quant = $query->capture_quantifier_for_id( $pattern_id, $capture_id );

I<Since version 0.09.>

Returns the quantifier associated with the given capture of the given pattern.
This will match one of the following C<TSQuantifier*> constants

   TSQuantifierZero
   TSQuantifierZeroOrOne
   TSQuantifierZeroOrMore
   TSQuantifierOne
   TSQuantifierOneOrMore

=cut

=head1 TODO

The following C library functions are currently unhandled:

   ts_query_start_byte_for_pattern
   ts_query_is_pattern_rooted
   ts_query_is_pattern_guaranteed_at_step
   ts_query_disable_capture
   ts_query_disable_pattern

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
