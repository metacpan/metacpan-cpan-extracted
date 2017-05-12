use strict;
use warnings;

use Test::More tests => 4;

use re::engine::PCRE2;

my $variable = 'll';
# These tests were fixed with 0.12, op_comp pat_count was ignored.

# This pattern matches erroneously, because anything after (and including) ${variable} is thrown out
ok("hello moon" !~ /^(he)${variable}o earth$/, "Variable expanded correctly, rest of the pattern not skipped");

# This pattern won't compile, because the regex engine only sees /H\w(/:
# "Unmatched ( in regex; marked by <-- HERE in m/H\w( <-- HERE / at t/variable_expansion.t line 14."

ok("Hello" =~ /H\w($variable)o/, "Variable expanded correctly");

my $re1 = qr/foo/;
ok("foobar" =~ /$re1/, "singlepattern stays in PCRE2 #26");

my $re2 = qr/bar/; # fails in concat_pat of foreign plugin patterns
ok("foobar" =~ /$re1$re2/, "multipattern fallback to core #26");
