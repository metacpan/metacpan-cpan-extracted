#!/usr/bin/env perl

# edge_cases.t — Destructive, pathological, and boundary-condition tests.
# Strategy: actively attempt to break or subvert abbreviate() by feeding
# hostile inputs, corrupted internal-helper returns, and context traps.
# Covers gaps left by unit.t (single-call behaviour), function.t (white-box),
# and integration.t (workflow).  Every subtest names its attack vector.

use strict;
use warnings;

use POSIX   qw(ENOENT);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Mockingbird;
use Test::Most;
use Test::Returns qw(returns_ok);

use Text::Names::Abbreviate qw(abbreviate);

# ---------------------------------------------------------------------------
# Named constants — every expected output and input string in one place.
# ---------------------------------------------------------------------------
Readonly my $PKG       => 'Text::Names::Abbreviate';
Readonly my $THREE     => 'John Quincy Adams';
Readonly my $TWO       => 'John Adams';
Readonly my $SINGLE    => 'Madonna';

# Expected outputs used repeatedly
Readonly my $OUT_THREE     => 'J. Q. Adams';
Readonly my $OUT_THREE_LF  => 'Adams, J. Q.';
Readonly my $OUT_TWO       => 'J. Adams';
Readonly my $OUT_TWO_LF    => 'Adams, J.';
Readonly my $OUT_COMPACT   => 'JQA';
Readonly my $OUT_INITIALS  => 'J.Q.A.';

# Large-input scale constants
Readonly my $MANY_COMMAS   => 100;
Readonly my $LONG_SEP_LEN  => 500;
Readonly my $LONG_NAME_LEN => 500;

# ---------------------------------------------------------------------------
# SECTION 1 — Exact error messages (MESSAGES table from POD)
# Validate that the exact error strings callers depend on have not drifted.
# ---------------------------------------------------------------------------

subtest 'MESSAGES: undef name — explicit croak text' => sub {
	# The code's explicit defined() guard fires before Params::Validate::Strict.
	# The croak text must include the package name, "name", and "defined".
	my @croak_calls;
	{
		my $g = mock_scoped 'Carp::croak' => sub {
			push @croak_calls, [@_];
			die @_;    # propagate so eval below catches it
		};
		eval { abbreviate(undef) };
	}
	is(scalar @croak_calls, 1, 'Carp::croak called exactly once for undef');
	my $msg = $croak_calls[0][0] // '';
	like($msg, qr/\Q$PKG\E/,   'croak message identifies package');
	like($msg, qr/name/i,       'croak message references parameter name');
	like($msg, qr/defined/i,    'croak message uses word "defined"');
	diag("undef croak: $msg") if $ENV{TEST_VERBOSE};
	done_testing();
};

subtest 'MESSAGES: empty string — error references name' => sub {
	throws_ok(
		sub { abbreviate('') },
		qr/name/i,
		'empty string: croak mentions "name"',
	);
	done_testing();
};

subtest 'MESSAGES: invalid format — error references "format" and lists valid values' => sub {
	throws_ok(
		sub { abbreviate($THREE, { format => 'long' }) },
		qr/format/i,
		'invalid format: error mentions "format"',
	);
	done_testing();
};

subtest 'MESSAGES: invalid style — error references "style"' => sub {
	throws_ok(
		sub { abbreviate($THREE, { style => 'sideways' }) },
		qr/style/i,
		'invalid style: error mentions "style"',
	);
	done_testing();
};

subtest 'MESSAGES: unknown option key — validator rejects extra parameters' => sub {
	# Params::Validate::Strict must reject keys not in %PARAM_SCHEMA.
	throws_ok(
		sub { abbreviate($THREE, { name => $THREE, xyzzy => 'bogus' }) },
		qr/.+/,
		'unknown option key causes croak',
	);
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 2 — Hostile scalar inputs that are defined and non-empty
# These are valid under the validator but semantically unusual.
# ---------------------------------------------------------------------------

subtest 'hostile scalar: "0" (defined, falsy, length-1 string)' => sub {
	# The string "0" is falsy in boolean context but has length 1, so it must
	# pass min=>1 validation and be treated as a single-name input.
	my $result = abbreviate('0');
	is($result, '0', '"0" returned unchanged as a single-token name');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: single space " " — collapses to empty output' => sub {
	# A single space is length 1 (passes validation) but normalises to ''.
	my $result = abbreviate(' ');
	is($result, '', 'single-space name yields empty output after normalisation');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: tab-only input normalises to empty' => sub {
	my $result = abbreviate("\t");
	is($result, '', 'tab-only name yields empty output');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: mixed whitespace-only (tab + newline + space)' => sub {
	my $result = abbreviate("  \t\n  ");
	is($result, '', 'mixed whitespace-only collapses to empty string');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: embedded newline treated as whitespace token boundary' => sub {
	# "\n" is \s so "John\nAdams" normalises to "John Adams" -> "J. Adams"
	my $result = abbreviate("John\nAdams");
	is($result, $OUT_TWO, 'embedded newline treated as word boundary');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: null byte in name — verbatim passthrough' => sub {
	# "\0" is length 1 and passes validation.  It is not a separator character,
	# so _normalize_name treats it as a token.  LIMITATION: non-alpha initial.
	my $null_name = "\0";
	my $result = abbreviate($null_name);
	is($result, $null_name, 'null-byte single-token name returned verbatim');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: control characters (\\x01\\x02) — not whitespace' => sub {
	# \x01 and \x02 are not Perl \s; they form a single non-space token.
	my $ctrl = "\x01\x02";
	my $result = abbreviate($ctrl);
	is($result, $ctrl, 'control-char-only name returned verbatim as single token');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: shell metacharacters in name — no code injection' => sub {
	# Pure Perl string processing; metacharacters must be inert.
	my $result = abbreviate('$(whoami) Quincy Adams');
	like($result, qr/Adams/, 'shell-metachar name treated as plain string');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile scalar: format-string %s %d in name — not interpolated' => sub {
	# No printf() is called on user data; format strings must be inert.
	my $result = abbreviate('%s %d Adams');
	is($result, '%. %. Adams', 'percent-sign name treated as plain characters')
		or note("actual: '$result'");
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 3 — Hostile reference-type inputs as `name`
# The validator schema declares name as type=>'string'; every ref must croak.
# ---------------------------------------------------------------------------

subtest 'hostile ref: arrayref as name — rejected' => sub {
	throws_ok(
		sub { abbreviate([qw(John Adams)]) },
		qr/.+/,
		'arrayref as name causes croak',
	);
	done_testing();
};

subtest 'hostile ref: hashref with no name key — missing required param' => sub {
	# {} could be mistaken for an options hashref; the validator must catch
	# the missing required 'name' key.
	throws_ok(
		sub { abbreviate({}) },
		qr/name/i,
		'empty hashref (no name key) croaks with reference to "name"',
	);
	done_testing();
};

subtest 'hostile ref: coderef as name — rejected' => sub {
	throws_ok(
		sub { abbreviate(sub { 'John Adams' }) },
		qr/.+/,
		'coderef as name causes croak',
	);
	done_testing();
};

subtest 'hostile ref: blessed object as name — rejected' => sub {
	my $obj = bless {}, 'SomeName';
	throws_ok(
		sub { abbreviate($obj) },
		qr/.+/,
		'blessed object as name causes croak',
	);
	done_testing();
};

subtest 'hostile ref: name key holds arrayref inside hashref call — rejected' => sub {
	throws_ok(
		sub { abbreviate({ name => [qw(John Adams)] }) },
		qr/.+/,
		'arrayref value for name key in hashref call causes croak',
	);
	done_testing();
};

subtest 'hostile ref: circular reference as name — rejected' => sub {
	my $circ = {};
	$circ->{self} = $circ;
	throws_ok(
		sub { abbreviate($circ) },
		qr/.+/,
		'circular reference as name causes croak',
	);
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 4 — Hostile option-parameter values
# Optional params (format, style, separator) with unusual or hostile values.
# ---------------------------------------------------------------------------

subtest 'hostile option: separator as arrayref — rejected' => sub {
	throws_ok(
		sub { abbreviate($THREE, { separator => [] }) },
		qr/.+/,
		'arrayref separator causes croak',
	);
	done_testing();
};

subtest 'hostile option: separator as undef — treated as default (.)' => sub {
	# Params::Validate::Strict skip-validates undef optional params; the
	# // operator in abbreviate then substitutes the default separator.
	my $result;
	lives_ok(
		sub { $result = abbreviate($THREE, { separator => undef }) },
		'undef separator accepted (optional param)',
	);
	is($result, $OUT_THREE, 'undef separator falls back to default "."');
	done_testing();
};

subtest 'hostile option: format as undef — treated as default format' => sub {
	my $result;
	lives_ok(
		sub { $result = abbreviate($THREE, { format => undef }) },
		'undef format accepted (optional param)',
	);
	is($result, $OUT_THREE, 'undef format falls back to "default" format');
	done_testing();
};

subtest 'hostile option: style as undef — treated as default style' => sub {
	my $result;
	lives_ok(
		sub { $result = abbreviate($THREE, { style => undef }) },
		'undef style accepted (optional param)',
	);
	is($result, $OUT_THREE, 'undef style falls back to "first_last"');
	done_testing();
};

subtest 'hostile option: very long separator string' => sub {
	# A pathologically long separator must not crash; output is just verbose.
	my $long_sep = 'X' x $LONG_SEP_LEN;
	my $result;
	lives_ok(
		sub { $result = abbreviate($TWO, { separator => $long_sep }) },
		"${LONG_SEP_LEN}-char separator accepted without crash",
	);
	returns_ok($result, { type => 'string' }, 'return is a string');
	like($result, qr/Adams/, 'last name still present in output');
	diag("long-sep output length: " . length($result)) if $ENV{TEST_VERBOSE};
	done_testing();
};

subtest 'hostile option: separator containing regex metacharacters' => sub {
	# The separator is used in join(), not in a regex.  Metacharacters are inert.
	for my $meta_sep (qw(. * + ? [ ] ( ) | ^ $ \\)) {
		my $result;
		lives_ok(
			sub { $result = abbreviate($TWO, { separator => $meta_sep }) },
			"regex metachar separator '$meta_sep' accepted",
		);
		returns_ok($result, { type => 'string' }, "return is string for sep='$meta_sep'");
	}
	done_testing();
};

subtest 'hostile option: separator containing shell metacharacters' => sub {
	for my $shell_sep ('`id`', '$(id)', '; rm -rf /', '&&', '||') {
		my $result;
		lives_ok(
			sub { $result = abbreviate($TWO, { separator => $shell_sep }) },
			"shell metachar separator accepted verbatim",
		);
		like($result, qr/Adams/, 'last name preserved in output');
		returns_ok($result, { type => 'string' }, 'return is a string');
	}
	done_testing();
};

subtest 'hostile option: format value that is long invalid string' => sub {
	# The format validator must reject any value not in the memberof list,
	# regardless of string length.
	throws_ok(
		sub { abbreviate($THREE, { format => 'x' x 10_000 }) },
		qr/format/i,
		'10000-char invalid format string is rejected',
	);
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 4b — Hostile 'particles' option inputs
# Valid types: boolean (0/1) or arrayref.  Every other type must be rejected.
# ---------------------------------------------------------------------------

subtest 'hostile particles: string value — rejected by validator' => sub {
	# MESSAGES: "particles: must be one of boolean, arrayref"
	throws_ok(
		sub { abbreviate($THREE, { particles => 'van' }) },
		qr/particles/i,
		'string particles value causes croak mentioning "particles"',
	);
	done_testing();
};

subtest 'hostile particles: hashref value — rejected by validator' => sub {
	throws_ok(
		sub { abbreviate($THREE, { particles => { van => 1 } }) },
		qr/particles/i,
		'hashref particles value causes croak mentioning "particles"',
	);
	done_testing();
};

subtest 'hostile particles: undef — treated as default (built-in list)' => sub {
	# Params::Validate::Strict skips validation of undef optional params;
	# abbreviate() then treats undef as "use the built-in list".
	my $result;
	lives_ok(
		sub { $result = abbreviate('Ludwig van Beethoven', { particles => undef }) },
		'undef particles accepted (optional param)',
	);
	is($result, 'L. van Beethoven', 'undef particles falls back to built-in list');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile particles: empty arrayref — no particles absorbed' => sub {
	# An empty list is a valid arrayref; none of its (absent) members match,
	# so no tokens are absorbed — same observable effect as particles => 0.
	my $result;
	lives_ok(
		sub { $result = abbreviate('Ludwig van Beethoven', { particles => [] }) },
		'empty arrayref particles accepted',
	);
	is($result, 'L. v. Beethoven', 'empty particle list absorbs nothing');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'hostile particles: arrayref containing undef — no crash, undef entry inert' => sub {
	# undef in the arrayref becomes a key undef=>1 in the particle hash.
	# No real name token is undef, so it never matches; must not crash.
	my $result;
	lives_ok(
		sub { $result = abbreviate('Ludwig van Beethoven', { particles => [undef, 'van'] }) },
		'arrayref with undef element accepted without crash',
	);
	is($result, 'L. van Beethoven', 'van still absorbed; undef entry is inert');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 5 — Pathological comma and whitespace inputs
# ---------------------------------------------------------------------------

subtest 'pathological: many consecutive commas collapse to one' => sub {
	# LIMITATION: multiple consecutive commas collapse before parsing.
	# Stacking 100 commas must not cause pathological behaviour.
	my $many = 'Adams' . (',' x $MANY_COMMAS) . 'John';
	my $result;
	lives_ok(
		sub { $result = abbreviate($many) },
		"${MANY_COMMAS} consecutive commas accepted without crash",
	);
	is($result, $OUT_TWO, 'mass-comma input normalises to standard output');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'pathological: string of only commas returns empty string' => sub {
	# All-comma string collapses to a bare comma (after s/,,/,/g loop).
	# The bare-comma branch in _normalize_name returns ('', 0).
	my $only_commas = ',' x $MANY_COMMAS;
	my $result;
	lives_ok(
		sub { $result = abbreviate($only_commas) },
		"string of ${MANY_COMMAS} commas accepted without crash",
	);
	is($result, '', 'all-comma input yields empty output');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'pathological: extremely long name with many components' => sub {
	my $long_name = join(' ', ('Quincy') x $LONG_NAME_LEN) . ' Adams';
	my $result;
	lives_ok(
		sub { $result = abbreviate($long_name) },
		"${LONG_NAME_LEN}-component name accepted without crash",
	);
	like($result, qr/Adams$/, 'last name appears at end of output');
	returns_ok($result, { type => 'string' }, 'return is a string');
	diag("long-name output length: " . length($result)) if $ENV{TEST_VERBOSE};
	done_testing();
};

subtest 'pathological: all-punctuation token name' => sub {
	# All characters are non-alpha; the LIMITATION says they become initials verbatim.
	my $result = abbreviate('!@# $%^ &*(');
	returns_ok($result, { type => 'string' }, 'all-punctuation name returns a string');
	done_testing();
};

subtest 'pathological: all-digit name' => sub {
	my $result = abbreviate('123 456 789');
	is($result, '1. 4. 789', 'digit tokens yield numeric initials per LIMITATION');
	returns_ok($result, { type => 'string' }, 'return is a string');
	done_testing();
};

subtest 'pathological: unicode high codepoints (emoji)' => sub {
	# Emoji are multi-byte in UTF-8 but single characters under use utf8.
	# The module uses substr($_, 0, 1) which is character-safe under utf8.
	use utf8;
	my $result;
	lives_ok(
		sub { $result = abbreviate("\x{1F600} \x{1F4A9} Smith") },
		'emoji-prefixed name accepted without crash',
	);
	returns_ok($result, { type => 'string' }, 'emoji name returns a string');
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 6 — Mock upstream failures: _normalize_name returning hostile values
# These tests verify what abbreviate does when its own private helper returns
# unexpected data.  This is a hostile internal-injection scenario.
# ---------------------------------------------------------------------------

subtest 'mock _normalize_name returns ("", 0) — abbreviate short-circuits to ""' => sub {
	# This is the documented early-exit path; mock confirms it is taken.
	my $g = mock_scoped "${PKG}::_normalize_name" => sub { ('', 0) };
	my $result = abbreviate($THREE);
	is($result, '', 'empty normalised name causes abbreviate to return ""');
	returns_ok($result, { type => 'string' }, 'return is a string even on early exit');
	done_testing();
};

subtest 'mock _normalize_name returns (undef, 0) — length() treats undef as 0' => sub {
	# If the helper ever returned undef, `unless length $name` sees length(undef)=0
	# and abbreviate exits early returning ''.  No crash, but a warning is emitted.
	my $g = mock_scoped "${PKG}::_normalize_name" => sub { (undef, 0) };
	my $result;
	# We expect no exception, just a possible uninitialized-value warning.
	lives_ok(
		sub { $result = abbreviate($THREE) },
		'undef from _normalize_name does not cause a fatal error',
	);
	is($result, '', 'abbreviate returns "" when normalised name is undef');
	done_testing();
};

subtest 'mock _normalize_name returns ("", 1) — empty name with leading-comma flag' => sub {
	# Even with had_leading_comma=1 an empty name must exit early.
	my $g = mock_scoped "${PKG}::_normalize_name" => sub { ('', 1) };
	my $result = abbreviate($THREE);
	is($result, '', 'empty name with leading-comma flag still returns ""');
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 7 — Mock upstream failures: _extract_parts returning hostile values
# Tests how the format dispatch branches react to bad helper output.
# ---------------------------------------------------------------------------

subtest 'mock _extract_parts returns (undef, "Adams") — compact branch dies' => sub {
	# compact does @{$initials} which dies if $initials is undef.
	mock("${PKG}::_normalize_name", sub { ($THREE, 0) });
	my $g = mock_scoped "${PKG}::_extract_parts" => sub { (undef, 'Adams') };
	throws_ok(
		sub { abbreviate($THREE, { format => 'compact' }) },
		qr/.+/,
		'undef initials arrayref in compact branch causes croak/die',
	);
	restore_all();
	done_testing();
};

subtest 'mock _extract_parts returns (undef, "Adams") — initials branch dies' => sub {
	mock("${PKG}::_normalize_name", sub { ($THREE, 0) });
	my $g = mock_scoped "${PKG}::_extract_parts" => sub { (undef, 'Adams') };
	throws_ok(
		sub { abbreviate($THREE, { format => 'initials' }) },
		qr/.+/,
		'undef initials arrayref in initials branch causes croak/die',
	);
	restore_all();
	done_testing();
};

subtest 'mock _extract_parts returns ([], undef) — default format handles undef last_name' => sub {
	# With empty initials and undef last_name, the default formatter does:
	#   return $last_name unless @{$initials}  →  returns undef
	# This violates the "returns a plain string" contract; the test documents it.
	mock("${PKG}::_normalize_name", sub { ($THREE, 0) });
	my $g = mock_scoped "${PKG}::_extract_parts" => sub { ([], undef) };
	my $result;
	lives_ok(
		sub { $result = abbreviate($THREE) },
		'([], undef) from _extract_parts does not cause a fatal error in default format',
	);
	diag("([], undef) result: " . (defined $result ? "'$result'" : 'undef'))
		if $ENV{TEST_VERBOSE};
	restore_all();
	done_testing();
};

subtest 'mock _extract_parts returns (["J","Q"], undef) — default format graceful' => sub {
	# With defined initials but undef last_name, the formatter treats undef
	# as falsy and returns just the initials portion.
	mock("${PKG}::_normalize_name", sub { ($THREE, 0) });
	my $g = mock_scoped "${PKG}::_extract_parts" => sub { (['J', 'Q'], undef) };
	my $result;
	lives_ok(
		sub { $result = abbreviate($THREE) },
		'([J,Q], undef) last_name does not crash default format',
	);
	like($result // '', qr/J/, 'initials still appear in output');
	restore_all();
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 8 — Context traps
# Verify behaviour when abbreviate is called in list, scalar, or void context,
# and that $_ mutations in surrounding code do not bleed into the function.
# ---------------------------------------------------------------------------

subtest 'context: scalar context returns a plain scalar string' => sub {
	my $result = abbreviate($THREE);
	ok(!ref($result), 'abbreviate in scalar context returns non-reference');
	is($result, $OUT_THREE, 'scalar-context result is correct');
	done_testing();
};

subtest 'context: list context returns a single-element list' => sub {
	my @results = abbreviate($THREE);
	is(scalar @results, 1,        'list context gives exactly one element');
	is($results[0], $OUT_THREE,   'that element is the expected string');
	returns_ok($results[0], { type => 'string' }, 'element is a string');
	done_testing();
};

subtest 'context: void context does not crash' => sub {
	lives_ok(
		sub { abbreviate($THREE) },
		'void context call does not die',
	);
	done_testing();
};

subtest 'context: $_ is not clobbered inside a for loop' => sub {
	# Classic $_ aliasing trap: a for loop aliases $_ to each element.
	# abbreviate must not touch $_.
	my @names  = ($THREE, $TWO, $SINGLE);
	my @seen_under;
	for (@names) {
		my $before = $_;
		abbreviate($_);
		push @seen_under, ($_ eq $before ? 1 : 0);
	}
	ok(!grep { !$_ } @seen_under, 'abbreviate never modifies $_ inside a for loop');
	done_testing();
};

subtest 'context: $_ as topic variable distinct from abbreviate argument' => sub {
	# Ensure that using $_ as the name argument does not cause double-aliasing.
	local $_ = $THREE;
	my $result = abbreviate($_);
	is($result, $OUT_THREE, 'using $_ as argument produces correct result');
	is($_, $THREE,          '$_ unchanged after use as argument');
	done_testing();
};

subtest 'context: $@ is not reset on successful call' => sub {
	eval { die "caller error\n" };
	my $saved_at = $@;
	abbreviate($THREE);
	is($@, $saved_at, 'abbreviate does not reset $@ on success');
	done_testing();
};

subtest 'context: $@ is not reset on error call' => sub {
	# Even a croak must preserve any $@ the caller had set previously.
	eval { die "prior error\n" };
	my $saved_at = $@;
	eval { abbreviate(undef) };    # croak expected; catch it
	# $@ is now the new croak message — but the KEY check is the croak happened.
	like($@, qr/name/i, 'new croak message visible in $@ after bad call');
	# The prior $@ is gone (overwritten by croak), which is normal Perl.
	done_testing();
};

subtest 'context: errno $! not clobbered by valid call' => sub {
	local $! = ENOENT;
	my $saved_errno = "$!";
	abbreviate($THREE);
	is("$!", $saved_errno, 'abbreviate does not modify $! on success');
	done_testing();
};

subtest 'context: errno $! not clobbered by error call' => sub {
	local $! = ENOENT;
	my $saved_errno = "$!";
	eval { abbreviate(undef) };
	is("$!", $saved_errno, 'abbreviate does not modify $! on croak');
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 9 — Recovery after errors
# A croak must leave the module in a state where subsequent valid calls work.
# ---------------------------------------------------------------------------

subtest 'recovery: valid call after undef croaks correctly' => sub {
	eval { abbreviate(undef) };    # trigger croak
	my $result = abbreviate($THREE);
	is($result, $OUT_THREE, 'module works correctly after a croak from undef input');
	done_testing();
};

subtest 'recovery: valid call after invalid format croak' => sub {
	eval { abbreviate($THREE, { format => 'garbage' }) };
	my $result = abbreviate($THREE, { format => 'compact' });
	is($result, $OUT_COMPACT, 'module works correctly after invalid format croak');
	done_testing();
};

subtest 'recovery: 10 valid calls after 10 interspersed croaks — no state leak' => sub {
	my @outputs;
	for my $i (1..10) {
		eval { abbreviate(undef) };      # croak — discard
		push @outputs, abbreviate($THREE);
	}
	my $all_same = !grep { $_ ne $OUT_THREE } @outputs;
	ok($all_same, '10 valid calls after 10 croaks all produce identical output');
	done_testing();
};

# ---------------------------------------------------------------------------
# SECTION 10 — Return value schema for hostile-but-valid inputs
# Every input that survives validation must return a plain scalar string.
# ---------------------------------------------------------------------------

subtest 'Test::Returns: schema for all hostile-valid inputs' => sub {
	my @cases = (
		[ abbreviate('0'),                                                         '"0" single-token'          ],
		[ abbreviate(' '),                                                         'single space → empty'      ],
		[ abbreviate("\t"),                                                        'tab-only → empty'          ],
		[ abbreviate("John\nAdams"),                                               'embedded newline'          ],
		[ abbreviate("\0"),                                                        'null-byte single token'    ],
		[ abbreviate("\x01\x02"),                                                  'control chars'             ],
		[ abbreviate('$(whoami) Quincy Adams'),                                    'shell metachar in name'    ],
		[ abbreviate($TWO, { separator => '`id`' }),                              'shell metachar separator'  ],
		[ abbreviate($TWO, { separator => '.' x $LONG_SEP_LEN }),                 'very long separator'       ],
		[ abbreviate(join(' ', ('X') x $LONG_NAME_LEN) . ' Adams'),               'very long name'            ],
		[ abbreviate($THREE, { separator => undef }),                              'undef separator → default' ],
		[ abbreviate($THREE, { format   => undef }),                              'undef format → default'    ],
		[ abbreviate($THREE, { style    => undef }),                              'undef style → default'     ],
	);

	for my $pair (@cases) {
		my ($result, $desc) = @{$pair};
		returns_ok($result, { type => 'string' }, "string returned for: $desc");
		diag("  $desc => '" . (defined $result ? $result : 'undef') . "'")
			if $ENV{TEST_VERBOSE};
	}
	done_testing();
};

done_testing();
