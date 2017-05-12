#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $win = mk_window;

my $widget = Tickit::Widget::Tabbed->new( tab_position => "top" );

$widget->add_tab( Tickit::Widget::Static->new( text => "Widget $_" ), label => "tab$_" ) for 1 .. 3;

$widget->set_window( $win );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("tab1",fg=>14,bg=>4), TEXT("]tab2 tab3 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 1")] ],
            'Display initially' );

is( $widget->active_tab_index, 0, '->active_tab_index initially' );

presskey( key => "Right" );

flush_tickit;

is_display( [ [TEXT(" tab1[",fg=>7,bg=>4), TEXT("tab2",fg=>14,bg=>4), TEXT("]tab3 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 2")] ],
            'Display after Right key' );

is( $widget->active_tab_index, 1, '->active_tab_index after Right key' );

presskey( key => "C-PageDown" );

flush_tickit;

is_display( [ [TEXT(" tab1 tab2[",fg=>7,bg=>4), TEXT("tab3",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 3")] ],
            'Display after C-PageDown key' );

is( $widget->active_tab_index, 2, '->active_tab_index after C-PageDown key' );

presskey( key => "M-1" );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("tab1",fg=>14,bg=>4), TEXT("]tab2 tab3 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 1")] ],
            'Display after M-1 key' );

is( $widget->active_tab_index, 0, '->active_tab_index after M-1 key' );

pressmouse( press => 1, 0, 7 );

flush_tickit;

is_display( [ [TEXT(" tab1[",fg=>7,bg=>4), TEXT("tab2",fg=>14,bg=>4), TEXT("]tab3 ",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 2")] ],
            'Display after press mouse 1 @(0,7)' );

is( $widget->active_tab_index, 1, '->active_tab_index after press mouse 1 @(0,7)' );

done_testing;
