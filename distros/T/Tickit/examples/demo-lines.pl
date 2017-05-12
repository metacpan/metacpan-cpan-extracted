#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

Tickit->new( root => RenderBufferDemo->new )->run;

package RenderBufferDemo;
use base qw( Tickit::Widget );
use Tickit::RenderBuffer qw(
   LINE_SINGLE LINE_DOUBLE LINE_THICK
   CAP_START CAP_END CAP_BOTH
);

sub lines { 1 }
sub cols  { 1 }

sub grid_at
{
   my ( $rb, $line, $col, $style, $pen ) = @_;

   # A 2x2 grid of cells
   $rb->hline_at( $line + 0, $col, $col + 12, $style, $pen );
   $rb->hline_at( $line + 3, $col, $col + 12, $style, $pen );
   $rb->hline_at( $line + 6, $col, $col + 12, $style, $pen );

   $rb->vline_at( $line + 0, $line + 6, $col +  0, $style, $pen );
   $rb->vline_at( $line + 0, $line + 6, $col +  6, $style, $pen );
   $rb->vline_at( $line + 0, $line + 6, $col + 12, $style, $pen );
}

sub corner_at
{
   my ( $rb, $line, $col, $style_horiz, $style_vert, $pen ) = @_;

   $rb->hline_at( $line, $col, $col + 2, $style_horiz, $pen, CAP_END );
   $rb->vline_at( $line, $line + 1, $col, $style_vert, $pen, CAP_END );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->text_at( 1, 2, "Single", $self->pen );
   grid_at( $rb, 2,  2, LINE_SINGLE, Tickit::Pen->new( fg => "red" ) );

   $rb->text_at( 1, 22, "Double", $self->pen );
   grid_at( $rb, 2, 22, LINE_DOUBLE, Tickit::Pen->new( fg => "green" ) );

   $rb->text_at( 1, 42, "Thick", $self->pen );
   grid_at( $rb, 2, 42, LINE_THICK, Tickit::Pen->new( fg => "blue" ) );

   my $pen;

   # Possible line interactions: crosses
   $pen = Tickit::Pen->new( fg => "cyan" );
   $rb->text_at( 10, 2, "Crossings", $self->pen );
   $rb->hline_at( 12,  4, 14, LINE_SINGLE, $pen, CAP_BOTH );
   $rb->hline_at( 15,  4, 14, LINE_DOUBLE, $pen, CAP_BOTH );
   $rb->hline_at( 18,  4, 14, LINE_THICK,  $pen, CAP_BOTH );
   $rb->vline_at( 12, 18,  5, LINE_SINGLE, $pen, CAP_BOTH );
   $rb->vline_at( 12, 18,  9, LINE_DOUBLE, $pen, CAP_BOTH );
   $rb->vline_at( 12, 18, 13, LINE_THICK,  $pen, CAP_BOTH );

   # T-junctions
   $pen = Tickit::Pen->new( fg => "magenta" );
   $rb->text_at( 10, 24, "T junctions", $self->pen );
   $rb->hline_at( 11, 25, 35, LINE_SINGLE, $pen, CAP_BOTH );
   $rb->hline_at( 14, 25, 35, LINE_DOUBLE, $pen, CAP_BOTH );
   $rb->hline_at( 17, 25, 35, LINE_THICK,  $pen, CAP_BOTH );
   $rb->vline_at( 11, 12, 26, LINE_SINGLE, $pen, CAP_END );
   $rb->vline_at( 11, 12, 30, LINE_DOUBLE, $pen, CAP_END );
   $rb->vline_at( 11, 12, 34, LINE_THICK,  $pen, CAP_END );
   $rb->vline_at( 14, 15, 26, LINE_SINGLE, $pen, CAP_END );
   $rb->vline_at( 14, 15, 30, LINE_DOUBLE, $pen, CAP_END );
   $rb->vline_at( 14, 15, 34, LINE_THICK,  $pen, CAP_END );
   $rb->vline_at( 17, 18, 26, LINE_SINGLE, $pen, CAP_END );
   $rb->vline_at( 17, 18, 30, LINE_DOUBLE, $pen, CAP_END );
   $rb->vline_at( 17, 18, 34, LINE_THICK,  $pen, CAP_END );

   # Corners
   $pen = Tickit::Pen->new( fg => "yellow" );
   $rb->text_at( 10, 42, "Corners", $self->pen );
   corner_at( $rb, 11, 44, LINE_SINGLE, LINE_SINGLE, $pen );
   corner_at( $rb, 11, 50, LINE_SINGLE, LINE_DOUBLE, $pen );
   corner_at( $rb, 11, 56, LINE_SINGLE, LINE_THICK,  $pen );
   corner_at( $rb, 14, 44, LINE_DOUBLE, LINE_SINGLE, $pen );
   corner_at( $rb, 14, 50, LINE_DOUBLE, LINE_DOUBLE, $pen );
   corner_at( $rb, 14, 56, LINE_DOUBLE, LINE_THICK,  $pen );
   corner_at( $rb, 17, 44, LINE_THICK,  LINE_SINGLE, $pen );
   corner_at( $rb, 17, 50, LINE_THICK,  LINE_DOUBLE, $pen );
   corner_at( $rb, 17, 56, LINE_THICK,  LINE_THICK,  $pen );
}
