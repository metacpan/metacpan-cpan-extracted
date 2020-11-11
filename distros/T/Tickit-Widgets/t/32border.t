#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Border;

my $win = mk_window;

my $static = Tickit::Widget::Static->new( text => "Widget" );

{
   my $widget = Tickit::Widget::Border->new;

   ok( defined $widget, 'defined $widget' );

   is( scalar $widget->children, 0, '$widget has 0 children' );

   $widget->set_child( $static );

   is( scalar $widget->children, 1, '$widget has 1 child after adding' );
   identical( $widget->child, $static, '$widget->child is $static' );

   is( $widget->lines, 1, '$widget->lines is 1' );
   is( $widget->cols,  6, '$widget->cols is 6' );

   $widget->set_window( $win );

   ok( defined $static->window, '$static has window after $widget->set_window' );

   flush_tickit;

   is_display( [ [TEXT("Widget")] ],
               'Display initially' );

   $widget->set_border( 2 );

   flush_tickit;

   is_display( [ BLANKLINES(2),
                 [BLANK(2), TEXT("Widget")] ],
               'Display after ->set_border' );

   $static->set_text( "New text" );

   flush_tickit;

   is_display( [ BLANKLINES(2),
                 [BLANK(2), TEXT("New text")] ],
              'Display after $static->set_text' );

   $widget->set_window( undef );

   ok( !defined $static->window, '$static has no window after ->set_window undef' );
}

$static->set_window( undef );
$static->set_text( "Widget" );

{
   my $widget = Tickit::Widget::Border->new;

   $widget->set_window( $win );

   flush_tickit;

   is_display( [ BLANKLINES(25) ],
               'Display blank before late adding of child' );

   $widget->set_child( $static );

   flush_tickit;

   is_display( [ [TEXT("Widget")] ],
               'Display after late adding of child' );

   $widget->set_window( undef );
}

done_testing;
