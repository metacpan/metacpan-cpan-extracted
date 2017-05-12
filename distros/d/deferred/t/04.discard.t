#!perl
use Test::More tests => 2;

use deferred "t::testload";
use t::testload;

BEGIN { ok !%t::testload:: }

no deferred -discard;

BEGIN { ok !%t::testload:: }

