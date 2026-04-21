use strict;
use warnings;

use Test::Most;

use Text::Names::Abbreviate qw(abbreviate);

# Optional integrations (only run if available)
my $has_text_names   = eval { require Text::Names; 1 };
my $has_text_trim    = eval { require Text::Trim; 1 };

subtest 'end-to-end: format + style + separator combinations' => sub {
	my $name = 'John Quincy Adams';

	is(
		abbreviate($name, { format => 'initials', style => 'first_last', separator => '.' }),
		'J.Q.A.',
		'initials + default style'
	);

	is(
		abbreviate($name, { format => 'initials', style => 'last_first', separator => '.' }),
		'A.J.Q.',
		'initials + last_first'
	);

	is(
		abbreviate($name, { format => 'compact', style => 'last_first' }),
		'AJQ',
		'compact + last_first'
	);

	is(
		abbreviate($name, { format => 'shortlast', separator => '-' }),
		'J- Q- Adams',
		'shortlast + custom separator'
	);

	done_testing();
};

subtest 'stateful usage: repeated calls consistency' => sub {
	my $name = 'George R R Martin';

	my @results = map {
		abbreviate($name, { format => 'initials' })
	} (1..10);

	is_deeply(
		\@results,
		[ ('G.R.R.M.') x 10 ],
		'consistent output across repeated calls'
	);

	done_testing();
};

subtest 'stateful usage: varying options over time' => sub {
	my $name = 'John Quincy Adams';

	my @outputs;
	push @outputs, abbreviate($name);
	push @outputs, abbreviate($name, { format => 'initials' });
	push @outputs, abbreviate($name, { format => 'compact' });
	push @outputs, abbreviate($name, { style => 'last_first' });

	is_deeply(
		\@outputs,
		[
			'J. Q. Adams',
			'J.Q.A.',
			'JQA',
			'Adams, J. Q.',
		],
		'different configurations produce expected sequence'
	);

	done_testing();
};

subtest 'pipeline: normalize -> abbreviate -> reuse output' => sub {
	my $input = 'Adams, John Quincy';

	my $step1 = abbreviate($input); # normalize + default
	my $step2 = abbreviate($step1, { format => 'initials' });

	is($step1, 'J. Q. Adams', 'step1 normalized');
	is($step2, 'J.Q.A.', 'step2 reprocessed correctly');

	done_testing();
};

subtest 'pipeline: chaining formats (non-reversible transformations)' => sub {
	my $name = 'George R R Martin';

	my $a = abbreviate($name, { format => 'compact' });     # GRRM
	my $b = abbreviate($a, { format => 'initials' });       # G.

	is($a, 'GRRM', 'compact first');

	is(
		$b,
		'G.',
		'compact output is treated as a single name (non-reversible)'
	);

	done_testing();
};

subtest 'robustness: mixed realistic inputs' => sub {
	my @names = (
		'John Quincy Adams',
		'Adams, John Quincy',
		'  John   Quincy   Adams  ',
		'George R R Martin',
		'Madonna',
	);

	for my $n (@names) {
		my $out = abbreviate($n);

		ok(defined $out, "output defined for '$n'");
		ok($out ne '', "non-empty output for '$n'");
	}

	done_testing();
};

subtest 'no cross-call state leakage' => sub {
	my $a = abbreviate('John Quincy Adams', { format => 'initials' });
	my $b = abbreviate('Jane Doe');

	is($a, 'J.Q.A.', 'first call correct');
	is($b, 'J. Doe', 'second call unaffected by first');

	done_testing();
};

subtest 'integration with Text::Trim (if available)' => sub {
	plan skip_all => 'Text::Trim not installed' unless $has_text_trim;

	my $raw = "   John Quincy Adams   ";
	my $trimmed = Text::Trim::trim($raw);

	is(
		abbreviate($trimmed),
		'J. Q. Adams',
		'works correctly after trimming'
	);

	done_testing();
};

subtest 'integration with Text::Names (if available)' => sub {
	plan skip_all => 'Text::Names not installed' unless $has_text_names;

	# We don't assume deep API, just basic parsing
	my $name = 'John Quincy Adams';

	my $abbrev = abbreviate($name);

	ok(defined $abbrev, 'abbreviation produced');
	ok($abbrev =~ /Adams/, 'last name preserved');

	done_testing();
};

subtest 'batch processing scenario' => sub {
	my @input = (
		'John Quincy Adams',
		'George R R Martin',
		'Jane Doe',
	);

	my @output = map {
		abbreviate($_, { format => 'initials' })
	} @input;

	is_deeply(
		\@output,
		[
			'J.Q.A.',
			'G.R.R.M.',
			'J.D.',
		],
		'batch processing works correctly'
	);

	done_testing();
};

subtest 'separator persistence across multiple calls (no hidden state)' => sub {
	my $name = 'John Quincy Adams';

	my $a = abbreviate($name, { separator => '-' });
	my $b = abbreviate($name); # should NOT inherit '-'

	is($a, 'J- Q- Adams', 'custom separator applied');
	is($b, 'J. Q. Adams', 'default separator restored');

	done_testing();
};

subtest 'end-to-end realistic workflow' => sub {
	my @raw = (
		'Adams, John Quincy',
		'Martin, George R R',
		'Doe, Jane',
	);

	my @processed = map {
		abbreviate($_, { format => 'initials', style => 'last_first' })
	} @raw;

	is_deeply(
		\@processed,
		[
			'A.J.Q.',
			'M.G.R.R.',
			'D.J.',
		],
		'full workflow from raw input to formatted output'
	);

	done_testing();
};

done_testing();
