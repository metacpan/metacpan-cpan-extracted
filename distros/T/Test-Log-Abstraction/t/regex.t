#!/usr/bin/env perl

# Regex audit tests.  The module's own regular expressions were hardened
# against catastrophic backtracking (possessive quantifiers, a lookbehind so
# a match can only start where a run of whitespace starts).  This file
# proves two things about each change:
#
#   1. It changed nothing: the old and new forms give identical results on
#      thousands of generated strings built from the characters each
#      pattern cares about.
#   2. It is linear: inputs built to make backtracking explode finish
#      within a generous time limit, at sizes where quadratic behaviour
#      would take minutes.

use strict;
use warnings;

use Test::Most;
use Readonly;
use Time::HiRes ();

use Test::Log::Abstraction;

Readonly::Scalar my $SEED => 20261010;	# fixed, so every run checks the same strings
Readonly::Scalar my $SAMPLES => 5_000;
Readonly::Scalar my $MAX_TOKENS => 12;
Readonly::Scalar my $HUGE => 1_000_000;	# characters in an adversarial input
# Whitespace floods are smaller: a long-running regex cannot be interrupted
# by alarm(), so a quadratic regression must fail the budget in seconds,
# not minutes.  At this size a linear pattern takes about 0.01s and the
# quadratic one described below about 9s.
Readonly::Scalar my $FLOOD => 200_000;
Readonly::Scalar my $BUDGET => 2;	# seconds; linear work at $HUGE takes milliseconds
Readonly::Scalar my $FILE => $INC{'Test/Log/Abstraction.pm'};

# The forms before the audit, kept here as the reference behaviour
Readonly::Scalar my $OLD_TRAILING => qr/\s+at \S+ line \d+\.?\s*\z/s;
Readonly::Scalar my $OLD_THIS_FILE => qr/\s+at \Q$FILE\E line \d+\.?/;
Readonly::Scalar my $OLD_PLACEHOLDER => qr/%(?:(%)|\{(\w+)\}([-+ 0#]*\d{0,3}(?:\.\d{1,3})?[sdiufeEgGxXobc]))/;
Readonly::Scalar my $OLD_LANG => qr/\A(?:(?i:auto)|[A-Za-z]{2,3}(?:[_.\@-][\w.\@-]*)?)\z/;

# The forms after the audit, as the module now writes them
Readonly::Scalar my $NEW_TRAILING => qr/(?<!\s)\s++at\ \S++\ line\ \d++\.?\s*+\z/sx;
Readonly::Scalar my $NEW_THIS_FILE => qr/(?<!\s)\s++at\ \Q$FILE\E\ line\ \d++\.?/x;
Readonly::Scalar my $NEW_PLACEHOLDER => qr/%(?:(%)|\{(\w+)\}([-+\ 0\#]*+\d{0,3}(?:\.\d{1,3})?[sdiufeEgGxXobc]))/x;
Readonly::Scalar my $NEW_LANG => qr/\A(?:(?i:auto)|[A-Za-z]{2,3}(?:[_.\@-][\w.\@-]*+)?)\z/;

# Deterministic random strings made of the given pieces
sub corpus {
	my @tokens = @_;

	srand($SEED);
	return map { join('', map { $tokens[int(rand(@tokens))] } 1 .. 1 + int(rand($MAX_TOKENS))) } 1 .. $SAMPLES;
}

# Every match of a pattern in a string, with all its captures
sub all_matches {
	my ($regex, $string) = @_;

	my @found;
	while($string =~ /$regex/g) {
		push @found, join("\0", $-[0], $+[0], map { defined($_) ? $_ : '<undef>' } ($1, $2, $3));
	}
	return \@found;
}

sub within_budget {
	my ($name, $code) = @_;

	my $started = Time::HiRes::time();
	$code->();
	my $taken = Time::HiRes::time() - $started;
	ok($taken < $BUDGET, sprintf('%s: %.3fs', $name, $taken));
	return;
}

# ===========================================================================
# 1. Nothing changed
# ===========================================================================

subtest 'trailing location: old and new remove exactly the same text' => sub {
	my @strings = corpus(' ', "\t", "\n", 'at', 'at ', ' line ', 'line', '1', '12', '.', 'x', 'y.pm', 'a b');
	my $differ = 0;
	foreach my $string (@strings) {
		(my $old = $string) =~ s/$OLD_TRAILING//;
		(my $new = $string) =~ s/$NEW_TRAILING//;
		$differ++ if($old ne $new);
	}
	is($differ, 0, "$SAMPLES generated strings: no difference");
};

subtest 'this-file location: old and new remove exactly the same text' => sub {
	my @strings = corpus(' ', "\t", 'at ', " $FILE", ' line ', '1', '.', 'x', ' at ');
	my $differ = 0;
	foreach my $string (@strings) {
		(my $old = $string) =~ s/$OLD_THIS_FILE//g;
		(my $new = $string) =~ s/$NEW_THIS_FILE//g;
		$differ++ if($old ne $new);
	}
	is($differ, 0, "$SAMPLES generated strings: no difference");
};

subtest 'placeholders: old and new find the same matches and captures' => sub {
	my @strings = corpus('%', '%%', '{', '}', 'a', 'name', '0', '00', '-', '+', ' ', '#', '5', '123', '1234', '.', '.2', 'd', 's', 'x', 'n', 'v');
	my $differ = 0;
	foreach my $string (@strings) {
		$differ++ if(join('|', @{all_matches($OLD_PLACEHOLDER, $string)}) ne join('|', @{all_matches($NEW_PLACEHOLDER, $string)}));
	}
	is($differ, 0, "$SAMPLES generated templates: no difference");
};

subtest 'lang format: old and new accept the same values' => sub {
	my @strings = corpus('a', 'B', 'auto', 'AUTO', 'de', 'eng', '_', '.', '@', '-', 'UTF', '8', ' ', "\x{e9}", "\n", 'x');
	my $differ = grep { (($_ =~ $OLD_LANG) ? 1 : 0) != (($_ =~ $NEW_LANG) ? 1 : 0) } @strings;
	is($differ, 0, "$SAMPLES generated values: no difference");
};

# ===========================================================================
# 2. Linear on hostile input, through the module's public behaviour
# ===========================================================================

subtest 'location stripping: whitespace floods' => sub {
	# A huge run of whitespace before an almost-location: every space is a
	# possible start.  The old \s+at was linear only because perl's
	# optimiser happened to skip those starts.  The textbook fix - making
	# it possessive, \s++at, without the lookbehind - is a trap: each
	# start then consumes the rest of the run, the optimiser no longer
	# helps, and the work is quadratic (measured: 2.3s at 100,000 spaces,
	# 20s at 300,000).  The lookbehind (?<!\s) allows a start only where a
	# run begins, which makes it linear whatever the optimiser does.
	within_budget('spaces, then a location that fails at the end', sub { Test::Log::Abstraction::_reason((' ' x $FLOOD) . 'at x line 1.Q') });
	within_budget('spaces, then this file with no line number', sub { Test::Log::Abstraction::_reason((' ' x $FLOOD) . "at $FILE line Q") });
	within_budget('alternating spaces and tabs', sub { Test::Log::Abstraction::_reason((" \t" x ($FLOOD / 2)) . 'at x line Q') });
	within_budget('many almost-locations', sub { Test::Log::Abstraction::_reason((' at x line 1.' x ($HUGE / 16)) . 'Q') });
	within_budget('one word that never ends', sub { Test::Log::Abstraction::_reason(' at ' . ('x' x $HUGE)) });
	is(Test::Log::Abstraction::_reason("bad   \t at x line 3.\n"), 'bad', 'and still removes a real location, with all the space before it');
};

subtest 'placeholders: zero floods' => sub {
	within_budget('one placeholder with a million zeros', sub { Test::Log::Abstraction::_interpolate('%{a}' . ('0' x $HUGE) . 'Q', { a => 1 }) });
	within_budget('many unfinished placeholders', sub { Test::Log::Abstraction::_interpolate(('%{a}0000' x ($HUGE / 8)) . 'Q', { a => 1 }) });
	is(Test::Log::Abstraction::_interpolate('[%{a}05d]', { a => 7 }), '[00007]', 'and still reads a zero flag followed by a width');
};

subtest 'lang: a long tail that fails at the end' => sub {
	within_budget('de_ + a million letters + !', sub { eval { Test::Log::Abstraction->new(lang => 'de_' . ('a' x $HUGE) . '!') } });
	within_budget('de_ + a million separators + !', sub { eval { Test::Log::Abstraction->new(lang => 'de_' . ('.-@' x ($HUGE / 3)) . '!') } });
	is(Test::Log::Abstraction->new(lang => 'de_DE.UTF-8@euro')->lang(), 'de', 'and still accepts a full locale name');
};

done_testing();
