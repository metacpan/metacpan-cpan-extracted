#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Test::More tests => 10;

BEGIN { use_ok('Test::Glade') }

{
  my $test_widget = {name => 'foo'};
  my $t = Test::Glade->new;
  $t->{widgets} = {$test_widget->{name} => $test_widget};
  ok( eq_set([$t->widgets], [$test_widget]) );
  is_deeply( $t->find_widget($test_widget), $test_widget );
}

{
  my $t = Test::Glade->new(file => "$FindBin::Bin/test.glade");
  ok( eq_set( 
    [map { $_->{name} } $t->widgets],
    [qw(window1 hbox1 button1 label1 vbox1
	radiobutton1 checkbutton1 statusbar1)],
  ) );
  
  ok( my $window = $t->find_widget({name => 'window1'}) );
  is_deeply( $window->properties, {
    visible => 1,
    title => 'window1',
    type => 'GTK_WINDOW_TOPLEVEL',
    window_position => 'GTK_WIN_POS_NONE',
    modal => 0,
    resizable => 1,
    destroy_with_parent => 0,
  } );
  is_deeply( [map { $_->name } @{$window->children}], ['hbox1'] );

  ok( my $button = $t->find_widget({name => 'button1'}) );
  is_deeply( $button->packing, {
    padding => 0,
    expand => 0,
    fill => 0,
  } );
  is_deeply( $button->signals, {
    clicked => 'on_button1_clicked',
  } );
}
