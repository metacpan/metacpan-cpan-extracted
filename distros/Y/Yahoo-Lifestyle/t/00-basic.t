#!/usr/bin/perl

use strict;
use Test::More tests => 3;

BEGIN { use_ok('Yahoo::Lifestyle'); }
ok($Yahoo::Lifestyle::VERSION) if $Yahoo::Lifestyle::VERSION or 1;
ok(my $life = Yahoo::Lifestyle->new({ appid => "Ea6oQPHIkY03GklWeauQHWPpPJByMjCDoxRxcW"}));
