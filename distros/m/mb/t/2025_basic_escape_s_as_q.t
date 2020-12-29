# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 1
---
s'ァ'1'
END1
---
s{(\G${mb::_anchor})@{[qr'(?:\x83\x40)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 2
s'ア'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ア)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 3
s'ィ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ィ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 4
s'イ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:イ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 5
s'ゥ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ゥ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 6
s'ウ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ウ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 7
s'ェ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ェ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 8
s'エ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:エ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 9
s'ォ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ォ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 10
s'オ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:オ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 11
s'カ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:カ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 12
s'ガ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ガ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 13
s'キ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:キ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 14
s'ギ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ギ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 15
s'ク'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ク)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 16
s'グ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:グ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 17
s'ケ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ケ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 18
s'ゲ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ゲ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 19
s'コ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:コ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 20
s'ゴ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ゴ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 21
s'サ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:サ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 22
s'ザ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ザ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 23
s'シ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:シ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 24
s'ジ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ジ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 25
s'ス'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ス)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 26
s'ズ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ズ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 27
s'セ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:セ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 28
s'ゼ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x5B)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 29
s'ソ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x5C)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 30
s'ゾ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x5D)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 31
s'タ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x5E)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 32
s'ダ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ダ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 33
s'チ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x60)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 34
s'ヂ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ヂ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 35
s'ッ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ッ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 36
s'ツ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ツ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 37
s'ヅ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ヅ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 38
s'テ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:テ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 39
s'デ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:デ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 40
s'ト'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ト)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 41
s'ド'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ド)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 42
s'ナ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ナ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 43
s'ニ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ニ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 44
s'ヌ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ヌ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 45
s'ネ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ネ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 46
s'ノ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ノ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 47
s'ハ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ハ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 48
s'バ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:バ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 49
s'パ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:パ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 50
s'ヒ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ヒ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 51
s'ビ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ビ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 52
s'ピ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ピ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 53
s'フ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:フ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 54
s'ブ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ブ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 55
s'プ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:プ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 56
s'ヘ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ヘ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 57
s'ベ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ベ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 58
s'ペ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ペ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 59
s'ホ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:ホ)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 60
s'ボ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x7B)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 61
s'ポ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x7C)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 62
s'マ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x7D)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 63
s'ミ'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:\x83\x7E)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 64
s'[ァ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x40))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 65
s'[ア]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ア))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 66
s'[ィ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ィ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 67
s'[イ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:イ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 68
s'[ゥ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ゥ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 69
s'[ウ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ウ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 70
s'[ェ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ェ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 71
s'[エ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:エ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 72
s'[ォ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ォ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 73
s'[オ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:オ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 74
s'[カ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:カ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 75
s'[ガ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ガ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 76
s'[キ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:キ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 77
s'[ギ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ギ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 78
s'[ク]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ク))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 79
s'[グ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:グ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 80
s'[ケ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ケ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 81
s'[ゲ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ゲ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 82
s'[コ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:コ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 83
s'[ゴ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ゴ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 84
s'[サ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:サ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 85
s'[ザ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ザ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 86
s'[シ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:シ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 87
s'[ジ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ジ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 88
s'[ス]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ス))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 89
s'[ズ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ズ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 90
s'[セ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:セ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 91
s'[ゼ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x5B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 92
s'[ソ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x5C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 93
s'[ゾ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x5D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 94
s'[タ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x5E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 95
s'[ダ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ダ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 96
s'[チ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x60))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 97
s'[ヂ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ヂ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 98
s'[ッ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ッ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 99
s'[ツ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ツ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 100
s'[ヅ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ヅ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 101
s'[テ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:テ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 102
s'[デ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:デ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 103
s'[ト]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ト))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 104
s'[ド]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ド))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 105
s'[ナ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ナ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 106
s'[ニ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ニ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 107
s'[ヌ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ヌ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 108
s'[ネ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ネ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 109
s'[ノ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ノ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 110
s'[ハ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ハ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 111
s'[バ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:バ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 112
s'[パ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:パ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 113
s'[ヒ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ヒ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 114
s'[ビ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ビ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 115
s'[ピ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ピ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 116
s'[フ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:フ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 117
s'[ブ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ブ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 118
s'[プ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:プ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 119
s'[ヘ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ヘ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 120
s'[ベ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ベ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 121
s'[ペ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ペ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 122
s'[ホ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ホ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 123
s'[ボ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x7B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 124
s'[ポ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x7C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 125
s'[マ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x7D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 126
s'[ミ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:\x83\x7E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 127
s'[^ァ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x40))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 128
s'[^ア]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ア))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 129
s'[^ィ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ィ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 130
s'[^イ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:イ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 131
s'[^ゥ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ゥ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 132
s'[^ウ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ウ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 133
s'[^ェ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ェ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 134
s'[^エ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:エ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 135
s'[^ォ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ォ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 136
s'[^オ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:オ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 137
s'[^カ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:カ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 138
s'[^ガ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ガ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 139
s'[^キ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:キ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 140
s'[^ギ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ギ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 141
s'[^ク]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ク))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 142
s'[^グ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:グ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 143
s'[^ケ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ケ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 144
s'[^ゲ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ゲ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 145
s'[^コ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:コ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 146
s'[^ゴ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ゴ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 147
s'[^サ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:サ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 148
s'[^ザ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ザ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 149
s'[^シ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:シ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 150
s'[^ジ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ジ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 151
s'[^ス]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ス))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 152
s'[^ズ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ズ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 153
s'[^セ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:セ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 154
s'[^ゼ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x5B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 155
s'[^ソ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x5C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 156
s'[^ゾ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x5D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 157
s'[^タ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x5E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 158
s'[^ダ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ダ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 159
s'[^チ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x60))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 160
s'[^ヂ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ヂ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 161
s'[^ッ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ッ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 162
s'[^ツ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ツ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 163
s'[^ヅ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ヅ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 164
s'[^テ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:テ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 165
s'[^デ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:デ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 166
s'[^ト]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ト))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 167
s'[^ド]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ド))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 168
s'[^ナ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ナ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 169
s'[^ニ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ニ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 170
s'[^ヌ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ヌ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 171
s'[^ネ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ネ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 172
s'[^ノ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ノ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 173
s'[^ハ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ハ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 174
s'[^バ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:バ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 175
s'[^パ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:パ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 176
s'[^ヒ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ヒ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 177
s'[^ビ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ビ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 178
s'[^ピ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ピ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 179
s'[^フ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:フ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 180
s'[^ブ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ブ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 181
s'[^プ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:プ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 182
s'[^ヘ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ヘ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 183
s'[^ベ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ベ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 184
s'[^ペ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ペ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 185
s'[^ホ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ホ))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 186
s'[^ボ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x7B))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 187
s'[^ポ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x7C))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 188
s'[^マ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x7D))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 189
s'[^ミ]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:\x83\x7E))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 190
s'.'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|.)' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 191
s'\B'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?<![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])|(?<=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 192
s'\D'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 193
s'\H'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 194
s'\N'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!\n)(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 195
s'\R'1'
END1
s{(\G${mb::_anchor})@{[qr'(?>\r\n|[\x0A\x0B\x0C\x0D])' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 196
s'\S'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 197
s'\V'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 198
s'\W'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 199
s'\b'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?<![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])|(?<=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 200
s'\d'1'
END1
s{(\G${mb::_anchor})@{[qr'[0123456789]' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 201
s'\h'1'
END1
s{(\G${mb::_anchor})@{[qr'[\x09\x20]' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 202
s'\s'1'
END1
s{(\G${mb::_anchor})@{[qr'[\t\n\f\r\x20]' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 203
s'\v'1'
END1
s{(\G${mb::_anchor})@{[qr'[\x0A\x0B\x0C\x0D]' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 204
s'\w'1'
END1
s{(\G${mb::_anchor})@{[qr'[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 205
s'[\b]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x08])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 206
s'[[:alnum:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 207
s'[[:alpha:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 208
s'[[:ascii:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x00-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 209
s'[[:blank:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 210
s'[[:cntrl:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x00-\x1F\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 211
s'[[:digit:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x30-\x39])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 212
s'[[:graph:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x21-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 213
s'[[:lower:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[abcdefghijklmnopqrstuvwxyz])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 214
s'[[:print:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x20-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 215
s'[[:punct:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 216
s'[[:space:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\s\x0B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 217
s'[[:upper:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZ])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 218
s'[[:word:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x30-\x39\x41-\x5A\x5F\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 219
s'[[:xdigit:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x30-\x39\x41-\x46\x61-\x66])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 220
s'[[:^alnum:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 221
s'[[:^alpha:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 222
s'[[:^ascii:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x00-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 223
s'[[:^blank:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 224
s'[[:^cntrl:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x00-\x1F\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 225
s'[[:^digit:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x30-\x39])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 226
s'[[:^graph:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x21-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 227
s'[[:^lower:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![abcdefghijklmnopqrstuvwxyz])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 228
s'[[:^print:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x20-\x7F])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 229
s'[[:^punct:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 230
s'[[:^space:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\s\x0B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 231
s'[[:^upper:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZ])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 232
s'[[:^word:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x5A\x5F\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 233
s'[[:^xdigit:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x46\x61-\x66])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 234
s'[.]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[.])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 235
s'[\B]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 236
s'[\D]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 237
s'[\H]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 238
s'[\N]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\N])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 239
s'[\R]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\R])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 240
s'[\S]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 241
s'[\V]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 242
s'[\W]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 243
s'[\b]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x08])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 244
s'[\d]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 245
s'[\h]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 246
s'[\s]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 247
s'[\v]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 248
s'[\w]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 249
s'[^.]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![.])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 250
s'[^\B]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\B])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 251
s'[^\D]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 252
s'[^\H]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 253
s'[^\N]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\N])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 254
s'[^\R]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\R])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 255
s'[^\S]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 256
s'[^\V]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 257
s'[^\W]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 258
s'[^\b]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\x08])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 259
s'[^\d]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![0123456789])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 260
s'[^\h]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\x09\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 261
s'[^\s]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\t\n\f\r\x20])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 262
s'[^\v]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![\x0A\x0B\x0C\x0D])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 263
s'[^\w]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 264
s'[アソゾABC1-3]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 265
s'[^アソゾABC1-3]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 266
s'[アソゾABC1-3[:alnum:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 267
s'[^アソゾABC1-3[:alnum:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 268
s'[アソゾ${_}ABC1-3[:alnum:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[${_}ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 269
s'[^アソゾ${_}ABC1-3[:alnum:]]'1'
END1
s{(\G${mb::_anchor})@{[qr'(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[${_}ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 270
s'Abア[アソゾABC1-3]'1'i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 271
s'Abア[^アソゾABC1-3]'1'i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 272
s'Abア[アソゾABC1-3[:alnum:]]'1'i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 273
s'Abア[^アソゾABC1-3[:alnum:]]'1'i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 274
s'Abア[アソゾ${_}ABC1-3[:alnum:]]'1'i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?=(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[${_}ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq regexp(<<'END2'); }, # test no 275
s'Abア[^アソゾ${_}ABC1-3[:alnum:]]'1'i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'Ab(?:ア)(?:(?!(?:ア)|(?:\x83\x5C)|(?:\x83\x5D)|[\x31-\x33]|[${_}ABC\x30-\x39\x41-\x5A\x61-\x7A])(?-xism:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))')]}@{[mb::_s_passed()]}}{$1 . '1'}e
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
