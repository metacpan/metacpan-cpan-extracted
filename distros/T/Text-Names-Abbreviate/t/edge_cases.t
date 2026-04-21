use strict;
use warnings;

use Test::Most;
use utf8;

use Text::Names::Abbreviate qw(abbreviate);

subtest 'undef and missing input' => sub {
	throws_ok { abbreviate(undef) } qr/Usage|name/i, 'undef name croaks';
	throws_ok { abbreviate() } qr/name/i, 'missing args croaks';
};

subtest 'empty and whitespace-only input' => sub {
	throws_ok { abbreviate('') } qr/name/i, 'empty string croaks';

	is(abbreviate('   '), '', 'whitespace-only collapses to empty output');
};

subtest 'single token names' => sub {
	is(abbreviate('Madonna'), 'Madonna', 'single name unchanged');
	is(abbreviate('Prince'), 'Prince', 'single name unchanged (another case)');
};

subtest 'excessive whitespace normalization' => sub {
	is(
		abbreviate('  John   Quincy   Adams  '),
		'J. Q. Adams',
		'multiple spaces normalized'
	);

	is(
		abbreviate("John\tQuincy\nAdams"),
		'J. Q. Adams',
		'mixed whitespace normalized'
	);
};

subtest 'comma edge cases' => sub {
	is(
		abbreviate(', John Quincy'),
		'J. Q.',
		'leading comma produces initials only'
	);

	is(
		abbreviate('Adams,'),
		'Adams',
		'trailing comma with no given names'
	);

	is(
		abbreviate(','),
		'',
		'just comma returns empty string'
	);

	is(
		abbreviate(' ,  John   '),
		'J.',
		'comma with messy whitespace'
	);
};

subtest 'multiple commas (pathological)' => sub {
	is(
		abbreviate('Adams,, John'),
		'J. Adams',
		'extra commas handled reasonably'
	);

	is(
		abbreviate(',,John'),
		'J.',
		'multiple leading commas collapse'
	);
};

subtest 'separator edge cases' => sub {
	is(
		abbreviate('John Quincy Adams', { separator => '' }),
		'J Q Adams',
		'empty separator'
	);

	is(
		abbreviate('John Quincy Adams', { separator => '-' }),
		'J- Q- Adams',
		'non-standard separator'
	);

	is(
		abbreviate('John Quincy Adams', { format => 'initials', separator => '-' }),
		'J-Q-A-',
		'initials format with custom separator'
	);
};

subtest 'invalid enum values' => sub {
	throws_ok {
		abbreviate('John Adams', { format => 'nonsense' })
	} qr/format/i, 'invalid format croaks';

	throws_ok {
		abbreviate('John Adams', { style => 'sideways' })
	} qr/style/i, 'invalid style croaks';
};

subtest 'shortlast quirks' => sub {
	is(
		abbreviate('John', { format => 'shortlast' }),
		'John',
		'shortlast with single name'
	);

	is(
		abbreviate('John Quincy', { format => 'shortlast' }),
		'J. Quincy',
		'shortlast with two names'
	);
};

subtest 'lossy transformations' => sub {
	my $compact = abbreviate('George R R Martin', { format => 'compact' });
	is($compact, 'GRRM', 'compact works');

	is(
		abbreviate($compact, { format => 'initials' }),
		'G.',
		're-abbreviation is lossy'
	);
};

subtest 'unicode and non-ascii' => sub {
	is(
		abbreviate('Émile Zola'),
		'É. Zola',
		'unicode characters preserved'
	);

	is(
		abbreviate('李 小龙'),
		'李. 小龙',
		'non-latin script handled (best effort)'
	);
};

subtest 'non-alphabetic tokens' => sub {
	is(
		abbreviate('John Q. Adams'),
		'J. Q. Adams',
		'periods in input tolerated'
	);

	is(
		abbreviate('John 123 Adams'),
		'J. 1. Adams',
		'numeric tokens treated as initials'
	);
};

subtest 'last_first style edge cases' => sub {
	is(
		abbreviate('John Quincy Adams', { style => 'last_first' }),
		'Adams, J. Q.',
		'last_first normal case'
	);

	is(
		abbreviate('John', { style => 'last_first' }),
		'John',
		'last_first single name'
	);

	is(
		abbreviate(', John Quincy', { style => 'last_first' }),
		'J. Q.',
		'last_first ignored when no last name'
	);
};

subtest 'very long input' => sub {
	my $long = join(' ', ('Name') x 1000);

	ok(length(abbreviate($long)) > 0, 'handles very long names without crashing');
};

done_testing();
