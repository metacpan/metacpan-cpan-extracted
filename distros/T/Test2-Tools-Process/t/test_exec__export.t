use Test2::V0 -no_srand => 1;
use Test::Exec;

imported_ok $_ for qw(
  exec_arrayref
);

done_testing;
