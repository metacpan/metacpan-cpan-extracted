#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 55;

use_ok('Text::Match::FastAlternatives');

my $tmfa = Text::Match::FastAlternatives->new(
    qw<avantgo googlebot 247sitewatch>);
ok($tmfa, 'Constructor returns an object');
isa_ok($tmfa, 'Text::Match::FastAlternatives');

ok($tmfa->match(lc q[Blah foo Avantgo]), 'match avantgo');
ok($tmfa->match(lc q[Avantgo UA]), 'match avantgo at start');
ok($tmfa->match(lc q[Blah fribble Googlebot foo]), 'match googlebot');
ok($tmfa->match(lc q[Blah fribble 247SiteWatch]), 'match 247sitewatch');
ok(!$tmfa->match(  q[Blah fribble 247SiteWatch]), 'no match 247Sitewatch');
ok(!$tmfa->match(lc q[Mozilla/4.0 (compatible; MSIE 6.0)]), 'no match IE6');

my $alphabet = join '', map { chr } 32 .. 126;
my $ab_tmfa = Text::Match::FastAlternatives->new($alphabet);
ok(!$ab_tmfa->match(''), q[empty string doesn't contain alphabet]);
ok($ab_tmfa->match($alphabet), 'alphabet contains alphabet');
ok($ab_tmfa->match(" $alphabet"), 'left-padded alphabet contains alphabet');
ok($ab_tmfa->match("$alphabet "), 'right-padded alphabet contains alphabet');
ok($ab_tmfa->match(" $alphabet "), 'both-padded alphabet contains alphabet');

my $path_tmfa = Text::Match::FastAlternatives->new("\x00", "\xFF");
ok(!$path_tmfa->match(''), q[empty string doesn't contain U+00 or U+FF]);
ok($path_tmfa->match("\x00"), q[U+00 contains U+00 or U+FF]);
ok($path_tmfa->match("\xFF"), q[U+FF contains U+00 or U+FF]);
ok($path_tmfa->match(" \x00"), q[left-padded U+00 contains U+00 or U+FF]);
ok($path_tmfa->match("\xFF "), q[right-padded U+FF contains U+00 or U+FF]);

my $empty_tmfa = Text::Match::FastAlternatives->new('');
ok($empty_tmfa->match(''), 'empty string contains empty string');
ok($empty_tmfa->match('a'), '"a" contains empty string');
ok($empty_tmfa->match('abc'), '"abc" contains empty string');
ok($empty_tmfa->match($alphabet), 'alphabet contains empty string');

my $null_tmfa = Text::Match::FastAlternatives->new();
ok(!$null_tmfa->match(''), q[empty string doesn't contain null matcher]);
ok(!$null_tmfa->match('a'), q['a' doesn't contain null matcher]);
ok(!$null_tmfa->match('abc'), q['abc' doesn't contain null matcher]);
ok(!$null_tmfa->match($alphabet), q[alphabet doesn't contain null matcher]);

eval { Text::Match::FastAlternatives->new(undef) };
ok($@, 'constructor dies on undef');

my $foobar_tmfa = Text::Match::FastAlternatives->new('foobar');
for (0x00, 0x0A, 0x1F, 0x7F, 0x80, 0xA0, 0xFF, 0x100, 0x200) {
    ok($empty_tmfa->match(chr $_), "character $_ contains empty string");
    ok(!$null_tmfa->match(chr $_), "character $_ doesn't contain null matcher");
    ok(!$foobar_tmfa->match(chr $_), "character $_ doesn't contain foobar");
}
