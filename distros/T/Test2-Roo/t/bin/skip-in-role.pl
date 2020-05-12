use Test2::Roo;

use lib 't/lib/';

test 'just fail' => sub { ok(0) };

with 'Skipper';

run_me;
done_testing;
