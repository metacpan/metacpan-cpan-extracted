use strict;
use warnings;
use utf8;
use Test::More;

plan skip_all => "not found deps module." if not eval { require Lingua::JA::Kana; 1 };

use Text::Shinobi qw/shinobi/;

my $text = 'ninja!';
my $code = "\x{92AB}\x{4EBB}\x{7D2B}\x{28282}\x{3099}\x{67CF}!";
my $kana = 'にんじや!';

is(
    shinobi(Lingua::JA::Kana::romaji2hiragana($text)),
    $code,
    'romaji to shinobi'
);

is(Text::Shinobi->decode($code), $kana, 'decode() check');

done_testing();
