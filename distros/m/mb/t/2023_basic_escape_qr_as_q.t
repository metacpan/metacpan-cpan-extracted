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
qr'ァ'
END1
---
qr{\G${mb::_anchor}@{[qr'(?:\x83\x40)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 2
qr'ア'
END1
qr{\G${mb::_anchor}@{[qr'(?:ア)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 3
qr'ィ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ィ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 4
qr'イ'
END1
qr{\G${mb::_anchor}@{[qr'(?:イ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 5
qr'ゥ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ゥ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 6
qr'ウ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ウ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 7
qr'ェ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ェ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 8
qr'エ'
END1
qr{\G${mb::_anchor}@{[qr'(?:エ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 9
qr'ォ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ォ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 10
qr'オ'
END1
qr{\G${mb::_anchor}@{[qr'(?:オ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 11
qr'カ'
END1
qr{\G${mb::_anchor}@{[qr'(?:カ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 12
qr'ガ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ガ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 13
qr'キ'
END1
qr{\G${mb::_anchor}@{[qr'(?:キ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 14
qr'ギ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ギ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 15
qr'ク'
END1
qr{\G${mb::_anchor}@{[qr'(?:ク)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 16
qr'グ'
END1
qr{\G${mb::_anchor}@{[qr'(?:グ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 17
qr'ケ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ケ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 18
qr'ゲ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ゲ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 19
qr'コ'
END1
qr{\G${mb::_anchor}@{[qr'(?:コ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 20
qr'ゴ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ゴ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 21
qr'サ'
END1
qr{\G${mb::_anchor}@{[qr'(?:サ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 22
qr'ザ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ザ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 23
qr'シ'
END1
qr{\G${mb::_anchor}@{[qr'(?:シ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 24
qr'ジ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ジ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 25
qr'ス'
END1
qr{\G${mb::_anchor}@{[qr'(?:ス)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 26
qr'ズ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ズ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 27
qr'セ'
END1
qr{\G${mb::_anchor}@{[qr'(?:セ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 28
qr'ゼ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x5B)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 29
qr'ソ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x5C)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 30
qr'ゾ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x5D)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 31
qr'タ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x5E)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 32
qr'ダ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ダ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 33
qr'チ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x60)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 34
qr'ヂ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ヂ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 35
qr'ッ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ッ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 36
qr'ツ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ツ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 37
qr'ヅ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ヅ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 38
qr'テ'
END1
qr{\G${mb::_anchor}@{[qr'(?:テ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 39
qr'デ'
END1
qr{\G${mb::_anchor}@{[qr'(?:デ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 40
qr'ト'
END1
qr{\G${mb::_anchor}@{[qr'(?:ト)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 41
qr'ド'
END1
qr{\G${mb::_anchor}@{[qr'(?:ド)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 42
qr'ナ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ナ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 43
qr'ニ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ニ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 44
qr'ヌ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ヌ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 45
qr'ネ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ネ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 46
qr'ノ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ノ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 47
qr'ハ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ハ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 48
qr'バ'
END1
qr{\G${mb::_anchor}@{[qr'(?:バ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 49
qr'パ'
END1
qr{\G${mb::_anchor}@{[qr'(?:パ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 50
qr'ヒ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ヒ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 51
qr'ビ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ビ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 52
qr'ピ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ピ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 53
qr'フ'
END1
qr{\G${mb::_anchor}@{[qr'(?:フ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 54
qr'ブ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ブ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 55
qr'プ'
END1
qr{\G${mb::_anchor}@{[qr'(?:プ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 56
qr'ヘ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ヘ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 57
qr'ベ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ベ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 58
qr'ペ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ペ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 59
qr'ホ'
END1
qr{\G${mb::_anchor}@{[qr'(?:ホ)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 60
qr'ボ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x7B)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 61
qr'ポ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x7C)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 62
qr'マ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x7D)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 63
qr'ミ'
END1
qr{\G${mb::_anchor}@{[qr'(?:\x83\x7E)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 64
qr'[ァ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x40))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 65
qr'[ア]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ア))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 66
qr'[ィ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ィ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 67
qr'[イ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:イ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 68
qr'[ゥ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ゥ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 69
qr'[ウ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ウ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 70
qr'[ェ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ェ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 71
qr'[エ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:エ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 72
qr'[ォ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ォ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 73
qr'[オ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:オ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 74
qr'[カ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:カ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 75
qr'[ガ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ガ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 76
qr'[キ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:キ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 77
qr'[ギ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ギ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 78
qr'[ク]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ク))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 79
qr'[グ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:グ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 80
qr'[ケ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ケ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 81
qr'[ゲ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ゲ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 82
qr'[コ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:コ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 83
qr'[ゴ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ゴ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 84
qr'[サ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:サ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 85
qr'[ザ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ザ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 86
qr'[シ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:シ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 87
qr'[ジ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ジ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 88
qr'[ス]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ス))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 89
qr'[ズ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ズ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 90
qr'[セ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:セ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 91
qr'[ゼ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x5B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 92
qr'[ソ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x5C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 93
qr'[ゾ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x5D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 94
qr'[タ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x5E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 95
qr'[ダ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ダ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 96
qr'[チ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x60))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 97
qr'[ヂ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ヂ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 98
qr'[ッ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ッ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 99
qr'[ツ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ツ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 100
qr'[ヅ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ヅ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 101
qr'[テ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:テ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 102
qr'[デ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:デ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 103
qr'[ト]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ト))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 104
qr'[ド]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ド))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 105
qr'[ナ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ナ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 106
qr'[ニ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ニ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 107
qr'[ヌ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ヌ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 108
qr'[ネ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ネ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 109
qr'[ノ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ノ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 110
qr'[ハ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ハ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 111
qr'[バ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:バ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 112
qr'[パ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:パ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 113
qr'[ヒ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ヒ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 114
qr'[ビ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ビ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 115
qr'[ピ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ピ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 116
qr'[フ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:フ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 117
qr'[ブ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ブ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 118
qr'[プ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:プ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 119
qr'[ヘ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ヘ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 120
qr'[ベ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ベ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 121
qr'[ペ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ペ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 122
qr'[ホ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ホ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 123
qr'[ボ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x7B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 124
qr'[ポ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x7C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 125
qr'[マ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x7D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 126
qr'[ミ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:\x83\x7E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 127
qr'[^ァ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x40))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 128
qr'[^ア]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ア))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 129
qr'[^ィ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ィ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 130
qr'[^イ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:イ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 131
qr'[^ゥ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ゥ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 132
qr'[^ウ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ウ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 133
qr'[^ェ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ェ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 134
qr'[^エ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:エ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 135
qr'[^ォ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ォ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 136
qr'[^オ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:オ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 137
qr'[^カ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:カ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 138
qr'[^ガ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ガ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 139
qr'[^キ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:キ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 140
qr'[^ギ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ギ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 141
qr'[^ク]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ク))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 142
qr'[^グ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:グ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 143
qr'[^ケ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ケ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 144
qr'[^ゲ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ゲ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 145
qr'[^コ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:コ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 146
qr'[^ゴ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ゴ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 147
qr'[^サ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:サ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 148
qr'[^ザ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ザ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 149
qr'[^シ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:シ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 150
qr'[^ジ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ジ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 151
qr'[^ス]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ス))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 152
qr'[^ズ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ズ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 153
qr'[^セ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:セ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 154
qr'[^ゼ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x5B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 155
qr'[^ソ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x5C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 156
qr'[^ゾ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x5D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 157
qr'[^タ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x5E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 158
qr'[^ダ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ダ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 159
qr'[^チ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x60))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 160
qr'[^ヂ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ヂ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 161
qr'[^ッ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ッ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 162
qr'[^ツ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ツ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 163
qr'[^ヅ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ヅ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 164
qr'[^テ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:テ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 165
qr'[^デ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:デ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 166
qr'[^ト]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ト))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 167
qr'[^ド]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ド))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 168
qr'[^ナ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ナ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 169
qr'[^ニ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ニ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 170
qr'[^ヌ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ヌ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 171
qr'[^ネ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ネ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 172
qr'[^ノ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ノ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 173
qr'[^ハ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ハ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 174
qr'[^バ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:バ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 175
qr'[^パ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:パ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 176
qr'[^ヒ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ヒ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 177
qr'[^ビ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ビ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 178
qr'[^ピ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ピ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 179
qr'[^フ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:フ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 180
qr'[^ブ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ブ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 181
qr'[^プ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:プ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 182
qr'[^ヘ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ヘ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 183
qr'[^ベ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ベ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 184
qr'[^ペ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ペ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 185
qr'[^ホ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ホ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 186
qr'[^ボ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x7B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 187
qr'[^ポ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x7C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 188
qr'[^マ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x7D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 189
qr'[^ミ]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:\x83\x7E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 190
qr'.'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|.)' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 191
qr'\B'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?<![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])|(?<=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 192
qr'\D'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 193
qr'\H'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 194
qr'\N'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!\n)(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 195
qr'\R'
END1
qr{\G${mb::_anchor}@{[qr'(?>\r\n|[\x0A\x0B\x0C\x0D])' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 196
qr'\S'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 197
qr'\V'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 198
qr'\W'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 199
qr'\b'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?<![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])|(?<=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 200
qr'\d'
END1
qr{\G${mb::_anchor}@{[qr'[0123456789]' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 201
qr'\h'
END1
qr{\G${mb::_anchor}@{[qr'[\x09\x20]' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 202
qr'\s'
END1
qr{\G${mb::_anchor}@{[qr'[\t\n\f\r\x20]' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 203
qr'\v'
END1
qr{\G${mb::_anchor}@{[qr'[\x0A\x0B\x0C\x0D]' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 204
qr'\w'
END1
qr{\G${mb::_anchor}@{[qr'[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 205
qr'[\b]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x08])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 206
qr'[[:alnum:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 207
qr'[[:alpha:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 208
qr'[[:ascii:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x00-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 209
qr'[[:blank:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 210
qr'[[:cntrl:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x00-\x1F\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 211
qr'[[:digit:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 212
qr'[[:graph:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x21-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 213
qr'[[:lower:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[abcdefghijklmnopqrstuvwxyz])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 214
qr'[[:print:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x20-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 215
qr'[[:punct:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 216
qr'[[:space:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\s\x0B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 217
qr'[[:upper:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZ])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 218
qr'[[:word:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39\x41-\x5A\x5F\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 219
qr'[[:xdigit:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39\x41-\x46\x61-\x66])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 220
qr'[[:^alnum:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 221
qr'[[:^alpha:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 222
qr'[[:^ascii:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x00-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 223
qr'[[:^blank:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 224
qr'[[:^cntrl:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x00-\x1F\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 225
qr'[[:^digit:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 226
qr'[[:^graph:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x21-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 227
qr'[[:^lower:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![abcdefghijklmnopqrstuvwxyz])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 228
qr'[[:^print:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x20-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 229
qr'[[:^punct:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 230
qr'[[:^space:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\s\x0B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 231
qr'[[:^upper:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZ])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 232
qr'[[:^word:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x5A\x5F\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 233
qr'[[:^xdigit:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x46\x61-\x66])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 234
qr'[.]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[.])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 235
qr'[\B]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 236
qr'[\D]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 237
qr'[\H]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 238
qr'[\N]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\N])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 239
qr'[\R]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\R])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 240
qr'[\S]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 241
qr'[\V]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 242
qr'[\W]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 243
qr'[\b]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x08])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 244
qr'[\d]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 245
qr'[\h]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 246
qr'[\s]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 247
qr'[\v]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 248
qr'[\w]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 249
qr'[^.]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![.])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 250
qr'[^\B]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 251
qr'[^\D]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 252
qr'[^\H]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 253
qr'[^\N]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\N])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 254
qr'[^\R]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\R])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 255
qr'[^\S]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 256
qr'[^\V]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 257
qr'[^\W]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 258
qr'[^\b]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\x08])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 259
qr'[^\d]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 260
qr'[^\h]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 261
qr'[^\s]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 262
qr'[^\v]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 263
qr'[^\w]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 264
qr'[アソゾABC1-3]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 265
qr'[^アソゾABC1-3]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 266
qr'[アソゾABC1-3[:alnum:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 267
qr'[^アソゾABC1-3[:alnum:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 268
qr'[アソゾ${_}ABC1-3[:alnum:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[${_}ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 269
qr'[^アソゾ${_}ABC1-3[:alnum:]]'
END1
qr{\G${mb::_anchor}@{[qr'(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[${_}ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 270
qr'Abア[アソゾABC1-3]'i
END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 271
qr'Abア[^アソゾABC1-3]'i
END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 272
qr'Abア[アソゾABC1-3[:alnum:]]'i
END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 273
qr'Abア[^アソゾABC1-3[:alnum:]]'i
END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 274
qr'Abア[アソゾ${_}ABC1-3[:alnum:]]'i
END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[${_}ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 275
qr'Abア[^アソゾ${_}ABC1-3[:alnum:]]'i
END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[${_}ABC1-3\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_m_passed()]}}
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
