#!perl
use Test::More tests => 5;

use deferred qr/^t::.*$/;
use t::testload;

ok !%t::testload::;
is 42, t::testload->foo;
ok %t::testload::;

BEGIN {
  eval { t::nonexistent->new };
  like $@, qr{Undefined subroutine/method called \(t::nonexistent::new};
}

use t::nonexistent;
eval { t::nonexistent->new };
like $@, qr{deferred load of t::nonexistent failed \(originally loaded at t/02.defer.t:\d+\)};

