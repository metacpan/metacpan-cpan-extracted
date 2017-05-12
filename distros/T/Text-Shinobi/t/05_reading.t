use strict;
use warnings;
use utf8;
use Test::More;

use Text::Shinobi qw/shinobi/;

my $dic = qx(echo -n `mecab-config --dicdir`/mecab-ipadic-neologd);

plan skip_all => "not found deps module." if not eval { require Text::Mecabist; 1 };
plan skip_all => "neologd required." if not -e $dic;

my $text = '忍びなれどもpartyナイ!';
my $code = "\x{28282}\x{6D7E}\x{2F55}\x{7D2B}\x{3099}\x{2F9D}\x{2EE9}\x{58B4}\x{2F9D}\x{2F8A}\x{3099}\x{2F1F}\x{7D2B}\x{2F1F}\x{2F8A}\x{309A}\x{30FC}\x{2F9D}\x{2F69}\x{682C}\x{30FC}\x{2F9D}\x{2EE9}\x{682C}!";
my $kana = 'しのびなれどもぱーていーない!';

my $res = Text::Mecabist->new({ dicdir => $dic })->parse($text, sub {
    my $node = shift;
    if ($node->readable and $node->reading) {
        $node->text(shinobi($node->reading));
    }
});

is("$res", $code, 'yomi with mecab/neologd');
is(Text::Shinobi->decode($code), $kana, 'decode() check');

done_testing();
