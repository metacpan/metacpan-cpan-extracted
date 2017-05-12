#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $win = mk_window;

my $widget = Tickit::Widget::Tabbed->new( tab_position => "top" );

my $tab = $widget->add_tab( Tickit::Widget::Static->new( text => "Widget" ), label => "tab" );

$widget->set_window( $win );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("tab",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget")] ],
            'Display initially' );

$tab->set_label( "newlabel" );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("newlabel",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget")] ],
            'Display after ->set_label' );

# Narrow rendering

$widget->set_window( undef );

my $subwin = $win->make_sub( 0, 0, 10, 30 );

$widget->add_tab( Tickit::Widget::Static->new( text => "Widget $_" ), label => "tab$_" ) for 1..10;

# Should be too narrow now

$widget->set_window( $subwin );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4),
               TEXT("newlabel",fg=>14,bg=>4),
               TEXT("]",fg=>7,bg=>4), 
               TEXT("tab1 tab2 tab3 ta",fg=>7,bg=>4),
               TEXT("..>",fg=>6,bg=>4),
               TEXT("",bg=>4)],
              [TEXT("Widget")] ],
            'Display with narrow truncation' );

$widget->activate_tab( 7 );

flush_tickit;

is_display( [ [TEXT("<..",fg=>6,bg=>4),
               TEXT("5 tab6[",fg=>7,bg=>4),
               TEXT("tab7",fg=>14,bg=>4), 
               TEXT("]tab8 tab9 tab10",fg=>7,bg=>4),
               TEXT("",bg=>4)],
              [TEXT("Widget 7")] ],
            'Display scrolls ribbon to active tab' );

done_testing;
