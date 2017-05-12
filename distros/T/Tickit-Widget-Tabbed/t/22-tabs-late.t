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

flush_tickit;

is_display( [ [TEXT("",bg=>4)] ],
            'Display initially blank' );

$widget->add_tab( Tickit::Widget::Static->new( text => "Late widget" ), label => "Late tab" );

flush_tickit;

is_display( [ [TEXT("[",fg=>7,bg=>4), TEXT("Late tab",fg=>14,bg=>4), TEXT("]",fg=>7,bg=>4), TEXT("",bg=>4)],
              [TEXT("Late widget")] ],
            'Display after ->add_tab' );

done_testing;
