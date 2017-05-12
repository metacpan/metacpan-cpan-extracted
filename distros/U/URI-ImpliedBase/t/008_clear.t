# -*- perl -*-

# t/008_clear.t - check that override and clear() work

use Test::More tests => 8;
use Cwd;

BEGIN { use_ok( 'URI::ImpliedBase' ); }

my $object = URI::ImpliedBase->new("./test");
is(URI::ImpliedBase->current_base,"file://".getcwd()."/test");
is($object->as_string, "file://".getcwd()."/test");

URI::ImpliedBase->clear();
is(URI::ImpliedBase->current_base,"");

$object=URI::ImpliedBase->new("./to_clobber");
$object = URI::ImpliedBase->new("../junk.html");
my @midpath = split /\//,getcwd;
pop @midpath;
my $midpath = join '/', @midpath;
is($object->as_string, "file://$midpath/junk.html");

is(URI::ImpliedBase->current_base,"file://".getcwd()."/to_clobber");

$object=URI::ImpliedBase->new("http://use.perl.org");
is(URI::ImpliedBase->current_base,"http://use.perl.org");
$object = URI::ImpliedBase->new("junk.html");
is($object->as_string, "http://use.perl.org/junk.html");

