#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use Tickit::Widget::VLine;

my ( $term, $win ) = mk_term_and_window;

my $widget = Tickit::Widget::VLine->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $win );

flush_tickit;

is_display( [ ( [BLANK(39), TEXT("│")] ) x 25 ],
            'Display initially' );

$widget->set_style( line_style => Tickit::RenderBuffer::LINE_DOUBLE );

flush_tickit;

is_display( [ ( [BLANK(39), TEXT("║")] ) x 25 ],
            'Display after ->set_style line_style' );

$widget->set_style( align => 0 );

flush_tickit;

is_display( [ ( [TEXT("║")] ) x 25 ],
            'Display after ->set_style align' );

$widget->set_style( align => "right" );

flush_tickit;

is_display( [ ( [BLANK(79), TEXT("║")] ) x 25 ],
            'Display after ->set_style align symbolic' );

done_testing;
