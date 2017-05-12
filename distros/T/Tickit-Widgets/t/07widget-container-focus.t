#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Test;

# Since we need real Windows in the widgets, it's easier just to use an HBox
# as a container. However, since HBox is no longer in core, we'll have to skip
# this test if it isn't available
BEGIN {
   eval { require Tickit::Widget::HBox } or
      plan skip_all => "Tickit::Widget::HBox is not available";
}

my ( $term, $win ) = mk_term_and_window;

my @f_widgets = map { my $w = TestWidget->new; $w->{CAN_FOCUS} = 1; $w } 0 .. 2;
my @n_widgets = map { TestWidget->new } 0 .. 3;

# first/after/before/last on a single container
{
   my $container = TestContainer->new;
   $container->set_window( $win );

   $container->add( $_ ) for $n_widgets[0], $f_widgets[0], $n_widgets[1], $f_widgets[1];

   is( $container->pen->getattr( 'fg' ), undef, '$container pen fg is undef before focus child' );

   $container->focus_next( first => undef );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "first" linear' );

   is( $container->pen->getattr( 'fg' ), 1, '$container pen fg is 1 after focus child' );

   $container->focus_next( after => $f_widgets[0] );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "after" linear' );

   $container->focus_next( before => $f_widgets[1] );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "before" linear' );

   $container->focus_next( last => undef );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "last" linear' );

   # Wrap-around at the top level
   $container->focus_next( after => $f_widgets[1] );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "after" linear wraparound' );

   $container->focus_next( before => $f_widgets[0] );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "before" linear wraparound' );

   $container->set_window( undef );
}

# Tree search
{
   my $tree1 = Tickit::Widget::HBox->new;
   $tree1->add( $_ ) for $f_widgets[0], $n_widgets[0];

   my $tree2 = Tickit::Widget::HBox->new;
   $tree2->add( $_ ) for $f_widgets[1], $n_widgets[1];

   my $root = Tickit::Widget::HBox->new;
   $root->add( $_ ) for $tree1, $tree2;

   $root->set_window( $win );

   $root->focus_next( first => undef );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "first" tree' );

   $tree1->focus_next( after => $f_widgets[0] );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "after" tree' );

   $tree2->focus_next( before => $f_widgets[1] );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "before" tree' );

   $root->focus_next( last => undef );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "last" tree' );

   # Wrap-around at the top level
   $tree2->focus_next( after => $f_widgets[1] );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "after" tree wraparound' );

   $tree1->focus_next( before => $f_widgets[0] );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "before" tree wraparound' );

   $root->set_window( undef );
}

# Tree with unfocusable children
{
   my $tree1 = Tickit::Widget::HBox->new;
   $tree1->add( $_ ) for $f_widgets[0], $n_widgets[0];

   my $tree2 = Tickit::Widget::HBox->new;
   $tree2->add( $_ ) for $n_widgets[1], $n_widgets[2];

   my $tree3 = Tickit::Widget::HBox->new;
   $tree3->add( $_ ) for $f_widgets[1], $n_widgets[3];

   my $root = Tickit::Widget::HBox->new;
   $root->add( $_ ) for $tree1, $tree2, $tree3;

   $root->set_window( $win );

   $root->focus_next( first => undef );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "first" tree sparse' );

   $tree1->focus_next( after => $f_widgets[0] );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "after" tree sparse' );

   $tree2->focus_next( before => $f_widgets[1] );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus after "before" tree sparse' );

   $root->focus_next( last => undef );
   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after "last" tree sparse' );

   $root->set_window( undef );
}

# hidden children
{
   my $root = Tickit::Widget::HBox->new;
   $root->add( $_ ) for @f_widgets;

   $root->set_window( $win );

   # Cheating
   $f_widgets[1]->window->hide;

   $root->focus_next( after => $f_widgets[0] );
   ok( !$f_widgets[1]->window->is_focused, '$f_widgets[1] does not have focus after "after" skips it' );
   ok(  $f_widgets[2]->window->is_focused, '$f_widgets[2] has focus after "after" skipped [1]' );

   $root->set_window( undef );
}

# Special method
{
   my $root = Tickit::Widget::HBox->new;
   $root->add( $_ ) for @f_widgets;

   $root->set_window( $win );

   # More cheating
   no warnings 'once';
   local *Tickit::Widget::HBox::children_for_focus = sub {
      shift;
      return $f_widgets[1], $f_widgets[2];
   };

   $root->focus_next( first => undef );
   ok( !$f_widgets[0]->window->is_focused, '$f_widgets[0] does not have focus with special method return' );
   ok(  $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus with special method return' );

   $root->set_window( undef );
}

# Tab / Shift-Tab key handling
{
   my $container = Tickit::Widget::HBox->new;
   $container->set_window( $win );

   $container->add( $_ ) for $n_widgets[0], $f_widgets[0], $n_widgets[1], $f_widgets[1];

   $container->focus_next( first => undef );
   ok( $f_widgets[0]->window->is_focused, '$f_widgets[0] has focus before Tab' );

   presskey( key => "Tab" );

   ok( $f_widgets[1]->window->is_focused, '$f_widgets[1] has focus after Tab' );

   $container->set_window( undef );
}

done_testing;

package TestWidget;

use base qw( Tickit::Widget );
use constant WIDGET_PEN_FROM_STYLE => 1;

sub render_to_rb {}

sub lines { 1 }
sub cols  { 5 }

sub CAN_FOCUS { shift->{CAN_FOCUS} }

use constant KEYPRESSES_FROM_STYLE => 1;

package TestContainer;

use base qw( Tickit::Widget::HBox );

use constant WIDGET_PEN_FROM_STYLE => 1;

use Tickit::Style -copy;
BEGIN {
   style_definition ":focus-child" =>
      fg => 1;
}
