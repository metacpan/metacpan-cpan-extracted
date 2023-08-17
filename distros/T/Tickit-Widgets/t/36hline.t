#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use Tickit::Widget::HLine;

my ( $term, $win ) = mk_term_and_window;

my $widget = Tickit::Widget::HLine->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $win );

flush_tickit;

is_display( [ BLANKLINES(12), [TEXT("─"x80) ] ],
            'Display initially' );

$widget->set_style( line_style => Tickit::RenderBuffer::LINE_DOUBLE );

flush_tickit;

is_display( [ BLANKLINES(12), [TEXT("═"x80) ] ],
            'Display after ->set_style line_style' );

$widget->set_style( valign => 0 );

flush_tickit;

is_display( [ BLANKLINES(0), [TEXT("═"x80) ] ],
            'Display after ->set_style valign' );

$widget->set_style( valign => "bottom" );

flush_tickit;

is_display( [ BLANKLINES(24), [TEXT("═"x80) ] ],
            'Display after ->set_style valign symbolic' );

done_testing;
