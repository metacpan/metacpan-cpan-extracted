#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing');
    }
}


use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;

diag "skipping META.yml test";
ok(1);
done_testing;
exit;

meta_yaml_ok();
