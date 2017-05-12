# -*- perl -*-
use strict;
use warnings;
use Test::Exception;
use Test::More tests =>
  195
  +15 # isPassword(v0.45).
  +17 # isChar.
  +44 # isExistentDay,isExistentTime,isExistentDateTime
  ;
use Tripletail '/dev/null';

#---------------------------------- 一般
my $v;
ok($v = $TL->newValue(''), 'new');
ok($v->set('***'), 'set');
is($v->get, '***', 'get');
dies_ok {$v->set(\123)} 'set die';

#---------------------------------- set系
is($v->setDate(2000,1,1)->get, '2000-01-01', 'setDate');
is($v->setDate(2000,99,99)->get, undef, 'setDate');
is($v->setDateTime(2000,1,1,2,3,4)->get, '2000-01-01 02:03:04', 'setDateTime');
is($v->setDateTime(2000,1,1,2,3,99)->get, undef, 'setDateTime');
is($v->setTime(1,2,3)->get, '01:02:03', 'setTime');
is($v->setTime(5)->get, '05:00:00', 'setTime');
is($v->setTime(99)->get, undef, 'setTime');

#---------------------------------- get系
$v->set('あ');
is($v->getLen, 3, 'getLen');
is($v->getSjisLen, 2, 'getSjisLen');
is($v->getCharLen, 1, 'getCharLen');

$v->setDate(2000,8,1);
ok($v->getAge, 'getAge');
is($v->getAge('2005-08-01'), 5, 'getAge');
is($v->getAge('2005-07-31'), 4, 'getAge');
is($v->getAge('****-**-**'), undef, 'getAge');

my $re_hira = qr/\xe3(?:\x81[\x81-\xbf]|\x82[\x80-\x93]|\x83\xbc)/;
my $re_kata = qr/\xe3(?:\x82[\xa1-\xbf]|\x83[\x80-\xb3]|\x83\xbc)/;
my $re_narrownum = qr{\d};
my $re_widenum = qr/\xef\xbc[\x90-\x99]/;
dies_ok {$v->getRegexp(undef)} 'getRegexp undef';
dies_ok {$v->getRegexp(\123)} 'getRegexp SCALAR';
is($v->getRegexp('HIra'), $re_hira, 'getRegexp');
is($v->getRegexp('kata'), $re_kata, 'getRegexp');
is($v->getRegexp('numbernarrow'), $re_narrownum, 'getRegexp');
is($v->getRegexp('numberwide'), $re_widenum, 'getRegexp');
dies_ok {$v->getRegexp('***')} 'getRegexp';

#---------------------------------- is系
ok($v->set('')->isEmpty, 'isEmpty');

ok($v->set(' ')->isWhitespace, 'isWhitespace');
ok(! $v->set('')->isWhitespace, 'isWhitespace');

ok($v->set(' ')->isBlank, 'isBlank');
ok($v->set('')->isBlank, 'isBlank');

ok(! $v->set('')->isPrintableAscii, 'isPrintableAscii');
ok(! $v->set('　')->isPrintableAscii, 'isPrintableAscii');
ok($v->set(' ')->isPrintableAscii, 'isPrintableAscii');
ok($v->set('a')->isPrintableAscii, 'isPrintableAscii');
ok($v->set('a ')->isPrintableAscii, 'isPrintableAscii');
ok(! $v->set("\n")->isPrintableAscii, 'isPrintableAscii');

ok(! $v->set('')->isWide, 'isWide');
ok($v->set('　')->isWide, 'isWide');
ok(! $v->set('1あＡ')->isWide, 'isWide');
ok(! $v->set('1あＡ')->isWide, 'isWide');
ok(! $v->set('ｱ')->isWide, 'isWide');

ok($v->set('_1aA')->isPassword, 'isPassword');
ok(! $v->set('1aA')->isPassword, 'isPassword');
ok(! $v->set('あ_1aA')->isPassword, 'isPassword');

{
  ok( $v->set('abx')->isPassword('alpha'), 'isPassword(alpha)');
  ok(!$v->set('XYZ')->isPassword('alpha'), 'isPassword(alpha)');
  ok( $v->set('XYz')->isPassword('ALPHA'), 'isPassword(ALPHA)');
  ok(!$v->set('!#*')->isPassword('ALPHA'), 'isPassword(ALPHA)');
  ok( $v->set('1!X')->isPassword('digit'), 'isPassword(digit)');
  ok(!$v->set('!*x')->isPassword('digit'), 'isPassword(digit)');
  ok( $v->set('!a9')->isPassword('symbol'), 'isPassword(symbol)');
  ok(!$v->set(' a9')->isPassword('symbol'), 'isPassword(symbol)');

  my $allow = ['!', '#', ' '];
  ok( $v->set('!# ')->isPassword($allow), 'isPassword(custom)');
  ok(!$v->set('***')->isPassword($allow), 'isPassword(custom)');

  ok( $v->set('1x#')->isPassword('alpha', 'digit'), 'isPassword(alpha,digit)');
  ok(!$v->set('12#')->isPassword('alpha', 'digit'), 'isPassword(alpha,digit)');
  ok(!$v->set('xy#')->isPassword('alpha', 'digit'), 'isPassword(alpha,digit)');
  ok(!$v->set('XY#')->isPassword('alpha', 'digit'), 'isPassword(alpha,digit)');
  ok(!$v->set('999')->isPassword('alpha', 'digit'), 'isPassword(alpha,digit)');
}

ok($v->set('112-3345')->isZipCode, 'isZipCode');
ok($v->set('743-48763-3216')->isTelNumber, 'isTelNumber');

ok( $v->set('null@example.org' )->isEmail, 'isEmail');
ok(!$v->set('null.@example.org')->isEmail, 'isEmail');
ok(!$v->set('.null@example.org')->isEmail, 'isEmail');

ok($v->set('null.@example.org')->isMobileEmail, 'isMobileEmail');
ok($v->set('.null@example.org')->isMobileEmail, 'isMobileEmail');
ok($v->set('.....@example.org')->isMobileEmail, 'isMobileEmail');

$v->set(500);
ok($v->isInteger, 'isInteger');
ok($v->isInteger(0, 500), 'isInteger');
ok(! $v->isInteger(0, 499), 'isInteger');
ok(! $v->set('100.1')->isInteger, 'isInteger');

$v->set(500.52);
ok($v->isReal, 'isReal');
ok($v->isReal(0, 500.6), 'isReal');
ok(! $v->isReal(0, 500.51), 'isReal');
ok(! $v->set('500.')->isReal, 'isReal');

ok($v->set('あああ')->isHira, 'isHira');
ok(! $v->set('あああ1')->isHira, 'isHira');
ok($v->set('ぁーん')->isHira, 'isHira');
ok($v->set('アアア')->isKata, 'isKata');
ok(! $v->set('アアア1')->isKata, 'isKata');
ok($v->set('ァーン')->isKata, 'isKata');

ok($v->set('2004-02-29')->isExistentDay, 'isExistentDay');
#ok($v->set('2004-2-29')->isExistentDay, 'isExistentDay');
#ok(! $v->set('2004-2-29')->isExistentDay, 'isExistentDay');
ok(! $v->set('2003-02-29')->isExistentDay, 'isExistentDay');

ok($v->set('00:00:00')->isExistentTime, 'isExistentTime');
#ok($v->set('0:0:0')->isExistentTime(1), 'isExistentTime');
#ok(! $v->set('0:0:0')->isExistentTime(0), 'isExistentTime');
ok(! $v->set('24:00:00')->isExistentTime, 'isExistentTime');
ok(! $v->set('02:60:00')->isExistentTime, 'isExistentTime');
ok(! $v->set('02:00:60')->isExistentTime, 'isExistentTime');

# デフォルト
ok($v->set('2004-02-29 00:00:00')->isExistentDateTime, 'isExistentDateTime');
ok(! $v->set('2003-02-29 00:00:00')->isExistentDateTime, 'isExistentDateTime');
ok(! $v->set('2010-06-01 24:00:00')->isExistentDateTime, 'isExistentDateTime');
ok(! $v->set('2010-6-1 0:00:00')->isExistentDateTime, 'isExistentDateTime');

# オプション
ok($v->set('2004-02-29 00:00:00')->isExistentDateTime(format => "YYYYMMDD HHMMSS"), 'isExistentDateTime');
ok($v->set('2004-02-29 00:00:00')->isExistentDateTime(date_delim => '-', time_delim => ':'), 'isExistentDateTime');
ok($v->set('2004/02/29 00:00:00')->isExistentDateTime(date_delim => '/', time_delim => ':'), 'isExistentDateTime');
ok($v->set('2004/02/29 00:00:00')->isExistentDateTime(date_delim => '-/', time_delim => '.:'), 'isExistentDateTime');
ok($v->set('2004 02 29 00 00 00')->isExistentDateTime(date_delim => ' ', time_delim => ' '), 'isExistentDateTime');
ok($v->set('2004/02/29 00:00:00')->isExistentDateTime(date_delim => '-/ ', time_delim => '.: '), 'isExistentDateTime');
ok($v->set('2004/02/29 00:00:00')->isExistentDateTime(date_delim => '/'), 'isExistentDateTime');
ok($v->set('20040229000000')->isExistentDateTime(date_delim => '', time_delim => ''), 'isExistentDateTime');
ok($v->set('20040229000000')->isExistentDateTime(date_delim_optional => '-/ ', time_delim_optional => '.: '), 'isExistentDateTime');
ok($v->set('20040229000000')->isExistentDateTime(date_delim_optional => '-/ ', time_delim_optional => '.: '), 'isExistentDateTime');

ok($v->set('2010-06-01 10:00:00')->isExistentDateTime(format => "YMD HMS"), 'isExistentDateTime format');
ok($v->set('2010-6-1 1:0:0')->isExistentDateTime(format => "YMD HMS"), 'isExistentDateTime format');
ok($v->set('10-6-1 1:0:0')->isExistentDateTime(format => "YMD HMS"), 'isExistentDateTime format');
ok(! $v->set('0-6-1 1:0:0')->isExistentDateTime(format => "YMD HMS"), 'isExistentDateTime format');
ok($v->set('2010-06-01 1:0:0')->isExistentDateTime(format => "YYYYMMDD HMS"), 'isExistentDateTime format');
ok(! $v->set('2010-6-1 1:0:0')->isExistentDateTime(format => "YYYYMMDD HMS"), 'isExistentDateTime format');
ok($v->set('2010-6-1 01:00:00')->isExistentDateTime(format => "YMD HHMMSS"), 'isExistentDateTime format');
ok(! $v->set('2010-6-1 1:0:0')->isExistentDateTime(format => "YMD HHMMSS"), 'isExistentDateTime format');
ok($v->set('20040229000000')->isExistentDateTime(format => "YMD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok(! $v->set('040229000000')->isExistentDateTime(format => "YMD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok(! $v->set('0229000000')->isExistentDateTime(format => "YMD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok($v->set('20040229000000')->isExistentDateTime(format => "YYYYMMDD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok($v->set('20040229000000')->isExistentDateTime(format => "YMD HHMMSS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok(! $v->set('20030229000000')->isExistentDateTime(format => "YMD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok(! $v->set('20030229000000')->isExistentDateTime(format => "YYYYMMDD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok(! $v->set('20030229000000')->isExistentDateTime(format => "YMD HHMMSS", date_delim => '', time_delim => ''), 'isExistentDateTime format');
ok(! $v->set('04229000')->isExistentDateTime(format => "YMD HMS", date_delim => '', time_delim => ''), 'isExistentDateTime format');

ok($v->set('2010-08-12 00:00:00')->isExistentDateTime(time_delim_optional => ':'), 'isExistentDateTime delim_optional');
ok($v->set('2010-08-12 000000')->isExistentDateTime(time_delim_optional => ':'), 'isExistentDateTime delim_optional');
ok($v->set('2010-08-12 000000')->isExistentDateTime(time_delim => ''), 'isExistentDateTime delim_optional');
ok(! $v->set('2010-08-12 00:00:00')->isExistentDateTime(time_delim => ''), 'isExistentDateTime delim_optional');
ok($v->set('2010-08-31 00:00:00')->isExistentDateTime(date_delim_optional => '-'), 'isExistentDateTime delim_optional');
ok($v->set('20100831 00:00:00')->isExistentDateTime( date_delim_optional => '-'), 'isExistentDateTime delim_optional');
ok($v->set('20100831 00:00:00')->isExistentDateTime(date_delim => ''), 'isExistentDateTime delim_optional');
ok(! $v->set('2010-08-31 00:00:00')->isExistentDateTime(date_delim => ''), 'isExistentDateTime delim_optional');
ok($v->set('2010-08-31 00:00:00')->isExistentDateTime(date_delim_optional => '-'), 'isExistentDateTime delim_optional');

ok($v->set('GIF89a-----')->isGif, 'isGif');
ok($v->set("\xFF\xD8-----")->isJpeg, 'isJpeg');
ok($v->set("\x89PNG\x0D\x0A\x1A\x0A-----")->isPng, 'isPng');

ok($v->set("https://foo/")->isHttpsUrl, 'isHttpsUrl');
ok($v->set("http://foo/")->isHttpUrl, 'isHttpUrl');

$v->set('テスト');
ok($v->isLen(0, 9), 'isLen');
ok(! $v->isLen(0, 8), 'isLen');
ok($v->isSjisLen(0, 6), 'isSjisLen');
ok(! $v->isSjisLen(0, 5), 'isSjisLen');
ok($v->isCharLen(0, 3), 'isCharLen');
ok(! $v->isCharLen(0, 2), 'isCharLen');

ok $v->set('example.org')->isDomainName, 'example.org is a domain name';
ok !$v->set('-example.org')->isDomainName, '-example.org is not a domain name';
ok !$v->set('123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890.jp')
      ->isDomainName, '1234...............7890.jp is too long to be a domain name';

is($v->set("192.168.0.1")->isIpAddress("10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 127.0.0.1 fe80::/10 ::1"), 1, 'isIpAddress');
is($v->set("255.168.0.1")->isIpAddress("10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 127.0.0.1 fe80::/10 ::1"), undef, 'isIpAddress');
is($v->set("255.168.0.1")->isIpAddress, undef, 'isIpAddress error');
is($v->set("255.168.0.1")->isIpAddress(\123), undef, 'isIpAddress error');
is($v->set("fe80::1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1")->isIpAddress('192.168.0.1'), undef, 'isIpAddress error');
is($v->set("255.168.0.1")->isIpAddress('fe80::1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1/10'), undef, 'isIpAddress error');

is($v->set('2000/01/01')->isDateString('%Y/%m/%d'), 1    , 'isDateString [2000/01/01] [%Y/%m/%d]');
is($v->set('2000/01/01')->isDateString('%Y-%m-%d'), undef, 'isDateString [2000/01/01] [%Y-%m-%d]');
dies_ok {
    $v->set('2000/01/01')->isDateString('foo bar');
} 'isDateString [2000/01/01] [foo bar]';

SKIP:
{
  if( $Tripletail::VERSION le '0.43' )
  {
    skip "isChar is not supported this version", 17;
  }
  ok($v->can("isChar"), "isChar is supported");

  throws_ok {
    $v->isChar();
  } qr/no arguments/, 'isChar requires arguments';

  my $digits = "0123456789";
  my $lower  = "abcdefghijklmnopqrstuvwxyz";
  my $upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  $v->set($digits);
  ok($v->isChar("digit"), "isChar: digit");

  $v->set("a");
  ok(!$v->isChar("digit"), "isChar: digit rejects alpha");

  $v->set($lower.$upper);
  ok($v->isChar("alpha"), "isChar: alpha");

  $v->set("0");
  ok(!$v->isChar("alpha"), "isChar: alpha rejects digit");

  $v->set($lower);
  ok($v->isChar("loweralpha"), "isChar: loweralpha");

  $v->set("A");
  ok(!$v->isChar("loweralpha"), "isChar: loweralpha rejects upper");

  $v->set("0");
  ok(!$v->isChar("loweralpha"), "isChar: loweralpha rejects digit");

  $v->set($upper);
  ok($v->isChar("upperalpha"), "isChar: upperalpha");

  $v->set("a");
  ok(!$v->isChar("upperalpha"), "isChar: upperalpha rejects lower");

  $v->set("0");
  ok(!$v->isChar("upperalpha"), "isChar: upperalpha rejects digit");

  $v->set('-_-');
  ok($v->isChar('- ,_'), "isChar: - and _");

  my $chk = ['#', '!'];
  $v->set("#!#!");
  ok($v->isChar($chk), "isChar: [#!]");
  $v->set("0");
  ok(!$v->isChar($chk), "isChar: [#!] rejected digit");
  $v->set("z");
  ok(!$v->isChar($chk), "isChar: [#!] rejected lower");
  $v->set("Z");
  ok(!$v->isChar($chk), "isChar: [#!] rejected upper");
}

#---------------------------------- conv系

is($v->set('1あアあ')->convHira->get, '1あああ', 'convHira');
is($v->set('1あアあ')->convKata->get, '1アアア', 'convKata');
is($v->set('あ１２３')->convNumber->get, 'あ123', 'convNumber');
is($v->set('_！１Ａ')->convNarrow->get, '_!1A', 'convNarrow');
is($v->set('＃3b')->convWide->get, '＃３ｂ', 'convWide');
is($v->set('1１aａあいうアイウポダｱｲｳﾎﾟﾀﾞ')->convKanaNarrow->get, '1１aａあいうｱｲｳﾎﾟﾀﾞｱｲｳﾎﾟﾀﾞ', 'convKanaNarrow');
is($v->set('1１aａあいうアイウポダｱｲｳﾎﾟﾀﾞ')->convKanaWide->get, '1１aａあいうアイウポダアイウポダ', 'convKanaWide');
is($v->set('1')->convComma->get, '1', 'convComma');
is($v->set('12')->convComma->get, '12', 'convComma');
is($v->set('123')->convComma->get, '123', 'convComma');
is($v->set('1234')->convComma->get, '1,234', 'convComma');
is($v->set('12345')->convComma->get, '12,345', 'convComma');
is($v->set('123456')->convComma->get, '123,456', 'convComma');
is($v->set('1234567')->convComma->get, '1,234,567', 'convComma');
is($v->set('12345678')->convComma->get, '12,345,678', 'convComma');
is($v->set('-12345678')->convComma->get, '-12,345,678', 'convComma');
is($v->set('-12345678.9')->convComma->get, '-12,345,678.9', 'convComma');

is($v->set("\n\n")->convLF->get, "\n\n", 'forceLF');
is($v->set("\r\n\r\n")->convLF->get, "\n\n", 'forceLF');
is($v->set("\r\r")->convLF->get, "\n\n", 'forceLF');

is($v->set("\n")->convBR->get, "<BR>\n", 'forceBR');
is($v->set("\r")->convBR->get, "<BR>\n", 'forceBR');
is($v->set("\r\n")->convBR->get, "<BR>\n", 'forceBR');

#---------------------------------- force系

is($v->set('1あア')->forceHira->get, 'あ', 'forceHira');
is($v->set('1あア')->forceKata->get, 'ア', 'forceKata');
is($v->set('１ａｂ9')->forceNumber->get, '9', 'forceNumber');

dies_ok {$v->set(500)->forceMin(undef)} 'set undef';
dies_ok {$v->set(500)->forceMin(\123)} 'set SCALAR';
is($v->set(500)->forceMin(10, 'foo')->get, '500', 'forceMin');
is($v->set(  5)->forceMin(10, 'foo')->get, 'foo', 'forceMin');
dies_ok {$v->set(500)->forceMax(undef)} 'set undef';
dies_ok {$v->set(500)->forceMax(\123)} 'set SCALAR';
is($v->set(500)->forceMax(10, 'foo')->get, 'foo', 'forceMax');
is($v->set(  5)->forceMax(10, 'foo')->get, '5'  , 'forceMax');

is($v->set('あえいおう')->forceMaxLen(6)->get, 'あえ', 'forceMaxLen');
is($v->set('あえいおう')->forceMaxUtf8Len(5)->get, 'あ', 'forceMaxUtf8Len');
is($v->set('あえいおう')->forceMaxSjisLen(5)->get, 'あえ', 'forceMaxSjisLen');
is($v->set('あえいおう')->forceMaxCharLen(4)->get, 'あえいお', 'forceMaxCharLen');

is($v->set(Unicode::Japanese->new("1\xED\x402", 'sjis')->utf8)->forcePortable->get, '12', 'forcePortable');
is($v->set(Unicode::Japanese->new("\x00\x0f\xf0\x10", 'ucs4')->utf8)->forcePcPortable->get, '', 'forcePcPortable');

#---------------------------------- その他

is($v->set(' A ')->trimWhitespace->get, 'A', 'trimWhitespace');
is($v->set('　A　')->trimWhitespace->get, 'A', 'trimWhitespace');
is($v->set("\t\tA\t\t")->trimWhitespace->get, 'A', 'trimWhitespace');
is($v->set("\t\t 　\tA  A\t 　　\t")->trimWhitespace->get, 'A  A', 'trimWhitespace');
ok(! $v->set(Unicode::Japanese->new("\xED\x40", 'sjis')->utf8)->isPortable, 'isPortable');
ok(! $v->set(Unicode::Japanese->new("\x00\x00\xf0\x10", 'ucs4')->utf8)->isPortable, 'isPortable');
ok(! $v->set(Unicode::Japanese->new("\x00\x0f\x10\x10", 'ucs4')->utf8)->isPortable, 'isPortable');
ok($v->set('あ')->isPortable, 'isPortable');
ok($v->set(Unicode::Japanese->new("\xED\x40", 'sjis')->utf8)->isPcPortable, 'isPcPortable');
ok($v->set(Unicode::Japanese->new("\x00\x00\xf0\x10", 'ucs4')->utf8)->isPcPortable, 'isPcPortable');
ok(! $v->set(Unicode::Japanese->new("\x00\x0f\xf0\x10", 'ucs4')->utf8)->isPcPortable, 'isPcPortable');
ok($v->set('あ')->isPortable, 'isPcPortable');
is($v->set("あああ　えええ")->countWords, 2, 'countWords');

my @str;
ok(@str = $v->set('あabいうえcdお')->strCut(2), 'strCut');

is($str[0],'あa','strCut');
is($str[1],'bい','strCut');
is($str[2],'うえ','strCut');
is($str[3],'cd','strCut');
is($str[4],'お','strCut');

ok(@str = $v->set('あabいうえcお')->strCutSjis(2), 'strCutSjis');

is($str[0],'あ','strCut');
is($str[1],'ab','strCut');
is($str[2],'い','strCut');
is($str[3],'う','strCut');
is($str[4],'え','strCut');
is($str[5],'c','strCut');
is($str[6],'お','strCut');

ok(@str = $v->set('あabいうえcお')->strCutUtf8(3), 'strCutUtf8');

is($str[0],'あ','strCut');
is($str[1],'ab','strCut');
is($str[2],'い','strCut');
is($str[3],'う','strCut');
is($str[4],'え','strCut');
is($str[5],'c','strCut');
is($str[6],'お','strCut');



foreach my $iter (
	['default', 10, undef,                   qr/^[a-zA-Z2-8]+$/],
	['common',  20, [qw(alpha ALPHA num _)], qr/^\w+$/],
	['alpha',    4, [qw(alpha)],             qr/^[a-z]+$/],
	['ALPHA',   16, [qw(ALPHA)],             qr/^[A-Z]+$/],
	['num',      6, [qw(num)],               qr/^[0-9]+$/],
	['sym',      8, [qw(! = : _ & ~)],       qr/^[!=:_&~]+$/],
)
{
  my ($name, $len, $type, $pat) = @$iter;
  my $s = $v->genRandomString($len, $type);
  ok($s, "genRandomString($name)");
  is(length($s), $len, "genRandomString($name).length ($len)");
  like($s, $pat, "genRandomString($name).pattern");
  isnt($s, $v->genRandomString($len, $type), "genRandomString($name).another");
}
ok($v->genRandomString(10), "genRandomString, without type");
{
  my $iter = ['mix/long', 100000, [qw(alpha ALPHA num _)], undef];
  my ($name, $len, $type, $pat) = @$iter;
  my $s = $v->genRandomString($len, $type);
  ok($s, "genRandomString($name)");
  is(length($s), $len, "genRandomString($name).length ($len)");
}

is($TL->newValue('SoftBank/XXX')->detectMobileAgent, 'utf8-jsky', 'detectMobileAgent(SoftBank/XXX)');
is($TL->newValue(undef)->detectMobileAgent, undef, 'detectMobileAgent(undef)');
