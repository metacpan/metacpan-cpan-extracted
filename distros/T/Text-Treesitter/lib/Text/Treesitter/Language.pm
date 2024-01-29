#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::Language 0.12;

use v5.14;
use warnings;

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::Language> - represents a F<tree-sitter> language grammar

=head1 SYNOPSIS

Usually accessed indirectly, via C<Text::Treesitter>. Can also be used
directly.

   use Text::Treesitter::Language;

   my $language_lib = "path/to/the/tree-sitter-perl.so";

   my $lang = Text::Treesitter::Language::load( $language_lib, "perl" );

   printf "This language defines %d symbols\n", $lang->symbol_count;

=head1 DESCRIPTION

Instances of this class represent an entire language grammar specification.
Typically an application will load just one of these for the lifetime of its
operation; or at least, just one per type of language being parsed.

=cut

=head1 UTILITY FUNCTIONS

These utility functions are not exported, and must be called fully-qualified.

=cut

=head2 build

   Text::Treesitter::Language::build( $output, @dirs );

Requests that a language grammar repository directory (or several) be compiled
into an object file that can later be loaded.

=cut

# We -could- use ExtUtils::CBuilder but that's intended for building
# specifically to link against perl, and it won't cope with the C++ version
# of the final link step

use Config;
use constant CC => $Config::Config{cc};

{
   my $guess;

   my @CXX_compile;
   sub CXX_compile
   {
      return @CXX_compile if @CXX_compile;

      require ExtUtils::CppGuess;
      $guess //= ExtUtils::CppGuess->new;
      my %opts = $guess->module_build_options;

      return @CXX_compile = ( $opts{config}{cc},
         # $opts{extra_compiler_flags} might begin with a space
         split m/ +/, $opts{extra_compiler_flags} =~ s/^ +//r,
      );
   }

   my @CXX_link;
   sub CXX_link
   {
      return @CXX_link if @CXX_link;

      require ExtUtils::CppGuess;
      $guess //= ExtUtils::CppGuess->new;
      my %opts = $guess->module_build_options;

      return @CXX_link = ( $opts{config}{cc},
         # $opts{extra_linker_flags} might begin with a space
         split m/ +/, $opts{extra_linker_flags} =~ s/^ +//r,
      );
   }
}

sub _compile
{
   my ( $source ) = @_;
   my $is_cpp = $source =~ m/\.cc$/;

   my $output = $source =~ s/\.cc?$/.o/r;

   my @args = ( $is_cpp ? CXX_compile : CC,
      "-o", $output,
      "-fPIC",
      "-c", $source,
   );

   push @args, "-ggdb";

   print join( " ", @args ), "\n";
   system( @args ) == 0 or
      die "Unable to $args[0] - $?\n";

   return $output;
}

sub _link
{
   my ( $output, $is_cpp, @objects ) = @_;

   my @args = ( $is_cpp ? CXX_link : CC,
      "-o", $output,
      "-shared",
      @objects,
   );

   print join( " ", @args ), "\n";
   system( @args ) == 0 or
      die "Unable to $args[0] - $?\n";

   return $output;
}

sub build
{
   my ( $output, @dirs ) = @_;

   my $is_cpp = 0;
   my @objects;

   foreach my $dir ( @dirs ) {
      my $srcdir = "$dir/src";

      unless( -f "$srcdir/parser.c" ) {
         die "Expected a parser.c within $srcdir\n";
      }

      push @objects, _compile( "$srcdir/parser.c" );

      if( -f "$srcdir/scanner.c" ) {
         push @objects, _compile( "$srcdir/scanner.c" );
      }

      if( -f "$srcdir/scanner.cc" ) {
         $is_cpp = 1;
         push @objects, _compile( "$srcdir/scanner.cc" );
      }
   }

   _link( $output, $is_cpp, @objects );
}

=head2 load

   $lang = Text::Treesitter::Language::load( $libfile, $name );

Attempts to actually load the grammar specification from the object file. The
object file must have been previously built (either by calling L</build>, or
obtained in some other way).

An instance of C<Text::Treesitter::Language> is returned. This can be passed
to the C<set_language> method of a L<Text::Treesitter::Parser> instance.

=cut

=head1 METHODS

=cut

=head2 symbol_count

   $count = $lang->symbol_count;

Returns the number of symbols defined in the language.

=head2 symbols

   @symbols = $lang->symbols;

Returns a list of Symbol instances, in id order. Each will be an instance of a
class having the following accessors::

   $symbol->id
   $symbol->name
   $symbol->type_is_regular
   $symbol->type_is_anonymous
   $symbol->type_is_auxiliary

=cut

package Text::Treesitter::Language::_Symbol {
   sub new { my $class = shift; return bless [ @_ ], $class; }
   sub id   { shift->[0] }
   sub name { shift->[1] }
   sub type { shift->[2] }
   sub type_is_regular   { shift->[2] == TSSymbolTypeRegular() }
   sub type_is_anonymous { shift->[2] == TSSymbolTypeAnonymous() }
   sub type_is_auxiliary { shift->[2] == TSSymbolTypeAuxiliary() }
}

sub symbols
{
   my $self = shift;
   my $count = $self->symbol_count;
   return $count unless wantarray;

   my @symbols;
   foreach my $id ( 0 .. $count - 1 ) {
      push @symbols, Text::Treesitter::Language::_Symbol->new(
         $id, $self->symbol_name( $id ), $self->symbol_type( $id ),
      );
   }

   return @symbols;
}

=head2 field_count

   $count = $lang->field_count;

Returns the number of fields defined in the language.

=head2 fields

   @fields = $lang->fields;

Returns a list of Field instances, in id order. Each will be an instance of a
class having the following accessors:

   $field->id
   $field->name

=cut

package Text::Treesitter::Language::_Field {
   sub new { my $class = shift; return bless [ @_ ], $class; }
   sub id   { shift->[0] }
   sub name { shift->[1] }
}

sub fields
{
   my $self = shift;
   my $count = $self->field_count;
   return $count unless wantarray;

   my @fields;
   foreach my $id ( 1 .. $count ) { # fields are 1-indexed
      push @fields, Text::Treesitter::Language::_Field->new(
         $id, $self->field_name_for_id( $id ),
      );
   }

   return @fields;
}

=head1 TODO

The following C library functions are currently unhandled:

   ts_language_symbol_for_name
   ts_language_field_id_for_name
   ts_language_version

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
