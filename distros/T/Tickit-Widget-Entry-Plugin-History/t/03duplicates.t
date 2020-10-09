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
   ignore_duplicates => 1,
);

push @history, qw( one two three );

$entry->set_window( $win );

flush_tickit;

presskey text => $_ for qw( t h r e e );
presskey key => "Enter";
flush_tickit;

is_deeply( \@history, [qw( one two three )],
   'ignore_duplicates supresses duplicate entry' );

done_testing;
