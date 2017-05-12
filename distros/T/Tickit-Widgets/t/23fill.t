#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Fill;

my $win = mk_window;

my $widget = Tickit::Widget::Fill->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $win );
flush_tickit;

is_display( [ ( [TEXT(" "x80)] ) x 25 ],
            'Display initially' );

$widget->set_style(
   text => "abcd",
);
flush_tickit;

is_display( [ ( [TEXT("abcd"x20)] ) x 25 ],
            'Display after set_style text' );

# Expose an area not starting at a multiple of 4
$widget->window->expose(
   Tickit::Rect->new( top => 1, lines => 5, left => 2, cols => 15 )
);
flush_tickit;

is_display( [ ( [TEXT("abcd"x20)] ) x 25 ],
            'Display after exposing a non-multiple area' );

$widget->set_style(
   skew => 1,
);
flush_tickit;

is_display( [ ( [TEXT("abcd"x20)],
                [TEXT("dabc"x20)],
                [TEXT("cdab"x20)],
                [TEXT("bcda"x20)] ) x 6,
              [TEXT("abcd"x20)] ],
            'Display after set_style skew' );

done_testing;
