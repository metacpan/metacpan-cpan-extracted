use Test::Routine;
use Test::Routine::Util;
use Test::More;

test "this isn't any problem"  => sub { pass };
test "we are testing My::Code" => sub { pass };

run_me;
done_testing;
