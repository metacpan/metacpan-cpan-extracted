#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $widget = Tickit::Widget::Tabbed->new( tab_position => "top" );

my @tabs = map {
        $widget->add_tab( Tickit::Widget::Static->new( text => "Widget $_" ), label => "tab$_" )
} 0 .. 2;

my $activated_self;
my $activated = 0;
$tabs[1]->set_on_activated( sub {
        ( $activated_self ) = @_;
        $activated++
} );

is( $activated, 0, '$activated initially' );

$widget->activate_tab( 1 );

is( $activated, 1, '$activated after ->activate_tab' );
identical( $activated_self, $tabs[1], '$activate_self' );

$widget->activate_tab( 0 );

is( $activated, 1, '$activated unchanged after ->activate_tab on a different tab' );

my $deactivated = 0;
$tabs[0]->set_on_deactivated( sub { $deactivated++ } );

$widget->activate_tab( 1 );

is( $deactivated, 1, '$deactivated after ->activate_tab elsewhere' );

done_testing;
