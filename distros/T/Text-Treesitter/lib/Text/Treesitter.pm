#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.70 ':experimental(adjust_params)';

package Text::Treesitter 0.04;
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

If not specified, a search will be made for a directory named
F<tree-sitter-$LANG> among any of the user's configured parser directories, as
given by the F<tree-sitter> config file.

=back

=cut

=head1 METHODS

=cut

=head2 treesitter_config

   $config = Text::Treesitter->treesitter_config;

Returns a data structure containing the user's tree-sitter config, parsed from
F<$HOME/.config/tree-sitter/config.json> if it exists. If there is no file
then C<undef> is returned.

This is usable as a class method.

=cut

{
   my $treesitter_config;
   sub treesitter_config
   {
      return $treesitter_config if $treesitter_config;

      require JSON::MaybeUTF8;

      my $path = "$ENV{HOME}/.config/tree-sitter/config.json";
      next unless -f $path;

      return $treesitter_config = JSON::MaybeUTF8::decode_json_text( read_text( $path ) );
   }
}

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

=head2 lang_dir

   $dir = $ts->lang_dir;

Returns the directory path to the language directory. This is either the
configured path that was set by the C<lang_dir> parameter, or discovered by
searching if one was not.

=cut

sub _find_langdir
{
   my ( $lang ) = @_;

   my $parser_directories = ( treesitter_config or return undef )->{"parser-directories"};
   foreach my $dir ( @$parser_directories ) {
      my $langdir = "$dir/tree-sitter-$lang";

      return $langdir if -d $langdir;
   }

   return undef;
}

field $_lang :reader;
field $_lang_dir :reader;

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

      $lang_dir //= _find_langdir( $lang_name );

      $lang_lib //= "tree-sitter-$lang_name.so";
      if( $lang_lib !~ m{/} and defined $lang_dir ) {
         $lang_lib = "$lang_dir/$lang_lib";
      }

      unless( -f $lang_lib ) {
         defined $lang_dir or
            croak "Language library object does not exist but cannot be built without a 'lang_dir'";

         Text::Treesitter::Language::build( $lang_lib, $lang_dir );
      }

      $_lang = Text::Treesitter::Language::load( $lang_lib, $lang_name );
   }
   else {
      croak "Need either a 'lang' or a 'lang_name'";
   }

   $_parser->set_language( $_lang );
   $_lang_dir //= $lang_dir;
}

=head2 parse_string

   $tree = $ts->parse_string( $str );

Parses a given input string using the internal parser, returning a node tree
as an instance of L<Text::Treesitter::Tree>.

=cut

method parse_string ( $str )
{
   require Text::Treesitter::Tree;

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
given path, and then compiling it as per L</load_query_string>. C<$path> may
be specified as relative to the current working directory, or relative to the
language directory given by C<lang_dir>. The first one found will be loaded.

=cut

method load_query_file ( $path )
{
   -f $path or $path = "$_lang_dir/$path";
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
