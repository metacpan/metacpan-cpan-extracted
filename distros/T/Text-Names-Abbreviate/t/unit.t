#!/usr/bin/env perl

use strict;
use warnings;

use POSIX qw(ENOENT);
use Readonly;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use Text::Names::Abbreviate qw(abbreviate);

# ---------------------------------------------------------------------------
# Named constants for all expected output strings and valid option values.
# Centralised here so that a single API change needs only one edit.
# ---------------------------------------------------------------------------
Readonly my $PKG        => 'Text::Names::Abbreviate';
Readonly my $FULL_NAME  => 'John Quincy Adams';
Readonly my $TWO_PART   => 'John Adams';
Readonly my $SINGLE     => 'Madonna';

# Format constants mirror the module's Readonly values (tested as strings here)
Readonly my @ALL_FORMATS => qw(default initials compact shortlast);
Readonly my @ALL_STYLES  => qw(first_last last_first);

# ===========================================================================
# SECTION 1 — POD SYNOPSIS examples
# The three examples in the SYNOPSIS are the canonical contract statements.
# Any change that breaks them is a breaking API change.
# ===========================================================================

subtest 'SYNOPSIS example 1: plain name default format' => sub {
	is(abbreviate($FULL_NAME), 'J. Q. Adams', 'POD example: J. Q. Adams');
	done_testing();
};

subtest 'SYNOPSIS example 2: Last, First form' => sub {
	is(abbreviate('Adams, John Quincy'), 'J. Q. Adams', 'POD example: Last, First reordered');
	done_testing();
};

subtest 'SYNOPSIS example 3: initials format with multiple middle names' => sub {
	is(
		abbreviate('George R R Martin', { format => 'initials' }),
		'G.R.R.M.',
		'POD example: G.R.R.M.',
	);
	done_testing();
};

# ===========================================================================
# SECTION 2 — Default format (J. Q. Adams)
# POD: "J. Q. Adams" — initials with default separator '.', then full last name.
# ===========================================================================

subtest 'default format: standard three-part name' => sub {
	is(abbreviate($FULL_NAME),     'J. Q. Adams', 'first+middle+last → J. Q. Adams');
	is(abbreviate($TWO_PART),      'J. Adams',    'first+last → J. Adams');
	is(abbreviate($SINGLE),        'Madonna',     'single name passed through unchanged');
	is(abbreviate('A B'),          'A. B',        'single-letter components handled');
	done_testing();
};

subtest 'default format: Last, First input form' => sub {
	is(abbreviate('Adams, John Quincy'),  'J. Q. Adams', 'standard Last, First input');
	is(abbreviate('Adams, John'),         'J. Adams',    'two-part Last, First');
	is(abbreviate('Adams,John Quincy'),   'J. Q. Adams', 'tight comma');
	is(abbreviate('Adams , John Quincy'), 'J. Q. Adams', 'space before comma');
	done_testing();
};

subtest 'default format: leading comma (no last name)' => sub {
	# A leading comma signals that there is no last-name component; every
	# token on the right side becomes an initial.
	is(abbreviate(', John Quincy'),  'J. Q.', 'leading comma: two initials');
	is(abbreviate(', John'),         'J.',    'leading comma: one initial');
	done_testing();
};

subtest 'default format: explicit first_last style matches default' => sub {
	is(
		abbreviate($FULL_NAME, { style => 'first_last' }),
		'J. Q. Adams',
		'explicit first_last is identical to omitting style',
	);
	done_testing();
};

subtest 'default format: last_first style' => sub {
	is(abbreviate($FULL_NAME, { style => 'last_first' }), 'Adams, J. Q.', 'three-part last_first');
	is(abbreviate($TWO_PART,  { style => 'last_first' }), 'Adams, J.',    'two-part last_first');
	is(abbreviate($SINGLE,    { style => 'last_first' }), 'Madonna',      'single name last_first unchanged');
	done_testing();
};

subtest 'default format: custom separator' => sub {
	is(abbreviate($FULL_NAME, { separator => ':' }),  'J: Q: Adams', 'colon separator');
	is(abbreviate($FULL_NAME, { separator => '' }),   'J Q Adams',   'empty separator removes punctuation');
	is(abbreviate($FULL_NAME, { separator => '-' }),  'J- Q- Adams', 'dash separator');
	done_testing();
};

# ===========================================================================
# SECTION 3 — Initials format (J.Q.A.)
# POD: "initials -- J.Q.A." — every name component reduced to its initial,
# joined with separator, with a trailing separator.
# ===========================================================================

subtest 'initials format: standard cases' => sub {
	is(abbreviate($FULL_NAME, { format => 'initials' }),         'J.Q.A.', 'three-part initials');
	is(abbreviate($TWO_PART,  { format => 'initials' }),         'J.A.',   'two-part initials');
	is(abbreviate($SINGLE,    { format => 'initials' }),         'M.',     'single name → initial + sep');
	done_testing();
};

subtest 'initials format: leading comma' => sub {
	is(abbreviate(', John Quincy', { format => 'initials' }), 'J.Q.', 'no last-name initial');
	is(abbreviate(', John',        { format => 'initials' }), 'J.',   'single initial');
	done_testing();
};

subtest 'initials format: last_first style moves last initial to front' => sub {
	# POD §style: "All formats honour this option."
	# For initials, last_first means Adams→A prepended; A.J.Q.
	is(
		abbreviate($FULL_NAME, { format => 'initials', style => 'last_first' }),
		'A.J.Q.',
		'last initial moved to front',
	);
	is(
		abbreviate($TWO_PART, { format => 'initials', style => 'last_first' }),
		'A.J.',
		'two-part last_first initials',
	);
	# Single name: _extract_parts reorder clears last_name; formatter sees
	# @initials=['M'], last_name='' → push skipped → result 'M.'
	is(
		abbreviate($SINGLE, { format => 'initials', style => 'last_first' }),
		'M.',
		'single name last_first initials: "M." (reorder clears last_name)',
	);
	done_testing();
};

subtest 'initials format: custom separator' => sub {
	is(abbreviate($FULL_NAME, { format => 'initials', separator => '-' }),         'J-Q-A-', 'dash separator');
	is(abbreviate($FULL_NAME, { format => 'initials', separator => '' }),          'JQA',    'empty separator');
	is(
		abbreviate($FULL_NAME, { format => 'initials', style => 'last_first', separator => '-' }),
		'A-J-Q-',
		'last_first + custom separator',
	);
	done_testing();
};

# ===========================================================================
# SECTION 4 — Compact format (JQA)
# POD: "compact -- JQA" — all initials concatenated, no separator.
# The separator option has no effect on compact output.
# ===========================================================================

subtest 'compact format: standard cases' => sub {
	is(abbreviate($FULL_NAME, { format => 'compact' }), 'JQA',  'three-part compact');
	is(abbreviate($TWO_PART,  { format => 'compact' }), 'JA',   'two-part compact');
	is(abbreviate($SINGLE,    { format => 'compact' }), 'M',    'single name compact');
	done_testing();
};

subtest 'compact format: leading comma' => sub {
	is(abbreviate(', John Quincy', { format => 'compact' }), 'JQ', 'leading comma compact');
	done_testing();
};

subtest 'compact format: last_first style' => sub {
	is(
		abbreviate($FULL_NAME, { format => 'compact', style => 'last_first' }),
		'AJQ',
		'compact last_first: last initial first',
	);
	is(
		abbreviate($TWO_PART, { format => 'compact', style => 'last_first' }),
		'AJ',
		'two-part compact last_first',
	);
	# Single name: _extract_parts reorder clears last_name; formatter sees
	# @initials=['M'], last_name='' → (length '' ? ... : ()) is empty → 'M'
	is(
		abbreviate($SINGLE, { format => 'compact', style => 'last_first' }),
		'M',
		'single name compact last_first: "M" (reorder clears last_name)',
	);
	done_testing();
};

subtest 'compact format: separator option is ignored' => sub {
	# compact joins with no separator regardless; the separator option must not
	# alter the output (this is not explicitly stated in POD but follows from
	# the format definition: compact = join('', @all_letters)).
	is(
		abbreviate($FULL_NAME, { format => 'compact', separator => '-' }),
		'JQA',
		'separator has no effect on compact',
	);
	done_testing();
};

# ===========================================================================
# SECTION 5 — Shortlast format
# POD: "shortlast -- initials then full last name; honours last_first style
# (e.g. Adams, J. Q.)."
# ===========================================================================

subtest 'shortlast format: standard cases' => sub {
	is(abbreviate($FULL_NAME, { format => 'shortlast' }), 'J. Q. Adams', 'three-part shortlast');
	is(abbreviate($TWO_PART,  { format => 'shortlast' }), 'J. Adams',    'two-part shortlast');
	is(abbreviate($SINGLE,    { format => 'shortlast' }), 'Madonna',     'single name: no initials, last name only');
	done_testing();
};

subtest 'shortlast format: leading comma (no last name)' => sub {
	# No last name means no trailing space; output is just the initials.
	is(abbreviate(', John Quincy', { format => 'shortlast' }), 'J. Q.', 'no trailing space after initials');
	is(abbreviate(', John',        { format => 'shortlast' }), 'J.',    'single initial, no trailing space');
	done_testing();
};

subtest 'shortlast format: last_first style' => sub {
	# POD example: "Adams, J. Q." — full last name first, then initials.
	is(
		abbreviate($FULL_NAME, { format => 'shortlast', style => 'last_first' }),
		'Adams, J. Q.',
		'three-part shortlast last_first',
	);
	is(
		abbreviate($TWO_PART, { format => 'shortlast', style => 'last_first' }),
		'Adams, J.',
		'two-part shortlast last_first',
	);
	is(
		abbreviate($SINGLE, { format => 'shortlast', style => 'last_first' }),
		'Madonna',
		'single name shortlast last_first unchanged',
	);
	done_testing();
};

subtest 'shortlast format: last_first with leading comma' => sub {
	# No last name even with last_first style: returns just the initials.
	is(
		abbreviate(', John', { format => 'shortlast', style => 'last_first' }),
		'J.',
		'leading comma last_first: initials only',
	);
	done_testing();
};

subtest 'shortlast format: custom separator' => sub {
	is(
		abbreviate($FULL_NAME, { format => 'shortlast', separator => ':' }),
		'J: Q: Adams',
		'colon separator in shortlast',
	);
	is(
		abbreviate($FULL_NAME, { format => 'shortlast', style => 'last_first', separator => ':' }),
		'Adams, J: Q:',
		'colon separator in shortlast last_first',
	);
	done_testing();
};

# ===========================================================================
# SECTION 6 — Input calling conventions
# Params::Get supports both positional string and hashref-only forms.
# ===========================================================================

subtest 'calling convention: positional string' => sub {
	is(abbreviate($FULL_NAME), 'J. Q. Adams', 'bare positional string');
	done_testing();
};

subtest 'calling convention: positional string + options hashref' => sub {
	is(
		abbreviate($FULL_NAME, { format => 'compact' }),
		'JQA',
		'string + hashref',
	);
	done_testing();
};

subtest 'calling convention: hashref only' => sub {
	is(
		abbreviate({ name => $FULL_NAME, format => 'compact' }),
		'JQA',
		'hashref-only with format',
	);
	is(
		abbreviate({ name => $TWO_PART }),
		'J. Adams',
		'hashref-only without options uses defaults',
	);
	done_testing();
};

# ===========================================================================
# SECTION 7 — Input normalization
# POD §name: whitespace, comma reordering, and consecutive comma collapse.
# ===========================================================================

subtest 'normalization: whitespace' => sub {
	is(abbreviate('  John   Quincy   Adams  '), 'J. Q. Adams', 'leading/trailing/internal whitespace');
	done_testing();
};

subtest 'normalization: comma form variations' => sub {
	is(abbreviate('Adams, John Quincy'),  'J. Q. Adams', 'standard comma spacing');
	is(abbreviate('Adams,John Quincy'),   'J. Q. Adams', 'no space after comma');
	is(abbreviate('Adams , John Quincy'), 'J. Q. Adams', 'space before comma');
	is(abbreviate('Adams ,John Quincy'),  'J. Q. Adams', 'asymmetric spacing');
	done_testing();
};

subtest 'normalization: consecutive commas collapse' => sub {
	# POD LIMITATIONS: "Multiple consecutive commas collapse to a single comma."
	is(abbreviate('Adams,,John Quincy'), 'J. Q. Adams', 'double comma collapses');
	done_testing();
};

subtest 'normalization: bare comma yields empty string' => sub {
	# POD §Returns: "Returns '' for inputs that normalise to nothing."
	is(abbreviate(' , '), '', 'whitespace-comma normalises to empty string');
	done_testing();
};

# ===========================================================================
# SECTION 8 — Separator option
# POD §separator: "String appended after each initial. Empty string removes
# all punctuation."
# ===========================================================================

subtest 'separator: empty string removes all punctuation' => sub {
	is(abbreviate($FULL_NAME, { separator => '' }),  'J Q Adams', 'empty sep: default format');
	is(abbreviate($FULL_NAME, { format => 'initials',  separator => '' }), 'JQA',       'empty sep: initials');
	is(abbreviate($FULL_NAME, { format => 'shortlast', separator => '' }), 'J Q Adams', 'empty sep: shortlast');
	done_testing();
};

subtest 'separator: applied consistently across all non-compact formats' => sub {
	for my $fmt (qw(default initials shortlast)) {
		lives_ok(
			sub { abbreviate($FULL_NAME, { format => $fmt, separator => '|' }) },
			"separator accepted for format=$fmt",
		);
	}
	done_testing();
};

# ===========================================================================
# SECTION 9 — Validation and error paths
# Tests the POD §MESSAGES table: exact error text is matched via pattern.
# ===========================================================================

subtest 'validation: undef name rejected' => sub {
	# POD MESSAGES row 1: "name parameter missing or undefined"
	throws_ok(
		sub { abbreviate(undef) },
		qr/name.*(?:required|defined|undefined)/i,
		'undef name: error mentions name/defined',
	);
	done_testing();
};

subtest 'validation: empty string rejected' => sub {
	# POD MESSAGES row 2: "name must be a non-empty string"
	throws_ok(
		sub { abbreviate('') },
		qr/name/i,
		'empty name: error mentions name',
	);
	done_testing();
};

subtest 'validation: no-argument call rejected' => sub {
	throws_ok(
		sub { abbreviate() },
		qr/name/i,
		'missing name: error mentions name',
	);
	done_testing();
};

subtest 'validation: invalid format rejected' => sub {
	# POD MESSAGES row 3: "format must be one of: ..."
	throws_ok(
		sub { abbreviate($FULL_NAME, { format => 'long' }) },
		qr/format/i,
		'invalid format: error mentions format',
	);
	done_testing();
};

subtest 'validation: invalid style rejected' => sub {
	# POD MESSAGES row 4: "style must be one of: ..."
	throws_ok(
		sub { abbreviate($FULL_NAME, { style => 'middle_first' }) },
		qr/style/i,
		'invalid style: error mentions style',
	);
	done_testing();
};

subtest 'validation: all documented format values accepted' => sub {
	for my $fmt (@ALL_FORMATS) {
		lives_ok(
			sub { abbreviate($FULL_NAME, { format => $fmt }) },
			"format '$fmt' is accepted",
		);
	}
	done_testing();
};

subtest 'validation: all documented style values accepted' => sub {
	for my $sty (@ALL_STYLES) {
		lives_ok(
			sub { abbreviate($FULL_NAME, { style => $sty }) },
			"style '$sty' is accepted",
		);
	}
	done_testing();
};

subtest 'validation: any separator string accepted (including empty)' => sub {
	lives_ok(sub { abbreviate($FULL_NAME, { separator => '.' })  }, 'period separator');
	lives_ok(sub { abbreviate($FULL_NAME, { separator => '' })   }, 'empty separator');
	lives_ok(sub { abbreviate($FULL_NAME, { separator => '::' }) }, 'multi-char separator');
	done_testing();
};

# ===========================================================================
# SECTION 10 — Exact error message via Test::Mockingbird
# Mock Carp::croak to capture the precise message string delivered for undef.
# This tests that the module reaches the explicit defined() guard and uses it.
# ===========================================================================

subtest 'undef name: exact croak message captured via mock' => sub {
	my @croak_calls;
	my $g = mock_scoped 'Carp::croak' => sub {
		push @croak_calls, [@_];
		die @_;	# propagate so throws_ok still catches something
	};

	eval { abbreviate(undef) };	# suppress die for assertion

	is(scalar @croak_calls, 1, 'Carp::croak called exactly once');
	like(
		$croak_calls[0][0],
		qr/\Q${PKG}\E.*name.*required.*defined/i,
		'croak message identifies package, "name", and "defined"',
	);

	diag("croak message: $croak_calls[0][0]") if $ENV{TEST_VERBOSE};
	done_testing();
};

# ===========================================================================
# SECTION 11 — POD §LIMITATIONS: documented edge-case behaviors
# The LIMITATIONS section describes accepted non-ideal behaviors that callers
# must account for. Tests confirm the documented behavior is stable.
# ===========================================================================

subtest 'LIMITATION: honorifics treated as name components' => sub {
	# POD: "Honorifics (Dr., Prof.) and suffixes (Jr., III) are not
	# detected or stripped; they are treated as name components."
	is(abbreviate('Dr. John Adams'),  'D. J. Adams', 'Dr. becomes initial D.');
	is(abbreviate('John Adams Jr.'),  'J. A. Jr.',   'Jr. treated as last name');
	done_testing();
};

subtest 'LIMITATION: non-alphabetic leading characters become initials verbatim' => sub {
	# POD: "Non-alphabetic leading characters (digits, punctuation) are
	# included as-is."
	is(abbreviate('1st John Adams'),  '1. J. Adams', 'digit initial preserved');
	is(abbreviate('.John Adams'),     '.. Adams',    'dot initial preserved');
	done_testing();
};

subtest 'LIMITATION: compact and initials are lossy (POD statement)' => sub {
	# POD: "compact and initials formats are lossy: passing their output back
	# into abbreviate does not reproduce the original result."
	my $compact  = abbreviate($FULL_NAME, { format => 'compact' });
	my $initials = abbreviate($FULL_NAME, { format => 'initials' });

	isnt(abbreviate($compact),  'J. Q. Adams', 'compact output does not round-trip');
	isnt(abbreviate($initials), 'J. Q. Adams', 'initials output does not round-trip');
	done_testing();
};

# ===========================================================================
# SECTION 12 — Return value schema (Test::Returns)
# POD §Returns: "A plain string." — every valid call must produce a scalar
# string. Never a reference, never undef.
# ===========================================================================

subtest 'return value: always a plain string across all formats and styles' => sub {
	my @cases = (
		[ abbreviate($FULL_NAME),                                                    'default'            ],
		[ abbreviate($FULL_NAME, { format => 'initials' }),                          'initials'           ],
		[ abbreviate($FULL_NAME, { format => 'compact' }),                           'compact'            ],
		[ abbreviate($FULL_NAME, { format => 'shortlast' }),                         'shortlast'          ],
		[ abbreviate($FULL_NAME, { style  => 'last_first' }),                        'last_first'         ],
		[ abbreviate($FULL_NAME, { format => 'initials',  style => 'last_first' }),  'initials/last_first'],
		[ abbreviate($FULL_NAME, { format => 'compact',   style => 'last_first' }),  'compact/last_first' ],
		[ abbreviate($FULL_NAME, { format => 'shortlast', style => 'last_first' }),  'shortlast/last_first'],
		[ abbreviate($SINGLE),                                                        'single name'        ],
		[ abbreviate(' , '),                                                          'empty normalisation' ],
		[ abbreviate(', John Quincy'),                                                'leading comma'      ],
	);

	for my $pair (@cases) {
		my ($result, $desc) = @{$pair};
		returns_ok($result, { type => 'string' }, "string returned for: $desc");
		diag("  $desc => '$result'") if $ENV{TEST_VERBOSE};
	}

	done_testing();
};

# ===========================================================================
# SECTION 13 — Global state integrity
# POD §Side Effects: "None. The function is purely functional with no
# persistent state." This section operationalises that guarantee.
# ===========================================================================

subtest 'global state: $_ not clobbered' => sub {
	local $_ = 'sentinel';
	abbreviate($FULL_NAME);
	is($_, 'sentinel', 'abbreviate does not modify $_');
	done_testing();
};

subtest 'global state: $@ not clobbered after successful call' => sub {
	# If the caller just handled an exception, abbreviate must not silently
	# reset $@ and cause the caller to miss its own error.
	eval { die "caller error\n" };
	my $saved = $@;
	abbreviate($FULL_NAME);
	is($@, $saved, 'abbreviate does not reset $@ on success');
	done_testing();
};

subtest 'global state: $! (errno) not clobbered' => sub {
	# A caller may have set $! to track a system error; abbreviate must leave it intact.
	local $! = ENOENT;
	my $saved = "$!";
	abbreviate($FULL_NAME);
	is("$!", $saved, 'abbreviate does not modify $!');
	done_testing();
};

subtest 'global state: alarm not cancelled by abbreviate' => sub {
	# abbreviate must not call alarm(0) or otherwise disturb a pending timer.
	# alarm() is not reliably implemented on Windows Perl (no native SIGALRM):
	# alarm(60) is a silent no-op there, so alarm(0) always reports 0 remaining
	# regardless of what abbreviate does.  Skip on that platform; this is a
	# test-portability limitation, not something abbreviate can be blamed for.
	plan skip_all => 'alarm() is not reliably supported on Windows Perl'
		if $^O eq 'MSWin32';

	local $SIG{ALRM} = sub { die "ALRM\n" };    # safety net in case timer fires
	alarm(60);
	abbreviate($FULL_NAME);
	my $remaining = alarm(0);    # cancel and retrieve remaining time
	cmp_ok($remaining, '>', 0, 'alarm still pending after abbreviate');
	done_testing();
};

subtest 'global state: stateless across repeated calls' => sub {
	# Confirms no mutable module-level state bleeds between invocations.
	my $r1 = abbreviate($FULL_NAME);
	abbreviate($FULL_NAME, { format => 'compact' });
	my $r3 = abbreviate($FULL_NAME);
	is($r1, $r3, 'identical inputs yield identical outputs before and after unrelated call');
	done_testing();
};

done_testing();
