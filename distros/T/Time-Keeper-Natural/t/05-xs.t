#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Config;
use Test::More;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Lexicon;

cmp_ok(Time::Keeper::Natural::_abi_version(), '>=', 3, 'the table is found at load');
is(Time::Keeper::Natural::_cache_generation(), 0, 'the first interpreter\'s caches are its first');
cmp_ok(Time::Keeper::Natural::_cache_size(), '>=', 0, 'and can be counted');

SKIP: {
    skip 'this perl has no threads', 3 unless $Config{useithreads};
    require threads;
    my $t = threads->create({ context => 'list' }, sub {
        return (Time::Keeper::Natural::_cache_generation(), Time::Keeper::Natural::_cache_size(),
                Time::Keeper::Natural::_abi_version());
    });
    my ($gen, $size, $abi) = $t->join;
    is($gen, 1, 'a thread starts with caches of its own');
    is($size, 0, 'and empty');
    is($abi, Time::Keeper::Natural::_abi_version(), 'with the same table');
}

# A lexicon is C tables tied to its hash; a thread's copy of the hash
# compiles its own on first use, and the parent's stays as it was.
my $X = 'Time::Keeper::Natural::Lexicon';
my $fr = $X->for('fr');
is($X->for('fr-FR')->code, $X->for('fr')->code, 'a lexicon is found by its canonical code') if $X->for('fr-FR')->code eq 'fr';
ok($X->for('fr') == $fr, 'and compiled once an interpreter');
cmp_ok(Time::Keeper::Natural::_cache_size(), '>=', 1, 'the cache holds it');
my @want = map { $_->{field} . $_->{n} } $fr->fixed('demain');
is_deeply(\@want, ['day1'], 'demain is tomorrow');
SKIP: {
    skip 'this perl has no threads', 4 unless $Config{useithreads};
    my $t = threads->create({ context => 'list' }, sub {
        my @m = map { $_->{field} . $_->{n} } $fr->fixed('demain');
        my $own = $X->for('fr');
        return (join(',', @m), $own == $fr ? 'same' : 'own', $fr->key('Après-Demain'), scalar $fr->patterns);
    });
    my ($m, $own, $key, $np) = $t->join;
    is($m, 'day1', 'a lexicon copied into a thread reads there');
    is($own, 'own', 'and the thread\'s cache is its own');
    is($key, 'après-demain', 'its keys');
    is($np, scalar $fr->patterns, 'and its patterns');
}
is(join(',', map { $_->{field} . $_->{n} } $fr->fixed('demain')), 'day1', 'the parent\'s reads after the thread');
is(scalar $fr->fixed('demain'), 1, 'a lookup in scalar context counts, as 0.01 did');
is(scalar $fr->fixed('nothing at all'), undef, 'and is undef for none');
is(scalar $fr->markers('past'), 2, 'markers count two');
ok(!eval { Time::Keeper::Natural::Lexicon::key({}, 'x'); 1 }, 'a hash that is not a lexicon');
like($@, qr/not a lexicon/, 'is refused by name');
ok(!eval { $X->for('xx-nowhere-at-all'); 1 } && $@ =~ /there is no locale 'xx-nowhere-at-all'/, 'no such locale');

done_testing;
