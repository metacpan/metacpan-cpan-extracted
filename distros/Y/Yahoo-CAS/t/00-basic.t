#!/usr/bin/perl

use strict;
use Test::More tests => 3;

BEGIN { use_ok('Yahoo::CAS'); }
ok($Yahoo::CAS::VERSION) if $Yahoo::CAS::VERSION or 1;
ok(my $cas = Yahoo::CAS->new({ appid => "Ea6oQPHIkY03GklWeauQHWPpPJByMjCDoxRxcW"}));
