#!/usr/bin/perl

use v5.36;

use Text::Treesitter::Language;
use Text::Treesitter::Parser;
use Text::Treesitter::Query;
use Text::Treesitter::QueryCursor;
use Text::Treesitter::QueryMatch;

use Convert::Color;
use File::Slurper qw( read_text );
use Getopt::Long;
use String::Tagged;
use String::Tagged::Terminal;

GetOptions(
   'language|l=s'   => \( my $LANGUAGE = "c" ),
   'unrecognised|u' => \( my $PRINT_UNRECOGNISED ),
   'directory|d=s'  => \( my $LANGUAGE_DIR ),
) or exit 1;

$LANGUAGE_DIR //= "languages/tree-sitter-$LANGUAGE";
my $LANGUAGE_OBJECT = $LANGUAGE_DIR . "/tree-sitter-$LANGUAGE.so";
unless( -f $LANGUAGE_OBJECT ) {
   require Text::Treesitter::Language;
   Text::Treesitter::Language::build( $LANGUAGE_OBJECT, $LANGUAGE_DIR );
}

my $p = Text::Treesitter::Parser->new;
my $lang = Text::Treesitter::Language::load( $LANGUAGE_OBJECT, $LANGUAGE );
$p->set_language( $lang );

my $querysrc = read_text "$LANGUAGE_DIR/queries/highlights.scm";
my $query = Text::Treesitter::Query->new( $lang, $querysrc );

my $str = String::Tagged->new( read_text $ARGV[0] // "/dev/stdin" );

my $tree = $p->parse_string( $str );

my %FORMATS = (
   comment    => { bg => "vga:blue", italic => 1 },
   variable   => { fg => "vga:cyan" },
   property   => { fg => "vga:cyan", italic => 1 },
   keyword    => { fg => "vga:yellow", bold => 1 },
   number     => { fg => "vga:magenta" },
   string     => { fg => "vga:magenta" },
   preproc    => { fg => "vga:blue", bold => 1 },
   type       => { fg => "vga:green" },
);

foreach ( values %FORMATS ) {
   $_->{fg} and
      $_->{fg} = Convert::Color->new( $_->{fg} )->as_xterm;
   $_->{bg} and
      $_->{bg} = Convert::Color->new( $_->{bg} )->as_xterm;
}

my $qc = Text::Treesitter::QueryCursor->new;

$qc->exec( $query, $tree->root_node );

my %UNRECOGNISED_CAPTURES;

while( my $match = $qc->next_match ) {
   foreach my $capture ( $match->captures ) {
      my $node = $capture->node;
      my $capturename = $query->capture_name_for_id( $capture->capture_id );

      my $start = $node->start_byte;
      my $len   = $node->end_byte - $start;

      if( my $format = $FORMATS{ $capturename } ) {
         $str->apply_tag( $start, $len, $_, $format->{$_} ) for keys %$format;
      }
      else {
         $UNRECOGNISED_CAPTURES{ $capturename }++;
      }
   }
}

foreach my $line ( $str->split( qr/\n/ ) ) {
   String::Tagged::Terminal->new_from_formatting( $line )
      ->say_to_terminal;
}

if( $PRINT_UNRECOGNISED and keys %UNRECOGNISED_CAPTURES ) {
   print STDERR "-------\nUnrecognised:\n";
   foreach ( sort keys %UNRECOGNISED_CAPTURES ) {
      print STDERR "  $_\n";
   }
}
