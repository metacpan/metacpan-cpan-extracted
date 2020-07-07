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
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 1
---
qr/ァ/

END1
---
qr{\G${mb::_anchor}@{[qr/(?:ソ@)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
qr/ア/

END1
qr{\G${mb::_anchor}@{[qr/(?:ア)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
qr/ィ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ィ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
qr/イ/

END1
qr{\G${mb::_anchor}@{[qr/(?:イ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
qr/ゥ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ゥ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
qr/ウ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ウ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
qr/ェ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ェ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
qr/エ/

END1
qr{\G${mb::_anchor}@{[qr/(?:エ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
qr/ォ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ォ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
qr/オ/

END1
qr{\G${mb::_anchor}@{[qr/(?:オ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
qr/カ/

END1
qr{\G${mb::_anchor}@{[qr/(?:カ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
qr/ガ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ガ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
qr/キ/

END1
qr{\G${mb::_anchor}@{[qr/(?:キ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
qr/ギ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ギ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
qr/ク/

END1
qr{\G${mb::_anchor}@{[qr/(?:ク)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
qr/グ/

END1
qr{\G${mb::_anchor}@{[qr/(?:グ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
qr/ケ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ケ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
qr/ゲ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ゲ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
qr/コ/

END1
qr{\G${mb::_anchor}@{[qr/(?:コ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
qr/ゴ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ゴ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
qr/サ/

END1
qr{\G${mb::_anchor}@{[qr/(?:サ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
qr/ザ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ザ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
qr/シ/

END1
qr{\G${mb::_anchor}@{[qr/(?:シ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
qr/ジ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ジ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
qr/ス/

END1
qr{\G${mb::_anchor}@{[qr/(?:ス)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
qr/ズ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ズ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
qr/セ/

END1
qr{\G${mb::_anchor}@{[qr/(?:セ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
qr/ゼ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ[)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
qr/ソ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ\)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
qr/ゾ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ])/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
qr/タ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ^)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
qr/ダ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ダ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
qr/チ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ`)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
qr/ヂ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ヂ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
qr/ッ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ッ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
qr/ツ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ツ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
qr/ヅ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ヅ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
qr/テ/

END1
qr{\G${mb::_anchor}@{[qr/(?:テ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
qr/デ/

END1
qr{\G${mb::_anchor}@{[qr/(?:デ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
qr/ト/

END1
qr{\G${mb::_anchor}@{[qr/(?:ト)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
qr/ド/

END1
qr{\G${mb::_anchor}@{[qr/(?:ド)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
qr/ナ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ナ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
qr/ニ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ニ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
qr/ヌ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ヌ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
qr/ネ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ネ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
qr/ノ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ノ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
qr/ハ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ハ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
qr/バ/

END1
qr{\G${mb::_anchor}@{[qr/(?:バ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
qr/パ/

END1
qr{\G${mb::_anchor}@{[qr/(?:パ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
qr/ヒ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ヒ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
qr/ビ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ビ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
qr/ピ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ピ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
qr/フ/

END1
qr{\G${mb::_anchor}@{[qr/(?:フ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
qr/ブ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ブ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
qr/プ/

END1
qr{\G${mb::_anchor}@{[qr/(?:プ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
qr/ヘ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ヘ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
qr/ベ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ベ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
qr/ペ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ペ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
qr/ホ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ホ)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
qr/ボ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ{)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
qr/ポ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ|)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
qr/マ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
qr/ミ/

END1
qr{\G${mb::_anchor}@{[qr/(?:ソ~)/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 64
qr/[ァ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ@])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 65
qr/[ア]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ア])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 66
qr/[ィ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ィ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 67
qr/[イ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[イ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 68
qr/[ゥ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ゥ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 69
qr/[ウ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ウ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 70
qr/[ェ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ェ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 71
qr/[エ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[エ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 72
qr/[ォ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ォ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 73
qr/[オ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[オ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 74
qr/[カ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[カ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 75
qr/[ガ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ガ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 76
qr/[キ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[キ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 77
qr/[ギ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ギ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 78
qr/[ク]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ク])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 79
qr/[グ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[グ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 80
qr/[ケ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ケ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 81
qr/[ゲ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ゲ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 82
qr/[コ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[コ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 83
qr/[ゴ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ゴ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 84
qr/[サ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[サ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 85
qr/[ザ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ザ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 86
qr/[シ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[シ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 87
qr/[ジ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ジ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 88
qr/[ス]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ス])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 89
qr/[ズ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ズ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 90
qr/[セ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[セ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 91
qr/[ゼ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ[])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 92
qr/[ソ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ\])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 93
qr/[ゾ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 94
qr/[タ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ^])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 95
qr/[ダ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ダ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 96
qr/[チ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ`])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 97
qr/[ヂ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ヂ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 98
qr/[ッ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ッ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 99
qr/[ツ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ツ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 100
qr/[ヅ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ヅ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 101
qr/[テ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[テ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 102
qr/[デ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[デ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 103
qr/[ト]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ト])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 104
qr/[ド]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ド])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 105
qr/[ナ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ナ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 106
qr/[ニ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ニ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 107
qr/[ヌ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ヌ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 108
qr/[ネ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ネ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 109
qr/[ノ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ノ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 110
qr/[ハ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ハ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 111
qr/[バ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[バ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 112
qr/[パ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[パ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 113
qr/[ヒ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ヒ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 114
qr/[ビ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ビ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 115
qr/[ピ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ピ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 116
qr/[フ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[フ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 117
qr/[ブ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ブ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 118
qr/[プ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[プ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 119
qr/[ヘ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ヘ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 120
qr/[ベ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ベ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 121
qr/[ペ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ペ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 122
qr/[ホ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ホ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 123
qr/[ボ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ{])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 124
qr/[ポ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ|])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 125
qr/[マ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ}])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 126
qr/[ミ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[ソ~])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 127
qr/[^ァ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ@])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 128
qr/[^ア]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ア])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 129
qr/[^ィ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ィ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 130
qr/[^イ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^イ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 131
qr/[^ゥ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ゥ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 132
qr/[^ウ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ウ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 133
qr/[^ェ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ェ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 134
qr/[^エ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^エ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 135
qr/[^ォ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ォ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 136
qr/[^オ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^オ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 137
qr/[^カ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^カ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 138
qr/[^ガ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ガ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 139
qr/[^キ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^キ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 140
qr/[^ギ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ギ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 141
qr/[^ク]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ク])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 142
qr/[^グ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^グ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 143
qr/[^ケ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ケ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 144
qr/[^ゲ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ゲ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 145
qr/[^コ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^コ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 146
qr/[^ゴ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ゴ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 147
qr/[^サ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^サ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 148
qr/[^ザ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ザ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 149
qr/[^シ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^シ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 150
qr/[^ジ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ジ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 151
qr/[^ス]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ス])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 152
qr/[^ズ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ズ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 153
qr/[^セ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^セ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 154
qr/[^ゼ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ[])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 155
qr/[^ソ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ\])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 156
qr/[^ゾ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 157
qr/[^タ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ^])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 158
qr/[^ダ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ダ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 159
qr/[^チ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ`])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 160
qr/[^ヂ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ヂ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 161
qr/[^ッ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ッ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 162
qr/[^ツ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ツ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 163
qr/[^ヅ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ヅ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 164
qr/[^テ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^テ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 165
qr/[^デ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^デ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 166
qr/[^ト]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ト])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 167
qr/[^ド]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ド])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 168
qr/[^ナ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ナ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 169
qr/[^ニ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ニ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 170
qr/[^ヌ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ヌ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 171
qr/[^ネ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ネ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 172
qr/[^ノ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ノ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 173
qr/[^ハ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ハ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 174
qr/[^バ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^バ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 175
qr/[^パ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^パ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 176
qr/[^ヒ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ヒ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 177
qr/[^ビ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ビ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 178
qr/[^ピ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ピ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 179
qr/[^フ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^フ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 180
qr/[^ブ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ブ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 181
qr/[^プ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^プ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 182
qr/[^ヘ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ヘ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 183
qr/[^ベ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ベ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 184
qr/[^ペ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ペ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 185
qr/[^ホ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ホ])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 186
qr/[^ボ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ{])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 187
qr/[^ポ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ|])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 188
qr/[^マ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ}])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 189
qr/[^ミ]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^ソ~])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 190
qr:ァ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ@)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 191
qr:ア:

END1
qr{\G${mb::_anchor}@{[qr`(?:ア)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 192
qr:ィ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ィ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 193
qr:イ:

END1
qr{\G${mb::_anchor}@{[qr`(?:イ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 194
qr:ゥ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ゥ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 195
qr:ウ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ウ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 196
qr:ェ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ェ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 197
qr:エ:

END1
qr{\G${mb::_anchor}@{[qr`(?:エ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 198
qr:ォ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ォ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 199
qr:オ:

END1
qr{\G${mb::_anchor}@{[qr`(?:オ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 200
qr:カ:

END1
qr{\G${mb::_anchor}@{[qr`(?:カ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 201
qr:ガ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ガ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 202
qr:キ:

END1
qr{\G${mb::_anchor}@{[qr`(?:キ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 203
qr:ギ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ギ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 204
qr:ク:

END1
qr{\G${mb::_anchor}@{[qr`(?:ク)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 205
qr:グ:

END1
qr{\G${mb::_anchor}@{[qr`(?:グ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 206
qr:ケ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ケ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 207
qr:ゲ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ゲ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 208
qr:コ:

END1
qr{\G${mb::_anchor}@{[qr`(?:コ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 209
qr:ゴ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ゴ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 210
qr:サ:

END1
qr{\G${mb::_anchor}@{[qr`(?:サ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 211
qr:ザ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ザ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 212
qr:シ:

END1
qr{\G${mb::_anchor}@{[qr`(?:シ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 213
qr:ジ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ジ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 214
qr:ス:

END1
qr{\G${mb::_anchor}@{[qr`(?:ス)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 215
qr:ズ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ズ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 216
qr:セ:

END1
qr{\G${mb::_anchor}@{[qr`(?:セ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 217
qr:ゼ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ[)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 218
qr:ソ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ\)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 219
qr:ゾ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ])` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 220
qr:タ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ^)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 221
qr:ダ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ダ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 222
qr:チ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ`)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 223
qr:ヂ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ヂ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 224
qr:ッ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ッ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 225
qr:ツ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ツ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 226
qr:ヅ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ヅ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 227
qr:テ:

END1
qr{\G${mb::_anchor}@{[qr`(?:テ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 228
qr:デ:

END1
qr{\G${mb::_anchor}@{[qr`(?:デ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 229
qr:ト:

END1
qr{\G${mb::_anchor}@{[qr`(?:ト)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 230
qr:ド:

END1
qr{\G${mb::_anchor}@{[qr`(?:ド)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 231
qr:ナ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ナ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 232
qr:ニ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ニ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 233
qr:ヌ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ヌ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 234
qr:ネ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ネ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 235
qr:ノ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ノ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 236
qr:ハ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ハ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 237
qr:バ:

END1
qr{\G${mb::_anchor}@{[qr`(?:バ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 238
qr:パ:

END1
qr{\G${mb::_anchor}@{[qr`(?:パ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 239
qr:ヒ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ヒ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 240
qr:ビ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ビ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 241
qr:ピ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ピ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 242
qr:フ:

END1
qr{\G${mb::_anchor}@{[qr`(?:フ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 243
qr:ブ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ブ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 244
qr:プ:

END1
qr{\G${mb::_anchor}@{[qr`(?:プ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 245
qr:ヘ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ヘ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 246
qr:ベ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ベ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 247
qr:ペ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ペ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 248
qr:ホ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ホ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 249
qr:ボ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ{)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 250
qr:ポ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ|)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 251
qr:マ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 252
qr:ミ:

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ~)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 253
qr:[ァ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ@])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 254
qr:[ア]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ア])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 255
qr:[ィ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ィ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 256
qr:[イ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[イ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 257
qr:[ゥ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ゥ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 258
qr:[ウ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ウ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 259
qr:[ェ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ェ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 260
qr:[エ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[エ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 261
qr:[ォ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ォ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 262
qr:[オ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[オ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 263
qr:[カ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[カ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 264
qr:[ガ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ガ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 265
qr:[キ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[キ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 266
qr:[ギ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ギ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 267
qr:[ク]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ク])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 268
qr:[グ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[グ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 269
qr:[ケ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ケ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 270
qr:[ゲ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ゲ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 271
qr:[コ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[コ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 272
qr:[ゴ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ゴ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 273
qr:[サ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[サ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 274
qr:[ザ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ザ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 275
qr:[シ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[シ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 276
qr:[ジ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ジ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 277
qr:[ス]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ス])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 278
qr:[ズ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ズ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 279
qr:[セ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[セ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 280
qr:[ゼ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ[])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 281
qr:[ソ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ\])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 282
qr:[ゾ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 283
qr:[タ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ^])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 284
qr:[ダ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ダ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 285
qr:[チ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ`])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 286
qr:[ヂ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヂ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 287
qr:[ッ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ッ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 288
qr:[ツ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ツ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 289
qr:[ヅ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヅ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 290
qr:[テ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[テ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 291
qr:[デ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[デ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 292
qr:[ト]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ト])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 293
qr:[ド]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ド])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 294
qr:[ナ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ナ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 295
qr:[ニ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ニ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 296
qr:[ヌ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヌ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 297
qr:[ネ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ネ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 298
qr:[ノ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ノ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 299
qr:[ハ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ハ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 300
qr:[バ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[バ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 301
qr:[パ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[パ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 302
qr:[ヒ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヒ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 303
qr:[ビ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ビ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 304
qr:[ピ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ピ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 305
qr:[フ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[フ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 306
qr:[ブ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ブ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 307
qr:[プ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[プ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 308
qr:[ヘ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヘ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 309
qr:[ベ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ベ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 310
qr:[ペ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ペ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 311
qr:[ホ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ホ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 312
qr:[ボ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ{])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 313
qr:[ポ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ|])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 314
qr:[マ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ}])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 315
qr:[ミ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ~])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 316
qr:[^ァ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ@])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 317
qr:[^ア]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ア])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 318
qr:[^ィ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ィ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 319
qr:[^イ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^イ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 320
qr:[^ゥ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ゥ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 321
qr:[^ウ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ウ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 322
qr:[^ェ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ェ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 323
qr:[^エ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^エ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 324
qr:[^ォ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ォ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 325
qr:[^オ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^オ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 326
qr:[^カ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^カ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 327
qr:[^ガ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ガ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 328
qr:[^キ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^キ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 329
qr:[^ギ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ギ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 330
qr:[^ク]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ク])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 331
qr:[^グ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^グ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 332
qr:[^ケ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ケ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 333
qr:[^ゲ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ゲ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 334
qr:[^コ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^コ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 335
qr:[^ゴ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ゴ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 336
qr:[^サ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^サ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 337
qr:[^ザ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ザ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 338
qr:[^シ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^シ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 339
qr:[^ジ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ジ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 340
qr:[^ス]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ス])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 341
qr:[^ズ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ズ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 342
qr:[^セ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^セ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 343
qr:[^ゼ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ[])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 344
qr:[^ソ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ\])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 345
qr:[^ゾ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 346
qr:[^タ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ^])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 347
qr:[^ダ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ダ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 348
qr:[^チ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ`])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 349
qr:[^ヂ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヂ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 350
qr:[^ッ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ッ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 351
qr:[^ツ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ツ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 352
qr:[^ヅ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヅ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 353
qr:[^テ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^テ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 354
qr:[^デ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^デ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 355
qr:[^ト]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ト])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 356
qr:[^ド]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ド])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 357
qr:[^ナ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ナ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 358
qr:[^ニ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ニ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 359
qr:[^ヌ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヌ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 360
qr:[^ネ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ネ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 361
qr:[^ノ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ノ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 362
qr:[^ハ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ハ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 363
qr:[^バ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^バ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 364
qr:[^パ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^パ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 365
qr:[^ヒ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヒ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 366
qr:[^ビ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ビ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 367
qr:[^ピ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ピ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 368
qr:[^フ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^フ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 369
qr:[^ブ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ブ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 370
qr:[^プ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^プ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 371
qr:[^ヘ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヘ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 372
qr:[^ベ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ベ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 373
qr:[^ペ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ペ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 374
qr:[^ホ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ホ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 375
qr:[^ボ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ{])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 376
qr:[^ポ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ|])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 377
qr:[^マ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ}])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 378
qr:[^ミ]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ~])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 379
qr@ァ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ@)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 380
qr@ア@

END1
qr{\G${mb::_anchor}@{[qr`(?:ア)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 381
qr@ィ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ィ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 382
qr@イ@

END1
qr{\G${mb::_anchor}@{[qr`(?:イ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 383
qr@ゥ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ゥ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 384
qr@ウ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ウ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 385
qr@ェ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ェ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 386
qr@エ@

END1
qr{\G${mb::_anchor}@{[qr`(?:エ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 387
qr@ォ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ォ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 388
qr@オ@

END1
qr{\G${mb::_anchor}@{[qr`(?:オ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 389
qr@カ@

END1
qr{\G${mb::_anchor}@{[qr`(?:カ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 390
qr@ガ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ガ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 391
qr@キ@

END1
qr{\G${mb::_anchor}@{[qr`(?:キ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 392
qr@ギ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ギ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 393
qr@ク@

END1
qr{\G${mb::_anchor}@{[qr`(?:ク)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 394
qr@グ@

END1
qr{\G${mb::_anchor}@{[qr`(?:グ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 395
qr@ケ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ケ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 396
qr@ゲ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ゲ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 397
qr@コ@

END1
qr{\G${mb::_anchor}@{[qr`(?:コ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 398
qr@ゴ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ゴ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 399
qr@サ@

END1
qr{\G${mb::_anchor}@{[qr`(?:サ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 400
qr@ザ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ザ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 401
qr@シ@

END1
qr{\G${mb::_anchor}@{[qr`(?:シ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 402
qr@ジ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ジ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 403
qr@ス@

END1
qr{\G${mb::_anchor}@{[qr`(?:ス)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 404
qr@ズ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ズ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 405
qr@セ@

END1
qr{\G${mb::_anchor}@{[qr`(?:セ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 406
qr@ゼ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ[)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 407
qr@ソ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ\)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 408
qr@ゾ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ])` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 409
qr@タ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ^)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 410
qr@ダ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ダ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 411
qr@チ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ`)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 412
qr@ヂ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ヂ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 413
qr@ッ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ッ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 414
qr@ツ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ツ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 415
qr@ヅ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ヅ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 416
qr@テ@

END1
qr{\G${mb::_anchor}@{[qr`(?:テ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 417
qr@デ@

END1
qr{\G${mb::_anchor}@{[qr`(?:デ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 418
qr@ト@

END1
qr{\G${mb::_anchor}@{[qr`(?:ト)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 419
qr@ド@

END1
qr{\G${mb::_anchor}@{[qr`(?:ド)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 420
qr@ナ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ナ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 421
qr@ニ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ニ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 422
qr@ヌ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ヌ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 423
qr@ネ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ネ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 424
qr@ノ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ノ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 425
qr@ハ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ハ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 426
qr@バ@

END1
qr{\G${mb::_anchor}@{[qr`(?:バ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 427
qr@パ@

END1
qr{\G${mb::_anchor}@{[qr`(?:パ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 428
qr@ヒ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ヒ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 429
qr@ビ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ビ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 430
qr@ピ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ピ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 431
qr@フ@

END1
qr{\G${mb::_anchor}@{[qr`(?:フ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 432
qr@ブ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ブ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 433
qr@プ@

END1
qr{\G${mb::_anchor}@{[qr`(?:プ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 434
qr@ヘ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ヘ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 435
qr@ベ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ベ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 436
qr@ペ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ペ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 437
qr@ホ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ホ)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 438
qr@ボ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ{)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 439
qr@ポ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ|)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 440
qr@マ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 441
qr@ミ@

END1
qr{\G${mb::_anchor}@{[qr`(?:ソ~)` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 442
qr@[ァ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ@])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 443
qr@[ア]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ア])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 444
qr@[ィ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ィ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 445
qr@[イ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[イ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 446
qr@[ゥ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ゥ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 447
qr@[ウ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ウ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 448
qr@[ェ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ェ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 449
qr@[エ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[エ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 450
qr@[ォ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ォ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 451
qr@[オ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[オ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 452
qr@[カ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[カ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 453
qr@[ガ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ガ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 454
qr@[キ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[キ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 455
qr@[ギ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ギ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 456
qr@[ク]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ク])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 457
qr@[グ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[グ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 458
qr@[ケ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ケ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 459
qr@[ゲ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ゲ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 460
qr@[コ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[コ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 461
qr@[ゴ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ゴ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 462
qr@[サ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[サ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 463
qr@[ザ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ザ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 464
qr@[シ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[シ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 465
qr@[ジ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ジ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 466
qr@[ス]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ス])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 467
qr@[ズ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ズ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 468
qr@[セ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[セ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 469
qr@[ゼ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ[])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 470
qr@[ソ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ\])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 471
qr@[ゾ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 472
qr@[タ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ^])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 473
qr@[ダ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ダ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 474
qr@[チ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ`])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 475
qr@[ヂ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヂ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 476
qr@[ッ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ッ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 477
qr@[ツ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ツ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 478
qr@[ヅ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヅ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 479
qr@[テ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[テ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 480
qr@[デ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[デ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 481
qr@[ト]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ト])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 482
qr@[ド]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ド])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 483
qr@[ナ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ナ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 484
qr@[ニ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ニ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 485
qr@[ヌ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヌ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 486
qr@[ネ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ネ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 487
qr@[ノ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ノ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 488
qr@[ハ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ハ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 489
qr@[バ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[バ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 490
qr@[パ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[パ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 491
qr@[ヒ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヒ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 492
qr@[ビ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ビ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 493
qr@[ピ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ピ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 494
qr@[フ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[フ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 495
qr@[ブ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ブ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 496
qr@[プ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[プ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 497
qr@[ヘ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ヘ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 498
qr@[ベ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ベ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 499
qr@[ペ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ペ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 500
qr@[ホ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ホ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 501
qr@[ボ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ{])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 502
qr@[ポ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ|])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 503
qr@[マ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ}])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 504
qr@[ミ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[ソ~])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 505
qr@[^ァ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ@])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 506
qr@[^ア]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ア])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 507
qr@[^ィ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ィ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 508
qr@[^イ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^イ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 509
qr@[^ゥ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ゥ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 510
qr@[^ウ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ウ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 511
qr@[^ェ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ェ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 512
qr@[^エ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^エ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 513
qr@[^ォ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ォ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 514
qr@[^オ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^オ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 515
qr@[^カ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^カ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 516
qr@[^ガ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ガ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 517
qr@[^キ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^キ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 518
qr@[^ギ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ギ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 519
qr@[^ク]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ク])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 520
qr@[^グ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^グ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 521
qr@[^ケ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ケ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 522
qr@[^ゲ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ゲ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 523
qr@[^コ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^コ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 524
qr@[^ゴ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ゴ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 525
qr@[^サ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^サ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 526
qr@[^ザ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ザ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 527
qr@[^シ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^シ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 528
qr@[^ジ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ジ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 529
qr@[^ス]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ス])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 530
qr@[^ズ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ズ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 531
qr@[^セ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^セ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 532
qr@[^ゼ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ[])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 533
qr@[^ソ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ\])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 534
qr@[^ゾ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 535
qr@[^タ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ^])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 536
qr@[^ダ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ダ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 537
qr@[^チ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ`])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 538
qr@[^ヂ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヂ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 539
qr@[^ッ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ッ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 540
qr@[^ツ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ツ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 541
qr@[^ヅ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヅ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 542
qr@[^テ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^テ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 543
qr@[^デ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^デ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 544
qr@[^ト]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ト])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 545
qr@[^ド]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ド])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 546
qr@[^ナ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ナ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 547
qr@[^ニ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ニ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 548
qr@[^ヌ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヌ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 549
qr@[^ネ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ネ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 550
qr@[^ノ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ノ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 551
qr@[^ハ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ハ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 552
qr@[^バ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^バ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 553
qr@[^パ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^パ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 554
qr@[^ヒ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヒ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 555
qr@[^ビ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ビ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 556
qr@[^ピ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ピ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 557
qr@[^フ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^フ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 558
qr@[^ブ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ブ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 559
qr@[^プ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^プ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 560
qr@[^ヘ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ヘ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 561
qr@[^ベ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ベ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 562
qr@[^ペ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ペ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 563
qr@[^ホ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ホ])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 564
qr@[^ボ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ{])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 565
qr@[^ポ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ|])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 566
qr@[^マ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ}])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 567
qr@[^ミ]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^ソ~])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 568
qr/./

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_dot})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 569
qr/\B/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_B})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 570
qr/\D/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_D})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 571
qr/\H/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_H})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 572
qr/\N/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_N})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 573
qr/\R/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_R})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 574
qr/\S/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_S})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 575
qr/\V/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_V})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 576
qr/\W/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_W})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 577
qr/\b/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_b})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 578
qr/\d/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_d})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 579
qr/\h/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_h})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 580
qr/\s/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_s})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 581
qr/\v/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_v})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 582
qr/\w/

END1
qr{\G${mb::_anchor}@{[qr/(?:@{mb::_w})/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 583
qr/[\b]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\b])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 584
qr/[[:alnum:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:alnum:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 585
qr/[[:alpha:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:alpha:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 586
qr/[[:ascii:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:ascii:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 587
qr/[[:blank:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:blank:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 588
qr/[[:cntrl:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:cntrl:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 589
qr/[[:digit:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:digit:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 590
qr/[[:graph:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:graph:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 591
qr/[[:lower:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:lower:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 592
qr/[[:print:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:print:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 593
qr/[[:punct:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:punct:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 594
qr/[[:space:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:space:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 595
qr/[[:upper:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:upper:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 596
qr/[[:word:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:word:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 597
qr/[[:xdigit:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:xdigit:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 598
qr/[[:^alnum:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^alnum:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 599
qr/[[:^alpha:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^alpha:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 600
qr/[[:^ascii:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^ascii:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 601
qr/[[:^blank:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^blank:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 602
qr/[[:^cntrl:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^cntrl:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 603
qr/[[:^digit:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^digit:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 604
qr/[[:^graph:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^graph:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 605
qr/[[:^lower:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^lower:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 606
qr/[[:^print:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^print:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 607
qr/[[:^punct:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^punct:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 608
qr/[[:^space:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^space:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 609
qr/[[:^upper:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^upper:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 610
qr/[[:^word:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^word:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 611
qr/[[:^xdigit:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^xdigit:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 612
qr/[.]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[.])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 613
qr/[\B]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\B])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 614
qr/[\D]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\D])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 615
qr/[\H]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\H])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 616
qr/[\N]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\N])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 617
qr/[\R]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\R])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 618
qr/[\S]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\S])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 619
qr/[\V]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\V])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 620
qr/[\W]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\W])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 621
qr/[\b]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\b])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 622
qr/[\d]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\d])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 623
qr/[\h]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\h])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 624
qr/[\s]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\s])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 625
qr/[\v]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\v])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 626
qr/[\w]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\w])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 627
qr/[^.]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^.])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 628
qr/[^\B]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\B])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 629
qr/[^\D]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\D])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 630
qr/[^\H]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\H])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 631
qr/[^\N]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\N])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 632
qr/[^\R]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\R])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 633
qr/[^\S]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\S])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 634
qr/[^\V]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\V])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 635
qr/[^\W]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\W])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 636
qr/[^\b]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\b])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 637
qr/[^\d]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\d])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 638
qr/[^\h]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\h])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 639
qr/[^\s]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\s])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 640
qr/[^\v]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\v])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 641
qr/[^\w]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^\\w])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 642
qr:.:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_dot})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 643
qr:\B:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_B})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 644
qr:\D:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_D})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 645
qr:\H:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_H})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 646
qr:\N:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_N})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 647
qr:\R:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_R})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 648
qr:\S:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_S})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 649
qr:\V:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_V})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 650
qr:\W:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_W})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 651
qr:\b:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_b})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 652
qr:\d:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_d})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 653
qr:\h:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_h})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 654
qr:\s:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_s})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 655
qr:\v:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_v})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 656
qr:\w:

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_w})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 657
qr:[\b]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 658
qr:[[:alnum:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:alnum:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 659
qr:[[:alpha:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:alpha:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 660
qr:[[:ascii:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:ascii:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 661
qr:[[:blank:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:blank:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 662
qr:[[:cntrl:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:cntrl:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 663
qr:[[:digit:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:digit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 664
qr:[[:graph:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:graph:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 665
qr:[[:lower:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:lower:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 666
qr:[[:print:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:print:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 667
qr:[[:punct:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:punct:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 668
qr:[[:space:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:space:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 669
qr:[[:upper:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:upper:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 670
qr:[[:word:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:word:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 671
qr:[[:xdigit:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:xdigit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 672
qr:[[:^alnum:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^alnum:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 673
qr:[[:^alpha:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^alpha:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 674
qr:[[:^ascii:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^ascii:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 675
qr:[[:^blank:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^blank:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 676
qr:[[:^cntrl:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^cntrl:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 677
qr:[[:^digit:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^digit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 678
qr:[[:^graph:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^graph:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 679
qr:[[:^lower:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^lower:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 680
qr:[[:^print:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^print:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 681
qr:[[:^punct:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^punct:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 682
qr:[[:^space:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^space:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 683
qr:[[:^upper:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^upper:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 684
qr:[[:^word:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^word:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 685
qr:[[:^xdigit:]]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^xdigit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 686
qr:[.]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[.])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 687
qr:[\B]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\B])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 688
qr:[\D]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\D])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 689
qr:[\H]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\H])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 690
qr:[\N]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\N])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 691
qr:[\R]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\R])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 692
qr:[\S]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\S])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 693
qr:[\V]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\V])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 694
qr:[\W]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\W])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 695
qr:[\b]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 696
qr:[\d]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\d])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 697
qr:[\h]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\h])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 698
qr:[\s]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\s])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 699
qr:[\v]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\v])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 700
qr:[\w]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\w])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 701
qr:[^.]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^.])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 702
qr:[^\B]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\B])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 703
qr:[^\D]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\D])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 704
qr:[^\H]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\H])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 705
qr:[^\N]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\N])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 706
qr:[^\R]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\R])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 707
qr:[^\S]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\S])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 708
qr:[^\V]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\V])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 709
qr:[^\W]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\W])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 710
qr:[^\b]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\b])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 711
qr:[^\d]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\d])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 712
qr:[^\h]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\h])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 713
qr:[^\s]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\s])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 714
qr:[^\v]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\v])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 715
qr:[^\w]:

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\w])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 716
qr@.@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_dot})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 717
qr@\B@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_B})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 718
qr@\D@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_D})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 719
qr@\H@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_H})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 720
qr@\N@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_N})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 721
qr@\R@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_R})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 722
qr@\S@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_S})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 723
qr@\V@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_V})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 724
qr@\W@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_W})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 725
qr@\b@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_b})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 726
qr@\d@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_d})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 727
qr@\h@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_h})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 728
qr@\s@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_s})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 729
qr@\v@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_v})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 730
qr@\w@

END1
qr{\G${mb::_anchor}@{[qr`(?:@{mb::_w})` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 731
qr@[\b]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 732
qr@[[:alnum:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:alnum:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 733
qr@[[:alpha:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:alpha:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 734
qr@[[:ascii:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:ascii:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 735
qr@[[:blank:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:blank:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 736
qr@[[:cntrl:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:cntrl:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 737
qr@[[:digit:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:digit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 738
qr@[[:graph:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:graph:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 739
qr@[[:lower:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:lower:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 740
qr@[[:print:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:print:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 741
qr@[[:punct:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:punct:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 742
qr@[[:space:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:space:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 743
qr@[[:upper:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:upper:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 744
qr@[[:word:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:word:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 745
qr@[[:xdigit:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:xdigit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 746
qr@[[:^alnum:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^alnum:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 747
qr@[[:^alpha:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^alpha:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 748
qr@[[:^ascii:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^ascii:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 749
qr@[[:^blank:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^blank:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 750
qr@[[:^cntrl:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^cntrl:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 751
qr@[[:^digit:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^digit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 752
qr@[[:^graph:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^graph:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 753
qr@[[:^lower:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^lower:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 754
qr@[[:^print:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^print:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 755
qr@[[:^punct:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^punct:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 756
qr@[[:^space:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^space:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 757
qr@[[:^upper:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^upper:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 758
qr@[[:^word:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^word:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 759
qr@[[:^xdigit:]]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[[:^xdigit:]])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 760
qr@[.]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[.])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 761
qr@[\B]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\B])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 762
qr@[\D]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\D])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 763
qr@[\H]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\H])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 764
qr@[\N]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\N])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 765
qr@[\R]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\R])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 766
qr@[\S]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\S])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 767
qr@[\V]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\V])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 768
qr@[\W]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\W])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 769
qr@[\b]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 770
qr@[\d]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\d])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 771
qr@[\h]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\h])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 772
qr@[\s]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\s])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 773
qr@[\v]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\v])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 774
qr@[\w]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[\\w])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 775
qr@[^.]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^.])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 776
qr@[^\B]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\B])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 777
qr@[^\D]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\D])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 778
qr@[^\H]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\H])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 779
qr@[^\N]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\N])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 780
qr@[^\R]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\R])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 781
qr@[^\S]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\S])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 782
qr@[^\V]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\V])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 783
qr@[^\W]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\W])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 784
qr@[^\b]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\b])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 785
qr@[^\d]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\d])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 786
qr@[^\h]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\h])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 787
qr@[^\s]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\s])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 788
qr@[^\v]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\v])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 789
qr@[^\w]@

END1
qr{\G${mb::_anchor}@{[qr`@{[mb::_cc(qq[^\\w])]}` ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 790
qr/[アソゾABC1-3]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[アソ\ソ]ABC1-3])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 791
qr/[^アソゾABC1-3]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^アソ\ソ]ABC1-3])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 792
qr/[アソゾABC1-3[:alnum:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[アソ\ソ]ABC1-3[:alnum:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 793
qr/[^アソゾABC1-3[:alnum:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^アソ\ソ]ABC1-3[:alnum:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 794
qr/[アソゾ${_}ABC1-3[:alnum:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[アソ\ソ]${_}ABC1-3[:alnum:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 795
qr/[^アソゾ${_}ABC1-3[:alnum:]]/

END1
qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[^アソ\ソ]${_}ABC1-3[:alnum:]])]}/ ]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 796
qr/Abア[アソゾABC1-3]/i

END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[アソ\ソ]ABC1-3])]}/)]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 797
qr/Abア[^アソゾABC1-3]/i

END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[^アソ\ソ]ABC1-3])]}/)]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 798
qr/Abア[アソゾABC1-3[:alnum:]]/i

END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[アソ\ソ]ABC1-3[:alnum:]])]}/)]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 799
qr/Abア[^アソゾABC1-3[:alnum:]]/i

END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[^アソ\ソ]ABC1-3[:alnum:]])]}/)]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 800
qr/Abア[アソゾ${_}ABC1-3[:alnum:]]/i

END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[アソ\ソ]${_}ABC1-3[:alnum:]])]}/)]}@{[mb::_m_passed()]}}

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 801
qr/Abア[^アソゾ${_}ABC1-3[:alnum:]]/i

END1
qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[^アソ\ソ]${_}ABC1-3[:alnum:]])]}/)]}@{[mb::_m_passed()]}}

END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
