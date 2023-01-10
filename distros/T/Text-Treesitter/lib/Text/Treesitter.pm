#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.70 ':experimental(adjust_params)';

package Text::Treesitter 0.03;
class Text::Treesitter
   :strict(params);

use Carp;

use File::Slurper qw( read_text );

=head1 NAME

C<Text::Treesitter> - Perl binding for F<tree-sitter>

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

This module provides several classes and utilities that wrap the
F<tree-sitter> parser library. A toplevel class is provided by this module
which wraps the functionallity of several other classes, which are also
available directly in the following modules:

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

=head1 CONSTRUCTOR

=head2 new

   $ts = Text::Treesitter->new( %params );

Returns a new C<Text::Treesitter> instance. Takes the following named
parameters:

=over 4

=item lang => Text::Treesitter::Language

Optional. An instance of L<Text::Treesitter::Language> to use in the parser.

=item lang_name => STRING

Optional. Gives the short name of the F<tree-sitter> language grammar.

Exactly one of C<lang> or C<lang_name> must be provided.

=item lang_lib => STRING

Gives the path to the compiled object file which contains the language
grammar. Optional; if not provided it will be presumed to be named based
on the language name, as F<tree-sitter-$LANG.so> within the language
directory. If the path does not contain a C</> character, it will have the
language directory path prepended onto it.

=item lang_dir => STRING

Gives the directory name in which to find the compiled object file which
contains the language grammar, or the sources to build it from.

=back

=cut

=head1 METHODS

=cut

=head2 parser

   $parser = $ts->parser;

Returns the L<Text::Treesitter::Parser> instance being used. The constructor
ensures that this will have a language set on it.

=cut

field $_parser :reader;
ADJUST {
   require Text::Treesitter::Parser;
   $_parser = Text::Treesitter::Parser->new;
}

=head2 lang

   $lang = $ts->lang;

Returns the L<Text::Treesitter::Language> instance being used by the parser.

=cut

field $_lang :reader;
ADJUST :params (
   :$lang      = undef,
   :$lang_name = undef,
   :$lang_dir  = undef,
   :$lang_lib  = undef,
) {
   if( defined $lang ) {
      $_lang = $lang;
   }
   elsif( defined $lang_name ) {
      require Text::Treesitter::Language;

      # TODO: maybe there's a platform-standard place to find a langdir?
      croak "Need a 'lang_dir' if using 'lang_name'" unless defined $lang_dir;

      $lang_lib //= "tree-sitter-$lang_name.so";
      $lang_lib =~ m{/} or
         $lang_lib = "$lang_dir/$lang_lib";

      unless( -f $lang_lib ) {
         Text::Treesitter::Language::build( $lang_lib, $lang_dir );
      }

      $_lang = Text::Treesitter::Language::load( $lang_lib, $lang_name );
   }
   else {
      croak "Need either a 'lang' or a 'lang_name'";
   }

   $_parser->set_language( $_lang );
}

=head2 parse_string

   $tree = $ts->parse_string( $str );

Parses a given input string using the internal parser, returning a node tree
as an instance of L<Text::Treesitter::Tree>.

=cut

method parse_string ( $str )
{
   $_parser->reset;
   return $_parser->parse_string( $str );
}

=head2 load_query_string

   $query = $ts->load_query_string( $str );

Creates a L<Text::Treesitter::Query> instance by compiling the match patterns
given in the source string for the language used by the parser.

=cut

method load_query_string ( $src )
{
   require Text::Treesitter::Query;
   return Text::Treesitter::Query->new( $_lang, $src );
}

=head2 load_query_file

   $query = $ts->load_query_file( $path );

Creates a L<Text::Treesitter::Query> instance by loading the text from the
given path, and then compiling it as per L</load_query_string>.

=cut

method load_query_file ( $path )
{
   return $self->load_query_string( read_text $path );
}

=head1 TODO

The following C library functions are currently unhandled:

   the entire TSTreeCursor API

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
