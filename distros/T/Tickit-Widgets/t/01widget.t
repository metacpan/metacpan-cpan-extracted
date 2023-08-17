#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000148;

my $lines = 1;
my $cols  = 5;
my $widget = TestWidget->new;

ok( defined $widget, 'defined $widget' );

is_oneref( $widget, '$widget has refcount 1 initially' );

my $pen = $widget->pen;
isa_ok( $pen, [ "Tickit::Pen" ], '$pen' );

is( { $widget->pen->getattrs }, {}, '$widget pen initially empty' );
is( $widget->pen->getattr('b'), undef, '$widget pen does not define b' );

is( [ $widget->requested_size ], [ 1, 5 ],
           '$widget->requested_size initially' );

{
   my $widget = TestWidget->new(
      style => { i => 1 },
   );

   is( { $widget->pen->getattrs }, { i => 1 }, 'Widget constructor sets initial pen' );
}

$lines = 2;
is( [ $widget->requested_size ], [ 1, 5 ],
           '$widget->requested_size unchanged before ->resized' );

$widget->resized;
is( [ $widget->requested_size ], [ 2, 5 ],
           '$widget->requested_size changed after ->resized' );

$widget->set_requested_size( 3, 8 );
is( [ $widget->requested_size ], [ 3, 8 ],
           '$widget->requested_size changed again after ->set_requested_size' );

is_oneref( $widget, '$widget has refcount 1 at EOF' );

done_testing;

use Object::Pad;
class TestWidget :isa(Tickit::Widget) {
   use constant WIDGET_PEN_FROM_STYLE => 1;

   method render_to_rb {}

   method lines { $lines }
   method cols  { $cols }
}
