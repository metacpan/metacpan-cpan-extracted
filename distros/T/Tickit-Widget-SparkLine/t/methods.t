#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More tests => 9;
use Tickit::Test;

use Tickit::Widget::SparkLine;

my ($term, $win) = mk_term_and_window;
my $widget = new_ok('Tickit::Widget::SparkLine' => [
	data => [0, 1, 2, 3, 4],
]);
is_deeply([ $widget->data ],  [ 0, 1, 2, 3, 4], 'data is correct');
is($widget->pop, 4, 'pop returns correct value');
is_deeply([ $widget->data ],  [ 0, 1, 2, 3], 'data is correct');
is($widget->shift, 0, 'shift returns correct value');
is_deeply([ $widget->data ],  [ 1, 2, 3], 'data is correct');
$widget->unshift(4);
is_deeply([ $widget->data ],  [ 4, 1, 2, 3], 'data is correct after unshift');
$widget->push(7);
is_deeply([ $widget->data ],  [ 4, 1, 2, 3, 7], 'data is correct after push');
$widget->splice(1, 0, 6, 4, 2);
is_deeply([ $widget->data ],  [ 4, 6, 4, 2, 1, 2, 3, 7], 'data is correct after splice');

