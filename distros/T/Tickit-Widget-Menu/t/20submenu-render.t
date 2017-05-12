#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Tickit::Test;
use Tickit::Window 0.57;  # ->bind_event

use Tickit::Widget::Menu;

my ( $term, $win ) = mk_term_and_window;

# Clear the initial expose event
flush_tickit;
drain_termlog;

# For later tests we need $win to clear itself
$win->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   $info->rb->eraserect( $info->rect );
});

{
   my $menu = Tickit::Widget::Menu->new(
      items => [
         Tickit::Widget::Menu::Item->new( name => "Item 1" ),
         Tickit::Widget::Menu->new(
            name => "Submenu",
            items => [
               Tickit::Widget::Menu::Item->new( name => "Sub 1" ),
               Tickit::Widget::Menu::Item->new( name => "Sub 2" ),
               Tickit::Widget::Menu::Item->new( name => "Sub 3" ),
            ]
         ),
      ],
   );

   $menu->popup( $win, 5, 5 );
   flush_tickit;

   is_termlog( [ GOTO(5,5), SETPEN(rv=>1), PRINT("┌─────────┐"),
                 GOTO(6,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Item 1"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(7,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Submenu"), SETPEN(rv=>1), PRINT(">"), SETPEN(rv=>1), PRINT("│"),
                 GOTO(8,5), SETPEN(rv=>1), PRINT("└─────────┘"), ],
               'Termlog after ->popup' );

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌─────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ Item 1  │",rv=>1)],
                 [BLANK(5), TEXT("│ Submenu>│",rv=>1)],
                 [BLANK(5), TEXT("└─────────┘",rv=>1)] ],
               'Display after ->popup' );

   pressmouse( press => 1, 7, 10 );
   flush_tickit;

   is_termlog( [ GOTO(7,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>0,bg=>2), PRINT("Submenu"), SETPEN(rv=>1), PRINT(">"), SETPEN(rv=>1), PRINT("│┌───────┐"),
                 GOTO( 8,16), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Sub 1"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO( 9,16), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Sub 2"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(10,16), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Sub 3"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(11,16), SETPEN(rv=>1), PRINT("└───────┘"), ],
               'Termlog after mouse press on Submenu' );

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌─────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ Item 1  │",rv=>1)],
                 [BLANK(5), TEXT("│ ",rv=>1), TEXT("Submenu",rv=>0,bg=>2), TEXT(">│",rv=>1),
                        TEXT("┌───────┐",rv=>1)],
                 [BLANK(5), TEXT("└─────────┘",rv=>1),
                        TEXT("│ Sub 1 │",rv=>1)],
                 [BLANK(16),
                        TEXT("│ Sub 2 │",rv=>1)],
                 [BLANK(16),
                        TEXT("│ Sub 3 │",rv=>1)],
                 [BLANK(16),
                        TEXT("└───────┘",rv=>1)] ],
               'Display after mouse press on Submenu' );

   $menu->dismiss;
   flush_tickit;

   is_termlog( [ GOTO(5,5), SETPEN(), ERASECH(11),
                 GOTO(6,5), SETPEN(), ERASECH(11),
                 GOTO(7,5), SETPEN(), ERASECH(20),
                 GOTO(8,5), SETPEN(), ERASECH(20),
                 GOTO(9,16), SETPEN(), ERASECH(9),
                 GOTO(10,16), SETPEN(), ERASECH(9),
                 GOTO(11,16), SETPEN(), ERASECH(9) ],
               'Termlog after ->dismiss' );

   is_display( [ BLANKLINES(25) ],
               'Display blank after ->dismiss' );
}

done_testing;
