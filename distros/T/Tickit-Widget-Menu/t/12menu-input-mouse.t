#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Tickit::Test;
use Tickit::Window 0.57;  # ->bind_event

use Tickit::Widget::Menu;

my ( $term, $win ) = mk_term_and_window;

# For later tests we need $win to clear itself
$win->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   $info->rb->eraserect( $info->rect );
});

{
   my $activated;

   my $menu = Tickit::Widget::Menu->new(
      items => [
         Tickit::Widget::Menu::Item->new( name => "Item 1", on_activate => sub { $activated = 1 } ),
         Tickit::Widget::Menu::Item->new( name => "Item 2", on_activate => sub { $activated = 2 } ),
      ],
   );

   $menu->popup( $win, 0, 0 );

   flush_tickit;

   is_display( [ [TEXT("┌────────┐",rv=>1)],
                 [TEXT("│ Item 1 │",rv=>1)],
                 [TEXT("│ Item 2 │",rv=>1)],
                 [TEXT("└────────┘",rv=>1)] ],
               'Display after ->popup' );

   drain_termlog;

   pressmouse( press => 1, 0, 5 );
   flush_tickit;

   is_termlog( [],
               'Termlog empty after mouse press on border' );

   pressmouse( drag => 1, 1, 5 );
   flush_tickit;

   is_display( [ [TEXT("┌────────┐",rv=>1)],
                 [TEXT("│ ",rv=>1), TEXT("Item 1",rv=>0,bg=>2), TEXT(" │",rv=>1)],
                 [TEXT("│ Item 2 │",rv=>1)],
                 [TEXT("└────────┘",rv=>1)] ],
               'Display after mouse drag to Item 1' );

   pressmouse( release => 1, 1, 5 );
   flush_tickit;

   is( $activated, 1, '$activated is 1 after mouse release on Item 1' );

   is_display( [ BLANKLINES(25) ],
               'Display blank after mouse release on Item 1' );
}

done_testing;
