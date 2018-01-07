use Test::More;
eval "use Test::Vars";
plan skip_all => 'Test::Vars required for testing for unused vars' if $@;
vars_ok('lib/WebService/Coincheck.pm');
done_testing;
