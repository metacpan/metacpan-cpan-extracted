use strict;
use warnings;
use utf8;
use Test::More;

use Text::Shinobi;

my $iroha = <<'...';
い ろ は に ほ へ と
ち り ぬ る を わ か
よ た れ そ つ ね な
ら む う ゐ の お く
や ま け ふ こ え て
あ さ き ゆ め み し
ゑ ひ も せ す ん
...

subtest 'default' => sub {
    is($Text::Shinobi::ENCODE, Text::Shinobi::Y2016, 'default is 2016');

    my $encoded = <<'...';
栬 ⽕⾊ ⼟⾊ 銫 氵⾊ 亻⾊ ⾝⾊
棈 ⽕⻘ 埥 錆 清 倩 ⾝⻘
横 熿 墴 鐄 潢 僙 ⾝⻩
⽊⾚ 焃 𡋽 䤲 浾 亻⾚ ⾝⾚
柏 𤇢 ⼟⽩ 鉑 泊 伯 ⾝⽩
𣘸 㷵 ⼟黒 𨭆 潶 𠎁 𨊂
橴 ⽕紫 ⼟紫 ⾦紫 氵紫 亻紫
...

    is(Text::Shinobi->encode($iroha), $encoded, 'encode()');
    is(Text::Shinobi->decode($encoded), $iroha, 'decode()');
    
    is(Text::Shinobi->encode('あいう！'), '𣘸栬𡋽！', 'pod example');
    is(Text::Shinobi->decode('𣘸栬𡋽？'), 'あいう？', 'pod example');
};

subtest 'DUO' => sub {
    local $Text::Shinobi::ENCODE = Text::Shinobi::DUO;
    
    my $encoded = <<'...';
⽊⾊ ⽕⾊ ⼟⾊ ⾦⾊ 氵⾊ 亻⾊ ⾝⾊
⽊⻘ ⽕⻘ ⼟⻘ ⾦⻘ 氵⻘ 亻⻘ ⾝⻘
⽊⻩ ⽕⻩ ⼟⻩ ⾦⻩ 氵⻩ 亻⻩ ⾝⻩
⽊⾚ ⽕⾚ ⼟⾚ ⾦⾚ 氵⾚ 亻⾚ ⾝⾚
⽊⽩ ⽕⽩ ⼟⽩ ⾦⽩ 氵⽩ 亻⽩ ⾝⽩
⽊黒 ⽕黒 ⼟黒 ⾦黒 氵黒 亻黒 ⾝黒
⽊紫 ⽕紫 ⼟紫 ⾦紫 氵紫 亻紫
...

    is(Text::Shinobi->encode($iroha), $encoded, 'encode()');
    is(Text::Shinobi->decode($encoded), $iroha, 'decode()');
    
    is(Text::Shinobi->encode('あいう'), '⽊黒⽊⾊⼟⾚', 'pod example');
};

subtest 'UTF8MB3' => sub {
    local $Text::Shinobi::ENCODE = Text::Shinobi::UTF8MB3;
    
    my $encoded = <<'...';
栬 ⽕⾊ ⼟⾊ 銫 氵⾊ 亻⾊ ⾝⾊
棈 ⽕⻘ 埥 錆 清 倩 ⾝⻘
横 熿 墴 鐄 潢 僙 ⾝⻩
⽊⾚ 焃 ⼟⾚ 䤲 浾 亻⾚ ⾝⾚
柏 ⽕⽩ ⼟⽩ 鉑 泊 伯 ⾝⽩
⽊黒 㷵 ⼟黒 ⾦黒 潶 亻黒 ⾝黒
橴 ⽕紫 ⼟紫 ⾦紫 氵紫 亻紫
...

    is(Text::Shinobi->encode($iroha), $encoded, 'encode()');
    is(Text::Shinobi->decode($encoded), $iroha, 'decode()');
    
    is(Text::Shinobi->encode('あいう'), '⽊黒栬⼟⾚', 'pod example');
};

done_testing();
