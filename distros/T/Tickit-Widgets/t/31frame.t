#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Frame;

my $win = mk_window;

my $static = Tickit::Widget::Static->new( text => "Widget" );

my $widget = Tickit::Widget::Frame->new(
   child => $static,
);

ok( defined $widget, 'defined $widget' );

$widget->set_window( $win );

ok( defined $static->window, '$static has window after $widget->set_window' );

flush_tickit;

is_display( [ [TEXT("+".("-"x78)."+")],
              [TEXT("|Widget".(" "x72)."|")],
              ( [TEXT("|"), BLANK(78), TEXT("|")] )  x 22,
              [TEXT("+".("-"x78)."+")] ],
            'Display initially' );

SKIP: {
   skip "No UTF-8 locale", 1 unless ${^UTF8LOCALE};

   $widget->set_style( linetype => "single" );

   flush_tickit;

   is_display( [ [TEXT("\x{250C}".("\x{2500}"x78)."\x{2510}")],
                 [TEXT("\x{2502}Widget".(" "x72)."\x{2502}")],
                 ( [TEXT("\x{2502}"), BLANK(78), TEXT("\x{2502}")] ) x 22,
                 [TEXT("\x{2514}".("\x{2500}"x78)."\x{2518}")] ],
               'Display after ->set_style(linetype)' );
}

# That linetype is hard to test against so put it back to ASCII
$widget->set_style( linetype => "ascii" );

$widget->set_title( "Title" );
flush_tickit;

is_display( [ [TEXT("+ Title ".("-"x71)."+")],
              [TEXT("|Widget".(" "x72)."|")],
              ( [TEXT("|"), BLANK(78), TEXT("|")] )  x 22,
              [TEXT("+".("-"x78)."+")] ],
            'Display with title' );

$widget->set_title_align( "right" );
flush_tickit;

is_display( [ [TEXT("+".("-"x71)." Title +")],
              [TEXT("|Widget".(" "x72)."|")],
              ( [TEXT("|"), BLANK(78), TEXT("|")] )  x 22,
              [TEXT("+".("-"x78)."+")] ],
            'Display with right-aligned title' );

$widget->set_style( frame_fg => "red" );
flush_tickit;

is_display( [ [TEXT("+".("-"x71)." Title +",fg=>1)],
              [TEXT("|",fg=>1), TEXT("Widget".(" "x72)), TEXT("|",fg=>1)],
              ( [TEXT("|",fg=>1), BLANK(78), TEXT("|",fg=>1)] ) x 22,
              [TEXT("+".("-"x78)."+",fg=>1)] ],
            'Display with correct pen' );

$static->set_text( "New text" );
flush_tickit;

is_display( [ [TEXT("+".("-"x71)." Title +",fg=>1)],
              [TEXT("|",fg=>1), TEXT("New text".(" "x70)), TEXT("|",fg=>1)],
              ( [TEXT("|",fg=>1), BLANK(78), TEXT("|",fg=>1)] ) x 22,
              [TEXT("+".("-"x78)."+",fg=>1)] ],
            'Display after $static->set_text' );

$widget->set_title( undef );
$widget->set_style( frame_fg => undef );

# Mixed linetypes
{
   $widget->set_style(
      linetype_top    => "double",
      linetype_bottom => "double",
      linetype_left   => "single",
      linetype_right  => "single",
   );
   flush_tickit;

   is_display( [ [TEXT("\x{2552}".("\x{2550}"x78)."\x{2555}")],
                 [TEXT("\x{2502}New text".(" "x70)."\x{2502}")],
                 ( [TEXT("\x{2502}"), BLANK(78), TEXT("\x{2502}")] ) x 22,
                 [TEXT("\x{2558}".("\x{2550}"x78)."\x{255b}")] ],
               'Display with mixed line styles' );

   $widget->set_style(
      linetype_left   => "solid_outside",
      linetype_right  => "solid_outside",
   );
   flush_tickit;

   is_display( [ [TEXT("\x{2550}"x80)],
                 [TEXT("\x{258c}New text".(" "x70)."\x{2590}")],
                 ( [TEXT("\x{258c}"), BLANK(78), TEXT("\x{2590}")] ) x 22,
                 [TEXT("\x{2550}"x80)] ],
               'Display with mixed line types' );
}

# Missing linetypes
{
   $widget->set_style(
      linetype_left  => "none",
      linetype_right => "none",
   );
   flush_tickit;

   is_display( [ [TEXT("\x{2550}"x80)],
                 [TEXT("New text".(" "x72))],
                 ( [BLANK(80)] ) x 22,
                 [TEXT("\x{2550}"x80)] ],
               'Display with left/right as none' );

   $widget->set_style(
      linetype_top    => "none",
      linetype_bottom => "none",
      linetype_left   => "single",
      linetype_right  => "single",
   );
   flush_tickit;

   is_display( [ [TEXT("\x{2502}New text".(" "x70)."\x{2502}")],
                 ( [TEXT("\x{2502}"), BLANK(78), TEXT("\x{2502}")] ) x 24 ],
               'Display with top/bottom as none' );
}

$widget->set_window( undef );

ok( !defined $static->window, '$static has no window after ->set_window undef' );

# Different linetypes to constructor
{
   my $widget = Tickit::Widget::Frame->new(
      style => {
         linetype => "none",
         linetype_left  => "single",
         linetype_right => "single",
      },
      child => $static,
   );

   $widget->set_window( $win );

   flush_tickit;

   is_display( [ [TEXT("\x{2502}"), TEXT("New text"), BLANK(70), TEXT("\x{2502}")],
                 ( [TEXT("\x{2502}"), BLANK(78), TEXT("\x{2502}")] ) x 24 ],
               'Display for $widget with individual linetypes to constructor' );

   $widget->set_window( undef );
}

done_testing;
