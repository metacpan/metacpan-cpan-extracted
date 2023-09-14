#!/usr/bin/perl

use v5.14;
use warnings;

use Tickit;
use Tickit::Pen;

sub render_to_rb
{
   my ( $win, $rb, $rect ) = @_;

   $rb->eraserect( $rect );

   my $line = 0;

   # fg colours
   {
      $rb->goto( $line, 0 ); $line += 2;
      for (qw( red blue green yellow )) {
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( fg => $_ ) );
         $rb->text( "fg $_" );
         $rb->restore;

         # TODO: Do we need a $rb->move?
         $rb->goto( $rb->line, $rb->col + 4 );
      }

      $rb->goto( $line, 0 ); $line += 2;
      for (qw( red blue green yellow )) {
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( fg => "hi-$_" ) );
         $rb->text( "fg hi-$_" );
         $rb->restore;

         $rb->goto( $rb->line, $rb->col + 4 );
      }
   }

   # bg colours
   {
      $rb->goto( $line, 0 ); $line += 2;
      for (qw( red blue green yellow )) {
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( bg => $_, fg => "black" ) );
         $rb->text( "bg $_" );
         $rb->restore;

         # TODO: Do we need a $rb->move?
         $rb->goto( $rb->line, $rb->col + 4 );
      }

      $rb->goto( $line, 0 ); $line += 2;
      for (qw( red blue green yellow )) {
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( bg => "hi-$_", fg => "black" ) );
         $rb->text( "bg hi-$_" );
         $rb->restore;

         $rb->goto( $rb->line, $rb->col + 4 );
      }
   }

   # basic styles
   {
      $rb->goto( $line, 0 ); $line += 2;
      for ([ b => "bold" ], [ i => "italic" ], [ strike => "strikethrough" ], [ af => "alternate font" ]) {
         my ( $attr, $label ) = @$_;
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( $attr => 1 ) );
         $rb->text( $label );
         $rb->restore;

         $rb->goto( $rb->line, $rb->col + 4 );
      }
   }

   {
      $rb->goto( $line, 0 ); $line += 2;
      for (qw( single double wavy )) {
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( u => Tickit::Pen->can( "PEN_UNDER_\U$_" )->() ) );
         $rb->text( "$_-underline" );
         $rb->restore;

         $rb->goto( $rb->line, $rb->col + 4 );
      }
   }

   {
      $rb->goto( $line, 0 ); $line += 2;

      $rb->savepen;
      $rb->setpen( Tickit::Pen->new( rv => 1 ) );
      $rb->text( "reverse video" );
      $rb->restore;
   }

   {
      $rb->goto( $line, 0 ); $line += 2;

      $rb->savepen;
      $rb->setpen( Tickit::Pen->new( blink => 1 ) );
      $rb->text( "blink" );
      $rb->restore;
   }

   {
      $rb->goto( $line, 0 ); $line += 2;
      for (qw( sub super )) {
         $rb->text( "$_" );
         $rb->savepen;
         $rb->setpen( Tickit::Pen->new( sizepos => Tickit::Pen->can( "PEN_SIZEPOS_\U${_}SCRIPT" )->() ) );
         $rb->text( "script" );
         $rb->restore;

         $rb->goto( $rb->line, $rb->col + 4 );
      }
   }
}

my $t = Tickit->new;
$t->bind_key( q => sub { $t->stop } );
$t->rootwin->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;

   render_to_rb( $win, $info->rb, $info->rect );
} );
$t->run;
