#!perl -w

use strict;

use Test::More tests => 15;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;

BEGIN { use_ok "Test::LongString" }

test_out("ok 1 - foo is foo");
is_string("foo", "foo", "foo is foo");
test_test("two small strings equal");

test_out("not ok 1 - foo is foo");
test_fail(6);
test_diag(qq!         got: "bar"
#       length: 3
#     expected: "foo"
#       length: 3
#     strings begin to differ at char 1 (line 1 column 1)!);
is_string("bar", "foo", "foo is foo");
test_test("two small strings different");

test_out("not ok 1 - foo is foo");
test_fail(3);
test_diag(qq!         got: undef
#     expected: "foo"!);
is_string(undef, "foo", "foo is foo");
test_test("got undef, expected small string");

test_out("not ok 1 - foo is foo");
test_fail(3);
test_diag(qq!         got: "foo"
#     expected: undef!);
is_string("foo", undef, "foo is foo");
test_test("expected undef, got small string");

test_out("not ok 1 - long binary strings");
test_fail(6);
test_diag(qq!         got: "This is a long string that will be truncated by th"...
#       length: 70
#     expected: "\\x{00}\\x{01}foo\\x{0a}bar"
#       length: 9
#     strings begin to differ at char 1 (line 1 column 1)!);
is_string(
    "This is a long string that will be truncated by the display() function",
    "\0\1foo\nbar",
    "long binary strings",
);
test_test("display of long strings and of control chars");

test_out("not ok 1 - spelling");
test_fail(6);
test_diag(qq!         got: "Element"
#       length: 7
#     expected: "El\\x{e9}ment"
#       length: 7
#     strings begin to differ at char 3 (line 1 column 3)!);
is_string(
    "Element",
    "Elément",
    "spelling",
);
test_test("Escape high-ascii chars");

test_out('not ok 1 - foo\nfoo is foo\nfoo');
test_fail(6);
test_diag(qq!         got: "foo\\x{0a}foo"
#       length: 7
#     expected: "foo\\x{0a}fpo"
#       length: 7
#     strings begin to differ at char 6 (line 2 column 2)!);
is_string("foo\nfoo", "foo\nfpo", 'foo\nfoo is foo\nfoo');
test_test("Count correctly prefix with multiline strings");

test_out("not ok 1 - this isn't Ulysses");
test_fail(6);
test_diag(qq!         got: ..."he bowl aloft and intoned:\\x{0a}--Introibo ad altare de"...
#       length: 275
#     expected: ..."he bowl alift and intoned:\\x{0a}--Introibo ad altare de"...
#       length: 275
#     strings begin to differ at char 233 (line 4 column 17)!);
is_string(
    <<ULYS1,
Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
lather on which a mirror and a razor lay crossed. A yellow dressinggown,
ungirdled, was sustained gently behind him by the mild morning air. He
held the bowl aloft and intoned:
--Introibo ad altare dei.
ULYS1
    <<ULYS2,
Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
lather on which a mirror and a razor lay crossed. A yellow dressinggown,
ungirdled, was sustained gently behind him by the mild morning air. He
held the bowl alift and intoned:
--Introibo ad altare dei.
ULYS2
    "this isn't Ulysses",
);
test_test("Display offset in diagnostics");

test_out("ok 1 - looks like Finnegans Wake");
is_string_nows(
    <<FW1,
riverrun, past Eve and Adam's, from swerve of shore to bend
of bay, brings us by a commodius vicus of recirculation back to
Howth Castle and Environs.
FW1
    qq(riverrun,pastEveandAdam's,fromswerveofshoretobendofbay,bringsusbyacommodiusvicusofrecirculationbacktoHowthCastleandEnvirons.),
    "looks like Finnegans Wake",
);
test_test("is_string_nows removes whitespace");

test_out("not ok 1 - non-ws differs");
test_fail(7);
test_diag(qq(after whitespace removal:
#          got: "abc"
#       length: 3
#     expected: "abd"
#       length: 3
#     strings begin to differ at char 3));
is_string_nows("a b c", "abd", "non-ws differs");
test_test("is_string_nows tests correctly");

test_out("not ok 1 - 123 is 124");
test_fail(6);
test_diag(qq!         got: "123"
#       length: 3
#     expected: "124"
#       length: 3
#     strings begin to differ at char 3 (line 1 column 3)!);
is_string("123", "124", "123 is 124");
test_test("two short number strings differ at char 3");

test_out("not ok 1 - 123 is 124");
test_fail(6);
test_diag(qq!         got: "123"
#       length: 3
#     expected: "124"
#       length: 3
#     strings begin to differ at char 3 (line 1 column 3)!);
is_string(0+"123", 0+"124", "123 is 124");
test_test("two small numbers compared in string context differ at char 3");

test_out("not ok 1 - 123 is 123xyz");
test_fail(6);
test_diag(qq!         got: "123"
#       length: 3
#     expected: "123xyz"
#       length: 6
#     strings begin to differ at char 4 (line 1 column 4)!);
is_string("123", "123xyz", "123 is 123xyz");
test_test("short number string differs from short string at char 4");

test_out("not ok 1 - 123 is 123xyz");
test_fail(6);
test_diag(qq!         got: "123"
#       length: 3
#     expected: "123xyz"
#       length: 6
#     strings begin to differ at char 4 (line 1 column 4)!);
is_string(0+"123", "123xyz", "123 is 123xyz");
test_test("small number differs from short string at char 4");

