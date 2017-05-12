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
         Tickit::Widget::Menu::Item->new( name => "Item 1", on_activate => sub { $activated = "Item 1" } ),
         Tickit::Widget::Menu->new(
            name => "Submenu",
            items => [
               Tickit::Widget::Menu::Item->new( name => "Sub 1", on_activate => sub { $activated = "Sub 1" } ),
               Tickit::Widget::Menu::Item->new( name => "Sub 2", on_activate => sub { $activated = "Sub 2" } ),
               Tickit::Widget::Menu::Item->new( name => "Sub 3", on_activate => sub { $activated = "Sub 3" } ),
            ]
         ),
      ],
   );

   $menu->popup( $win, 5, 5 );

   flush_tickit;

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌─────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ Item 1  │",rv=>1)],
                 [BLANK(5), TEXT("│ Submenu>│",rv=>1)],
                 [BLANK(5), TEXT("└─────────┘",rv=>1)] ],
               'Display after ->popup' );

   pressmouse( press => 1, 7, 10 );
   flush_tickit;

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

   pressmouse( drag => 1, 8, 20 );
   flush_tickit;

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌─────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ Item 1  │",rv=>1)],
                 [BLANK(5), TEXT("│ ",rv=>1), TEXT("Submenu",rv=>0,bg=>2), TEXT(">│",rv=>1),
                        TEXT("┌───────┐",rv=>1)],
                 [BLANK(5), TEXT("└─────────┘",rv=>1),
                        TEXT("│ ",rv=>1),TEXT("Sub 1",rv=>0,bg=>2), TEXT(" │",rv=>1)],
                 [BLANK(16),
                        TEXT("│ Sub 2 │",rv=>1)],
                 [BLANK(16),
                        TEXT("│ Sub 3 │",rv=>1)],
                 [BLANK(16),
                        TEXT("└───────┘",rv=>1)] ],
               'Display after mouse drag on Submenu' );

   pressmouse( drag => 1, 6, 8 );
   flush_tickit;

   is_display( [ BLANKLINES(5),
                 [BLANK(5), TEXT("┌─────────┐",rv=>1)],
                 [BLANK(5), TEXT("│ ",rv=>1), TEXT("Item 1 ",rv=>0,bg=>2), TEXT(" │",rv=>1)],
                 [BLANK(5), TEXT("│ Submenu>│",rv=>1)],
                 [BLANK(5), TEXT("└─────────┘",rv=>1)] ],
               'Display after mouse drag to Item 1' );

   pressmouse( release => 1, 6, 8 );
   flush_tickit;

   is( $activated, "Item 1", '$activated is Item 1 after mouse release' );

   is_display( [ BLANKLINES(25) ],
               'Display blank after mouse release on Item 1' );
}

done_testing;
