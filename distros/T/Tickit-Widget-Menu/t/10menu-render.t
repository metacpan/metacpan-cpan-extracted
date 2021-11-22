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
         Tickit::Widget::Menu::Item->new( name => "Item 1", on_activate => sub {} ),
         Tickit::Widget::Menu::Item->new( name => "Item 2", on_activate => sub {} ),
      ],
   );

   ok( defined $menu, '$menu defined' );
   isa_ok( $menu, "Tickit::Widget::Menu", '$menu isa Tickit::Widget::Menu' );

   is( $menu->lines,  4, '$menu->lines' );
   is( $menu->cols,  10, '$menu->cols' );

   $menu->popup( $win, 5, 5 );
   flush_tickit;

   is_termlog( [ GOTO(5,5), SETPEN(rv=>1), PRINT("┌────────┐"),
                 GOTO(6,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Item 1"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(7,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Item 2"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(8,5), SETPEN(rv=>1), PRINT("└────────┘"), ],
               'Termlog after ->popup' );

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ Item 1 │",rv=>1)],
                 [BLANK(5), TEXT("│ Item 2 │",rv=>1)],
                 [BLANK(5), TEXT("└────────┘",rv=>1)] ],
               'Display after ->popup' );

   $menu->dismiss;
   flush_tickit;

   is_termlog( [ GOTO(5,5), SETPEN(), ERASECH(10),
                 GOTO(6,5), SETPEN(), ERASECH(10),
                 GOTO(7,5), SETPEN(), ERASECH(10),
                 GOTO(8,5), SETPEN(), ERASECH(10) ],
               'Termlog after menu click' );
}

# Separator
{
   my $menu = Tickit::Widget::Menu->new(
      items => [
         Tickit::Widget::Menu::Item->new( name => "Item 1", on_activate => sub {} ),
         Tickit::Widget::Menu->separator,
         Tickit::Widget::Menu::Item->new( name => "Item 2", on_activate => sub {} ),
      ],
   );

   $menu->popup( $win, 5, 5 );
   flush_tickit;

   is_termlog( [ GOTO(5,5), SETPEN(rv=>1), PRINT("┌────────┐"),
                 GOTO(6,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Item 1"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(7,5), SETPEN(rv=>1), PRINT("├────────┤"),
                 GOTO(8,5), SETPEN(rv=>1), PRINT("│"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("Item 2"), SETPEN(rv=>1), ERASECH(1,1), SETPEN(rv=>1), PRINT("│"),
                 GOTO(9,5), SETPEN(rv=>1), PRINT("└────────┘"), ],
               'Termlog with menu with separator' );

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ Item 1 │",rv=>1)],
                 [BLANK(5), TEXT("├────────┤",rv=>1)],
                 [BLANK(5), TEXT("│ Item 2 │",rv=>1)],
                 [BLANK(5), TEXT("└────────┘",rv=>1)] ],
               'Display with menu with separator' );

   $menu->dismiss;
   flush_tickit;
}

# Pre-highlight
{
   my $menu = Tickit::Widget::Menu->new(
      items => [ map {
         Tickit::Widget::Menu::Item->new( name => $_, on_activate => sub {} )
      } qw( One Two Three ) ],
   );

   $menu->highlight_item( 1 );

   $menu->popup( $win, 0, 0 );
   flush_tickit;

   is_display( [ [TEXT("┌───────┐",rv=>1)],
                 [TEXT("│ One   │",rv=>1)],
                 [TEXT("│ ",rv=>1), TEXT("Two  ",bg=>2), TEXT(" │",rv=>1)],
                 [TEXT("│ Three │",rv=>1)],
                 [TEXT("└───────┘",rv=>1)] ],
               'Display with pre-highlight' );

   $menu->dismiss;
   flush_tickit;
}

done_testing;
