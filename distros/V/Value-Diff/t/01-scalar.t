use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing scalar - no diff' => sub {
	ok !diff(0, 0), 'zero is equal to zero';
	ok !diff(1, 1), 'one is equal to one';
	ok !diff('', ''), 'empty string is equal to empty string';
	ok !diff('aoeu', 'aoeu'), 'string is equal to string';
};

subtest 'testing scalar - diff' => sub {
	my $out;

	ok diff(0, 1, \$out), 'zero is not equal to one';
	is $out, 0, 'diff ok';

	ok diff('aoeu', '', \$out), 'string is not equal to empty string';
	is $out, 'aoeu', 'diff ok';
};

done_testing;

