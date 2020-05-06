#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use WordList::Test::OneTwo;

my @wordlists = (
    "WordList::Test::OneTwo" => {},
    "WordList::Test::Dynamic::OneTwo_Each" => {},
    "WordList::Test::Dynamic::OneTwo_FirstNextReset" => {},
    "WordList::Test::Dynamic::OneTwo_EachParam" => {
        params => {foo=>1},
    },
);

while (my ($wordlist, $wordlist_data) = splice @wordlists, 0, 2) {
    eval "require $wordlist";
    my $wl_obj = $wordlist->new(%{ $wordlist_data->{params} // {} });

    subtest "each_word ($wordlist)" => sub {
        my @res;

        @res = (); $wl_obj->each_word(sub { push @res, $_[0] });
        is_deeply(\@res, ["one","two"]) or diag explain \@res;

        @res = (); $wl_obj->each_word(sub { push @res, $_[0], $_[0]; -2 });
        is_deeply(\@res, ["one","one"]) or diag explain \@res;
    };

    subtest "first_word, next_word, reset_iterator ($wordlist)" => sub {
        is_deeply($wl_obj->first_word, "one");
        is_deeply($wl_obj->next_word , "two");
        $wl_obj->reset_iterator;
        is_deeply($wl_obj->next_word, "one");
        is_deeply($wl_obj->next_word, "two");
        is_deeply($wl_obj->next_word , undef);
    };

    subtest "word_exists ($wordlist)" => sub {
        ok( $wl_obj->word_exists("one"));
        ok( $wl_obj->word_exists("one"));
        ok(!$wl_obj->word_exists(""));
        ok(!$wl_obj->word_exists("three"));
    };

    subtest "pick ($wordlist)" => sub {
        dies_ok { $wl_obj->pick(0) };

        my $res;

        $res = $wl_obj->pick;
        ok($res eq 'one' || $res eq 'two');

        $res = [$wl_obj->pick(2)];
        is(scalar(@$res), 2);
        ok($res->[0] eq 'one' && $res->[1] eq 'two' || $res->[0] eq 'two' && $res->[1] eq 'one');

        $res = [$wl_obj->pick(3)];
        is(scalar(@$res), 2);
        ok($res->[0] eq 'one' && $res->[1] eq 'two' || $res->[0] eq 'two' && $res->[1] eq 'one');
    };

    subtest "all_words ($wordlist)" => sub {
        is_deeply([$wl_obj->all_words], ["one","two"]);
    };
} # for $wordlist

done_testing;
