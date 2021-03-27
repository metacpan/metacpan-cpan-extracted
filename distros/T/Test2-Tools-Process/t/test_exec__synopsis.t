use strict;
use warnings;
use Test::More;
use Test::Exec;

is_deeply exec_arrayref { exec 'foo', 'bar', 'baz' }, [qw( foo bar baz )], 'found exec!';
is exec_arrayref { }, undef, 'did not exec!';

done_testing;
