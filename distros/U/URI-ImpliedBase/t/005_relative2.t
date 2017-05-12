# -*- perl -*-

# t/005_relative2.t - check that we set the base from the cwd

use Test::More tests => 3;
use Cwd;

BEGIN { use_ok( 'URI::ImpliedBase' ); }

my $object = URI::ImpliedBase->new("./test");

is(URI::ImpliedBase->current_base,"file://".getcwd()."/test");
is($object->as_string, "file://".getcwd()."/test");
