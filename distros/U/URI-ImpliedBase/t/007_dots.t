# -*- perl -*-

# t/006_relative3.t - check that dot and dot-dot work

use Test::More tests => 5;
use Cwd;

BEGIN { use_ok( 'URI::ImpliedBase' ); }

my $object = URI::ImpliedBase->new("./test");
is(URI::ImpliedBase->current_base,"file://".getcwd()."/test");
is($object->as_string, "file://".getcwd()."/test");

$object = URI::ImpliedBase->new("../junk.html");
my @midpath = split /\//,getcwd;
pop @midpath;
my $midpath = join '/', @midpath;
is($object->as_string, "file://$midpath/junk.html");

is(URI::ImpliedBase->current_base,"file://".getcwd()."/test");
