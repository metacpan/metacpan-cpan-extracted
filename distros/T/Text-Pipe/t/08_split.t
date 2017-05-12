#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe 'PIPE';
use Test::More tests => 4;

my $pipe = PIPE 'Split';

is_deeply($pipe->filter('test'), [ qw(t e s t) ], 'split with defaults');

$pipe->pattern('s');
is_deeply($pipe->filter('test'), [ qw(te t) ], 'split along "s"');

$pipe->limit(1);
is_deeply($pipe->filter('asbscs'), [ qw(asbscs) ], 'split along "s", limit 1');

$pipe->limit(2);
is_deeply($pipe->filter('asbscs'), [ qw(a bscs) ], 'split along "s", limit 2');

