#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Role::Tiny;
use WordList::Test::OneTwo;

my $wl = WordList::Test::OneTwo->new;
is(ref($wl), "WordList::Test::OneTwo");

Role::Tiny->apply_roles_to_object($wl, 'WordListRole::Test');
is($wl->first_word, "one");
is($wl->next_word, "two");

ok(ref($wl) ne "WordList::Test::OneTwo", 'object has been reblessed to another package');
$wl->reset_iterator;
is($wl->first_word, "one");
is($wl->next_word, "two");

done_testing;
