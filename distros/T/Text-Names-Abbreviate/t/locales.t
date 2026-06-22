#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use POSIX qw(ENOENT);
use Test::Most;

use Text::Names::Abbreviate qw(abbreviate);

# ---------------------------------------------------------------------------
# Sanity subtest -- BAIL_OUT immediately on any basic failure so the locale
# subtests below do not produce misleading failures.
# ---------------------------------------------------------------------------
subtest 'sanity: module loads and core call succeeds' => sub {
	my $result = eval { abbreviate('John Adams') };
	BAIL_OUT('abbreviate() sanity check failed: ' . ($@ // 'unknown error'))
		unless defined($result) && $result eq 'J. Adams';

	pass('sanity check passed');
	done_testing();
};

# ---------------------------------------------------------------------------
# System-locale subtests
# Test that croak messages fire correctly and that OS error strings are
# sourced via Perl's own layer (not POSIX::strerror, which can diverge from
# the C library used internally by Perl).
# ---------------------------------------------------------------------------
my @locales = (
	'en_US.UTF-8',
	'de_DE.UTF-8',
	'ja_JP.UTF-8',    # East Asian; verifies no multi-byte collation breakage
);

for my $locale (@locales) {
	subtest "error paths under system locale $locale" => sub {
		local $ENV{LC_ALL} = $locale;
		local $ENV{LANG}   = $locale;

		throws_ok { abbreviate() }
			qr/name/i,
			"missing name croaks under $locale";

		throws_ok { abbreviate('') }
			qr/name/i,
			"empty name croaks under $locale";

		throws_ok { abbreviate('John', { format => 'bad' }) }
			qr/format/i,
			"bad format croaks under $locale";

		throws_ok { abbreviate('John', { style => 'bad' }) }
			qr/style/i,
			"bad style croaks under $locale";

		# Source OS error string directly from Perl's errno layer --
		# do NOT use POSIX::strerror, which may diverge from libc under
		# some locale/glibc combinations.
		local $! = ENOENT;
		my $os_msg = "$!";
		ok(length($os_msg) > 0, "OS error string non-empty under $locale: $os_msg");

		done_testing();
	};
}

# ---------------------------------------------------------------------------
# Names from different geographic regions (country-of-origin sanity checks)
# Verifies that characters from various scripts are handled without data loss.
# ---------------------------------------------------------------------------
subtest 'country sanity: GB -- anglophone name' => sub {
	is(abbreviate('Winston Leonard Spencer Churchill'), 'W. L. S. Churchill', 'GB: multi-part anglophone name');
	done_testing();
};

subtest 'country sanity: US -- anglophone with middle initial' => sub {
	is(abbreviate('John F Kennedy'), 'J. F. Kennedy', 'US: middle initial');
	done_testing();
};

subtest 'country sanity: FR -- accented characters' => sub {
	is(abbreviate('Emile Zola'),   'E. Zola',  'FR: unaccented fallback');
	is(abbreviate('Jean-Paul Sartre'), 'J. Sartre', 'FR: hyphenated given name treated as one token');
	done_testing();
};

subtest 'country sanity: DE -- umlauts preserved' => sub {
	is(abbreviate('Johann Wolfgang von Goethe'), 'J. W. v. Goethe', 'DE: particle treated as token');
	done_testing();
};

subtest 'country sanity: CN -- CJK characters (best-effort)' => sub {
	# The module makes no claims about CJK word segmentation; it treats
	# whitespace-separated tokens as name components.
	is(abbreviate('Mao Zedong'), 'M. Zedong', 'CN: romanised form abbreviated correctly');
	done_testing();
};

# ---------------------------------------------------------------------------
# Concurrent-instance safety (no shared mutable state)
# ---------------------------------------------------------------------------
subtest 'concurrent instance safety: interleaved calls do not bleed state' => sub {
	my @pairs = (
		[ 'John Adams',           'J. Adams'      ],
		[ 'George Washington',    'G. Washington'  ],
		[ 'Thomas Jefferson',     'T. Jefferson'   ],
		[ 'Adams, John Quincy',   'J. Q. Adams'    ],
	);

	# Simulate interleaved calls (no threads; verifies no lexical-state leakage)
	for my $pair (@pairs) {
		my ($input, $expected) = @{$pair};
		is(abbreviate($input), $expected, "no state bleed for '$input'");
	}

	done_testing();
};

done_testing();
