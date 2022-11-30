use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing return values' => sub {
	my $ret;

	$ret = diff('a', 'a');
	is $ret, !!0, 'false value is really false';

	$ret = diff('a', 'b');
	is $ret, !!1, 'true value is really true';
};

subtest 'testing empty values' => sub {
	my $out;

	diff('test', 'test', \$out);
	is_deeply $out, undef, 'empty ok';

	diff({a => 'test'}, {a => 'test'}, \$out);
	is_deeply $out, {}, 'empty hash ok';

	diff(['test'], ['test'], \$out);
	is_deeply $out, [], 'empty array ok';

	diff(\'test', \'test', \$out);
	is $$out, undef, 'empty scalar ok';

	diff(\\'test', \\'test', \$out);
	is $$out, undef, 'empty ref ok';
};

done_testing;

