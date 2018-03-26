#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use WordList::Test::OneTwo;

my $wl = WordList::Test::OneTwo->new;

subtest each_word => sub {
    my @res;

    @res = (); $wl->each_word(sub { push @res, $_[0] });
    is_deeply(\@res, ["one","two"]);

    @res = (); $wl->each_word(sub { push @res, $_[0], $_[0]; -2 });
    is_deeply(\@res, ["one","one"]);
};

subtest word_exists => sub {
    ok( $wl->word_exists("one"));
    ok( $wl->word_exists("one"));
    ok(!$wl->word_exists(""));
    ok(!$wl->word_exists("three"));
};

subtest pick => sub {
    dies_ok { $wl->pick(0) };

    my $res;

    $res = $wl->pick;
    ok($res eq 'one' || $res eq 'two');

    $res = [$wl->pick(2)];
    is(scalar(@$res), 2);
    ok($res->[0] eq 'one' && $res->[1] eq 'two' || $res->[0] eq 'two' && $res->[1] eq 'one');

    $res = [$wl->pick(3)];
    is(scalar(@$res), 2);
    ok($res->[0] eq 'one' && $res->[1] eq 'two' || $res->[0] eq 'two' && $res->[1] eq 'one');
};

subtest all_words => sub {
    is_deeply([$wl->all_words], ["one","two"]);
};

done_testing;
