#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

my $data = { qw/ zap pow whomp zoom bamf krak plop oomp / };

use Text::Template::Inline 'summarize';
is summarize($data, '{zap} {bamf}'), 'pow krak', 'change function name';

use Text::Template::Inline 'fixup';
is fixup($data, '{zap} {bamf}'), 'pow krak', 'again';
lives_ok sub { eval 'fixup $data => "{zap} {bamf}"' }, 'syntactic sugar';
is summarize($data, '{zap} {bamf}'), 'pow krak', 'first one still there';

dies_ok sub { render($data, '{zap} {bamf}') }, 'default not imported';

# vi:filetype=perl ts=4 sts=4 et bs=2:
