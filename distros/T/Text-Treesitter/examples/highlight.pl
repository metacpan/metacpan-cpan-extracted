#!/usr/bin/perl

use v5.36;
use utf8;

no warnings qw( experimental::builtin experimental::for_list );
use builtin qw( true false indexed );

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
   'folding|F'      => \( my $FOLDING ),
   'injections|J'   => \( my $INJECTIONS ),
) or exit 1;

STDOUT->binmode( ':encoding(UTF-8)' );

my %FORMATS = (
   # Names stolen from tree-sitter's highlight theme
   attribute  => { fg => "vga:cyan", italic => 1 },
   comment    => { fg => "xterm:15", bg => "xterm:54", italic => 1 },
   decorator  => { fg => "xterm:140", italic => 1 },
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
   'text.title'    => { fg => "vga:yellow", bold => 1, under => 1 },
   'text.uri'      => { fg => "vga:blue", under => 1 },

   # Extra names
   label      => { fg => "xterm:140", under => 1 },
   preproc    => { fg => "xterm:140", bold => 1 },
   verbatim   => { fg => "xterm:251", monospace => 1 },
);

if( $USE_THEME and my $config = Text::Treesitter->treesitter_config ) {
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

my $str = String::Tagged->new( read_text $ARGV[0] // "/dev/stdin" );

my @fold_regions;
my $fold_deepest = 0;

my %UNRECOGNISED_CAPTURES;

my %TS_FOR_LANGUAGE;

sub apply_language_highlights( $language, %opts )
{
   my $ts = $TS_FOR_LANGUAGE{ $language } //= eval { Text::Treesitter->new(
      lang_name => $language,
      lang_dir  => $LANGUAGE_DIR,
   ) };
   defined $ts or return;

   my $query_highlight = $ts->load_query_file( "highlights.scm" );

   my $query_folding;
   if( $FOLDING and -f ( my $folding_path = $ts->query_file_path( "fold.scm" ) ) ) {
      $query_folding = $ts->load_query_file( $folding_path );
   }

   my $query_injections;
   if( $INJECTIONS and -f ( my $injections_path = $ts->query_file_path( "injections.scm" ) ) ) {
      $query_injections = $ts->load_query_file( $injections_path );
   }

   my $tree;
   if( defined $opts{start_byte} ) {
      $tree = $ts->parse_string_range( $str, %opts{qw( start_byte end_byte )} );
   }
   else {
      $tree = $ts->parse_string( $str );
   }
   my $root = $tree->root_node;

   my $qc = Text::Treesitter::QueryCursor->new;

   # For ease of code management, line numbers are 0-indexed
   if( $FOLDING and $query_folding ) {
      $qc->exec( $query_folding, $root );

      my @regions_applied;

      while( my $captures = $qc->next_match_captures( multi => 1 ) ) {
         my @nodes = $captures->{fold}->@*;

         # Some fold patterns capture multiple toplevel nodes.
         my $startline = ( $nodes[ 0]->start_point )[0];
         my $endline   = ( $nodes[-1]->end_point )[0];

         die "TODO: This fold region starts earlier than the previous one"
            if @fold_regions and $startline < $fold_regions[-1][0];

         next if $startline == $endline;

         push @fold_regions, [ $startline, $endline ];

         pop @regions_applied while @regions_applied and $regions_applied[-1][1] < $startline;
         push @regions_applied, $fold_regions[-1];

         $fold_deepest = scalar @regions_applied if @regions_applied > $fold_deepest;
      }
   }

   if( $INJECTIONS and $query_injections ) {
      $qc->exec( $query_injections, $root );

      while( my $captures = $qc->next_match_captures ) {
         my $sublanguage;
         my $content;
         if( defined $captures->{language} ) {
            $sublanguage = $captures->{language}->text;
            $content     = $captures->{content};
         }
         elsif( keys $captures->%* > 1 ) {
            warn "This injection capture yielded more than one name key\n";
            next;
         }
         else {
            $sublanguage = ( keys $captures->%* )[0];
            $content     = $captures->{$sublanguage};
         }

         apply_language_highlights( $sublanguage,
            start_byte => $content->start_byte,
            end_byte   => $content->end_byte,
         );
      }
   }

   $qc->exec( $query_highlight, $root );

   while( my $captures = $qc->next_match_captures ) {
      CAPTURE: foreach my $capturename ( sort keys $captures->%* ) {
         my $node = $captures->{$capturename};

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
}

apply_language_highlights( $LANGUAGE );

foreach my ( $lnum, $line ) ( indexed $str->split( qr/\n/ ) ) {
   if( $FOLDING ) {
      my @regions = grep { $_->[0] <= $lnum and $lnum <= $_->[1] } @fold_regions;
      my $final_here;
      my $markers = join "", map {
         $_->[0] == $lnum ? ( $final_here = true, "┌" )[1] :
         $_->[1] == $lnum ? ( $final_here = true, "└" )[1] :
                            "│";
      } @regions;

      $markers .= ( $final_here ? "─" : " " ) while length $markers < $fold_deepest;

      print $markers . " ";
   }
   String::Tagged::Terminal->new_from_formatting( $line )
      ->say_to_terminal;
}

if( $PRINT_UNRECOGNISED and keys %UNRECOGNISED_CAPTURES ) {
   print STDERR "-------\nUnrecognised:\n";
   foreach ( sort keys %UNRECOGNISED_CAPTURES ) {
      print STDERR "  $_\n";
   }
}
