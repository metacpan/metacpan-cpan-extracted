# -*- perl -*-

# t/003_set_base.t - check that base is actually getting set

use Test::More tests => 3;

BEGIN { use_ok( 'URI::ImpliedBase' ); }

my $object = URI::ImpliedBase->new("http://blah.foo.com");
is(URI::ImpliedBase->current_base, "http://blah.foo.com");

$object = URI::ImpliedBase->new("http://bar.baz.com/test");
is(URI::ImpliedBase->current_base, "http://bar.baz.com/test");
