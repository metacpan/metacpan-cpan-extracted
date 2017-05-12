use Test::More;
plan skip_all => 'Set DEVEL_TESTS to run these tests'
     unless $ENV{DEVEL_TESTS};
eval "use Test::Prereq::Build";
plan skip_all => "Test::Prereq::Build required to test dependencies" if $@;
prereq_ok();
