#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Console;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;

my $win = mk_window;

my $console = Tickit::Console->new;

$console->set_window( $win );

# A particularly silly layout
my $tab = $console->add_tab(
   name => "Silly",
   make_widget => sub {
      my ( $scroller ) = @_;

      my $hbox = Tickit::Widget::HBox->new(
         spacing => 2,
      );

      $hbox->add( Tickit::Widget::Static->new( text => "Left" ) );
      $hbox->add( $scroller, expand => 1 );
      $hbox->add( Tickit::Widget::Static->new( text => "Right" ) );

      return $hbox;
   },
);

flush_tickit;

is_display( [ [TEXT("Left"), BLANK(71), TEXT("Right")],
              BLANKLINES(22),
              [TEXT("[",fg=>7,bg=>4), TEXT("Silly",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), BLANK(73,bg=>4)],
              BLANKLINE() ],
            'Display initially with make_widget' );

$tab->append_line( "One" );
$tab->append_line( "Two" );
$tab->append_line( "Three" );
flush_tickit;

is_display( [ [TEXT("Left"), BLANK(2), TEXT("One"), BLANK(66), TEXT("Right")],
              [BLANK(6),               TEXT("Two"), BLANK(71) ],
              [BLANK(6),               TEXT("Three"), BLANK(69) ],
              BLANKLINES(20),
              [TEXT("[",fg=>7,bg=>4), TEXT("Silly",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), BLANK(73,bg=>4)],
              BLANKLINE() ],
            'Display after ->append_line on tab with custom widget' );

done_testing;
