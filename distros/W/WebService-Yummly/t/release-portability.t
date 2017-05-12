#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing');
    }
}

use Test::More;

ok(1);
diag ".travis.yml has two dots";
done_testing;
exit;


#eval "use Test::Portability::Files";
#plan skip_all => "Test::Portability::Files required for testing portability"
#  if $@;
#run_tests();

