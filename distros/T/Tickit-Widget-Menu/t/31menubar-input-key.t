#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Tickit::Test;

use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu;

my ( $term, $win ) = mk_term_and_window;

my $activated;

my $menubar = Tickit::Widget::MenuBar->new(
   items => [
      Tickit::Widget::Menu->new( name => "File",
         items => [
            Tickit::Widget::Menu::Item->new( name => "File 1", on_activate => sub { $activated = "F1" } ),
            Tickit::Widget::Menu::Item->new( name => "File 2", on_activate => sub { $activated = "F2" } ),
         ],
      ),
      Tickit::Widget::Menu->new( name => "Edit",
         items => [
            Tickit::Widget::Menu::Item->new( name => "Edit 1", on_activate => sub { $activated = "E1" } ),
         ],
      ),
   ]
);

$menubar->set_window( $win );
flush_tickit;

# Start/end of every test should have the display in initial state
my @INITIAL = ( [TEXT("File  Edit",rv=>1)] );
is_display( \@INITIAL,
            'Display initially' );

{
   presskey( key => "F10" );
   flush_tickit;

   is_display( [ [TEXT("File",rv=>0,bg=>2), TEXT("  Edit",rv=>1)],
                 [TEXT("┌────────┐",rv=>1)],
                 [TEXT("│ File 1 │",rv=>1)],
                 [TEXT("│ File 2 │",rv=>1)],
                 [TEXT("└────────┘",rv=>1)] ],
               'Display after F10' );

   presskey( key => "Right" );

   flush_tickit;

   is_display( [ [TEXT("File  ",rv=>1), TEXT("Edit",rv=>0,bg=>2)],
                 [BLANK(6), TEXT("┌────────┐",rv=>1)],
                 [BLANK(6), TEXT("│ Edit 1 │",rv=>1)],
                 [BLANK(6), TEXT("└────────┘",rv=>1)] ],
               'Display after Right, Enter' );

   presskey( key => "Down" );
   flush_tickit;

   is_display( [ [TEXT("File  ",rv=>1), TEXT("Edit",rv=>0,bg=>2)],
                 [BLANK(6), TEXT("┌────────┐",rv=>1)],
                 [BLANK(6), TEXT("│ ",rv=>1), TEXT("Edit 1",rv=>0,bg=>2), TEXT(" │",rv=>1)],
                 [BLANK(6), TEXT("└────────┘",rv=>1)] ],
               'Display after Down' );

   presskey( key => "Enter" );
   flush_tickit;

   is( $activated, "E1", '$activated is E1 after Enter Edit 1' );

   is_display( \@INITIAL,
               'Display after Enter' );
}

done_testing;
