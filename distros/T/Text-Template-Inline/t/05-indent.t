#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use Text::Template::Inline;

my $data = { qw/ zap pow whomp zoom bamf krak plop oomp / };

is render($data, q[
  {zap}
  {plop} {bamf}
  {whomp}
]), q[pow
oomp krak
zoom
], 'basic unindent';

is render($data, q[
    {zap}
      {plop} {bamf}
        {whomp}
]), q[pow
  oomp krak
    zoom
], 'relative unindent';

is render($data, q[
     {zap}
    {plop} {bamf}
    {whomp}
]), q[ pow
oomp krak
zoom
], 'relative unindent';

# vi:filetype=perl ts=4 sts=4 et bs=2:
