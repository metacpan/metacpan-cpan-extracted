#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use Text::Template::Inline;

my $data = [qw/ zero one two three /];

is render($data, '{2} {3}'),     'two three',     'basic templating';
is render($data, '{1} {3} {5}'), 'one three {5}', 'missing keys';
is render($data, '{1} {?} {1}'), 'one {?} one',   'ignore invalid';
is render($data, '{1} {02} {1}'), 'one two one',   'accept leading zeroes';
is render($data, '{{1}} { {2} }'), '{one} { two }', 'ignore out-of-place braces';
is eval('render $data => "{2} {3}"'), 'two three', 'syntactic sugar';

my $nested = [$data, $data, $data, $data];
my $nested2 = [$nested, $nested, $nested, $nested];

is render($nested, '{1.3} {3.0}'), 'three zero', 'basic key paths';
is render($nested2, '{1.3.0} {0.1.2}'), 'zero two', 'nested key paths';
is render($nested,'{1.5}'), '{1.5}', 'traversal to nonexistent';

# vi:filetype=perl ts=4 sts=4 et bs=2:
