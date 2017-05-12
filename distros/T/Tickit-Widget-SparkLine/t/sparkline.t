#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use Test::Deep;
use Tickit::Test;

use Tickit::Widget::SparkLine;

binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my ($term, $win) = mk_term_and_window;

my $widget = new_ok('Tickit::Widget::SparkLine' => [
	data => [0, 1, 2, 3, 4],
]);
cmp_deeply([ $widget->data ],  [ 0, 1, 2, 3, 4], 'data is correct');
is($widget->lines, 1, '$widget->lines' );
$widget->set_window( $win );

flush_tickit();
