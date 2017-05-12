use Test::Harness qw( runtests );
use FindBin;

use lib ".test/lib/";

use XML::Comma;

my $dir = $FindBin::Bin;
chdir $dir;

print "--- unit tests from t/ directory --- \n";
runtests (
't/aaa_test_setup.t',
't/bootstrap.t',
't/collection.t',
't/decorator.t', 
't/document_hooks.t',
't/index_only.t',
't/indexing.t',
't/introspection.t',
't/multi_store_doctype.t',
't/order.t',
't/par_def.t',
't/parser.t',
't/read_only.t',
't/storage.t',
't/timestamp.t',
't/util.t',
't/validation.t',
't/virtual_element.t',
't/zzz_test_cleanup.t',

);
print "---\n\n";



#  print "--- story functional tests -- \n";
#   runtests qw( functional_test/story-test.pl );
#  print "---\n\n";



