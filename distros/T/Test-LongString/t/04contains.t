#!perl -Tw

use strict;

use Test::More tests => 5;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;
use Test::LongString;

# In there
test_out("ok 1 - What's in my dog food?");
contains_string("Dog food", "foo", "What's in my dog food?");
test_test("a small string matches");

# Not in there
test_out("not ok 1 - Any nachos?");
test_fail(5);
test_diag(qq(    searched: "Dog food"));
test_diag(qq(  can't find: "Nachos"));
test_diag(qq(        LCSS: "o"));
test_diag(qq(LCSS context: "Dog food"));
contains_string("Dog food","Nachos", "Any nachos?");
test_test("Substring doesn't match (with LCSS)");

{
    local $Test::LongString::LCSS = 0;
    # Not in there, with LCSS output disabled
    test_out("not ok 1 - Any nachos?");
    test_fail(3);
    test_diag(qq(    searched: "Dog food"));
    test_diag(qq(  can't find: "Nachos"));
    contains_string("Dog food","Nachos", "Any nachos?");
    test_test("Substring doesn't match (with LCSS)");
}

# Source string undef
test_out("not ok 1 - Look inside undef");
test_fail(2);
test_diag(qq(String to look in is undef));
contains_string(undef,"Orange everything", "Look inside undef");
test_test("Source string undef fails");

# Searching string undef
test_out("not ok 1 - Look for undef");
test_fail(2);
test_diag(qq(String to look for is undef));
contains_string('"Mesh" is not a color', undef, "Look for undef");
test_test("Substring undef fails");
