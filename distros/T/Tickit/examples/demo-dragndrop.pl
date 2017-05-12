#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( GridBox );

package DndArea;
use base qw( Tickit::Widget );
use Tickit::RenderBuffer;

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;
   my $win = $self->window or return;

   $rb->clear;

   my $centreline = int( $win->lines / 2 );

   if( $self->{dragging} ) {
      $rb->text_at( $centreline-1, int( ($win->cols - 10) / 2 ),
                    $self->{dragging} == 2 ? "*dragging*" : "*DRAGGING*",
                    Tickit::Pen->new( fg => "red" ) );
   }
   $rb->text_at( $centreline, int( $win->cols / 2 ) - 5, ref $self );
   $rb->text_at( $centreline+1, int( ($win->cols - length $self->{latest_mouse}) / 2 ), $self->{latest_mouse} )
      if defined $self->{latest_mouse};

   if( $self->can( "render_rb" ) ) {
      $self->render_rb( $rb );
   }
}

package SourceArea;
use base qw( DndArea );

sub render_rb
{
   my $self = shift;
   my ( $rb ) = @_;

   if( defined $self->{start_line} ) {
      $rb->text_at( $self->{start_line}, $self->{start_col}, "S", Tickit::Pen->new( fg => "red" ) );
   }

   if( defined $self->{over_line} ) {
      $rb->text_at( $self->{over_line}-1, $self->{over_col}  , "|", Tickit::Pen->new ( fg => "black" ) );
      $rb->text_at( $self->{over_line}+1, $self->{over_col}  , "|", Tickit::Pen->new ( fg => "black" ) );
      $rb->text_at( $self->{over_line}  , $self->{over_col}-1, "-", Tickit::Pen->new ( fg => "black" ) );
      $rb->text_at( $self->{over_line}  , $self->{over_col}+1, "-", Tickit::Pen->new ( fg => "black" ) );
   }

   if( defined $self->{end_line} ) {
      $rb->text_at( $self->{end_line}, $self->{end_col}, "E", Tickit::Pen->new ( fg => "magenta" ) );
   }
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   $self->{latest_mouse} = sprintf "%s button %d at (%d,%d)",
      $args->type, $args->button, $args->line, $args->col;

   if( $args->type eq "press" ) {
      undef $_ for @{$self}{qw( start_line start_col over_line over_col end_line end_col )};
   }

   if( $args->type eq "drag_start" ) {
      ( $self->{start_line}, $self->{start_col} ) = ( $args->line, $args->col );
   }

   if( $args->type eq "drag" ) {
      ( $self->{over_line}, $self->{over_col} ) = ( $args->line, $args->col );
      $self->{dragging} = 1;
   }

   if( $args->type eq "drag_outside" ) {
      $self->{dragging} = 2;
   }

   if( $args->type eq "drag_drop" ) {
      ( $self->{end_line}, $self->{end_col} ) = ( $args->line, $args->col );
   }

   if( $args->type eq "drag_stop" ) {
      undef $_ for @{$self}{qw( over_line over_col )};
      $self->{dragging} = 0;
   }

   $self->redraw;
   return 1;
}

package DestArea;
use base qw( DndArea );

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   $self->{latest_mouse} = sprintf "%s button %d at (%d,%d)",
      $args->type, $args->button, $args->line, $args->col;

   $self->redraw;
   return 1;
}

package main;

my $gridbox = Tickit::Widget::GridBox->new(
   col_spacing => 2,
   row_spacing => 1,
);
$gridbox->add( 0, 0, SourceArea->new( bg => "green" ), col_expand => 1, row_expand => 1 );
$gridbox->add( 1, 1, DestArea->new( bg => "blue" ),    col_expand => 1, row_expand => 1 );

Tickit->new( root => $gridbox )->run;
