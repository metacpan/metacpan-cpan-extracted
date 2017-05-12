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

$widget->add_tab( Tickit::Widget::Static->new( text => "Widget $_ content" ), label => "label$_" ) for 1 .. 3;

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("label1",fg=>14,bg=>4), TEXT("]label2 label3",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Widget 1 content")] ],
            'Display initially' );

$widget->tab_position( "left" );

flush_tickit;

is_display( [ [TEXT("label1",fg=>14,bg=>4), TEXT(" >",fg=>7,bg=>4), TEXT("Widget 1 content")],
              [TEXT("label2  ",fg=>7,bg=>4)],
              [TEXT("label3  ",fg=>7,bg=>4)] ],
            'Display after ->tab_position change orientation' );

done_testing;
