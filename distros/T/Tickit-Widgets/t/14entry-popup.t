#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Tickit::Test;

use Tickit::Widget::Entry;

my ( $term, $win ) = mk_term_and_window;

my $entry = Tickit::Widget::Entry->new;

$entry->set_text( "Text here" );
$entry->set_position( length $entry->text );

$entry->set_window( $win );
flush_tickit;

my $popup = $entry->make_popup_at_cursor( +1, 0, 3, 3 );
$popup->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   my $rb = $info->rb;

   $rb->text_at( 0, 0, "AAA" );
   $rb->text_at( 1, 0, "BBB" );
   $rb->text_at( 2, 0, "CCC" );
});

$popup->show;
flush_tickit;

is_display( [ [TEXT("Text here")],
              [BLANK(9), TEXT("AAA")],
              [BLANK(9), TEXT("BBB")],
              [BLANK(9), TEXT("CCC")] ],
            'Display with popup' );

is_cursorpos( 0, 9, 'Position with popup' );

done_testing;
