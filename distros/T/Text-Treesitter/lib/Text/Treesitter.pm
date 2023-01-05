#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter 0.02;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Text::Treesitter> - Perl binding for F<tree-sitter>

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

This module provides several classes and utilities that wrap the
F<tree-sitter> parser library.

This particular package does not (currently) provide any functionallity; to
actually use the parser you will need to use some of the specific modules:

=over 4

=item *

L<Text::Treesitter::Language> - represents a F<tree-sitter> language grammar

=item *

L<Text::Treesitter::Node> - an element of a F<tree-sitter> parse result

=item *

L<Text::Treesitter::Parser> - parse some input text according to a F<tree-sitter> grammar

=item *

L<Text::Treesitter::Query> - represents a set of F<tree-sitter> query patterns

=item *

L<Text::Treesitter::QueryCursor> - stores the result of a F<tree-sitter> node query

=item *

L<Text::Treesitter::QueryMatch> - stores the result of a F<tree-sitter> query pattern match

=item *

L<Text::Treesitter::Tree> - holds the result of a F<tree-sitter> parse operation

=back

=cut

=head1 TODO

The following C library functions are currently unhandled:

   the entire TSTreeCursor API

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
