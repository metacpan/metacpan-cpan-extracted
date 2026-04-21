use strict;
use warnings;

use Test::Most;
use Test::Exception;

use Text::Names::Abbreviate qw(abbreviate);

# --------------------------------------------------
# Default format: all branches
# --------------------------------------------------
subtest 'default format full branch coverage' => sub {
	is(
		abbreviate('John Quincy Adams'),
		'J. Q. Adams',
		'normal default case'
	);

	is(
		abbreviate('John'),
		'John',
		'no initials branch'
	);

	is(
		abbreviate('John Quincy'),
		'J. Quincy',
		'single initial + last'
	);

	is(
		abbreviate('John Quincy', { style => 'last_first' }),
		'Quincy, J.',
		'last_first with one initial'
	);
};

# --------------------------------------------------
# initials format: all combinations
# --------------------------------------------------
subtest 'initials format coverage' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'initials' }),
		'J.Q.A.',
		'initials includes last name'
	);

	is(
		abbreviate('John', { format => 'initials' }),
		'J.',
		'single name initials'
	);

	is(
		abbreviate('John Quincy', { format => 'initials' }),
		'J.Q.',
		'two-part initials'
	);

	is(
		abbreviate(', John Quincy', { format => 'initials' }),
		'J.Q.',
		'leading comma removes last name'
	);
};

# --------------------------------------------------
# compact format: edge coverage
# --------------------------------------------------
subtest 'compact format coverage' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'compact' }),
		'JQA',
		'normal compact'
	);

	is(
		abbreviate('John', { format => 'compact' }),
		'J',
		'single name → no initials'
	);

	is(
		abbreviate('John Quincy', { format => 'compact' }),
		'JQ',
		'two-part compact'
	);

	is(
		abbreviate(', John Quincy', { format => 'compact' }),
		'JQ',
		'leading comma compact'
	);
};

# --------------------------------------------------
# shortlast: all branches
# --------------------------------------------------
subtest 'shortlast format coverage' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'shortlast' }),
		'J. Q. Adams',
		'normal shortlast'
	);

	is(
		abbreviate('John', { format => 'shortlast' }),
		'John',
		'no initials branch'
	);

	is(
		abbreviate(', John Quincy', { format => 'shortlast' }),
		'J. Q. ',
		'no last name but initials exist'
	);
};

# --------------------------------------------------
# last_first interactions (non-default formats)
# --------------------------------------------------
subtest 'last_first with non-default formats' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'initials', style => 'last_first' }),
		'A.J.Q.',
		'last initial moved to front'
	);

	is(
		abbreviate('John Quincy Adams', { format => 'compact', style => 'last_first' }),
		'AJQ',
		'compact last_first ordering'
	);
};

# --------------------------------------------------
# separator interactions across formats
# --------------------------------------------------
subtest 'separator interaction matrix' => sub {
	is(
		abbreviate('John Quincy Adams', { separator => ':' }),
		'J: Q: Adams',
		'default format custom separator'
	);

	is(
		abbreviate('John Quincy Adams', { format => 'shortlast', separator => ':' }),
		'J: Q: Adams',
		'shortlast custom separator'
	);

	is(
		abbreviate('John Quincy Adams', { format => 'initials', separator => ':' }),
		'J:Q:A:',
		'initials custom separator'
	);
};

# --------------------------------------------------
# normalization branches
# --------------------------------------------------
subtest 'comma normalization branches' => sub {
	is(
		abbreviate('Adams, John Quincy'),
		'J. Q. Adams',
		'normal comma case'
	);

	is(
		abbreviate('Adams,John Quincy'),
		'J. Q. Adams',
		'comma without space'
	);

	is(
		abbreviate('Adams , John Quincy'),
		'J. Q. Adams',
		'space before comma'
	);

	is(
		abbreviate('Adams ,John Quincy'),
		'J. Q. Adams',
		'space variations'
	);
};

# --------------------------------------------------
# rare normalization paths
# --------------------------------------------------
subtest 'normalization fallback branches' => sub {
	is(
		abbreviate('Adams,'),
		'Adams',
		'only last name survives'
	);

	is(
		abbreviate(',John'),
		'J.',
		'only rest survives'
	);
};

# --------------------------------------------------
# initials filtering (empty substr edge)
# --------------------------------------------------
subtest 'initial filtering edge cases' => sub {
	is(abbreviate('  J   Q   Adams  '), 'J. Q. Adams', 'handles already-initial-like input');

	is( abbreviate(' . . Adams'), '.. .. Adams', 'non-letter tokens treated literally as initials')
};

# --------------------------------------------------
# pathological combinations
# --------------------------------------------------
subtest 'format + style + separator combinations' => sub {
	is(
		abbreviate('John Quincy Adams', {
			format => 'initials',
			style => 'last_first',
			separator => '-'
		}),
		'A-J-Q-',
		'all options combined'
	);
};

# --------------------------------------------------
# stress test repeated calls (state safety)
# --------------------------------------------------
subtest 'statelessness' => sub {
	my $a = abbreviate('John Quincy Adams');
	my $b = abbreviate('John Quincy Adams', { format => 'compact' });
	my $c = abbreviate('John Quincy Adams');

	is($a, 'J. Q. Adams', 'first call correct');
	is($b, 'JQA', 'second call correct');
	is($c, 'J. Q. Adams', 'no state leakage');
};

# --------------------------------------------------
# boundary: minimal substr behavior
# --------------------------------------------------
subtest 'substr boundary behavior' => sub {
	is(abbreviate('A B C'), 'A. B. C', 'single-letter tokens');

	is(abbreviate('A B', { format => 'initials' }), 'A.B.', 'single letters initials format');
};

done_testing();
