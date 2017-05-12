use Test::More;
use utf8;
use Encode qw/encode_utf8/;
use Text::Shirasu;

my $ts = Text::Shirasu->new;

subtest 'normalize' => sub {
	is $ts->normalize("０１２３４５６７８９"), "0123456789", "z2h normalize number";
	is $ts->normalize("ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "z2h normalize uppercase alphabet";
	is $ts->normalize("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ"), "abcdefghijklmnopqrstuvwxyz", "z2h normalize lowercase alphabet";
	is $ts->normalize("！＂＃＄％＆＇（）＊＋，－．／：；＜＞？＠［￥］＾＿｀｛｜｝"), "!\"#\$%&'()*+,-./:;<>?@[¥]^_`{|}", "z2h normalize symbols";
	is $ts->normalize("アカサ㌍タなのです"), "アカサカロリータなのです", "nfkc normalize";
	is $ts->normalize("＝。、・「」"), "=｡､･｢｣", "z2h normalize symbols second turn";
	is $ts->normalize(" ああ "), "ああ", "trim spaces";
	is $ts->normalize("　ああ　"), "ああ", "trim spaces";
	is $ts->normalize("お、俺の━ ”（＊）” を掘らないで〰〰 ’＋１’"), "お､俺のー \"(*)\" を掘らないで '+1'", "complex normalize";
};

subtest 'normalize(encode_utf8)' => sub {
	is $ts->normalize(encode_utf8 "０１２３４５６７８９"), "0123456789", "z(encode_utf8)2h normalize number";
	is $ts->normalize(encode_utf8 "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "z(encode_utf8)2h normalize uppercase alphabet";
	is $ts->normalize(encode_utf8 "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ"), "abcdefghijklmnopqrstuvwxyz", "z(encode_utf8)2h normalize lowercase alphabet";
	is $ts->normalize(encode_utf8 "！＂＃＄％＆＇（）＊＋，－．／：；＜＞？＠［￥］＾＿｀｛｜｝"), "!\"#\$%&'()*+,-./:;<>?@[¥]^_`{|}", "z(encode_utf8)2h normalize symbols";
	is $ts->normalize(encode_utf8 "アカサ㌍タなのです"), "アカサカロリータなのです", "nfkc normalize(encode_utf8)";
	is $ts->normalize(encode_utf8 "＝。、・「」"), "=｡､･｢｣", "z2h normalize symbols second turn(encode_utf8)";
	is $ts->normalize(encode_utf8 " ああ "), "ああ", "trim spaces(encode_utf8)";
	is $ts->normalize(encode_utf8 "　ああ　"), "ああ", "trim spaces(encode_utf8)";
	is $ts->normalize(encode_utf8 "お、俺の━ ”（＊）” を掘らないで〰〰 ’＋１’"), "お､俺のー \"(*)\" を掘らないで '+1'", "complex normalize(encode_utf8)";
};

subtest 'initialize normalize with subroutine' => sub {
	my $html = do { local $/; <DATA> };
	is $ts->normalize("&hearts;", qw/decode_entities/), "♥", "can init with decode_entities";
	like $ts->normalize($html, qw/strip_html/), qr/タイトル/, "can init with strip_html";
	is $ts->normalize("大根が大好き", \&ika), "大根が大好きイカ！", "can init with main subroutine";
	is $ts->normalize("大根はとても㌍高い", qw/nfkc/, \&ika, qw/alnum_z2h/), "大根はとてもカロリー高いイカ!", "can init with nkfc and main subroutine";
};

done_testing;

sub ika { $_[0] . "イカ！" }

__DATA__
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>タイトル</title>
    <script type="text/javascript">hoge();</script>
</head>

</html>