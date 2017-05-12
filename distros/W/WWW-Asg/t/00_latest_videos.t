use strict;
use warnings;
use utf8;

use Test::More;
use WWW::Asg;
use Encode;

open( IN, "t/fixture/new-movie.html" );
my $html = Encode::decode( 'UTF-8', join '', <IN> );
close IN;

my $expect_latest_videos = [
    {
        ccd            => 'baiorensu',
        ccd_text       => 'バイオレンス',
        date           => '2012-08-30T10:13:00',
        description    => '媚薬の効き目に酔いしれている...',
        mcd            => '4zAA8rPeInyUQrds',
        play_time      => 152,
        play_time_text => '2:32',
        thumbnail =>
'http://smedia11.asg.to/t/20120830/1346289729_266132_335574.flv/200x148/12',
        title =>
'世界一のチ●ポに薬漬けされて白目むくまでガン突きFUCK！！！／まりか',
        url => 'http://asg.to/contentsPage.html?mcd=4zAA8rPeInyUQrds',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=4zAA8rPeInyUQrds", 450, 372);</script>',
    },
    {
        ccd            => 'kyonyu',
        ccd_text       => '巨乳',
        date           => '2012-08-30T10:08:00',
        description    => 'ふぅ・・・',
        mcd            => 'kUfU9VhkBFE5qkzi',
        play_time      => 401,
        play_time_text => '6:41',
        thumbnail =>
'http://smedia21.asg.to/t/20120830/1346289686_841918_335573.flv/200x148/12',
        title => 'むちむちプリン',
        url   => 'http://asg.to/contentsPage.html?mcd=kUfU9VhkBFE5qkzi',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=kUfU9VhkBFE5qkzi", 450, 372);</script>',
    },
    {
        ccd            => 'kyonyu',
        ccd_text       => '巨乳',
        date           => '2012-08-30T09:19:00',
        description    => '女の子と二人っきりになる為、...',
        mcd            => 'SmOLYTyDa4D96GXG',
        play_time      => 1290,
        play_time_text => '21:30',
        thumbnail =>
'http://smedia14.asg.to/t/20120830/1346288398_629200_335572.flv/200x148/12',
        title =>
'女の子と二人っきりになる為、お手伝いさんを雇ってみたら胸の谷間が',
        url => 'http://asg.to/contentsPage.html?mcd=SmOLYTyDa4D96GXG',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=SmOLYTyDa4D96GXG", 450, 372);</script>',
    },
    {
        ccd            => 'shirouto',
        ccd_text       => '素人',
        date           => '2012-08-30T04:50:00',
        description    => '新体操で有名な某女子大に通う...',
        mcd            => 'EP8VvYtt0QhlL3SR',
        play_time      => 67,
        play_time_text => '1:07',
        thumbnail =>
'http://smedia11.asg.to/t/20120830/1346270297_65857_334085.flv/200x148/12',
        title =>
'現役女子大生 〜新体操でインカレを目指しているKちゃん〜(1)',
        url => 'http://asg.to/contentsPage.html?mcd=EP8VvYtt0QhlL3SR',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=EP8VvYtt0QhlL3SR", 450, 372);</script>',
    },
    {
        ccd            => 'shirouto',
        ccd_text       => '素人',
        date           => '2012-08-30T04:50:00',
        description    => '物は試し…と高額バイトにつられ...',
        mcd            => 'MHPqky93lVQwTDo5',
        play_time      => 63,
        play_time_text => '1:03',
        thumbnail =>
'http://smedia25.asg.to/t/20120830/1346270301_479522_334086.flv/200x148/12',
        title => 'あなたより綺麗な人、紹介してください。(1)',
        url   => 'http://asg.to/contentsPage.html?mcd=MHPqky93lVQwTDo5',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=MHPqky93lVQwTDo5", 450, 372);</script>',
    },
    {
        ccd            => 'shirouto',
        ccd_text       => '素人',
        date           => '2012-08-30T04:40:00',
        description    => '新体操で有名な某女子大に通う...',
        mcd            => 'CbxJb2Asj6Dgh2Jh',
        play_time      => 60,
        play_time_text => '1:00',
        thumbnail =>
'http://smedia18.asg.to/t/20120830/1346269581_494292_334271.flv/200x148/12',
        title =>
'現役女子大生 〜新体操でインカレを目指しているKちゃん〜(2)',
        url => 'http://asg.to/contentsPage.html?mcd=CbxJb2Asj6Dgh2Jh',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=CbxJb2Asj6Dgh2Jh", 450, 372);</script>',
    },
    {
        ccd            => 'shirouto',
        ccd_text       => '素人',
        date           => '2012-08-30T04:40:00',
        description    => '物は試し…と高額バイトにつられ...',
        mcd            => 'A9BSUXAQfhCOqEJ1',
        play_time      => 63,
        play_time_text => '1:03',
        thumbnail =>
'http://smedia25.asg.to/t/20120830/1346269659_219981_334272.flv/200x148/12',
        title => 'あなたより綺麗な人、紹介してください。(2)',
        url   => 'http://asg.to/contentsPage.html?mcd=A9BSUXAQfhCOqEJ1',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=A9BSUXAQfhCOqEJ1", 450, 372);</script>',
    },
    {
        ccd            => 'bisyojo',
        ccd_text       => '美少女',
        date           => '2012-08-30T04:30:00',
        description    => 'もし女性の性欲が目に見えてわ...',
        mcd            => 'uQLVN5ZriuIHOfas',
        play_time      => 62,
        play_time_text => '1:02',
        thumbnail =>
'http://smedia17.asg.to/t/20120830/1346268986_30925_333962.flv/200x148/12',
        title =>
'女性のセックス願望が一目でわかる‘性欲まるわかりバッジ’(1)',
        url => 'http://asg.to/contentsPage.html?mcd=uQLVN5ZriuIHOfas',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=uQLVN5ZriuIHOfas", 450, 372);</script>',
    },
    {
        ccd            => 'seihuku',
        ccd_text       => 'コスプレ・制服系',
        date           => '2012-08-30T04:30:00',
        description    => '“冒険したい優等生！？”周防ゆ...',
        mcd            => 'RCOaqyVtYEfuQvgV',
        play_time      => 60,
        play_time_text => '1:00',
        thumbnail =>
'http://smedia11.asg.to/t/20120830/1346268905_750477_333961.flv/200x148/12',
        title => 'おしゃぶり生徒会長 周防ゆきこ(1)',
        url   => 'http://asg.to/contentsPage.html?mcd=RCOaqyVtYEfuQvgV',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=RCOaqyVtYEfuQvgV", 450, 372);</script>',
    },
    {
        ccd            => 'bisyojo',
        ccd_text       => '美少女',
        date           => '2012-08-30T04:20:00',
        description    => 'もし女性の性欲が目に見えてわ...',
        mcd            => 'kL6murai1mUmz0ek',
        play_time      => 62,
        play_time_text => '1:02',
        thumbnail =>
'http://smedia25.asg.to/t/20120830/1346268353_294013_334148.flv/200x148/12',
        title =>
'女性のセックス願望が一目でわかる‘性欲まるわかりバッジ’(2)',
        url => 'http://asg.to/contentsPage.html?mcd=kL6murai1mUmz0ek',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=kL6murai1mUmz0ek", 450, 372);</script>',
    }
];

my $asg           = WWW::Asg->new;
my @latest_videos = $asg->_extract_videos($html);

is @latest_videos, 10;
is_deeply \@latest_videos, $expect_latest_videos;

done_testing();
