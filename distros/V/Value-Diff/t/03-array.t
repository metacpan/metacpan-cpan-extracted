use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing array - no diff' => sub {
	ok !diff([], []), 'empty array is equal to empty array';
	ok !diff([undef], [undef]), 'array with one element is equal to array with one element';
	ok !diff([undef, 1], [undef, 1]), 'array with two elements is equal to array with two elements (same order)';
	ok !diff([1, undef], [undef, 1]),
		'array with two elements is equal to array with two elements (different order)';
	ok !diff([1, undef], [undef, 1, 2]), 'there is no diff if second array has extra elements';

	ok !diff([['three'], [['two', 'one']], 'zero'], ['zero', [['one', 'two']], ['three']]), 'deep nested ok';
};

subtest 'testing array - diff' => sub {
	my $out;

	ok diff([1], [], \$out), 'array with one element is not equal to empty array';
	is_deeply $out, [1], 'diff ok';

	ok diff([undef, 1], [undef], \$out), 'arrays differ when first array has extra elements';
	is_deeply $out, [1], 'diff ok';

	ok diff(['abc', 1], ['def', 1, undef], \$out),
		'arrays differ when element from first array has is not found in the second array';
	is_deeply $out, ['abc'], 'diff ok';

	ok diff(['abc', 'abc', 'abc'], ['abc'], \$out), 'arrays differ when not all elements are matched';
	is_deeply $out, ['abc', 'abc'], 'diff ok';

	ok diff([['three'], [['two', 'one']], 'zero'], ['zero', [['one']], ['three']], \$out), 'deep nested ok';
	is_deeply $out, [[['two', 'one']]], 'diff ok';    # TODO: should ideally be just 'two'
};

done_testing;

