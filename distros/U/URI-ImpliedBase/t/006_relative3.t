# -*- perl -*-

# t/006_relative3.t - check that base gets set for relative path firstr

use Test::More tests => 3;
use Cwd;

BEGIN { use_ok( 'URI::ImpliedBase' ); }

my $object = URI::ImpliedBase->new("test");
is(URI::ImpliedBase->current_base,"file://".getcwd()."/test");
is($object->as_string, "file://".getcwd()."/test");


