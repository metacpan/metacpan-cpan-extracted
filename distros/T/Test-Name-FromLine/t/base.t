use strict;
use warnings;
use Test::More;
use Test::Differences;
use Test::Name::FromLine;

sub x ($) { my $s = shift; $s =~ s{^\s+|\s+$}{}g; $s }
sub test_test (&) { # from Test::Test::More written by id:wakabatan
	my $code = shift;

	open my $file1, '>', \(my $s = '');
	open my $file2, '>', \(my $t = '');
	open my $file3, '>', \(my $u = '');

	{
		my $builder = Test::Builder->create;
		$builder->output($file1);
		$builder->failure_output($file2);
		$builder->todo_output($file3);
		no warnings 'redefine';
		local *Test::More::builder = sub { $builder };

		# For Test::Class
		my $diag = \&Test::Builder::diag;
		local *Test::Builder::diag = sub {
			shift;
			$diag->($builder, @_);
		};

		# For Test::Differences
		local *Test::Builder::new = sub { $builder };

		$code->();
	}

	close $file1;
	close $file2;
	close $file3;

	return { output => x $s, failure_output => x $t, todo_output => x $u };
}

eq_or_diff test_test {
	is 1, 1;
} -> {output}, x q{
ok 1 - L44: is 1, 1;
}, 'is 1, 1 => ok';

eq_or_diff test_test {
	is 1, 0;
} -> {failure_output}, x "
#   Failed test 'L50: is 1, 0;'
#   at $0 line 50.
#          got: '1'
#     expected: '0'
", 'is 1, 0 => ng';

eq_or_diff test_test {
	is 1, 1, 'name';
} -> {output}, x q{
ok 1 - L59: name
}, 'has name';

eq_or_diff test_test {
	ok 1;
} -> {output}, x q{
ok 1 - L65: ok 1;
}, 'ok 1';

eq_or_diff test_test {
	isnt 1, 0;
} -> {output}, x q{
ok 1 - L71: isnt 1, 0;
}, 'isnt';

done_testing;
