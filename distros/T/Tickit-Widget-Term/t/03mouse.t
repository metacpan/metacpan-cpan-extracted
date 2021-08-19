#!/usr/bin/perl

use v5.26;
use warnings;
use experimental qw( signatures );

use Test::More;

use Tickit::Test;

use Tickit::Widget::Term;

my $root = mk_window;

my $widget = Tickit::Widget::Term->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $root );
flush_tickit;

my $outbytes;
$widget->set_on_output( sub ( $bytes ) { $outbytes .= $bytes } );

# Enable mouse reporting mode
$widget->write_input( "\e[?1002h" );

# mouse press/release
{
   $outbytes = "";
   pressmouse press   => 1, 10, 10, 0;
   is( $outbytes, "\e[M\x20\x2B\x2B", 'on_output for mouse press' );

   $outbytes = "";
   pressmouse release => 1, 10, 10, 0;
   is( $outbytes, "\e[M\x23\x2B\x2B", 'on_output for mouse release' );
}

# mouse drag
{
   $outbytes = "";
   pressmouse press   => 1, 10, 10, 0;
   is( $outbytes, "\e[M\x20\x2B\x2B", 'on_output for mouse press' );

   $outbytes = "";
   pressmouse drag => 1, 10, 15, 0;
   is( $outbytes, "\e[M\x40\x30\x2B", 'on_output for mouse drag' );

   $outbytes = "";
   pressmouse release => 1, 10, 15, 0;
   is( $outbytes, "\e[M\x23\x30\x2B", 'on_output for mouse release' );
}

# mouse wheel
{
   $outbytes = "";
   pressmouse wheel => "down", 10, 10, 0;
   is( $outbytes, "\e[M\x61\x2B\x2B", 'on_output for mouse wheel' );
}

done_testing;
