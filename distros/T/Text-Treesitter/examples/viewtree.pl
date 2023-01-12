#!/usr/bin/perl

use v5.36;
use utf8;

STDOUT->binmode( ":encoding(UTF-8)" );

use Text::Treesitter;

use Getopt::Long;
use Term::ReadLine;
use String::Tagged;
use String::Tagged::Terminal;

use constant {
   COLOUR_RED     => 1,
   COLOUR_GREEN   => 2,
   COLOUR_YELLOW  => 3,
   COLOUR_MAGENTA => 5,
};

GetOptions(
   'language|l=s'   => \( my $LANGUAGE = "c" ),
   'unrecognised|u' => \( my $PRINT_UNRECOGNISED ),
   'directory|d=s'  => \( my $LANGUAGE_DIR ),
) or exit 1;

my $ts = Text::Treesitter->new(
   lang_name => $LANGUAGE,
   lang_dir  => $LANGUAGE_DIR,
);

my $term = Term::ReadLine->new( "viewtree.pl" );

sub build_leader_string
{
   my ( $positions ) = @_;

   my $str = "";
   my $prevcol = 0;
   foreach my $i ( keys @$positions ) {
      my ( $startcol, $endcol ) = $positions->[$i]->@*;
      my $is_final = ( $i == $#$positions );

      my ( $open, $mid, $close ) =
         $is_final ? ( "├", "─", "┤" ) : ( "│", " ", "│" );

      $str .= " " x ( $startcol - $prevcol );
      if( $endcol == $startcol ) {
         $str .= "│";
      }
      else {
         $str .= $open . $mid x ( $endcol - $startcol - 1 ) . $close;
      }
      $prevcol = $endcol + 1;
   }

   return $str;
}

sub print_tree_flamegraph
{
   my ( $line, @nodes ) = @_;

   my @children;
   foreach my $node ( @nodes ) {
      push @children, $node->child_nodes;
   }

   print_tree_flamegraph( $line, @children ) if @children;

   # Column numbers are all 0-based

   my @positions;

   foreach my $node ( @nodes ) {
      my $has_children = $node->child_count > 0;

      my ( undef, $col ) = $node->start_point;
      my ( undef, $endcol ) = $node->end_point;

      my $len = $endcol - $col;
      $len or next;

      my $str = String::Tagged::Terminal->new;

      $str->append( build_leader_string( \@positions ) );
      my $prevcol = @positions ? $positions[-1][1] + 1 : 0;
      $str->append( " " x ( $col - $prevcol ) );

      push @positions, [ $col, $endcol - 1 ];

      my $is_named = $node->is_named;

      $str->append_tagged( substr( $line, $col, $len ),
         fgindex => $has_children ? COLOUR_GREEN :
                    $is_named     ? COLOUR_MAGENTA :
                                    COLOUR_YELLOW,
      );

      if( $is_named ) {
         $str->append( " "x( length( $line ) - $endcol ) );
         $str->append_tagged( sprintf( ' %s', $node->type ),
            $node->type eq "ERROR" ? ( fgindex => COLOUR_RED ) : (),
         );
      }

      $str->say_to_terminal;
   }

   print build_leader_string( \@positions ), "\n";
}

while( defined( my $line = $term->readline( "> " ) ) ) {
   my $tree = $ts->parse_string( $line );

   print_tree_flamegraph( $line, $tree->root_node );

   print "$line\n";
}
