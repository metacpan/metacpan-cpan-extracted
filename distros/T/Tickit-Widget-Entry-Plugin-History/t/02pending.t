#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Entry;
use Tickit::Widget::Entry::Plugin::History;

my $win = mk_window;

my $entry = Tickit::Widget::Entry->new;

my @history;
Tickit::Widget::Entry::Plugin::History->apply( $entry,
   storage => \@history,
);

push @history, qw( one two three );

$entry->set_window( $win );

flush_tickit;

presskey text => $_ for qw( a b c d );
flush_tickit;

is_display( [ "abcd" ], 'Display after initial typing' );

presskey key => "Up";
flush_tickit;

is_display( [ "three" ],
   'Display after history replay' );

presskey key => "Down";
flush_tickit;

is_display( [ "abcd" ],
   'Display after history replay cancel' );

done_testing;
