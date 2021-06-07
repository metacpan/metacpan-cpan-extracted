#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use Role::Tiny;
use WordList::Char::Latin1::UpperCaseLetter;

my $w = WordList::Char::Latin1::UpperCaseLetter->new;
Role::Tiny->apply_roles_to_object($w, "WordListRole::BinarySearch");

for ("A".."Z") {
    ok($w->word_exists("$_"), $_);
}
ok(!$w->word_exists("a"));
ok(!$w->word_exists("0"));
done_testing;
