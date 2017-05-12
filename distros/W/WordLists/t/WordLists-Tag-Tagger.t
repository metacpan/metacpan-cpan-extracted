#!perl -w
use strict;
use Test::More;
use WordLists::Tag::Tagger;

my $sMS= q{
	The quick, brown fox jumps over the lazy dog.
 };

ok(my $tagger = WordLists::Tag::Tagger->new(), 'can create tagger object');

ok(my $with_human_tags = $tagger->add_human_tags($sMS), 'add human tags to ms');
like($with_human_tags, qr/<span pos=['"]noun['"]>dog/, 'add_human_tags correctly idenfifies "dog" as noun');
unlike($tagger->add_human_tags('<>'),qr/<>/, 'add_human_tags strips <>');
unlike($tagger->add_human_tags('&'),qr/&/, 'add_human_tags strips &');

ok(my $results_wl = $tagger->get_wordlist($sMS), 'create wordlist from ms');
is(length($results_wl->get_senses_for('jumps')),1, 'wordlist has words');
is(length($results_wl->get_senses_for('the')),1, 'wordlist counts "the" once only');
# is(${[$results_wl->get_senses_for('jumps')]}[0]->get('pos'),'v', 'correctly identifies jumps as verb'); # Don't require this - Lingua::EN::Tagger doesn't correctly identify it!

done_testing();
