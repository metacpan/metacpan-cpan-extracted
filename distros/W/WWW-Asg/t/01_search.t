use strict;
use warnings;
use utf8;

use Test::More;
use WWW::Asg;
use Encode;

open( IN, "t/fixture/search.html" );
my $html = Encode::decode( 'utf8', join '', <IN> );
close IN;

my %condition = ( q => '巨乳', );

my $expect_search_videos = [
    {
        ccd      => 'ol',
        ccd_text => 'OL・お姉さん・痴女',
        date     => '2012-08-30T11:10:00',
        description =>
'今後も抜ける動画をどんどん投稿していきたいと思いますので、ブログ「アダルトな午後」へアクセスご協力お願いしますｍ（＿＿）ｍ',
        mcd            => 't8DWA8Lx9tn7M5vf',
        play_time      => 459,
        play_time_text => '7:39',
        thumbnail =>
'http://smedia20.asg.to/t/20120830/1346294104_809067_335576.flv/200x148/12',
        title => '性欲盛んな巨乳美女をホテルでハメ',
        url   => 'http://asg.to/contentsPage.html?mcd=t8DWA8Lx9tn7M5vf',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=t8DWA8Lx9tn7M5vf", 450, 372);</script>',
    },
    {
        ccd         => 'kyonyu',
        ccd_text    => '巨乳',
        date        => "2012-08-30T01:49:31",
        description => 'アゲ 1  サゲ 0   コメント数：',
        mcd         => 'SoZWbkLaESa68ivtUs4OksbnrXLsXCKq',
        thumbnail   => '',
        title       => '貧乳オッパイ画像',
        url =>
'http://asg.tohttp://pix.asg.to/contentsPage.html?mcd=SoZWbkLaESa68ivtUs4OksbnrXLsXCKq',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=SoZWbkLaESa68ivtUs4OksbnrXLsXCKq", 450, 372);</script>',
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
        ccd      => 'kyonyu',
        ccd_text => '巨乳',
        date     => '2012-08-30T09:19:00',
        description =>
'女の子と二人っきりになる為、お手伝いさんを雇ってみたら胸の谷間が',
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
        ccd      => 'bisyojo',
        ccd_text => '美少女',
        date     => '2012-08-30T04:30:00',
        description =>
'もし女性の性欲が目に見えてわかったら？赤く光ればセックスOKのバッジが存在する世界。父と娘、黒髪女子高生、巨乳工女、発情女検事、美人未亡人のバッジが赤く...',
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
        ccd      => 'bisyojo',
        ccd_text => '美少女',
        date     => '2012-08-30T04:20:00',
        description =>
'もし女性の性欲が目に見えてわかったら？赤く光ればセックスOKのバッジが存在する世界。父と娘、黒髪女子高生、巨乳工女、発情女検事、美人未亡人のバッジが赤く...',
        mcd            => 'kL6murai1mUmz0ek',
        play_time      => 62,
        play_time_text => '1:02',
        thumbnail =>
'http://smedia25.asg.to/t/20120830/1346268353_294013_334148.flv/200x148/12',
        title =>
'女性のセックス願望が一目でわかる‘性欲まるわかりバッジ’(2)',
        url => 'http://asg.to/contentsPage.html?mcd=kL6murai1mUmz0ek',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=kL6murai1mUmz0ek", 450, 372);</script>',
    },
    {
        ccd      => 'kyonyu',
        ccd_text => '巨乳',
        date     => '2012-08-29T21:30:00',
        description =>
'クラスメイトの優しいお姉さんと童貞喪失SEX 完全版はブログにて絶賛公開中！他のエロ動画も多数更新済！',
        mcd            => 'yw4cY7knY73IAc7c',
        play_time      => 359,
        play_time_text => '5:59',
        thumbnail =>
'http://smedia18.asg.to/t/20120829/1346244001_812454_335560.flv/200x148/12',
        title => 'クラスメイトの優しいお姉さんと童貞喪失SEX',
        url   => 'http://asg.to/contentsPage.html?mcd=yw4cY7knY73IAc7c',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=yw4cY7knY73IAc7c", 450, 372);</script>',
    },
    {
        ccd      => 'kyonyu',
        ccd_text => '巨乳',
        date     => '2012-08-29T21:21:00',
        description =>
'とっても仲良しの2人が今回濃厚3Pコースをやってくれちゃいましたよ。数あるマットテクを2人で同時にやってくれてる姿は見ていてＭＡＸ超えのエロさで...',
        mcd            => '7sFMAO2onhzMTDgp',
        play_time      => 192,
        play_time_text => '3:12',
        thumbnail =>
'http://smedia17.asg.to/t/20120829/1346243401_362555_335559.flv/200x148/12',
        title => '【新着】マット上で3Pローションプレイ',
        url   => 'http://asg.to/contentsPage.html?mcd=7sFMAO2onhzMTDgp',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=7sFMAO2onhzMTDgp", 450, 372);</script>',
    },
    {
        ccd      => 'kyonyu',
        ccd_text => '巨乳',
        date     => '2012-08-29T17:56:00',
        description =>
'マンを持して、ついに登場〜。 かんないnetとは...詳しくはHPをご覧ください',
        mcd            => 'JEiFuKV731hPFdV2',
        play_time      => 180,
        play_time_text => '3:00',
        thumbnail =>
'http://smedia25.asg.to/t/20120829/1346231384_29723_335556.flv/200x148/12',
        title => 'あの有名女優が・・・',
        url   => 'http://asg.to/contentsPage.html?mcd=JEiFuKV731hPFdV2',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=JEiFuKV731hPFdV2", 450, 372);</script>',
    },
    {
        ccd      => 'kyonyu',
        ccd_text => '巨乳',
        date     => '2012-08-29T17:55:00',
        description =>
'マンを持して、ついに登場〜。 かんないnetとは...詳しくはHPをご覧ください',
        mcd            => 'ElpI1i60dHivhppW',
        play_time      => 180,
        play_time_text => '3:00',
        thumbnail =>
'http://smedia23.asg.to/t/20120829/1346231292_181679_335555.flv/200x148/12',
        title => 'あの有名女優が・・・',
        url   => 'http://asg.to/contentsPage.html?mcd=ElpI1i60dHivhppW',
        embed => '<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=ElpI1i60dHivhppW", 450, 372);</script>',
    }
];

my $asg           = WWW::Asg->new;
my @search_videos = $asg->_extract_videos($html);

is @search_videos, 10;
is_deeply \@search_videos, $expect_search_videos;

done_testing();
