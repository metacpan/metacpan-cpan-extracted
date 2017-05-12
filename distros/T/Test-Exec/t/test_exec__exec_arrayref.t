use Test2::Bundle::Extended;
use Test::Exec;

# this replaces t/basic.t

is exec_arrayref { exec 'foo', 'bar', 'baz' }, [qw(foo bar baz)], 'exec_arrayref with exec';
is exec_arrayref { eval { exec 'foo', 'bar', 'baz' } }, [qw(foo bar baz)], 'exec_arrayref with exec and eval';
is exec_arrayref { }, undef, 'exec_arrayref without exec';
is exec_arrayref { do_exec() }, [qw( bar baz )], 'indirect';

sub do_exec
{
  exec 'bar', 'baz';
}

done_testing;
