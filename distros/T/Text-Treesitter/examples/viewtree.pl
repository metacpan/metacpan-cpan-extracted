#!/usr/bin/perl

use v5.36;
use utf8;

STDOUT->binmode( ":encoding(UTF-8)" );

use Text::Treesitter;

use Getopt::Long;
use List::Util qw( pairs );
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
   'file|f=s'       => \( my $FILE ),
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
   my ( $line, $lineidx, @namednodes ) = @_;

   my @children;
   foreach my $p ( @namednodes ) {
      my ( undef, $node ) = @$p;

      push @children, pairs $node->field_names_with_child_nodes;
   }

   print_tree_flamegraph( $line, $lineidx, @children ) if @children;

   # Column numbers are all 0-based

   my @positions;

   foreach my $p ( @namednodes ) {
      my ( $fieldname, $node ) = @$p;

      my $has_children = $node->child_count > 0;

      my ( $startrow, $col ) = $node->start_point;
      my ( $endrow, $endcol ) = $node->end_point;

      next if $startrow > $lineidx or $endrow < $lineidx;

      # Clamp col range
      $col = 0 if $startrow < $lineidx;
      $endcol = length $line if $endrow > $lineidx;

      my $len = $endcol - $col
         or next;

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
      if( defined $fieldname or $is_named ) {
         $str->append( " "x( length( $line ) - $endcol ) );

         $str->append( " $fieldname:" ) if defined $fieldname;
         $str->append_tagged( sprintf( ' (%s)', $node->type ),
            $node->type eq "ERROR" ? ( fgindex => COLOUR_RED ) : (),
         ) if $is_named;
      }

      $str->say_to_terminal;
   }

   print build_leader_string( \@positions ), "\n";
}

sub extract_nodes_on_line
{
   my ( $lineidx, $node ) = @_;

   return ( $node ) if $node->start_row == $lineidx and $node->end_row == $lineidx;

   my @ret;
   foreach my $child ( $node->child_nodes ) {
      my $childstart = $child->start_row;
      last if $childstart > $lineidx;

      my $childend = $child->end_row;
      next if $childend < $lineidx;

      push @ret, extract_nodes_on_line( $lineidx, $child ) if
         $childstart <= $lineidx and $childend >= $lineidx;
   }

   # If @ret is empty that means $node is the leaf node that covered the
   # -entire- line
   return $node if !@ret;

   return @ret;
}

if( defined $FILE ) {
   my $tree = $ts->parse_file( $FILE );
   my $root = $tree->root_node;

   # We can't call print_tree_flamegraph on text spanning multiple lines. Also
   # the output will be huge and unusable. Split it per line and only output
   # the nodes contained entirely within each line.
   my @lines = split m/\n/, $root->text;

   foreach my $lineidx ( 0 .. $#lines ) {
      my $line = $lines[$lineidx];

      if( !length $line ) {
         print "\n";
         next;
      }

      my @linenodes = extract_nodes_on_line( $lineidx, $root );

      if( @linenodes ) {
         print "\n" if $lineidx > 0;
         print_tree_flamegraph( $line, $lineidx, map { [ undef, $_ ] } @linenodes );
      }
      print "$line\n";
   }

   exit;
}

while( defined( my $line = $term->readline( "> " ) ) ) {
   my $tree = $ts->parse_string( $line );

   print_tree_flamegraph( $line, 0, [ undef, $tree->root_node ] );

   print "$line\n";
}
