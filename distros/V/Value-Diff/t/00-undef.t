use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing undef - no diff' => sub {
	ok !diff(undef, undef), 'undef is equal to undef';
};

subtest 'testing undef - diff' => sub {
	my $out;

	ok diff(undef, 0, \$out), 'undef is not equal to zero';
	is $out, undef, 'diff ok';

	ok diff(undef, '', \$out), 'undef is not equal to empty string';
	is $out, undef, 'diff ok';

	ok diff(0, undef, \$out), 'zero is not equal to undef';
	is $out, 0, 'diff ok';

	ok diff('', undef, \$out), 'empty string is not equal to undef';
	is $out, '', 'diff ok';

	ok diff(undef, !!1, \$out), 'undef is not equal to true';
	is $out, undef, 'diff ok';
};

done_testing;

