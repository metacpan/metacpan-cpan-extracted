#!perl -Tw

use strict;

use Test::More tests => 5;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;
use Test::LongString;

# In there
test_out("ok 1 - Any chocolate in my peanut butter?");
lacks_string("Reese's Peanut Butter Cups", "Chocolate", "Any chocolate in my peanut butter?");
test_test("Lacking");

# Not in there
test_out("not ok 1 - Any peanut butter in my chocolate?");
test_fail(4);
test_diag(qq(    searched: "Reese's Peanut Butter Cups"));
test_diag(qq(   and found: "Peanut Butter"));
test_diag(qq! at position: 8 (line 1 column 9)!);
lacks_string("Reese's Peanut Butter Cups", "Peanut Butter", "Any peanut butter in my chocolate?");
test_test("Not lacking");

# Multiple lines
test_out("not ok 1 - Mild?");
test_fail(4);
test_diag(qq(    searched: "Stately, plump Buck Mulligan came from the stairhe"...));
test_diag(qq(   and found: "mild"));
test_diag(qq! at position: 195 (line 3 column 51)!);
lacks_string(<<'EXAMPLE',"mild","Mild?");
Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
lather on which a mirror and a razor lay crossed. A yellow dressinggown,
ungirdled, was sustained gently behind him by the mild morning air. He
held the bowl aloft and intoned:
--Introibo ad altare dei.
EXAMPLE
test_test("Multiple lines not lacking");

# Source string undef
test_out("not ok 1 - Look inside undef");
test_fail(2);
test_diag(qq(String to look in is undef));
lacks_string(undef,"Orange everything", "Look inside undef");
test_test("Source string undef fails");

# Searching string undef
test_out("not ok 1 - Look for undef");
test_fail(2);
test_diag(qq(String to look for is undef));
lacks_string('"Fishnet" is not a color', undef, "Look for undef");
test_test("Substring undef fails");
