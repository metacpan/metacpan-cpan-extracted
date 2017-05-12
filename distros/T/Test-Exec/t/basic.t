use strict;
use warnings;
use Test::More tests => 4;
use Test::Exec;

is_deeply exec_arrayref { exec 'foo', 'bar', 'baz' }, [qw(foo bar baz)], 'exec_arrayref with exec';
is_deeply exec_arrayref { eval { exec 'foo', 'bar', 'baz' } }, [qw(foo bar baz)], 'exec_arrayref with exec and eval';
is exec_arrayref { }, undef, 'exec_arrayref without exec';
is_deeply exec_arrayref { do_exec() }, [qw( bar baz )], 'indirect';

sub do_exec
{
  exec 'bar', 'baz';
}
