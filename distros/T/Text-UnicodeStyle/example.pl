#!/usr/bin/env perl

use utf8;
use open ':std', ':encoding(UTF-8)';
use 5.010;
use strict;
use warnings;

use lib 'lib';
use Text::UnicodeStyle qw( stylize );

say stylize('route_id', 'monospace');
say stylize('route_short_name', 'monospace');
say stylize('mkdir folder_name', 'monospace');
say stylize('ABCXYZ',   'script');
say stylize('CHRNZ',    'doublestruck');
