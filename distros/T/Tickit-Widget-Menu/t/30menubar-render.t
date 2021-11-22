#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu;

my ( $term, $win ) = mk_term_and_window;

{
   my $menubar = Tickit::Widget::MenuBar->new(
      items => [
         Tickit::Widget::Menu->new( name => "File", items => [] ),
         Tickit::Widget::Menu->new( name => "Edit", items => [] ),
         Tickit::Widget::Menu->separator,
         Tickit::Widget::Menu->new( name => "Help", items => [] ),
      ]
   );

   ok( defined $menubar, '$menubar defined' );
   isa_ok( $menubar, "Tickit::Widget::MenuBar", '$menubar isa Tickit::Widget::MenuBar' );

   is( $menubar->lines,  1, '$menubar->lines' );
   is( $menubar->cols,  18, '$menubar->cols' );

   $menubar->set_window( $win );
   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN(rv=>1),
                 PRINT("File"),
                 SETPEN(rv=>1),
                 ERASECH(2,1),
                 SETPEN(rv=>1),
                 PRINT("Edit"),
                 SETPEN(rv=>1),
                 ERASECH(66,1),
                 SETPEN(rv=>1),
                 PRINT("Help"),

                 map { GOTO($_,0), SETPEN(rv=>1), ERASECH(80) } 1 .. 24 ],
               'Termlog initially' );

   is_display( [ [TEXT("File  Edit" . ( " " x 66 ) . "Help",rv=>1)] ],
               'Display initially' );
}

done_testing;
