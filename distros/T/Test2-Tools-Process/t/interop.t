use Test2::V0 -no_srand => 1;
use Test2::Tools::Process;
use Test::Exec;

is exec_arrayref { exec 'foo','bar','baz' }, [qw( foo bar baz )], 'use Test::Exec';

process {
  exec 'foo','bar','baz';
} [
  proc_event exec => ['foo','bar','baz'],
];

done_testing;
