#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Text::Names::Abbreviate qw(abbreviate);

subtest 'default format (POD examples and expected behavior)' => sub {
	is(
		abbreviate('John Quincy Adams'),
		'J. Q. Adams',
		'default format standard name'
	);

	is(
		abbreviate('Adams, John Quincy'),
		'J. Q. Adams',
		'default format supports last, first input'
	);

	done_testing();
};

subtest 'format => initials' => sub {
	is(
		abbreviate('George R R Martin', { format => 'initials' }),
		'G.R.R.M.',
		'initials format from POD'
	);

	is(
		abbreviate('John Adams', { format => 'initials' }),
		'J.A.',
		'two-part name initials'
	);

	done_testing();
};

subtest 'format => compact' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'compact' }),
		'JQA',
		'compact format'
	);

	is(
		abbreviate('John Adams', { format => 'compact' }),
		'JA',
		'compact short name'
	);

	done_testing();
};

subtest 'format => shortlast' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'shortlast' }),
		'J. Q. Adams',
		'shortlast format'
	);

	is(
		abbreviate('John Adams', { format => 'shortlast' }),
		'J. Adams',
		'shortlast minimal case'
	);

	done_testing();
};

subtest 'style => first_last (default)' => sub {
	is(
		abbreviate('John Quincy Adams', { style => 'first_last' }),
		'J. Q. Adams',
		'first_last explicit matches default'
	);

	done_testing();
};

subtest 'style => last_first' => sub {
	is(
		abbreviate('John Quincy Adams', { style => 'last_first' }),
		'Adams, J. Q.',
		'last_first style'
	);

	done_testing();
};

subtest 'separator option' => sub {
	is(
		abbreviate('John Quincy Adams', { format => 'initials', separator => '-' }),
		'J-Q-A-',
		'custom separator applied'
	);

	is(
		abbreviate('John Quincy Adams', { separator => '' }),
		'J Q Adams',
		'empty separator removes punctuation'
	);

	done_testing();
};

subtest 'single-name input' => sub {
	is(
		abbreviate('Madonna'),
		'Madonna',
		'single name unchanged'
	);

	is(
		abbreviate('Madonna', { format => 'initials' }),
		'M.',
		'single name initials'
	);

	done_testing();
};

subtest 'minimal valid input' => sub {
	is(
		abbreviate('A B'),
		'A. B',
		'two single-letter names'
	);

	done_testing();
};

subtest 'validation: required parameter' => sub {
	throws_ok(
		sub { abbreviate() },
		qr/name/,
		'missing name parameter'
	);

	throws_ok(
		sub { abbreviate(undef) },
		qr/name/,
		'undef name rejected'
	);

	done_testing();
};

subtest 'validation: format values' => sub {
	for my $format (qw(default initials compact shortlast)) {
		lives_ok(
			sub { abbreviate('John Adams', { format => $format }) },
			"valid format '$format'"
		);
	}

	throws_ok(
		sub { abbreviate('John Adams', { format => 'invalid' }) },
		qr/format/,
		'invalid format rejected'
	);

	done_testing();
};

subtest 'validation: style values' => sub {
	for my $style (qw(first_last last_first)) {
		lives_ok(
			sub { abbreviate('John Adams', { style => $style }) },
			"valid style '$style'"
		);
	}

	throws_ok(
		sub { abbreviate('John Adams', { style => 'invalid' }) },
		qr/style/,
		'invalid style rejected'
	);

	done_testing();
};

subtest 'validation: separator type' => sub {
	lives_ok(
		sub { abbreviate('John Adams', { separator => '.' }) },
		'valid separator'
	);

	lives_ok(
		sub { abbreviate('John Adams', { separator => '' }) },
		'empty separator allowed'
	);

	done_testing();
};

done_testing();
