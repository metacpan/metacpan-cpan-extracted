use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing scalar ref - no diff' => sub {
	ok !diff(\undef, \undef), 'undef ref is equal to undef ref';
	ok !diff(\'str', \'str'), 'string ref is equal to string ref';

	ok !diff(\\\'str', \\\'str'), 'deep nested ok';
};

subtest 'testing scalar ref - diff' => sub {
	my $out;

	ok diff(\undef, \'str', \$out), 'undef ref is not equal to string ref';
	is_deeply $$out, undef, 'diff ok';
	ok diff(\'str', \undef, \$out), 'string ref is not equal to undef ref';
	is_deeply $$out, 'str', 'diff ok';

	ok diff(\\\'str', \\'str', \$out), 'deep nested ok';
	is_deeply $$$$out, 'str', 'diff ok';
};

done_testing;

