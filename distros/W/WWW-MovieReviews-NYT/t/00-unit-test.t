#!perl

use 5.006;
use strict; use warnings;
use WWW::MovieReviews::NYT;
use Test::More tests => 1;

eval { WWW::MovieReviews::NYT->new(); };
like($@, qr/ERROR: API Key is missing./);
