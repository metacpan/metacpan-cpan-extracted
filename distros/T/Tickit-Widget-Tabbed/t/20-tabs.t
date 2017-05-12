#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $win = mk_window;

my $widget = Tickit::Widget::Tabbed->new( tab_position => "top" );

my @tabs = map {
        $widget->add_tab( Tickit::Widget::Static->new( text => "Widget $_" ), label => "tab$_" )
} 0 .. 2;

is_oneref( $widget, '$widget still has refcount 1 after constructing tabs' );

is( $tabs[$_]->index, $_, "\$tabs[$_]->index" ) for 0 .. 2;

is( $widget->active_tab_index, 0, '$widget->active_tab_index initially' );

ok(  $tabs[0]->is_active, '$tabs[0] is active initially' );
ok( !$tabs[1]->is_active, '$tabs[1] is not active initially' );
ok( !$tabs[2]->is_active, '$tabs[2] is not active initially' );

identical( $widget->active_tab, $tabs[0], '$widget->active_tab is $tabs[0] initially' );

$widget->set_window( $win );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("tab0",fg=>14,bg=>4), TEXT("]tab1 tab2 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 0")] ],
            'Display initially' );

$widget->activate_tab( 1 );

is( $widget->active_tab_index, 1, '$widget->active_tab_index after ->activate_tab' );

ok( !$tabs[0]->is_active, '$tabs[0] is not active after ->activate_tab' );
ok(  $tabs[1]->is_active, '$tabs[1] is active after ->activate_tab' );
ok( !$tabs[2]->is_active, '$tabs[2] is not active after ->activate_tab' );

identical( $widget->active_tab, $tabs[1], '$widget->active_tab is $tabs[1] after ->activate_tab' );

flush_tickit;

is_display( [ [TEXT(" tab0[",fg=>7,bg=>4), TEXT("tab1",fg=>14,bg=>4), TEXT("]tab2 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 1")] ],
            'Display after ->activate_tab index' );

$widget->activate_tab( $tabs[2] );

flush_tickit;

is_display( [ [TEXT(" tab0 tab1[",fg=>7,bg=>4), TEXT("tab2",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 2")] ],
            'Display after ->activate_tab $tab' );

$widget->move_tab( 1, +1 );

is( $tabs[0]->index, 0, '$tabs[0]->index after ->move_tab +1' );
is( $tabs[1]->index, 2, '$tabs[1]->index after ->move_tab +1' );
is( $tabs[2]->index, 1, '$tabs[2]->index after ->move_tab +1' );

is( $widget->active_tab_index, 1, '$widget->active_tab_index after ->move_tab +1' );

ok( !$tabs[0]->is_active, '$tabs[0] is not active after ->move_tab +1' );
ok( !$tabs[1]->is_active, '$tabs[1] is not active after ->move_tab +1' );
ok(  $tabs[2]->is_active, '$tabs[2] is active after ->move_tab +1' );

flush_tickit;

is_display( [ [TEXT(" tab0[",fg=>7,bg=>4), TEXT("tab2",fg=>14,bg=>4), TEXT("]tab1 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 2")] ],
            'Display after ->move_tab +1' );

$widget->move_tab( 2, -1 );

is( $tabs[0]->index, 0, '$tabs[0]->index after ->move_tab -1' );
is( $tabs[1]->index, 1, '$tabs[1]->index after ->move_tab -1' );
is( $tabs[2]->index, 2, '$tabs[2]->index after ->move_tab -1' );

is( $widget->active_tab_index, 2, '$widget->active_tab_index after ->move_tab -1' );

ok( !$tabs[0]->is_active, '$tabs[0] is not active after ->move_tab -1' );
ok( !$tabs[1]->is_active, '$tabs[1] is not active after ->move_tab -1' );
ok(  $tabs[2]->is_active, '$tabs[2] is active after ->move_tab -1' );

flush_tickit;

is_display( [ [TEXT(" tab0 tab1[",fg=>7,bg=>4), TEXT("tab2",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 2")] ],
            'Display after ->move_tab -1' );

$widget->remove_tab( 1 );
splice @tabs, 1, 1, ();

is( $widget->active_tab_index, 1, '$widget->active_tab_index after ->remove' );

ok( !$tabs[0]->is_active, '$tabs[0] is not active after ->remove_tab' );
ok(  $tabs[1]->is_active, '$tabs[1] is active after ->remove_tab' );

identical( $widget->active_tab, $tabs[1], '$widget->active_tab is $tabs[1] after ->remove_tab' );

flush_tickit;

is_display( [ [TEXT(" tab0[",fg=>7,bg=>4), TEXT("tab2",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 2")] ],
            'Display after ->remove_tab index' );

# Removing active tab
{
        push @tabs, $widget->add_tab(
                Tickit::Widget::Static->new( text => "Widget 3" ),
                label => "tab3",
        );
        flush_tickit;

        $widget->remove_tab( 1 );
        splice @tabs, 1, 1, ();

        is( $widget->active_tab_index, 1, '$widget->active_tab_index after ->remove active' );

        ok( !$tabs[0]->is_active, '$tabs[0] is not active after ->remove_tab active' );
        ok(  $tabs[1]->is_active, '$tabs[1] is active after ->remove_tab active' );

        identical( $widget->active_tab, $tabs[1], '$widget->active_tab is $tabs[1] after ->remove_tab active' );

        flush_tickit;

        is_display( [ [TEXT(" tab0[",fg=>7,bg=>4), TEXT("tab3",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
                        [TEXT("Widget 3")] ],
                'Display after ->remove_tab active' );
}

$widget->set_window( undef );

is_oneref( $widget, '$widget still has refcount 1 before EOF' );

done_testing;
