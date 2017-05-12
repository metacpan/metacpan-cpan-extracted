# -*- perl -*-

# t/004_relative1.t - check that existing base is used for relative

use Test::More tests => 3;

BEGIN { use_ok( 'URI::ImpliedBase' ); }

my $object = URI::ImpliedBase->new("http://blah.foo.com");
is(URI::ImpliedBase->current_base, "http://blah.foo.com");

$object = URI::ImpliedBase->new("subdir/one");
is($object->as_string, "http://blah.foo.com/subdir/one");
