# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
use_ok("Text::Context::EitherSide");
Text::Context::EitherSide->import("get_context");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $text = "The quick brown fox jumped over the lazy dog";


    is(
        get_context(2, $text, "fox"),
        "... quick brown fox jumped over ...",
        "one word, context 2"
    );

    is(
        get_context(2, $text, "fox", "jumped"),
        "... quick brown fox jumped over the ...",
        "adjacent words, context 2"
    );

    is(
        get_context(2, $text, "fox", "jumped", "dog"),
        "... quick brown fox jumped over the lazy dog",
        "adjacent and distinct words, (including one at the end) context 2"
    );

    is(
        get_context(1, $text, "fox", "jumped", "dog"),
        "... brown fox jumped over ... lazy dog",
        "adjacent and distinct words, (including one at the end) context 1"
    );

    is(
        get_context(1, $text, "fox jumped dog"),
        "... brown fox jumped over ... lazy dog",
        "arguments get_context split correctly"
    );

    is(
        get_context(1, "Test > X foo && bar | z", "X", "bar"),
        "... > X foo && bar | ...",
        "non-words act like words"
    );

    is(
        get_context(2, "wobble wobble wobble wobble wobble wobble wobble", "wobble"),
        "wobble wobble wobble wobble wobble wobble wobble",
        "repeated words are caught multiple times"
    );

    is(get_context(0, "bother blast damned", "the", "last"),
        '', "only whole words match, not partial words");

    is(
        get_context(0, $text, "fox", "dog"),
        "... fox ... dog",
        "Context 0 (How very silly)"
    );
