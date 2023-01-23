#!/usr/bin/perl

use v5.36;

use Text::Treesitter;
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
   'use-theme|U'    => \( my $USE_THEME ),
) or exit 1;

STDOUT->binmode( ':encoding(UTF-8)' );

my $ts = Text::Treesitter->new(
   lang_name => $LANGUAGE,
   lang_dir  => $LANGUAGE_DIR,
);

my $query = $ts->load_query_file( "queries/highlights.scm" );

my $str = String::Tagged->new( read_text $ARGV[0] // "/dev/stdin" );

my $tree = $ts->parse_string( $str );

my %FORMATS = (
   # Names stolen from tree-sitter's highlight theme
   attribute  => { fg => "vga:cyan", italic => 1 },
   comment    => { fg => "xterm:15", bg => "xterm:54", italic => 1 },
   function   => { fg => "xterm:147", },
   keyword    => { fg => "vga:yellow", bold => 1 },
   module     => { fg => "vga:green", bold => 1 },
   number     => { fg => "vga:magenta" },
   operator   => { fg => "vga:yellow" },
   string     => { fg => "vga:magenta" },
   type       => { fg => "vga:green" },
   variable   => { fg => "vga:cyan" },

   'string.special' => { fg => "vga:red" },
   'function.builtin' => { fg => "xterm:147", bold => 1 },

   # For tree-sitter-perl
   'variable.scalar' => { fg => "xterm:50" },
   'variable.array'  => { fg => "xterm:43" },
   'variable.hash'   => { fg => "xterm:81" },

   # For markup languages; e.g. used by tree-sitter-pod
   'text.emphasis' => { italic => 1 },
   'text.literal'  => { monospace => 1 },
   'text.quote'    => { italic => 1, bg => "xterm:236", },
   'text.strong'   => { bold => 1 },
   'text.uri'      => { fg => "vga:blue", under => 1 },

   # Extra names
   label      => { fg => "xterm:140", under => 1 },
   preproc    => { fg => "xterm:140", bold => 1 },
   verbatim   => { fg => "xterm:251", monospace => 1 },
);

if( $USE_THEME and my $config = $ts->treesitter_config ) {
   my %theme = $config->{theme}->%*;
   foreach my $key ( sort keys %theme ) {
      my %format = ( ref $theme{$key} ) ? $theme{$key}->%* : ( color => $theme{$key} );

      $format{fg} = "xterm:" . delete $format{color} if defined $format{color};

      $FORMATS{$key} = \%format;
   }
}

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
   my @captures = $match->captures;

   next unless $query->test_predicates_for_match( $tree, $match, \@captures );

   CAPTURE: foreach my $capture ( @captures ) {
      my $node = $capture->node;
      my $capturename = $query->capture_name_for_id( $capture->capture_id );

      my $start = $tree->byte_to_char( $node->start_byte );
      my $len   = $tree->byte_to_char( $node->end_byte ) - $start;

      my @nameparts = split m/\./, $capturename;
      while( @nameparts ) {
         if( my $format = $FORMATS{ join ".", @nameparts } ) {
            $str->apply_tag( $start, $len, $_, $format->{$_} ) for keys %$format;
            next CAPTURE;
         }

         pop @nameparts;
      }

      $UNRECOGNISED_CAPTURES{ $capturename }++;
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
