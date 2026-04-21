#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use Text::Names::Abbreviate qw(abbreviate);

subtest 'basic functionality' => sub {
	is(abbreviate('John Quincy Adams'), 'J. Q. Adams', 'default format');
	is(abbreviate('John Adams'), 'J. Adams', 'first + last');
	is(abbreviate('Madonna'), 'Madonna', 'single name');
	done_testing();
};

subtest 'format => initials' => sub {
	is(abbreviate('John Quincy Adams', { format => 'initials' }), 'J.Q.A.', 'initials format');
	is(abbreviate('George R R Martin', { format => 'initials' }), 'G.R.R.M.', 'multiple initials');
	done_testing();
};

subtest 'format => compact' => sub {
	is(abbreviate('John Quincy Adams', { format => 'compact' }), 'JQA', 'compact format');
	is(abbreviate('George R R Martin', { format => 'compact' }), 'GRRM', 'compact multiple');
	done_testing();
};

subtest 'format => shortlast' => sub {
	is(abbreviate('John Quincy Adams', { format => 'shortlast' }), 'J. Q. Adams', 'shortlast standard');
	is(abbreviate('Madonna', { format => 'shortlast' }), 'Madonna', 'shortlast single name');
	done_testing();
};

subtest 'style handling' => sub {
	is(
		abbreviate('John Quincy Adams', { style => 'last_first' }),
		'Adams, J. Q.',
		'last_first style default format'
	);

	is(
		abbreviate('John Quincy Adams', { format => 'initials', style => 'last_first' }),
		'A.J.Q.',
		'last_first moves last initial first'
	);
	done_testing();
};

subtest 'separator handling' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'initials', separator => '-' }),
		'J-Q-A-',
		'custom separator'
	);

	is(
		abbreviate('John Quincy Adams', { separator => '' }),
		'J Q Adams',
		'empty separator in default format'
	);
	done_testing();
};

subtest 'comma normalization (internal branch)' => sub {
	is(
		abbreviate('Adams, John Quincy'),
		'J. Q. Adams',
		'last, first normalized'
	);

	is(
		abbreviate('Adams, John'),
		'J. Adams',
		'two-part comma name'
	);
	done_testing();
};

subtest 'leading comma edge case ($had_leading_comma)' => sub {
	is(
		abbreviate(', John Quincy'),
		'J. Q.',
		'leading comma drops last name'
	);

	is(
		abbreviate(', John', { format => 'initials' }),
		'J.',
		'leading comma initials only'
	);
	done_testing();
};

subtest 'whitespace normalization (internal behavior)' => sub {
	is(
		abbreviate('  John   Quincy   Adams  '),
		'J. Q. Adams',
		'extra whitespace normalized'
	);

	is(
		abbreviate("Adams,   John   Quincy  "),
		'J. Q. Adams',
		'whitespace with comma'
	);
	done_testing();
};

subtest 'initial extraction edge cases' => sub {
	is(
		abbreviate('J Q Adams'),
		'J. Q. Adams',
		'single-letter names preserved'
	);

	is(
		abbreviate('J. Q. Adams'),
		'J. Q. Adams',
		'pre-initialized input tolerated'
	);
	done_testing();
};

subtest 'empty and degenerate input paths' => sub {
	throws_ok(
		sub { abbreviate('') },
		qr/name/,
		'empty string rejected by validation'
	);

	is(
		abbreviate(' , '),
		'',
		'comma/whitespace normalizes to empty string'
	);
	done_testing();
};

subtest 'validation errors' => sub {
	throws_ok(
		sub { abbreviate(undef) },
		qr/name/,
		'undef name rejected'
	);

	throws_ok(
		sub { abbreviate('John', { format => 'invalid' }) },
		qr/format/,
		'invalid format rejected'
	);

	throws_ok(
		sub { abbreviate('John', { style => 'invalid' }) },
		qr/style/,
		'invalid style rejected'
	);
	done_testing();
};

subtest 'last_first with non-default formats (internal branch)' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'compact', style => 'last_first' }),
		'AJQ',
		'last initial moved to front in compact'
	);

	is(
		abbreviate('John Quincy Adams', { format => 'initials', style => 'last_first' }),
		'A.J.Q.',
		'last initial moved in initials'
	);
	done_testing();
};

done_testing();
