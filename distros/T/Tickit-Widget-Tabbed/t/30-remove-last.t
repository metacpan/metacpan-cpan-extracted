#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $win = mk_window;

my $widget = Tickit::Widget::Tabbed->new( tab_position => "top" );
$widget->set_window( $win );

$widget->add_tab( Tickit::Widget::Static->new( text => "Widget content" ), label => "label" );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("label",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4),TEXT("",bg=>4)],
              [TEXT("Widget content")] ],
            'Display initially' );

$widget->remove_tab( 0 );

flush_tickit;

is_display( [ [TEXT("",bg=>4)],
              [TEXT("")] ],
            'Display blanked after removing last tab' );

done_testing;
