#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::ScrollBox;

my $win = mk_window;

# Needs 40x20
my $static = Tickit::Widget::Static->new(
   text => join "\n", map { $_ x 40 } 'A' .. 'T'
);

my $widget = Tickit::Widget::ScrollBox->new(
   horizontal => "on_demand",
   vertical   => "on_demand",
   child => $static,
);

$widget->set_window( $win );
flush_tickit;

# Oversized at 80x25
{
   ok( !$widget->_h_visible, 'H invisible at 80x25' );
   ok( !$widget->_v_visible, 'V invisible at 80x25' );
}

# Undersized vertically at 80x15
{
   $win->resize( 15, 80 );
   ok( !$widget->_h_visible, 'H invisible at 80x15' );
   ok(  $widget->_v_visible, 'V visible at 80x15' );
}

# Undersized horizontally at 30x25
{
   $win->resize( 25, 30 );
   ok(  $widget->_h_visible, 'H visible at 30x25' );
   ok( !$widget->_v_visible, 'V invisible at 30x25' );
}

# Undersized at 30x15
{
   $win->resize( 15, 30 );
   ok(  $widget->_h_visible, 'H visible at 30x15' );
   ok(  $widget->_v_visible, 'V visible at 30x15' );
}

# Exactly at limits
{
   $win->resize( 20, 40 );
   ok( !$widget->_h_visible, 'H invisible at 40x20' );
   ok( !$widget->_v_visible, 'V invisible at 40x20' );
}

# Making either scrollbar visible forces the other when at-limit
{
   $win->resize( 20, 39 );
   ok(  $widget->_h_visible, 'H visible at 39x20' );
   ok(  $widget->_v_visible, 'V visible at 39x20' );

   $win->resize( 19, 40 );
   ok(  $widget->_h_visible, 'H visible at 40x19' );
   ok(  $widget->_v_visible, 'V visible at 40x19' );
}

done_testing;
