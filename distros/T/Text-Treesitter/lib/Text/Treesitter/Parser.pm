#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::Parser 0.02;

use v5.14;
use warnings;

require Text::Treesitter;

=head1 NAME

C<Text::Treesitter::Parser> - parse some input text according to a F<tree-sitter> grammar

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Instances of this class perform the actual parsing operation, taking a language
specification (in the form of a L<Text::Treesitter::Language> instance) and the
input text string, yielding a result (in the form of a
L<Text::Treesitter::Tree> instance).

=cut

=head1 CONSTRUCTOR

=head2 new

   $parser = Text::Treesitter::Parser->new;

Returns a new parser instance. A language must be set (by calling
L</set_language>) before parsing can be performed.

=head1 METHODS

=head2 set_language

   $parser->set_language( $lang );

Sets the language specification, as specified by an instance of
L<Text::Treesitter::Language>.

=head2 parse_string

   $tree = $parser->parse_string( $str );

Parses a given input string, returning a node tree as an instance of
L<Text::Treesitter::Tree>.

=head2 reset

   $parser->reset;

Resets the internal state of the parser so it can be used again.

=cut

=head1 TODO

The following C library functions are currently unhandled:

   ts_parser_set_included_ranges
   ts_parser_included_ranges
   ts_parser_parse
   ts_parser_set_timeout_micros
   ts_parser_timeout_micros
   ts_parser_set_cancellation_flag
   ts_parser_cancellation_flag
   ts_parser_set_logger
   ts_parser_logger

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
