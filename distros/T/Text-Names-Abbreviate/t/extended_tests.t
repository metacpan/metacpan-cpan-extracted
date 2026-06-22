#!/usr/bin/env perl

# extended_tests.t — Path-coverage tests targeting every conditional branch
# and LCSAJ sequence in Text::Names::Abbreviate.  Complements unit.t (per-call
# black-box), function.t (white-box helper isolation), integration.t (workflow),
# and edge_cases.t (hostile inputs).
#
# Coverage strategy:
#   - Section 1: Single-name 8-cell matrix.  Fills two confirmed gaps:
#       compact+last_first and initials+last_first for a single-token name,
#       where _extract_parts reorders and then the formatter sees an empty
#       last_name (the "M-false" and "K-false" sub-paths).
#   - Section 2: Two-token 8-cell matrix (default separator).
#   - Section 3: Leading-comma 8-cell matrix.  Confirms that the
#       had_leading_comma=1 branch bypasses last_first reordering regardless
#       of the style option.
#   - Section 4: separator="" cross-format matrix.  Exercises the join()
#       paths for every format×style with an empty separator.
#   - Section 5: separator interaction for shortlast last_first (gap: "-" and "").
#   - Section 6: Explicit shortlast ternary paths A1/A2/B1/B2/B3.
#   - Section 7: Explicit default-format paths U/V/W/X.
#   - Section 8: compact ignores separator invariant (all 4 separators).
#   - Section 9: 3+ consecutive comma normalization (minimal cases that validate
#       the s/,+/,/g fix at 3, 4, and 5 commas).
#   - Section 10: Test::Returns schema validation.
#   - Dead-code note: see comment in Section 1 re: `length $last_name` guard.

use strict;
use warnings;

use Readonly;
use Test::Most;
use Test::Returns qw(returns_ok);

use Text::Names::Abbreviate qw(abbreviate);

# ---------------------------------------------------------------------------
# Named constants — every literal string appears exactly once.
# ---------------------------------------------------------------------------
Readonly my $PKG => 'Text::Names::Abbreviate';

# Test-name inputs
Readonly my $THREE   => 'John Quincy Adams';
Readonly my $TWO     => 'John Adams';
Readonly my $SINGLE  => 'Madonna';
Readonly my $SINGLE2 => 'X';

# Comma-form equivalents
Readonly my $COMMA_THREE => 'Adams, John Quincy';
Readonly my $COMMA_TWO   => 'Adams, John';

# Leading-comma forms
Readonly my $LEAD_TWO  => ', John Quincy';
Readonly my $LEAD_ONE  => ', John';

# Separator tokens used across sections
Readonly my $SEP_DOT   => '.';
Readonly my $SEP_DASH  => '-';
Readonly my $SEP_EMPTY => '';
Readonly my $SEP_COLON => ':';

# All format/style option values
Readonly my @ALL_FORMATS => qw(default initials compact shortlast);
Readonly my @ALL_STYLES  => qw(first_last last_first);

# ===========================================================================
# SECTION 1 — Single-name × format × style (8-cell matrix)
#
# Strategy: a single-token name means _extract_parts pops the token as
# last_name and leaves @initials empty.  When style=last_first and format is
# compact or initials, the reorder condition
#     $style eq last_first  &&  $format ne default  &&  $format ne shortlast
#     && length $last_name       <-- NB: always true here; see dead-code note
# fires: the last-name initial is unshifted onto @initials and $last_name is
# cleared.  The formatter then sees a non-empty @initials and an empty
# $last_name.  These are the two genuine coverage gaps.
#
# Dead-code note: the `&& length $last_name` sub-condition in _extract_parts
# is unreachable in the else (non-leading-comma) branch because
# `$last_name = pop @parts` from a non-empty split result is always non-empty.
# The guard is defensive but never evaluates to false in production.
# ===========================================================================

subtest 'single-name: default format, both styles' => sub {
	# No initials exist; default format returns $last_name unchanged
	# (Branch U: "return $last_name unless @{$initials}").
	is(abbreviate($SINGLE, { style => 'first_last' }), $SINGLE, 'default/first_last: unchanged');
	is(abbreviate($SINGLE, { style => 'last_first' }), $SINGLE, 'default/last_first: unchanged (no initials → Branch U)');
	done_testing();
};

subtest 'single-name: initials format, both styles' => sub {
	# first_last: last_name 'Madonna' → initial 'M' pushed, result 'M.'
	is(abbreviate($SINGLE, { format => 'initials', style => 'first_last' }), 'M.', 'initials/first_last: "M."');

	# last_first: _extract_parts reorder fires → @initials=['M'], last_name=''.
	# Formatter: push @letters only if length $last_name → false → skip.
	# Result: join('.','M').'.' = 'M.'  [COVERAGE GAP: M-false path via reorder]
	is(abbreviate($SINGLE, { format => 'initials', style => 'last_first' }), 'M.', 'initials/last_first: "M." (reorder, empty last_name)');
	done_testing();
};

subtest 'single-name: compact format, both styles' => sub {
	# first_last: no initials, last_name='Madonna', takes last initial → 'M'
	is(abbreviate($SINGLE, { format => 'compact', style => 'first_last' }), 'M', 'compact/first_last: "M"');

	# last_first: _extract_parts reorder fires → @initials=['M'], last_name=''.
	# Formatter: (length '' ? ... : ()) → empty list → join q{}, ['M'] = 'M'
	# [COVERAGE GAP: K-false path via single-token last_first reorder]
	is(abbreviate($SINGLE, { format => 'compact', style => 'last_first' }), 'M', 'compact/last_first: "M" (reorder, empty last_name)');
	done_testing();
};

subtest 'single-name: shortlast format, both styles' => sub {
	# first_last: @initials empty → joined='', length(joined)=0 → returns $last_name (Branch B3)
	is(abbreviate($SINGLE, { format => 'shortlast', style => 'first_last' }), $SINGLE, 'shortlast/first_last: unchanged (Branch B3)');

	# last_first: $style eq last_first && length 'Madonna' → TRUE.
	#   But length($joined) = 0 → returns $last_name (Branch A2)
	is(abbreviate($SINGLE, { format => 'shortlast', style => 'last_first' }), $SINGLE, 'shortlast/last_first: unchanged (Branch A2)');
	done_testing();
};

subtest 'single-name: separator has no effect (no initials to separate)' => sub {
	# For default/shortlast, the separator only appears after initials.
	# With no initials, any separator must produce the same output.
	for my $fmt (qw(default shortlast)) {
		for my $sep ($SEP_DOT, $SEP_DASH, $SEP_EMPTY, $SEP_COLON) {
			my $result = abbreviate($SINGLE, { format => $fmt, separator => $sep });
			is($result, $SINGLE, "$fmt sep='$sep': single name unchanged");
		}
	}
	done_testing();
};

# ===========================================================================
# SECTION 2 — Two-token name × format × style (default separator)
# ===========================================================================

subtest 'two-token: all format × style combinations' => sub {
	my %expected = (
		'default|first_last'   => 'J. Adams',
		'default|last_first'   => 'Adams, J.',
		'initials|first_last'  => 'J.A.',
		'initials|last_first'  => 'A.J.',
		'compact|first_last'   => 'JA',
		'compact|last_first'   => 'AJ',
		'shortlast|first_last' => 'J. Adams',
		'shortlast|last_first' => 'Adams, J.',
	);

	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			my $key    = "$fmt|$sty";
			my $result = abbreviate($TWO, { format => $fmt, style => $sty });
			is($result, $expected{$key}, "two-token $key => '$expected{$key}'");
		}
	}
	done_testing();
};

# ===========================================================================
# SECTION 3 — Leading-comma × format × style (8-cell matrix)
#
# Strategy: when had_leading_comma=1, _extract_parts takes the first branch
# (all tokens become initials, last_name='').  The last_first reordering
# condition is in the ELSE branch and is never reached.  Therefore,
# style=last_first has NO effect on the output for leading-comma inputs.
# This section makes that invariant explicit.
# ===========================================================================

subtest 'leading-comma: last_first produces same output as first_last' => sub {
	# All 4 formats: with $LEAD_TWO (', John Quincy') the result must be
	# identical regardless of style.
	my %expected = (
		'default'   => 'J. Q.',
		'initials'  => 'J.Q.',
		'compact'   => 'JQ',
		'shortlast' => 'J. Q.',
	);

	for my $fmt (@ALL_FORMATS) {
		my $r_fl = abbreviate($LEAD_TWO, { format => $fmt, style => 'first_last' });
		my $r_lf = abbreviate($LEAD_TWO, { format => $fmt, style => 'last_first' });
		is($r_fl, $expected{$fmt}, "leading-comma $fmt/first_last => '$expected{$fmt}'");
		is($r_lf, $expected{$fmt}, "leading-comma $fmt/last_first => same as first_last");
	}
	done_testing();
};

subtest 'leading-comma: single-initial form (LEAD_ONE = ", John")' => sub {
	my %expected = (
		'default'   => 'J.',
		'initials'  => 'J.',
		'compact'   => 'J',
		'shortlast' => 'J.',
	);

	for my $fmt (@ALL_FORMATS) {
		my $result = abbreviate($LEAD_ONE, { format => $fmt });
		is($result, $expected{$fmt}, "LEAD_ONE $fmt => '$expected{$fmt}'");
	}
	done_testing();
};

subtest 'leading-comma: separator applies only to initials (no last-name token)' => sub {
	# With a leading comma there is no last name, so the separator appears
	# only in the initial positions.
	is(abbreviate($LEAD_TWO, { separator => $SEP_COLON }),                      'J: Q:', 'default + colon');
	is(abbreviate($LEAD_TWO, { format => 'initials', separator => $SEP_COLON }), 'J:Q:',  'initials + colon');
	is(abbreviate($LEAD_TWO, { format => 'shortlast', separator => $SEP_COLON }),'J: Q:', 'shortlast + colon');
	is(abbreviate($LEAD_TWO, { separator => $SEP_EMPTY }),                       'J Q',   'default + empty sep');
	is(abbreviate($LEAD_TWO, { format => 'initials', separator => $SEP_EMPTY }), 'JQ',    'initials + empty sep');
	done_testing();
};

# ===========================================================================
# SECTION 4 — separator="" cross-format × style matrix
#
# Empty separator eliminates all punctuation between initials.  Compact is
# always empty regardless of separator; others collapse dots/dashes to nothing.
# ===========================================================================

subtest 'separator="" × all formats × both styles for three-part name' => sub {
	# Pre-computed expected values (separator="" removes all init punctuation).
	my %expected = (
		'default|first_last'   => 'J Q Adams',
		'default|last_first'   => 'Adams, J Q',    # gap: last_first + empty sep
		'initials|first_last'  => 'JQA',
		'initials|last_first'  => 'AJQ',            # gap: last_first + empty sep
		'compact|first_last'   => 'JQA',            # compact always ignores sep
		'compact|last_first'   => 'AJQ',            # compact always ignores sep
		'shortlast|first_last' => 'J Q Adams',
		'shortlast|last_first' => 'Adams, J Q',     # gap: last_first + empty sep
	);

	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			my $key    = "$fmt|$sty";
			my $result = abbreviate($THREE, { format => $fmt, style => $sty, separator => $SEP_EMPTY });
			is($result, $expected{$key}, "sep='' $key => '$expected{$key}'");
		}
	}
	done_testing();
};

subtest 'separator="" for two-token and single-token names' => sub {
	is(abbreviate($TWO,    { separator => $SEP_EMPTY }), 'J Adams', 'two-token default empty sep');
	is(abbreviate($TWO,    { format => 'initials',  separator => $SEP_EMPTY }), 'JA', 'two-token initials empty sep');
	is(abbreviate($TWO,    { format => 'compact',   separator => $SEP_EMPTY }), 'JA', 'two-token compact empty sep (always)');
	is(abbreviate($TWO,    { format => 'shortlast', separator => $SEP_EMPTY }), 'J Adams', 'two-token shortlast empty sep');
	is(abbreviate($SINGLE, { separator => $SEP_EMPTY }), $SINGLE, 'single name empty sep: no change');
	done_testing();
};

# ===========================================================================
# SECTION 5 — shortlast + last_first + separator variations
# (Gap: only ':' was tested in unit.t for this combination.)
# ===========================================================================

subtest 'shortlast + last_first + all four separators' => sub {
	is(
		abbreviate($THREE, { format => 'shortlast', style => 'last_first', separator => $SEP_DOT }),
		'Adams, J. Q.',
		'shortlast/last_first/dot',
	);
	is(
		abbreviate($THREE, { format => 'shortlast', style => 'last_first', separator => $SEP_DASH }),
		'Adams, J- Q-',
		'shortlast/last_first/dash',    # gap: previously only ":" was tested
	);
	is(
		abbreviate($THREE, { format => 'shortlast', style => 'last_first', separator => $SEP_EMPTY }),
		'Adams, J Q',
		'shortlast/last_first/empty',   # gap: empty separator with last_first+shortlast
	);
	is(
		abbreviate($THREE, { format => 'shortlast', style => 'last_first', separator => $SEP_COLON }),
		'Adams, J: Q:',
		'shortlast/last_first/colon',
	);
	done_testing();
};

subtest 'default + last_first + dash and empty separators' => sub {
	is(
		abbreviate($THREE, { style => 'last_first', separator => $SEP_DASH }),
		'Adams, J- Q-',
		'default/last_first/dash',
	);
	is(
		abbreviate($THREE, { style => 'last_first', separator => $SEP_EMPTY }),
		'Adams, J Q',
		'default/last_first/empty',
	);
	done_testing();
};

# ===========================================================================
# SECTION 6 — Explicit shortlast ternary paths (A1, A2, B1, B2, B3)
#
# The shortlast formatter has the most complex branch structure:
#
#   if (last_first AND has_last_name) {          -- Path A
#     has_joined ? "$last, $joined" : $last_name  -- A1, A2
#   } else {                                      -- Path B
#     has_joined
#       ? (has_last_name ? "$joined $last" : $joined)  -- B1, B2
#       : $last_name                              -- B3
#   }
# ===========================================================================

subtest 'shortlast path A1: last_first + has_last_name + has_initials' => sub {
	# Three-part: initials=['J','Q'], last='Adams'; style=last_first → A1
	is(
		abbreviate($THREE, { format => 'shortlast', style => 'last_first' }),
		'Adams, J. Q.',
		'A1: "Adams, J. Q."',
	);
	done_testing();
};

subtest 'shortlast path A2: last_first + has_last_name + NO initials (single name)' => sub {
	# Single-token: initials=[], last='Madonna'; style=last_first.
	# joined=''; length(joined)=0 → returns $last_name = 'Madonna' (A2)
	is(
		abbreviate($SINGLE, { format => 'shortlast', style => 'last_first' }),
		$SINGLE,
		'A2: single-token last_first → last_name unchanged',
	);
	done_testing();
};

subtest 'shortlast path B1: first_last + has_initials + has_last_name' => sub {
	# Three-part first_last: joined='J. Q.', last='Adams' → "$joined $last"
	is(
		abbreviate($THREE, { format => 'shortlast', style => 'first_last' }),
		'J. Q. Adams',
		'B1: "J. Q. Adams"',
	);
	done_testing();
};

subtest 'shortlast path B2: first_last + has_initials + NO last_name (leading comma)' => sub {
	# Leading comma: had_leading_comma=1 → last_name=''; joined is non-empty.
	# → returns $joined (no last_name to append)
	is(
		abbreviate($LEAD_TWO, { format => 'shortlast', style => 'first_last' }),
		'J. Q.',
		'B2: "J. Q." (no last_name)',
	);
	# Also verify that last_first does NOT change the output (B-path instead of A).
	is(
		abbreviate($LEAD_TWO, { format => 'shortlast', style => 'last_first' }),
		'J. Q.',
		'B2 (last_first style): still "J. Q." — no last_name → A-path not taken',
	);
	done_testing();
};

subtest 'shortlast path B3: first_last + NO initials + ($last_name returned)' => sub {
	# Single-token first_last: initials=[], joined='', length(joined)=0 → returns $last_name
	is(
		abbreviate($SINGLE, { format => 'shortlast', style => 'first_last' }),
		$SINGLE,
		'B3: single-token first_last → last_name unchanged',
	);
	done_testing();
};

# ===========================================================================
# SECTION 7 — Explicit default-format paths (U, V, W, X)
#
# Default format:
#   U: no initials        → return $last_name  (single token)
#   V: last_first + last  → "$last_name, $joined"
#   W: first_last + last  → "$joined $last_name"
#   X: no last_name       → $joined  (leading comma case)
# ===========================================================================

subtest 'default path U: no initials → last_name returned directly' => sub {
	is(abbreviate($SINGLE),                             $SINGLE, 'U: "Madonna" (first_last)');
	is(abbreviate($SINGLE, { style => 'last_first' }),  $SINGLE, 'U: "Madonna" (last_first — same, no initials)');
	done_testing();
};

subtest 'default path V: last_first + has last_name' => sub {
	is(abbreviate($THREE, { style => 'last_first' }),              'Adams, J. Q.', 'V three-part');
	is(abbreviate($TWO,   { style => 'last_first' }),              'Adams, J.',    'V two-part');
	is(abbreviate($THREE, { style => 'last_first', separator => $SEP_DASH }), 'Adams, J- Q-', 'V with dash sep');
	done_testing();
};

subtest 'default path W: first_last + has last_name' => sub {
	is(abbreviate($THREE),                                          'J. Q. Adams', 'W three-part');
	is(abbreviate($TWO),                                            'J. Adams',    'W two-part');
	is(abbreviate($THREE, { separator => $SEP_DASH }),              'J- Q- Adams', 'W with dash sep');
	done_testing();
};

subtest 'default path X: no last_name (leading comma) → just joined initials' => sub {
	is(abbreviate($LEAD_TWO),                                       'J. Q.',   'X two initials');
	is(abbreviate($LEAD_ONE),                                       'J.',      'X one initial');
	is(abbreviate($LEAD_TWO, { style => 'last_first' }),            'J. Q.',   'X last_first style irrelevant (no last_name)');
	is(abbreviate($LEAD_TWO, { separator => $SEP_COLON }),          'J: Q:',   'X colon separator');
	done_testing();
};

# ===========================================================================
# SECTION 8 — compact ignores separator (invariant)
#
# The compact formatter does join(q{}, ...) with no sep argument.
# Any separator value must produce identical output.
# ===========================================================================

subtest 'compact: separator option has no effect (all 4 separator values)' => sub {
	for my $sty (@ALL_STYLES) {
		my $expected = ($sty eq 'first_last') ? 'JQA' : 'AJQ';
		for my $sep ($SEP_DOT, $SEP_DASH, $SEP_EMPTY, $SEP_COLON) {
			my $result = abbreviate($THREE, { format => 'compact', style => $sty, separator => $sep });
			is($result, $expected, "compact/$sty sep='$sep': always '$expected'");
		}
	}
	done_testing();
};

# ===========================================================================
# SECTION 9 — 3+ consecutive comma normalization
#
# s/,+/,/g (the fix for the original s/,,/,/g) must collapse any run of
# commas — including odd-length runs — to a single comma in one pass.
# Tests at 3, 4, and 5 commas (the minimal non-trivial cases).
# ===========================================================================

subtest 's/,+/,/g fix: 3 consecutive commas (minimum above double)' => sub {
	# Adams,,,John → collapse to Adams,John → reorder → 'John Adams' → 'J. Adams'
	is(abbreviate('Adams,,,John'), 'J. Adams', '3-comma reorder');
	# ,,,John → collapse to ,John → leading comma → 'J.'
	is(abbreviate(',,,John'),      'J.',        '3 leading commas → single initial');
	# Adams,,, → collapse to Adams, → trailing comma → 'Adams'
	is(abbreviate('Adams,,,'),     'Adams',     '3 trailing commas → last name only');
	done_testing();
};

subtest 's/,+/,/g fix: 4 and 5 consecutive commas' => sub {
	is(abbreviate('Adams,,,,John'),  'J. Adams', '4-comma reorder');
	is(abbreviate('Adams,,,,,John'), 'J. Adams', '5-comma reorder');
	is(abbreviate(',,,,John'),       'J.',       '4 leading commas → single initial');
	is(abbreviate(',,,,,John'),      'J.',       '5 leading commas → single initial');
	done_testing();
};

subtest 's/,+/,/g fix: comma-only strings' => sub {
	# A string of only commas collapses to a single comma, which splits into
	# empty left and right → early return ('', 0) → abbreviate returns ''.
	is(abbreviate(',,,'),   '', '3-comma-only string yields empty output');
	is(abbreviate(',,,,'),  '', '4-comma-only string yields empty output');
	done_testing();
};

subtest 's/,+/,/g fix: Last, First with extra embedded commas' => sub {
	# Double comma embedded: 'Adams,,John Quincy' → still reorders correctly
	is(abbreviate('Adams,,John Quincy'),  'J. Q. Adams', 'double-embedded comma reordered');
	is(abbreviate('Adams,,,John Quincy'), 'J. Q. Adams', 'triple-embedded comma reordered');
	done_testing();
};

# ===========================================================================
# SECTION 10 — Test::Returns schema validation
#
# Every output of abbreviate() must satisfy { type => 'string' } per the POD.
# This section validates all new call sites introduced in this file.
# ===========================================================================

subtest 'return schema: single-name × all formats × both styles' => sub {
	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			my $result = abbreviate($SINGLE, { format => $fmt, style => $sty });
			returns_ok($result, { type => 'string' }, "single/$fmt/$sty is a string");
		}
	}
	done_testing();
};

subtest 'return schema: leading-comma × all formats × both styles' => sub {
	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			my $result = abbreviate($LEAD_TWO, { format => $fmt, style => $sty });
			returns_ok($result, { type => 'string' }, "lead-comma/$fmt/$sty is a string");
		}
	}
	done_testing();
};

subtest 'return schema: empty separator × all formats × both styles' => sub {
	for my $fmt (@ALL_FORMATS) {
		for my $sty (@ALL_STYLES) {
			my $result = abbreviate($THREE, { format => $fmt, style => $sty, separator => $SEP_EMPTY });
			returns_ok($result, { type => 'string' }, "sep=''/$fmt/$sty is a string");
		}
	}
	done_testing();
};

subtest 'return schema: 3-comma normalization outputs' => sub {
	for my $input ('Adams,,,John', ',,,John', 'Adams,,,', ',,,', ',,,,') {
		my $result = abbreviate($input);
		returns_ok($result, { type => 'string' }, "3-comma '$input' returns a string");
		diag("  '$input' => '$result'") if $ENV{TEST_VERBOSE};
	}
	done_testing();
};

done_testing();
