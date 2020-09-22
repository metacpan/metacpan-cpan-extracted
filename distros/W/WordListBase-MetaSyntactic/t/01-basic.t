#!perl

use strict;
use warnings;
use Test::More 0.98;

use WordList::MetaSyntactic::test_wlb_meta;

my $wl = WordList::MetaSyntactic::test_wlb_meta->new;
my @w; $wl->each_word(sub { push @w, $_[0] }); is(scalar(@w), 26);
is($wl->first_word, 'a');
is($wl->next_word, 'b');
$wl->reset_iterator;
is($wl->next_word, 'a');
$wl->pick;
ok( $wl->word_exists('a'));
ok(!$wl->word_exists('A'));
@w = $wl->all_words; is(scalar(@w), 26);

done_testing;
