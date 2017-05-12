#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;
use Tickit::RenderBuffer;

use Tickit::Widget::Menu::Item;

my $term = mk_term;

my $activated;

{
   my $item = Tickit::Widget::Menu::Item->new(
      name => "Some item",
      on_activate => sub { $activated++ },
   );

   ok( defined $item, '$item defined' );
   isa_ok( $item, "Tickit::Widget::Menu::Item", '$item isa Tickit::Widget::Menu::Item' );

   my $rb = Tickit::RenderBuffer->new( lines => 1, cols => 10 );
   $rb->goto( 0, 0 );

   $rb->setpen( Tickit::Pen->new( bg => 4 ) );

   $item->render_label( $rb, 10, undef );

   $rb->flush_to_term( $term );
   flush_tickit;

   is_termlog( [ GOTO(0,0), SETPEN(bg=>4), PRINT("Some item") ],
               'Termlog after ->render_label' );

   is_display( [ [TEXT("Some item",bg=>4)] ],
               'Display after ->render_label' );

   $item->activate;
   is( $activated, 1, '$activated is 1 after ->activate' );
}

done_testing;
