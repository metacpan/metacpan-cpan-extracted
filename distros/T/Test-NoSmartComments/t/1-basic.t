use strict;
use warnings;

use Test::Builder::Tester tests => 3;
use Test::More;

use Test::NoSmartComments;

use FindBin;
use File::chdir;
#use lib "$FileBin::Bin/lib";



#$CWD = "$FindBin::Bin";
chdir "$FindBin::Bin/test";

test_out('ok 1 - lib/Dumb.pm w/o Smart::Comments');
no_smart_comments_in "lib/Dumb.pm";
test_test 'Cleared Dumb';


test_out 'not ok 1 - lib/Smart.pm w/o Smart::Comments';
test_fail(+1);
no_smart_comments_in "lib/Smart.pm";
test_test 'Caught Smart';

test_out('ok 1 - lib/Dumb.pm w/o Smart::Comments');
test_out('not ok 2 - lib/Smart.pm w/o Smart::Comments');
test_fail(+1);
no_smart_comments_in_all;
test_test 'correctly scanned all';

#done_testing;
