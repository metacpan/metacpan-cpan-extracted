#!/usr/bin/env perl

use 5.006;
use strict; use warnings;
use WWW::Google::CustomSearch;
use Test::More tests => 1;

my ($api_key, $cx, $engine);
$api_key = 'Your_API_Key';
$cx      = 'Search_Engine_Identifier';
$engine  = WWW::Google::CustomSearch->new(api_key => $api_key, cx => $cx);

eval { $engine->search(); };
like($@, qr/ERROR: Missing query string/);
