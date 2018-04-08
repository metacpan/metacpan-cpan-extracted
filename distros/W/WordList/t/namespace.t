#!perl

use strict;
use warnings;
use Test::More 0.98;

use WordList::Namespace qw(is_actual_wordlist_module);

subtest is_actual_wordlist_module => sub {
    ok(!is_actual_wordlist_module("Foo"));
    ok(!is_actual_wordlist_module("WordList"));
    ok(!is_actual_wordlist_module("WordLists"));

    ok( is_actual_wordlist_module("WordList::ID::KBBI"));
    ok( is_actual_wordlist_module("WordList::Password::BigList"));

    ok(!is_actual_wordlist_module("WordList::Namespace"));
    ok(!is_actual_wordlist_module("WordList::MetaSyntactic"));

    ok(!is_actual_wordlist_module("WordList::Mod"));
    ok(!is_actual_wordlist_module("WordList::Mod::Foo"));
};

done_testing;
