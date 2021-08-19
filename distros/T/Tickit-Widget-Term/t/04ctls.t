#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Term;

Tickit::Test->can( "is_termctl" ) or
   plan skip_all => "Requires Tickit::Test::is_termctl()";

my $root = mk_window;

my $widget = Tickit::Widget::Term->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $root );
$widget->take_focus;
flush_tickit;

# cursor vis is hard because of Tickit update model
# we need the cursor visible to test this though
$widget->write_input( "\e[?25h" );

# cursor blink
{
   $widget->write_input( "\e[?12l" );
   flush_tickit;

   is_termctl( Tickit::Term::TERMCTL_CURSORBLINK, 0, 'cursor-blink off' );

   $widget->write_input( "\e[?12h" );
   flush_tickit;

   is_termctl( Tickit::Term::TERMCTL_CURSORBLINK, 1, 'cursor-blink off' );
}

# cursor shape
{
   $widget->write_input( "\e[3 q" );
   flush_tickit;

   is_termctl( Tickit::Term::TERMCTL_CURSORSHAPE, Tickit::Term::CURSORSHAPE_UNDER,
      'cursor-shape under' );

   $widget->write_input( "\e[5 q" );
   flush_tickit;

   is_termctl( Tickit::Term::TERMCTL_CURSORSHAPE, Tickit::Term::CURSORSHAPE_LEFT_BAR,
      'cursor-shape left-bar' );
}

done_testing;
