#!/usr/bin/perl

# Mutant-killer tests, derived from xt/mutant_20260619_024440.t (mutation.json).
#
# Target mutant:
#   COND_INV_362_2 (MEDIUM) -- lib/Text/Names/Abbreviate.pm line 362
#   Source:   if ($format eq $FMT_SHORTLAST) {
#   Mutation: invert condition `if` to `unless`
#
# FINDING: this mutant is EQUIVALENT and cannot be killed by any test.
#
# By the time line 362 runs, compact/initials have already returned
# (lines 351/356), so only 'shortlast' and 'default' formats can reach
# it.  Under `unless`, format=default takes the shortlast-formula branch
# (lines 363-370) instead of the default-formula branch (372-377), and
# vice versa for format=shortlast.
#
# Investigating why this survived revealed a real bug: the default-
# formula branch gated its final ternary on the *truthiness* of
# $last_name (`$last_name ? ... : ...`), while the shortlast-formula
# branch correctly gated on `length($last_name)`.  Since "0" is the only
# non-empty Perl string that is falsy, a last name of literally "0"
# (e.g. "John 0") was silently dropped by the default formula but kept
# by the shortlast formula -- the two branches disagreed, and so the
# `unless` mutant *was* distinguishable from the (buggy) original.
#
# That bug has been fixed (line 377: `$last_name ?` -> `length($last_name) ?`).
# But fixing it makes the two formulas provably identical for every
# (initials, last_name, style, separator) input: both reduce to
# "if no initials, return last_name as-is; otherwise join initials, then
# prepend/append the last name keyed off length(), not truthiness".
# Once the original and the mutant agree on every input, no test --
# correct or otherwise -- can tell them apart.  This was confirmed by
# brute-force comparison across names, separators (including "0", "",
# multi-char, and whitespace), and both styles: zero differences.
#
# Per the mutant-killers skill: "If writing a valid mutant-killer test
# reveals an actual bug in the source code, assume the test is right and
# output the necessary fix for the code."  The fix has been applied.
# The regression tests below pin that fix.  The final subtest is a
# property-based equivalence guard: if a future change to either the
# default or shortlast formula ever reintroduces a difference, this
# guard fails and COND_INV_362_2 becomes killable again -- at which
# point a real mutant-killer assertion should be added here.

use strict;
use warnings;
use Readonly;
use Test::Most;
use Test::Returns qw(returns_ok);

use Text::Names::Abbreviate qw(abbreviate);

Readonly my $STRING_SCHEMA => { type => 'string' };

# The only input shape (a last name of literally "0") that exposed the
# truthiness-vs-length bug responsible for COND_INV_362_2's survival.
Readonly my $NAME_ZERO_LAST => 'John 0';

subtest 'regression: default format keeps a falsy-but-real last name "0"' => sub {
	# Before the fix this returned "J." (the trailing "0" was dropped
	# because `$last_name ? ...` treats the string "0" as false).
	my $result = abbreviate($NAME_ZERO_LAST);
	is($result, 'J. 0', 'default/first_last keeps "0" as the last name');
	returns_ok($result, $STRING_SCHEMA, 'default/first_last falsy-zero result matches string schema');
};

subtest 'regression: default/last_first already handled "0" correctly' => sub {
	# This path was always gated by length(), so it never had the bug;
	# included to characterise both sides of the style switch.
	my $result = abbreviate($NAME_ZERO_LAST, { style => 'last_first' });
	is($result, '0, J.', 'default/last_first keeps "0" as the last name');
	returns_ok($result, $STRING_SCHEMA, 'default/last_first falsy-zero result matches string schema');
};

subtest 'regression: shortlast format was always correct for "0"' => sub {
	# The shortlast branch already used length() throughout; this pins
	# that it still agrees with the now-fixed default branch.
	my $result = abbreviate($NAME_ZERO_LAST, { format => 'shortlast' });
	is($result, 'J. 0', 'shortlast/first_last keeps "0" as the last name');
	returns_ok($result, $STRING_SCHEMA, 'shortlast/first_last falsy-zero result matches string schema');
};

subtest 'regression: shortlast/last_first was always correct for "0"' => sub {
	my $result = abbreviate($NAME_ZERO_LAST, { format => 'shortlast', style => 'last_first' });
	is($result, '0, J.', 'shortlast/last_first keeps "0" as the last name');
	returns_ok($result, $STRING_SCHEMA, 'shortlast/last_first falsy-zero result matches string schema');
};

subtest 'EQUIVALENT MUTANT GUARD: default and shortlast formulas agree on every input' => sub {
	# This is NOT a mutant-killer in the usual sense: it documents and
	# pins the equivalence that makes COND_INV_362_2 unkillable.  It
	# covers ordinary names, the falsy-zero edge case, leading-comma
	# (no-last-name) input, single tokens, and a spread of separators
	# (default '.', empty, multi-char, and the digit '0' itself, which
	# would interact badly with a truthiness check on the separator).
	#
	# If this subtest ever fails, the two formulas have diverged again --
	# which means COND_INV_362_2 has become a real, killable mutant and a
	# genuine `is(...)` assertion distinguishing the two branches should
	# be added above instead of this guard.
	my @names = ('John Quincy Adams', $NAME_ZERO_LAST, '0 0', 'X', ', John', 'Madonna', '0');
	my @separators = ('.', q{}, '::', '0', '  ');
	my @styles = ('first_last', 'last_first');

	for my $name (@names) {
		for my $sep (@separators) {
			for my $style (@styles) {
				my $default_result = abbreviate($name, {
					format    => 'default',
					style     => $style,
					separator => $sep,
				});
				my $shortlast_result = abbreviate($name, {
					format    => 'shortlast',
					style     => $style,
					separator => $sep,
				});
				is(
					$default_result,
					$shortlast_result,
					"default and shortlast agree for name=[$name] sep=[$sep] style=$style",
				);
			}
		}
	}
};

done_testing();
