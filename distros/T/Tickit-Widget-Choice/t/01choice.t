#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Choice;

my $root = mk_window;

my $win = $root->make_sub( 0, 0, 3, 20 );

my $choice = Tickit::Widget::Choice->new(
   choices => [
      [ 1 => "one" ],
      [ 2 => "two" ],
      [ 3 => "three" ],
   ],
);

ok( defined $choice, 'defined $choice' );

is( $choice->lines, 1, '$choice->lines' );
is( $choice->cols,  9, '$choice->cols' );

is( $choice->chosen_value, 1, '$choice->chosen_value' );

$choice->set_window( $win );

flush_tickit;

is_display( [ [TEXT("│",fg=>15), TEXT("one             "), TEXT("│-│",fg=>15)] ],
   'Display initially' );

$choice->choose_by_value( 2 );
is( $choice->chosen_value, 2, '$choice->chosen_value after ->choose_by_value' );

flush_tickit;

is_display( [ [TEXT("│",fg=>15), TEXT("two             "), TEXT("│-│",fg=>15)] ],
   'Display after ->choose_by_value' );

{
   # Keypresses
   $choice->take_focus;
   flush_tickit;

   is_display( [ [TEXT("║",fg=>15), TEXT("two             "), TEXT("║-║",fg=>15)] ],
      'Display after ->take_focus' );

   presskey( key => "Down" );

   is( $choice->chosen_value, 3, '$choice->chosen_value after keypress' );

   flush_tickit;

   is_display( [ [TEXT("║",fg=>15), TEXT("three           "), TEXT("║-║",fg=>15)] ],
      'Display after keypress' );
}

done_testing;
