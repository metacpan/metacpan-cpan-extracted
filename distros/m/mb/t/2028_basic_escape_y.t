# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

@test = (
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 1
---
y'ァ'1'
END1
---
s{(\G${mb::_anchor})((?:(?=(?:\x83\x40))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ァ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 2
y'ア'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ア))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ア',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 3
y'ィ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ィ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ィ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 4
y'イ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:イ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'イ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 5
y'ゥ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ゥ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ゥ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 6
y'ウ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ウ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ウ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 7
y'ェ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ェ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ェ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 8
y'エ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:エ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'エ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 9
y'ォ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ォ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ォ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 10
y'オ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:オ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'オ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 11
y'カ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:カ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'カ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 12
y'ガ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ガ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ガ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 13
y'キ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:キ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'キ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 14
y'ギ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ギ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ギ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 15
y'ク'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ク))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ク',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 16
y'グ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:グ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'グ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 17
y'ケ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ケ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ケ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 18
y'ゲ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ゲ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ゲ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 19
y'コ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:コ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'コ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 20
y'ゴ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ゴ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ゴ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 21
y'サ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:サ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'サ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 22
y'ザ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ザ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ザ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 23
y'シ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:シ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'シ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 24
y'ジ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ジ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ジ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 25
y'ス'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ス))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ス',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 26
y'ズ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ズ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ズ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 27
y'セ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:セ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'セ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 28
y'ゼ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x5B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ゼ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 29
y'ソ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x5C)|[\])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ソ\',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 30
y'ゾ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x5D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ゾ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 31
y'タ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x5E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'タ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 32
y'ダ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ダ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ダ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 33
y'チ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x60))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'チ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 34
y'ヂ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ヂ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ヂ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 35
y'ッ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ッ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ッ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 36
y'ツ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ツ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ツ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 37
y'ヅ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ヅ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ヅ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 38
y'テ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:テ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'テ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 39
y'デ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:デ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'デ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 40
y'ト'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ト))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ト',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 41
y'ド'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ド))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ド',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 42
y'ナ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ナ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ナ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 43
y'ニ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ニ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ニ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 44
y'ヌ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ヌ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ヌ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 45
y'ネ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ネ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ネ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 46
y'ノ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ノ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ノ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 47
y'ハ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ハ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ハ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 48
y'バ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:バ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'バ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 49
y'パ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:パ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'パ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 50
y'ヒ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ヒ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ヒ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 51
y'ビ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ビ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ビ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 52
y'ピ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ピ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ピ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 53
y'フ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:フ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'フ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 54
y'ブ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ブ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ブ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 55
y'プ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:プ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'プ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 56
y'ヘ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ヘ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ヘ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 57
y'ベ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ベ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ベ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 58
y'ペ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ペ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ペ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 59
y'ホ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:ホ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ホ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 60
y'ボ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x7B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ボ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 61
y'ポ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x7C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ポ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 62
y'マ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x7D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'マ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 63
y'ミ'1'
END1
s{(\G${mb::_anchor})((?:(?=(?:\x83\x7E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))}{$1.mb::tr($2,q'ミ',q'1','r')}eg
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 64
y # comment 1-1
# comment 1-2
  # comment 1-3
{search} # comment 2-1
# comment 2-2
  # comment 2-3
{replacement} # comment 3-1
# comment 3-2
  # comment 3-3
END1
s # comment 1-1
# comment 1-2
  # comment 1-3
{(\G${mb::_anchor})((?:(?=[search])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))} # comment 2-1
# comment 2-2
  # comment 2-3
{$1.mb::tr($2,q{search},q{replacement},'r')}eg # comment 3-1
# comment 3-2
  # comment 3-3
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

sub regexp {
    local($_) = @_;
    if (qr// eq '(?^:)') {
        s{\(\?-xism:}{(?^:}g;
    }
    return $_;
}

__END__
