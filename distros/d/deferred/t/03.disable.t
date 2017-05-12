#!perl
use Test::More tests => 2;

use deferred "t::testload";
use t::testload;

BEGIN {
  ok !%t::testload::;
}

BEGIN {
  no deferred;
  ok %t::testload::;
}
