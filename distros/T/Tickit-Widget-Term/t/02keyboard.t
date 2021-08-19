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

# plain printing key
{
   $outbytes = "";
   presskey text => "X";
   is( $outbytes, "X", 'on_output for plain text key' );
}

# symbolic key
{
   $outbytes = "";
   presskey key => "Up";
   is( $outbytes, "\e[A", 'on_output for plain text key' );
}

done_testing;
