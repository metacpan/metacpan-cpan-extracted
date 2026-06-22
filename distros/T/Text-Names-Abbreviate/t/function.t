#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use Text::Names::Abbreviate qw(abbreviate);

# ---------------------------------------------------------------------------
# Constants: avoid repeating magic strings across test cases
# ---------------------------------------------------------------------------
Readonly my $PKG => 'Text::Names::Abbreviate';

# ---------------------------------------------------------------------------
# Direct references to private helpers for white-box isolation.
# These are package-scoped subs, not exported, but fully callable by FQN.
# ---------------------------------------------------------------------------
my $normalize = \&Text::Names::Abbreviate::_normalize_name;
my $extract   = \&Text::Names::Abbreviate::_extract_parts;

# ===========================================================================
# SECTION 1 — _normalize_name: exhaustive branch coverage
# Each branch corresponds to a distinct case in the comma-detection logic.
# ===========================================================================

subtest '_normalize_name: plain input passes through' => sub {
	# Strategy: no comma → whitespace-collapsed output, flag = 0.
	my ($name, $had) = $normalize->('John Quincy Adams');
	is($name, 'John Quincy Adams', 'simple name unchanged');
	is($had,  0,                   'had_leading_comma is 0');

	my ($ws, $had2) = $normalize->('  John   Quincy   Adams  ');
	is($ws,   'John Quincy Adams', 'internal whitespace collapsed');
	is($had2, 0,                   'no comma flag set');

	diag("_normalize_name plain: '$name', had=$had") if $ENV{TEST_VERBOSE};
	done_testing();
};

subtest '_normalize_name: Last, First reordering' => sub {
	# Strategy: when both sides of the comma are non-empty the sub
	# must return "First Last" order with had_leading_comma = 0.
	my ($name, $had) = $normalize->('Adams, John Quincy');
	is($name, 'John Quincy Adams', 'reordered to first-last');
	is($had,  0,                   'normal comma, not leading');

	($name) = $normalize->('Adams,John');
	is($name, 'John Adams', 'tight comma reordered');

	($name) = $normalize->('Adams , John');
	is($name, 'John Adams', 'spaces around comma reordered');

	($name) = $normalize->('Adams ,John');
	is($name, 'John Adams', 'asymmetric spacing handled');

	diag("reorder: '$name'") if $ENV{TEST_VERBOSE};
	done_testing();
};

subtest '_normalize_name: leading comma sets had_leading_comma' => sub {
	# Strategy: when the left side of the comma is empty and the right
	# is non-empty the caller has no last name — set the flag so
	# _extract_parts treats every token as an initial.
	my ($name, $had) = $normalize->(', John Quincy');
	is($name, 'John Quincy', 'rest extracted correctly');
	is($had,  1,             'had_leading_comma is 1');

	diag("leading-comma: '$name', had=$had") if $ENV{TEST_VERBOSE};
	done_testing();
};

subtest '_normalize_name: trailing comma (no first name)' => sub {
	# Strategy: right side is empty, left side is non-empty → return just
	# the last name with had_leading_comma = 0.
	my ($name, $had) = $normalize->('Adams,');
	is($name, 'Adams', 'last name returned alone');
	is($had,  0,       'not a leading-comma form');

	done_testing();
};

subtest '_normalize_name: bare comma returns empty string' => sub {
	# Strategy: both sides empty after split → early return ('', 0).
	my ($name, $had) = $normalize->(',');
	is($name, '', 'empty result for bare comma');
	is($had,  0,  'flag is 0 on empty result');

	done_testing();
};

subtest '_normalize_name: consecutive commas collapse before parsing' => sub {
	# Strategy: s/,+/,/g (not the original s/,,/,/g) collapses any run of
	# commas in one left-to-right pass, including odd-length runs of 3+.
	my ($name, $had) = $normalize->('Adams,,John');
	is($name, 'John Adams', 'double comma reduced then reordered');
	is($had,  0,            'not a leading-comma form');

	# 3 commas — original s/,,/,/g would have left 2 commas after one pass.
	($name, $had) = $normalize->('Adams,,,John');
	is($name, 'John Adams', '3 commas collapsed to 1 then reordered');
	is($had,  0,            'not a leading-comma form (3 commas)');

	# Leading triple comma — collapses to single leading comma.
	($name, $had) = $normalize->(',,,John');
	is($name, 'John', '3 leading commas → rest extracted');
	is($had,  1,      'had_leading_comma is 1 (leading triple comma)');

	# Trailing triple comma — collapses to trailing comma → just last name.
	($name, $had) = $normalize->('Adams,,,');
	is($name, 'Adams', '3 trailing commas → last name only');
	is($had,  0,       'not a leading-comma form (trailing commas)');

	done_testing();
};

# ===========================================================================
# SECTION 2 — _extract_parts: exhaustive branch coverage
# Each branch tests a different combination of had_leading_comma, format,
# and style to ensure all code paths in the helper are exercised.
# ===========================================================================

subtest '_extract_parts: empty input returns empty pair' => sub {
	my ($inits, $last) = $extract->('', 0, 'default', 'first_last');
	is_deeply($inits, [], 'no initials for empty input');
	is($last,          '', 'no last name for empty input');

	done_testing();
};

subtest '_extract_parts: single token becomes last name' => sub {
	# A single-word name has no initials; the word itself is the last name.
	my ($inits, $last) = $extract->('Madonna', 0, 'default', 'first_last');
	is_deeply($inits, [], 'no initials');
	is($last, 'Madonna',   'single token is last name');

	done_testing();
};

subtest '_extract_parts: normal multi-token first_last' => sub {
	my ($inits, $last) = $extract->('John Quincy Adams', 0, 'default', 'first_last');
	is_deeply($inits, ['J', 'Q'], 'two initials extracted');
	is($last, 'Adams',            'last name popped from token list');

	done_testing();
};

subtest '_extract_parts: had_leading_comma — all tokens become initials' => sub {
	# When the caller has no last name component, every token is an initial.
	my ($inits, $last) = $extract->('John Quincy', 1, 'default', 'first_last');
	is_deeply($inits, ['J', 'Q'], 'all tokens yield initials');
	is($last, '',                 'last name is empty');

	done_testing();
};

subtest '_extract_parts: last_first reordering for initials and compact' => sub {
	# For non-default, non-shortlast formats, last_first moves the last
	# initial to the front of the array and clears last_name.
	for my $fmt (qw(initials compact)) {
		my ($inits, $last) = $extract->('John Quincy Adams', 0, $fmt, 'last_first');
		is_deeply($inits, ['A', 'J', 'Q'], "last initial first for format=$fmt");
		is($last, '',                       "last_name cleared for format=$fmt");
	}
	done_testing();
};

subtest '_extract_parts: last_first reorder for single-token input (compact/initials)' => sub {
	# Strategy: a single token is popped as last_name; @initials starts empty.
	# The reorder condition is still true (length $last_name > 0), so
	# unshift moves 'M' onto @initials and clears last_name.
	# This covers the path: @initials=[] before reorder, ['M'] after.
	#
	# Note: the `&& length $last_name` sub-condition in the reorder guard is
	# always true in this (non-leading-comma) branch since pop from a non-empty
	# split never yields ''.  It is a defensive dead-code guard.
	for my $fmt (qw(initials compact)) {
		my ($inits, $last) = $extract->('Madonna', 0, $fmt, 'last_first');
		is_deeply($inits, ['M'], "single-token $fmt/last_first: initials=['M']");
		is($last,          '',   "single-token $fmt/last_first: last_name cleared");
	}
	done_testing();
};

subtest '_extract_parts: shortlast NOT reordered under last_first' => sub {
	# shortlast retains the full last name regardless of style so that the
	# formatter can place it in the right position itself.
	my ($inits, $last) = $extract->('John Quincy Adams', 0, 'shortlast', 'last_first');
	is_deeply($inits, ['J', 'Q'], 'initials unchanged for shortlast');
	is($last, 'Adams',             'full last name preserved for shortlast');

	done_testing();
};

subtest '_extract_parts: default format not reordered for last_first' => sub {
	# default format reordering happens in the formatter, not here.
	my ($inits, $last) = $extract->('John Quincy Adams', 0, 'default', 'last_first');
	is_deeply($inits, ['J', 'Q'], 'initials unchanged for default/last_first');
	is($last, 'Adams',             'last name preserved for default/last_first');

	done_testing();
};

subtest '_extract_parts: empty initials filtered out' => sub {
	# The grep { length $_ } step removes any zero-length entries that
	# could arise from degenerate tokenisation paths.
	my ($inits, $last) = $extract->('A B C', 0, 'default', 'first_last');
	is_deeply($inits, ['A', 'B'], 'single-letter tokens become single-char initials');
	is($last, 'C',                'last name correct');

	done_testing();
};

# ===========================================================================
# SECTION 3 — abbreviate: delegation isolation via Test::Mockingbird
# Tests that abbreviate correctly orchestrates its private helpers without
# coupling the assertions to helper internals.
# ===========================================================================

subtest 'abbreviate delegates to _normalize_name with the raw name' => sub {
	# Strategy: spy on _normalize_name so the original still runs, but
	# capture the call to verify the argument contract.
	my $spy = spy("${PKG}::_normalize_name");

	abbreviate('John Adams');

	my @calls = $spy->();
	is(scalar @calls, 1,           '_normalize_name called exactly once');
	is($calls[0][1],  'John Adams', 'raw name passed to _normalize_name');

	restore_all();
	done_testing();
};

subtest 'abbreviate short-circuits to "" when _normalize_name returns empty' => sub {
	# Strategy: replace _normalize_name with a stub that returns ('', 0).
	# abbreviate must return '' without calling _extract_parts.
	my $g = mock_scoped "${PKG}::_normalize_name" => sub { ('', 0) };

	is(abbreviate('anything'), '', 'early exit on empty normalised name');

	done_testing();
};

subtest 'abbreviate forwards all options to _extract_parts' => sub {
	# Strategy: stub _normalize_name so its output is predictable, then
	# spy on _extract_parts to verify that format and style reach it.
	mock("${PKG}::_normalize_name", sub { ('Stub Name', 0) });
	my $spy = spy("${PKG}::_extract_parts");

	abbreviate('anything', { format => 'compact', style => 'last_first', separator => '-' });

	my @calls = $spy->();
	is(scalar @calls, 1,            '_extract_parts called exactly once');
	is($calls[0][1],  'Stub Name',  'normalised name forwarded');
	is($calls[0][2],  0,            'had_leading_comma forwarded');
	is($calls[0][3],  'compact',    'format forwarded');
	is($calls[0][4],  'last_first', 'style forwarded');

	restore_all();
	done_testing();
};

# ===========================================================================
# SECTION 4 — abbreviate: format dispatch coverage
# Each format is tested across meaningful input shapes to verify the
# formatter branch is entered and produces the correct output.
# ===========================================================================

subtest 'abbreviate: compact format' => sub {
	is(abbreviate('John Quincy Adams',  { format => 'compact' }),                         'JQA',  'full name compact');
	is(abbreviate('John Adams',          { format => 'compact' }),                         'JA',   'two-part compact');
	is(abbreviate('Madonna',             { format => 'compact' }),                         'M',    'single name compact');
	is(abbreviate(', John Quincy',       { format => 'compact' }),                         'JQ',   'leading comma compact');
	is(abbreviate('John Quincy Adams',   { format => 'compact',  style => 'last_first' }), 'AJQ',  'compact last_first');

	done_testing();
};

subtest 'abbreviate: initials format' => sub {
	is(abbreviate('John Quincy Adams',  { format => 'initials' }),                          'J.Q.A.', 'full initials');
	is(abbreviate('John Adams',          { format => 'initials' }),                          'J.A.',   'two-part initials');
	is(abbreviate('Madonna',             { format => 'initials' }),                          'M.',     'single name');
	is(abbreviate(', John Quincy',       { format => 'initials' }),                          'J.Q.',   'leading comma');
	is(abbreviate('George R R Martin',   { format => 'initials' }),                          'G.R.R.M.', 'multiple middle initials');
	is(abbreviate('John Quincy Adams',   { format => 'initials', style => 'last_first' }),   'A.J.Q.', 'initials last_first');
	is(abbreviate('John Quincy Adams',   { format => 'initials', separator => '-' }),         'J-Q-A-', 'custom separator');

	done_testing();
};

subtest 'abbreviate: default format' => sub {
	is(abbreviate('John Quincy Adams'),                                     'J. Q. Adams',  'standard default');
	is(abbreviate('John Adams'),                                             'J. Adams',     'two-part default');
	is(abbreviate('Madonna'),                                                'Madonna',      'single name unchanged');
	is(abbreviate('A B'),                                                    'A. B',         'single-letter components');
	is(abbreviate('John Quincy Adams', { style => 'last_first' }),           'Adams, J. Q.', 'last_first default');
	is(abbreviate('John Adams',        { style => 'last_first' }),           'Adams, J.',    'two-part last_first');
	is(abbreviate('Madonna',           { style => 'last_first' }),           'Madonna',      'single name last_first unchanged');
	is(abbreviate('John Quincy Adams', { separator => ':' }),                'J: Q: Adams',  'custom separator');
	is(abbreviate('John Quincy Adams', { separator => '' }),                 'J Q Adams',    'empty separator removes punctuation');
	is(abbreviate('John Quincy Adams', { style => 'first_last' }),           'J. Q. Adams',  'explicit first_last matches default');

	done_testing();
};

subtest 'abbreviate: shortlast format' => sub {
	is(abbreviate('John Quincy Adams', { format => 'shortlast' }),                          'J. Q. Adams',  'standard shortlast');
	is(abbreviate('John Adams',         { format => 'shortlast' }),                          'J. Adams',     'two-part shortlast');
	is(abbreviate('Madonna',            { format => 'shortlast' }),                          'Madonna',      'single name shortlast unchanged');
	is(abbreviate(', John Quincy',      { format => 'shortlast' }),                          'J. Q.',        'no trailing space without last name');
	is(abbreviate('John Quincy Adams',  { format => 'shortlast', style => 'last_first' }),   'Adams, J. Q.', 'shortlast last_first');
	is(abbreviate('Madonna',            { format => 'shortlast', style => 'last_first' }),   'Madonna',      'shortlast last_first single name');
	is(abbreviate('John Quincy Adams',  { format => 'shortlast', separator => ':' }),         'J: Q: Adams',  'shortlast custom separator');
	is(abbreviate(', John',             { format => 'shortlast', style => 'last_first' }),   'J.',           'shortlast last_first leading comma');

	done_testing();
};

# ===========================================================================
# SECTION 5 — abbreviate: validation and error paths
# Tests the exact croak messages for all known error conditions so that
# callers can rely on the error text described in the MESSAGES POD.
# ===========================================================================

subtest 'abbreviate: undef name rejected before validator' => sub {
	# The explicit defined() guard fires before Params::Validate::Strict,
	# because PVS min=>1 only applies to defined values.
	throws_ok(
		sub { abbreviate(undef) },
		qr/name/,
		'undef name croaks with /name/'
	);
	done_testing();
};

subtest 'abbreviate: empty string rejected by validator' => sub {
	throws_ok(
		sub { abbreviate('') },
		qr/name/,
		'empty string rejected with /name/'
	);
	done_testing();
};

subtest 'abbreviate: invalid format rejected' => sub {
	throws_ok(
		sub { abbreviate('John Adams', { format => 'long' }) },
		qr/format/,
		'invalid format croaks with /format/'
	);
	done_testing();
};

subtest 'abbreviate: invalid style rejected' => sub {
	throws_ok(
		sub { abbreviate('John Adams', { style => 'middle_first' }) },
		qr/style/,
		'invalid style croaks with /style/'
	);
	done_testing();
};

subtest 'abbreviate: all valid format values accepted' => sub {
	for my $fmt (qw(default initials compact shortlast)) {
		lives_ok(
			sub { abbreviate('John Adams', { format => $fmt }) },
			"format '$fmt' is accepted"
		);
	}
	done_testing();
};

subtest 'abbreviate: all valid style values accepted' => sub {
	for my $sty (qw(first_last last_first)) {
		lives_ok(
			sub { abbreviate('John Adams', { style => $sty }) },
			"style '$sty' is accepted"
		);
	}
	done_testing();
};

subtest 'abbreviate: normalises to empty returns empty string' => sub {
	# Whitespace-only comma expression reduces to '' in _normalize_name.
	is(abbreviate(' , '), '', 'bare whitespace-comma yields empty string');
	done_testing();
};

# ===========================================================================
# SECTION 6 — calling conventions
# Params::Get supports both positional-string and hashref-only call forms.
# ===========================================================================

subtest 'abbreviate: hashref-only calling convention' => sub {
	is(
		abbreviate({ name => 'John Quincy Adams', format => 'compact' }),
		'JQA',
		'hashref-only call works'
	);
	is(
		abbreviate({ name => 'John Adams' }),
		'J. Adams',
		'hashref-only with just name'
	);
	done_testing();
};

subtest 'abbreviate: comma-normalised input forms' => sub {
	is(abbreviate('Adams, John Quincy'),  'J. Q. Adams', 'Last, First normalised');
	is(abbreviate('Adams,John Quincy'),   'J. Q. Adams', 'tight comma normalised');
	is(abbreviate('Adams , John Quincy'), 'J. Q. Adams', 'space-before-comma normalised');
	is(abbreviate('Adams ,John Quincy'),  'J. Q. Adams', 'asymmetric spaces normalised');
	done_testing();
};

# ===========================================================================
# SECTION 7 — global variable isolation
# Helpers must not silently clobber $_ or other global state.
# ===========================================================================

subtest 'abbreviate does not clobber $_' => sub {
	local $_ = 'sentinel';
	abbreviate('John Adams');
	is($_, 'sentinel', 'abbreviate leaves $_ unchanged');
	done_testing();
};

subtest '_normalize_name does not clobber $_' => sub {
	local $_ = 'sentinel';
	$normalize->('Adams, John');
	is($_, 'sentinel', '_normalize_name leaves $_ unchanged');
	done_testing();
};

subtest '_extract_parts does not clobber $_' => sub {
	local $_ = 'sentinel';
	$extract->('John Quincy Adams', 0, 'default', 'first_last');
	is($_, 'sentinel', '_extract_parts leaves $_ unchanged');
	done_testing();
};

subtest 'repeated calls do not accumulate state' => sub {
	# Regression: ensure no module-level mutable state leaks between calls.
	my $first  = abbreviate('John Quincy Adams');
	my $second = abbreviate('John Quincy Adams', { format => 'compact' });
	my $third  = abbreviate('John Quincy Adams');

	is($first,  'J. Q. Adams', 'first call correct');
	is($second, 'JQA',         'second call (compact) correct');
	is($third,  'J. Q. Adams', 'third call unchanged — no state leakage');
	done_testing();
};

# ===========================================================================
# SECTION 8 — return value schema validation (Test::Returns)
# Every valid input must produce a plain string, never a reference or undef.
# ===========================================================================

subtest 'abbreviate return values satisfy string schema' => sub {
	my @cases = (
		[ abbreviate('John Quincy Adams'),                                        'default'           ],
		[ abbreviate('John Quincy Adams', { format => 'initials' }),              'initials'          ],
		[ abbreviate('John Quincy Adams', { format => 'compact' }),               'compact'           ],
		[ abbreviate('John Quincy Adams', { format => 'shortlast' }),             'shortlast'         ],
		[ abbreviate('John Quincy Adams', { style  => 'last_first' }),            'last_first'        ],
		[ abbreviate('Madonna'),                                                  'single name'       ],
		[ abbreviate(' , '),                                                      'empty normalisation'],
		[ abbreviate(', John Quincy'),                                            'leading comma'     ],
	);

	for my $pair (@cases) {
		my ($result, $desc) = @{$pair};
		returns_ok($result, { type => 'string' }, "result is a string: $desc");
		diag("  $desc => '$result'") if $ENV{TEST_VERBOSE};
	}

	done_testing();
};

subtest '_normalize_name output satisfies expected types' => sub {
	my ($name, $had) = $normalize->('Adams, John Quincy');
	returns_ok($name, { type => 'string' }, 'normalised name is a string');
	ok($had == 0 || $had == 1, 'had_leading_comma is boolean 0 or 1');
	done_testing();
};

subtest '_extract_parts output satisfies expected types' => sub {
	my ($inits, $last) = $extract->('John Quincy Adams', 0, 'default', 'first_last');
	ok(ref($inits) eq 'ARRAY', 'initials is an arrayref');
	returns_ok($last, { type => 'string' }, 'last name is a string');
	returns_ok($inits->[0], { type => 'string' }, 'each initial is a string') if @{$inits};
	done_testing();
};

# ===========================================================================
# SECTION 9 — memory cycle checks (Test::Memory::Cycle)
# The module builds small, flat data structures; confirm no cycles arise.
# ===========================================================================

subtest 'no circular references in _extract_parts output' => sub {
	my ($inits, $last) = $extract->('John Quincy Adams', 0, 'default', 'first_last');
	memory_cycle_ok($inits, 'initials arrayref has no cycles');
	done_testing();
};

subtest 'no circular references across repeated abbreviate calls' => sub {
	my @results = map { abbreviate($_) }
		('John Adams', 'George R R Martin', 'Madonna', ', John');
	memory_cycle_ok(\@results, 'no cycles in accumulated results');
	done_testing();
};

done_testing();
