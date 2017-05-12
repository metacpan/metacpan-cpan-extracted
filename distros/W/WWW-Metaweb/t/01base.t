#!/usr/bin/perl

use strict;
use Test::Simple tests => 2;

use WWW::Metaweb;

ok(1, 'module loaded okay');

ok(WWW::Metaweb->version, 'version is non-zero');

exit;
