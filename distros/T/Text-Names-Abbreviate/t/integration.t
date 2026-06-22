#!/usr/bin/env perl
# Integration tests for Text::Names::Abbreviate.
# Focus: multi-call workflows, batch processing, pipeline chaining,
# caller-environment robustness, and end-to-end dispatch verification.
# Individual format/style/separator behaviours are covered by t/unit.t.
# Private-helper branch coverage lives in t/function.t.

use strict;
use warnings;

use POSIX        qw(ENOENT);
use Readonly;
use Test::Mockingbird;
use Test::Most;
use Test::Returns qw(returns_ok);

use Text::Names::Abbreviate qw(abbreviate);

# ---------------------------------------------------------------------------
# Named constants -- eliminate all magic strings
# ---------------------------------------------------------------------------
Readonly my $PKG          => 'Text::Names::Abbreviate';
Readonly my $THREE_PART   => 'John Quincy Adams';
Readonly my $COMMA_THREE  => 'Adams, John Quincy';
Readonly my $TWO_PART     => 'John Adams';
Readonly my $COMMA_TWO    => 'Adams, John';
Readonly my $SINGLE       => 'Madonna';
Readonly my $REPEATED_MID => 'George R R Martin';
Readonly my $COMMA_REP    => 'Martin, George R R';

Readonly my @ALL_FORMATS => qw(default initials compact shortlast);
Readonly my @ALL_STYLES  => qw(first_last last_first);
Readonly my @SAMPLE_SEPS => ('.', '-', '', ':');

# Exhaustive expected values for $THREE_PART across all format x style x
# separator combinations.  compact ignores separator entirely.  shortlast and
# default both retain the full last name in the formatter, so they produce
# identical output for a three-part name.
Readonly my %EXPECTED_MATRIX => (
	'default|first_last|.'    => 'J. Q. Adams',
	'default|first_last|-'    => 'J- Q- Adams',
	'default|first_last|'     => 'J Q Adams',
	'default|first_last|:'    => 'J: Q: Adams',
	'default|last_first|.'    => 'Adams, J. Q.',
	'default|last_first|-'    => 'Adams, J- Q-',
	'default|last_first|'     => 'Adams, J Q',
	'default|last_first|:'    => 'Adams, J: Q:',
	'initials|first_last|.'   => 'J.Q.A.',
	'initials|first_last|-'   => 'J-Q-A-',
	'initials|first_last|'    => 'JQA',
	'initials|first_last|:'   => 'J:Q:A:',
	'initials|last_first|.'   => 'A.J.Q.',
	'initials|last_first|-'   => 'A-J-Q-',
	'initials|last_first|'    => 'AJQ',
	'initials|last_first|:'   => 'A:J:Q:',
	'compact|first_last|.'    => 'JQA',
	'compact|first_last|-'    => 'JQA',
	'compact|first_last|'     => 'JQA',
	'compact|first_last|:'    => 'JQA',
	'compact|last_first|.'    => 'AJQ',
	'compact|last_first|-'    => 'AJQ',
	'compact|last_first|'     => 'AJQ',
	'compact|last_first|:'    => 'AJQ',
	'shortlast|first_last|.'  => 'J. Q. Adams',
	'shortlast|first_last|-'  => 'J- Q- Adams',
	'shortlast|first_last|'   => 'J Q Adams',
	'shortlast|first_last|:'  => 'J: Q: Adams',
	'shortlast|last_first|.'  => 'Adams, J. Q.',
	'shortlast|last_first|-'  => 'Adams, J- Q-',
	'shortlast|last_first|'   => 'Adams, J Q',
	'shortlast|last_first|:'  => 'Adams, J: Q:',
);

# ---------------------------------------------------------------------------

use_ok($PKG, 'abbreviate');

# ===========================================================================
# SECTION 1 -- Systematic format x style x separator matrix
#
# Exhaustively validates the full Cartesian product for a canonical three-part
# name and verifies the POD return schema on every result.  Unlike t/unit.t
# (which checks individual behaviours), this subtest proves the entire dispatch
# chain (normalize -> extract -> format) is consistent for all configurations.
# ===========================================================================

subtest 'matrix: all format x style x separator combinations for three-part name' => sub {
	# 4 formats x 2 styles x 4 separators = 32 configurations, each checked
	# for exact output value and for conformance to the POD return schema.
	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			for my $sep (@SAMPLE_SEPS) {
				my $key    = "$fmt|$sty|$sep";
				my $result = abbreviate($THREE_PART, {
					format    => $fmt,
					style     => $sty,
					separator => $sep,
				});
				my $expected = $EXPECTED_MATRIX{$key};

				diag("matrix[$key] => '$result'") if $ENV{TEST_VERBOSE};

				is($result, $expected, "matrix[$key]");
				returns_ok($result, { type => 'string' }, "matrix[$key] returns string");
			}
		}
	}

	done_testing();
};

# ===========================================================================
# SECTION 2 -- Input form equivalence across a batch pipeline
#
# Strategy: for every (format, style) pair, verify that the "First Last" form
# and the "Last, First" form produce identical output.  This is the integration-
# level proof that _normalize_name() canonicalises both input forms correctly,
# and that the equivalence holds across the full option space.
# ===========================================================================

subtest 'equivalence: direct and comma forms are interchangeable in a pipeline' => sub {
	my @pairs = (
		[ $THREE_PART,   $COMMA_THREE ],
		[ $TWO_PART,     $COMMA_TWO   ],
		[ $REPEATED_MID, $COMMA_REP   ],
	);

	for my $pair (@pairs) {
		my ($direct, $comma) = @{$pair};
		for my $fmt (@ALL_FORMATS) {
			for my $sty (@ALL_STYLES) {
				my $a = abbreviate($direct, { format => $fmt, style => $sty });
				my $b = abbreviate($comma,  { format => $fmt, style => $sty });

				diag("equiv '$direct' vs '$comma' [$fmt/$sty]: a='$a' b='$b'")
					if $ENV{TEST_VERBOSE};

				is($a, $b, "equiv: '$direct' == '$comma' for $fmt/$sty");
			}
		}
	}

	done_testing();
};

# ===========================================================================
# SECTION 3 -- Calling convention interoperability
#
# Params::Get supports three calling conventions: positional string, string
# with options hashref, and hashref-only.  All three must produce identical
# output when used interchangeably inside the same pipeline.
# ===========================================================================

subtest 'calling conventions: all three produce identical output within a pipeline' => sub {
	Readonly my $EXPECT_DEFAULT  => 'J. Q. Adams';
	Readonly my $EXPECT_INITIALS => 'J.Q.A.';
	Readonly my $EXPECT_COMPACT  => 'JQA';

	is(abbreviate($THREE_PART),                                       $EXPECT_DEFAULT,  'positional -> default');
	is(abbreviate($THREE_PART, { format => 'default' }),              $EXPECT_DEFAULT,  'string+hashref -> default');
	is(abbreviate({ name => $THREE_PART }),                           $EXPECT_DEFAULT,  'hashref-only -> default');

	is(abbreviate($THREE_PART,          { format => 'initials' }),    $EXPECT_INITIALS, 'string+hashref -> initials');
	is(abbreviate({ name => $THREE_PART, format => 'initials' }),     $EXPECT_INITIALS, 'hashref-only -> initials');

	is(abbreviate($THREE_PART,          { format => 'compact' }),     $EXPECT_COMPACT,  'string+hashref -> compact');
	is(abbreviate({ name => $THREE_PART, format => 'compact' }),      $EXPECT_COMPACT,  'hashref-only -> compact');

	done_testing();
};

# ===========================================================================
# SECTION 4 -- Multi-step pipeline
#
# Tests that the output of one abbreviate() call can serve as valid input to
# the next.  The first subtest demonstrates the intended use case (the POD
# describes re-parsing as valid); the remaining two document the LIMITATIONS
# around lossy round-trips.
# ===========================================================================

subtest 'pipeline: Last,First -> abbreviate -> re-abbreviate' => sub {
	# Two-step workflow: comma form first, then convert the abbreviated result
	# to initials.  Verifies that the output of step 1 is a valid name for step 2.
	my $step1 = abbreviate($COMMA_THREE);
	my $step2 = abbreviate($step1, { format => 'initials' });

	diag("step1='$step1' step2='$step2'") if $ENV{TEST_VERBOSE};

	is($step1, 'J. Q. Adams', 'step1: comma form normalised and abbreviated');
	is($step2, 'J.Q.A.',      'step2: abbreviated default output re-abbreviated to initials');

	done_testing();
};

subtest 'pipeline: lossy round-trip through compact (LIMITATION)' => sub {
	# POD LIMITATIONS: "compact and initials formats are lossy."
	# compact collapses the name to a single merged token; re-abbreviating
	# that token treats the whole string as a single name component.
	my $compact_out = abbreviate($THREE_PART, { format => 'compact' });
	my $re_abbrev   = abbreviate($compact_out, { format => 'initials' });

	diag("compact='$compact_out' re-abbreviated='$re_abbrev'") if $ENV{TEST_VERBOSE};

	is($compact_out, 'JQA', 'compact produces a single merged token');
	is($re_abbrev,   'J.',  'compact output treated as one name component when re-abbreviated');
	isnt($re_abbrev, 'J.Q.A.', 'round-trip through compact cannot reproduce original (LIMITATION)');

	done_testing();
};

subtest 'pipeline: lossy round-trip through initials (LIMITATION)' => sub {
	# initials format produces dot-separated chars with no spaces; re-parsing
	# treats the whole thing as a single token because there are no space delimiters.
	my $initials_out = abbreviate($THREE_PART, { format => 'initials' });
	my $re_abbrev    = abbreviate($initials_out);

	diag("initials='$initials_out' re-abbreviated='$re_abbrev'") if $ENV{TEST_VERBOSE};

	is($initials_out, 'J.Q.A.', 'initials output is a dot-separated string');
	isnt($re_abbrev, 'J. Q. Adams', 'initials output does not round-trip to original (LIMITATION)');

	done_testing();
};

# ===========================================================================
# SECTION 5 -- Batch processing workflows
#
# Simulates realistic caller scenarios: a list of raw names in various forms
# is mapped to a consistent abbreviated format in a single pipeline pass.
# Validates both the correct output values and the return-type schema.
# ===========================================================================

subtest 'batch: initials from a mixed-form input list' => sub {
	# Citation-building workflow: raw names arrive in different text forms and
	# must all be converted to the initials format in one map pass.
	my @raw = (
		$THREE_PART,
		$COMMA_THREE,
		$TWO_PART,
		$SINGLE,
		$REPEATED_MID,
		'  John   Quincy   Adams  ',   # padded -- normalised internally
	);

	my @output = map { abbreviate($_, { format => 'initials' }) } @raw;

	diag('batch initials: ' . join(', ', @output)) if $ENV{TEST_VERBOSE};

	is_deeply(
		\@output,
		[ 'J.Q.A.', 'J.Q.A.', 'J.A.', 'M.', 'G.R.R.M.', 'J.Q.A.' ],
		'mixed input forms produce consistent initials',
	);

	returns_ok($_, { type => 'string' }, 'batch element is string') for @output;

	done_testing();
};

subtest 'batch: index-style (last_first initials) from comma-form inputs' => sub {
	# Index/citation workflow: Last,First inputs converted to last_first initials
	# for a bibliography.  Exercises the normalise -> reorder -> format chain.
	my @raw = ($COMMA_THREE, $COMMA_TWO, $COMMA_REP);

	my @processed = map {
		abbreviate($_, { format => 'initials', style => 'last_first' })
	} @raw;

	diag('index batch: ' . join(', ', @processed)) if $ENV{TEST_VERBOSE};

	is_deeply(
		\@processed,
		[ 'A.J.Q.', 'A.J.', 'M.G.R.R.' ],
		'Last,First inputs produce last_first initials in batch',
	);

	done_testing();
};

subtest 'batch: shortlast display labels for a UI list' => sub {
	# Display-label workflow: shortlast with last_first style produces human-
	# readable labels suitable for a sorted UI widget.
	my @raw = ($THREE_PART, $TWO_PART, $SINGLE);

	my @labels = map {
		abbreviate($_, { format => 'shortlast', style => 'last_first' })
	} @raw;

	diag('shortlast batch: ' . join(', ', @labels)) if $ENV{TEST_VERBOSE};

	is_deeply(
		\@labels,
		[ 'Adams, J. Q.', 'Adams, J.', 'Madonna' ],
		'shortlast last_first batch produces correct display labels',
	);

	done_testing();
};

# ===========================================================================
# SECTION 6 -- Statelessness across a complex multi-call pipeline
#
# POD §Side Effects: "None. The function is purely functional with no
# persistent state."  Options set in one call must never influence the next.
# These subtests interleave contrasting configurations and verify the defaults
# are always restored.
# ===========================================================================

subtest 'stateless: options do not persist across interleaved calls' => sub {
	my $name = $THREE_PART;

	# Round-trip through every extreme option, then verify the plain call
	# always reverts to the documented defaults (format=default,
	# style=first_last, separator='.').
	my $r1 = abbreviate($name, { format => 'compact',  style => 'last_first', separator => '-' });
	my $r2 = abbreviate($name);
	my $r3 = abbreviate($name, { format => 'initials', style => 'last_first', separator => ':' });
	my $r4 = abbreviate($name);
	my $r5 = abbreviate($name, { separator => '|' });
	my $r6 = abbreviate($name);

	diag("stateless: r1=$r1 r2=$r2 r3=$r3 r4=$r4 r5=$r5 r6=$r6")
		if $ENV{TEST_VERBOSE};

	is($r1, 'AJQ',         'compact + last_first + dash');
	is($r2, 'J. Q. Adams', 'defaults restored after compact');
	is($r3, 'A:J:Q:',      'initials + last_first + colon');
	is($r4, 'J. Q. Adams', 'defaults restored after initials');
	is($r5, 'J| Q| Adams', 'pipe separator applied');
	is($r6, 'J. Q. Adams', 'defaults restored after custom separator');

	done_testing();
};

subtest 'stateless: separator default intact after a batch with custom separator' => sub {
	# Run a batch that uses a custom separator throughout, then confirm the
	# following plain call uses the documented default separator '.'.
	my @batch = map { abbreviate($_, { separator => '::' }) }
		($THREE_PART, $TWO_PART);

	my $after = abbreviate($THREE_PART);

	diag('batch_sep: batch=' . join(', ', @batch) . " after='$after'")
		if $ENV{TEST_VERBOSE};

	is($after, 'J. Q. Adams', 'default separator intact after batch with custom separator');

	done_testing();
};

subtest 'stateless: repeated identical calls produce identical output' => sub {
	# Idempotence: the same arguments always yield the same result.
	my @results = map { abbreviate($REPEATED_MID, { format => 'initials' }) } (1 .. 10);

	is_deeply(
		\@results,
		[ ('G.R.R.M.') x 10 ],
		'10 identical calls produce 10 identical outputs',
	);

	done_testing();
};

# ===========================================================================
# SECTION 7 -- Global state preservation across a pipeline
#
# POD §Side Effects: "None."  Verify that $_, $@, and $! in the calling
# environment are untouched by any combination of abbreviate() calls.
# ===========================================================================

subtest 'global state: $_ not clobbered across a multi-format pipeline' => sub {
	local $_ = 'pipeline-sentinel';
	my $before = $_;

	abbreviate($THREE_PART);
	abbreviate($THREE_PART, { format => 'initials', style => 'last_first' });
	abbreviate($TWO_PART,   { format => 'compact' });
	abbreviate($SINGLE,     { format => 'shortlast', separator => '-' });

	is($_, $before, '$_ unchanged across a four-call pipeline');

	done_testing();
};

subtest 'global state: $@ and $! preserved across a pipeline' => sub {
	# Simulate a caller that handled an exception, then calls abbreviate.
	# Verify neither errno nor the exception variable are disturbed.
	eval { die "prior caller error\n" };
	my $saved_at = $@;

	{
		local $! = ENOENT;
		my $saved_bang = "$!";

		abbreviate($THREE_PART);
		abbreviate($TWO_PART,    { format => 'initials' });
		abbreviate($SINGLE,      { format => 'compact' });
		abbreviate($COMMA_THREE, { style  => 'last_first' });

		is("$!", $saved_bang, '$! (errno) not modified across a four-call pipeline');
	}

	is($@, $saved_at, '$@ not modified by any call in the pipeline');

	done_testing();
};

# ===========================================================================
# SECTION 8 -- Error pipeline: end-to-end croak propagation
#
# Uses a Test::Mockingbird spy (original Carp::croak still fires) to confirm
# that the full error path from abbreviate() through to the caller's $@ is
# correct.  Also verifies that a caught error leaves the module in a clean
# state for subsequent valid calls.
# ===========================================================================

subtest 'error pipeline: undef name -- croak fires and $@ is set correctly' => sub {
	# Strategy: spy on Carp::croak so the original still dies, but we capture
	# the call record to inspect the message.
	my $croak_spy = spy('Carp::croak');

	eval { abbreviate(undef) };
	my @calls = $croak_spy->();
	restore_all();

	diag('croak args: ' . (scalar @calls ? $calls[0][1] : '(none)'))
		if $ENV{TEST_VERBOSE};

	is(scalar @calls, 1,      'Carp::croak called exactly once for undef name');
	like($calls[0][1], qr/name/i,      'croak message references "name" parameter');
	like($calls[0][1], qr/\Q$PKG\E/,   'croak message identifies the package');
	like($@,           qr/name/i,      'die propagates to caller $@');

	done_testing();
};

subtest 'error pipeline: module state clean after a caught error' => sub {
	# After catching a croak the module must be fully operational: no global
	# state should have been corrupted.
	eval { abbreviate(undef) };
	my $ok = abbreviate($THREE_PART);

	diag("post-error result: '$ok'") if $ENV{TEST_VERBOSE};

	is($ok, 'J. Q. Adams', 'valid call succeeds and returns correct result after caught error');

	done_testing();
};

# ===========================================================================
# SECTION 9 -- Spy-based dispatch chain verification
#
# Uses a Test::Mockingbird spy (original still runs) to confirm that
# _normalize_name() is called exactly once per abbreviate() call across a
# batch pipeline, and that each call receives the correct raw input.
# This verifies that the full dispatch chain is engaged for every element.
# ===========================================================================

subtest 'dispatch chain: _normalize_name called once per abbreviate in a batch' => sub {
	my @batch = ($THREE_PART, $TWO_PART, $SINGLE, $REPEATED_MID);

	my $norm_spy = spy("${PKG}::_normalize_name");
	my @results  = map { abbreviate($_) } @batch;
	my @spy_calls = $norm_spy->();
	restore_all();

	diag('spy calls: ' . scalar @spy_calls . ' for batch of ' . scalar @batch)
		if $ENV{TEST_VERBOSE};

	is(scalar @spy_calls, scalar @batch,
		'_normalize_name called exactly once per abbreviate() in the batch');

	for my $i (0 .. $#batch) {
		is($spy_calls[$i][1], $batch[$i],
			"_normalize_name call #${\($i + 1)} received correct raw input '$batch[$i]'");
	}

	done_testing();
};

# ===========================================================================
# SECTION 10 -- Caller deployment: no external helpers required
#
# Text::Names::Abbreviate has no optional dependencies.  These tests verify
# it is fully self-contained: whitespace normalisation, comma handling, and
# consecutive-comma collapse all work without any external text-processing
# modules.  Test::Without::Module simulates a minimal deployment environment.
# ===========================================================================

subtest 'deployment: self-contained normalisation without Text::Trim' => sub {
	# If a future refactor inadvertently adds a Text::Trim dependency, hiding
	# the module here will surface the regression immediately.
	require Test::Without::Module;
	Test::Without::Module->import('Text::Trim');

	is(abbreviate('  John   Quincy   Adams  '), 'J. Q. Adams',
		'internal whitespace collapsed without Text::Trim');

	is(abbreviate('Adams,,John Quincy'), 'J. Q. Adams',
		'consecutive commas normalised without external helpers');

	is(abbreviate(', John Quincy'), 'J. Q.',
		'leading-comma form handled without external helpers');

	Test::Without::Module->unimport('Text::Trim');

	done_testing();
};

subtest 'deployment: works alongside Text::Names when available' => sub {
	# When an optional related module (Text::Names) is present, verify there
	# are no symbol conflicts and abbreviate() is unaffected.
	eval { require Text::Names } or do {
		plan skip_all => 'Text::Names not installed';
		return;
	};

	my $result = abbreviate($THREE_PART);

	is($result, 'J. Q. Adams', 'abbreviate unaffected by Text::Names being loaded');
	returns_ok($result, { type => 'string' }, 'return value is string');

	done_testing();
};

# ===========================================================================
# SECTION 11 -- LIMITATIONS: end-to-end verification
#
# The POD LIMITATIONS section describes accepted behaviours that callers must
# account for.  These tests confirm that the documented limitations are stable
# across real-world name inputs.
# ===========================================================================

subtest 'LIMITATION pipeline: honorifics treated as name components end-to-end' => sub {
	# POD: "Honorifics (Dr., Prof.) and suffixes (Jr., III) are not detected
	# or stripped; they are treated as name components."
	my @cases = (
		[ 'Dr. John Adams',   'D. J. Adams' ],
		[ 'John Adams Jr.',   'J. A. Jr.'   ],
		[ 'Prof. Jane Smith', 'P. J. Smith' ],
	);

	for my $pair (@cases) {
		my ($input, $expected) = @{$pair};
		diag("honorific: '$input' => '$expected'") if $ENV{TEST_VERBOSE};
		is(abbreviate($input), $expected, "LIMITATION: '$input' -> '$expected'");
	}

	done_testing();
};

subtest 'LIMITATION pipeline: non-alphabetic leading characters preserved verbatim' => sub {
	# POD: "Non-alphabetic leading characters (digits, punctuation) are included as-is."
	is(abbreviate('1st John Adams'), '1. J. Adams', 'digit token preserved verbatim');
	is(abbreviate('.John Adams'),    '.. Adams',    'dot token produces .. initial');

	done_testing();
};

subtest 'LIMITATION pipeline: lossy formats do not round-trip through any style' => sub {
	# Verify the lossiness holds for both styles and both lossy formats.
	for my $fmt (qw(compact initials)) {
		for my $sty (@ALL_STYLES) {
			my $out = abbreviate($THREE_PART, { format => $fmt, style => $sty });
			isnt(abbreviate($out), $THREE_PART,
				"$fmt/$sty output cannot round-trip to original (LIMITATION)");
		}
	}

	done_testing();
};

# ===========================================================================
# SECTION 12 -- Test::Returns: end-to-end return schema validation
#
# POD §Returns: "A plain string."  Every combination of format and style, and
# every edge-case input, must produce a value satisfying { type => 'string' }.
# ===========================================================================

subtest 'Test::Returns: every pipeline output satisfies the string return schema' => sub {
	Readonly my %STR_SCHEMA => (type => 'string');

	# Full format x style cross-product
	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			returns_ok(
				abbreviate($THREE_PART, { format => $fmt, style => $sty }),
				\%STR_SCHEMA,
				"string returned: fmt=$fmt sty=$sty",
			);
		}
	}

	# Edge-case inputs
	returns_ok(abbreviate($SINGLE),               \%STR_SCHEMA, 'single-word name');
	returns_ok(abbreviate(','),                    \%STR_SCHEMA, 'bare comma (empty result)');
	returns_ok(abbreviate(', John Q'),             \%STR_SCHEMA, 'leading-comma form');
	returns_ok(abbreviate($COMMA_THREE),           \%STR_SCHEMA, 'Last,First form');
	returns_ok(abbreviate('  padded  '),           \%STR_SCHEMA, 'padded single-word name');
	returns_ok(abbreviate('Adams,,John Quincy'),   \%STR_SCHEMA, 'consecutive commas');

	done_testing();
};

done_testing();
