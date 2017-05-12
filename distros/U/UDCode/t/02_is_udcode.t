use Test::More tests => 15;
use lib '../lib';

BEGIN { use_ok( 'UDCode' ) }

ok(! is_udcode("b", "ab", "abba")); # abba,b   ab,b,ab
ok(! is_udcode("a", "ab", "ba")); # ab,a    a,ba
ok(  is_udcode("ab", "ba"));
ok(  is_udcode("a", "b"));
ok(  is_udcode("aab", "ab", "b"));
ok(  is_udcode("a", "ab"));     # not a prefix code

ok(  is_udcode("a"));     # trivial

# What if some of the strings in the code list are identical?
# Are they considered the same strings or different strings?
#
# For example, suppose is_udcode("x", "x")
# Then $code[0] . $code[1] eq $code[1] . $code[0]
# So this is not UD.
# But all we have is "x" . "x" eq "x" . "x", so maybe is *is* UD
#
# Behavior decision: identical code words are disregarded
# So the code above *is* UD.
ok(  is_udcode("a", "a"));     # trivial
ok(  is_udcode("a", "a", "a"));     # trivial
ok(! is_udcode("a", "ab", "ba", "a"));
ok(! is_udcode("b", "ab", "ab", "abba"));
ok(  is_udcode("ab", "ba", "ba"));
ok(  is_udcode("a", "b", "b"));
ok(  is_udcode("a", "b", "b", "a"));
