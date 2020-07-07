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
s/ァ/1/

END1
---
s{(\G${mb::_anchor})@{[qr/(?:ソ@)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
s/ア/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ア)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
s/ィ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ィ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
s/イ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:イ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
s/ゥ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ゥ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
s/ウ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ウ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
s/ェ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ェ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
s/エ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:エ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
s/ォ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ォ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
s/オ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:オ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
s/カ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:カ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
s/ガ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ガ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
s/キ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:キ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
s/ギ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ギ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
s/ク/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ク)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
s/グ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:グ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
s/ケ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ケ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
s/ゲ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ゲ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
s/コ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:コ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
s/ゴ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ゴ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
s/サ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:サ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
s/ザ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ザ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
s/シ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:シ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
s/ジ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ジ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
s/ス/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ス)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
s/ズ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ズ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
s/セ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:セ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
s/ゼ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ[)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
s/ソ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ\)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
s/ゾ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ])/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
s/タ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ^)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
s/ダ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ダ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
s/チ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ`)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
s/ヂ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ヂ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
s/ッ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ッ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
s/ツ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ツ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
s/ヅ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ヅ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
s/テ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:テ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
s/デ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:デ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
s/ト/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ト)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
s/ド/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ド)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
s/ナ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ナ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
s/ニ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ニ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
s/ヌ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ヌ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
s/ネ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ネ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
s/ノ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ノ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
s/ハ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ハ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
s/バ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:バ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
s/パ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:パ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
s/ヒ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ヒ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
s/ビ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ビ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
s/ピ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ピ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
s/フ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:フ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
s/ブ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ブ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
s/プ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:プ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
s/ヘ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ヘ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
s/ベ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ベ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
s/ペ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ペ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
s/ホ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ホ)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
s/ボ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ{)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
s/ポ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ|)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
s/マ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
s/ミ/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:ソ~)/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 64
s/[ァ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ@])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 65
s/[ア]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ア])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 66
s/[ィ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ィ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 67
s/[イ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[イ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 68
s/[ゥ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ゥ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 69
s/[ウ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ウ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 70
s/[ェ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ェ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 71
s/[エ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[エ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 72
s/[ォ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ォ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 73
s/[オ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[オ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 74
s/[カ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[カ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 75
s/[ガ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ガ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 76
s/[キ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[キ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 77
s/[ギ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ギ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 78
s/[ク]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ク])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 79
s/[グ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[グ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 80
s/[ケ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ケ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 81
s/[ゲ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ゲ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 82
s/[コ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[コ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 83
s/[ゴ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ゴ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 84
s/[サ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[サ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 85
s/[ザ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ザ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 86
s/[シ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[シ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 87
s/[ジ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ジ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 88
s/[ス]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ス])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 89
s/[ズ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ズ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 90
s/[セ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[セ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 91
s/[ゼ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ[])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 92
s/[ソ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ\])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 93
s/[ゾ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 94
s/[タ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ^])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 95
s/[ダ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ダ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 96
s/[チ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ`])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 97
s/[ヂ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ヂ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 98
s/[ッ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ッ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 99
s/[ツ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ツ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 100
s/[ヅ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ヅ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 101
s/[テ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[テ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 102
s/[デ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[デ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 103
s/[ト]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ト])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 104
s/[ド]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ド])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 105
s/[ナ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ナ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 106
s/[ニ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ニ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 107
s/[ヌ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ヌ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 108
s/[ネ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ネ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 109
s/[ノ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ノ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 110
s/[ハ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ハ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 111
s/[バ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[バ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 112
s/[パ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[パ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 113
s/[ヒ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ヒ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 114
s/[ビ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ビ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 115
s/[ピ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ピ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 116
s/[フ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[フ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 117
s/[ブ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ブ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 118
s/[プ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[プ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 119
s/[ヘ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ヘ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 120
s/[ベ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ベ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 121
s/[ペ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ペ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 122
s/[ホ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ホ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 123
s/[ボ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ{])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 124
s/[ポ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ|])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 125
s/[マ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ}])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 126
s/[ミ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[ソ~])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 127
s/[^ァ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ@])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 128
s/[^ア]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ア])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 129
s/[^ィ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ィ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 130
s/[^イ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^イ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 131
s/[^ゥ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ゥ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 132
s/[^ウ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ウ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 133
s/[^ェ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ェ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 134
s/[^エ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^エ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 135
s/[^ォ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ォ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 136
s/[^オ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^オ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 137
s/[^カ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^カ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 138
s/[^ガ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ガ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 139
s/[^キ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^キ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 140
s/[^ギ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ギ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 141
s/[^ク]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ク])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 142
s/[^グ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^グ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 143
s/[^ケ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ケ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 144
s/[^ゲ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ゲ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 145
s/[^コ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^コ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 146
s/[^ゴ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ゴ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 147
s/[^サ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^サ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 148
s/[^ザ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ザ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 149
s/[^シ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^シ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 150
s/[^ジ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ジ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 151
s/[^ス]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ス])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 152
s/[^ズ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ズ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 153
s/[^セ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^セ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 154
s/[^ゼ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ[])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 155
s/[^ソ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ\])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 156
s/[^ゾ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 157
s/[^タ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ^])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 158
s/[^ダ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ダ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 159
s/[^チ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ`])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 160
s/[^ヂ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ヂ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 161
s/[^ッ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ッ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 162
s/[^ツ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ツ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 163
s/[^ヅ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ヅ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 164
s/[^テ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^テ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 165
s/[^デ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^デ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 166
s/[^ト]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ト])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 167
s/[^ド]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ド])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 168
s/[^ナ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ナ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 169
s/[^ニ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ニ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 170
s/[^ヌ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ヌ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 171
s/[^ネ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ネ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 172
s/[^ノ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ノ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 173
s/[^ハ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ハ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 174
s/[^バ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^バ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 175
s/[^パ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^パ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 176
s/[^ヒ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ヒ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 177
s/[^ビ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ビ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 178
s/[^ピ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ピ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 179
s/[^フ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^フ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 180
s/[^ブ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ブ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 181
s/[^プ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^プ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 182
s/[^ヘ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ヘ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 183
s/[^ベ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ベ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 184
s/[^ペ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ペ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 185
s/[^ホ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ホ])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 186
s/[^ボ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ{])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 187
s/[^ポ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ|])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 188
s/[^マ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ}])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 189
s/[^ミ]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^ソ~])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 190
s:ァ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ@)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 191
s:ア:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ア)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 192
s:ィ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ィ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 193
s:イ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:イ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 194
s:ゥ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ゥ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 195
s:ウ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ウ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 196
s:ェ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ェ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 197
s:エ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:エ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 198
s:ォ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ォ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 199
s:オ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:オ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 200
s:カ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:カ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 201
s:ガ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ガ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 202
s:キ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:キ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 203
s:ギ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ギ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 204
s:ク:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ク)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 205
s:グ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:グ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 206
s:ケ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ケ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 207
s:ゲ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ゲ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 208
s:コ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:コ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 209
s:ゴ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ゴ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 210
s:サ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:サ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 211
s:ザ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ザ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 212
s:シ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:シ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 213
s:ジ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ジ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 214
s:ス:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ス)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 215
s:ズ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ズ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 216
s:セ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:セ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 217
s:ゼ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ[)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 218
s:ソ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ\)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 219
s:ゾ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ])` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 220
s:タ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ^)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 221
s:ダ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ダ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 222
s:チ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ`)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 223
s:ヂ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ヂ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 224
s:ッ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ッ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 225
s:ツ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ツ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 226
s:ヅ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ヅ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 227
s:テ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:テ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 228
s:デ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:デ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 229
s:ト:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ト)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 230
s:ド:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ド)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 231
s:ナ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ナ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 232
s:ニ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ニ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 233
s:ヌ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ヌ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 234
s:ネ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ネ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 235
s:ノ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ノ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 236
s:ハ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ハ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 237
s:バ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:バ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 238
s:パ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:パ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 239
s:ヒ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ヒ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 240
s:ビ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ビ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 241
s:ピ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ピ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 242
s:フ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:フ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 243
s:ブ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ブ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 244
s:プ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:プ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 245
s:ヘ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ヘ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 246
s:ベ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ベ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 247
s:ペ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ペ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 248
s:ホ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ホ)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 249
s:ボ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ{)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 250
s:ポ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ|)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 251
s:マ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 252
s:ミ:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ~)` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 253
s:[ァ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ@])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 254
s:[ア]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ア])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 255
s:[ィ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ィ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 256
s:[イ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[イ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 257
s:[ゥ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ゥ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 258
s:[ウ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ウ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 259
s:[ェ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ェ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 260
s:[エ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[エ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 261
s:[ォ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ォ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 262
s:[オ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[オ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 263
s:[カ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[カ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 264
s:[ガ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ガ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 265
s:[キ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[キ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 266
s:[ギ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ギ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 267
s:[ク]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ク])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 268
s:[グ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[グ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 269
s:[ケ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ケ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 270
s:[ゲ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ゲ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 271
s:[コ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[コ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 272
s:[ゴ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ゴ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 273
s:[サ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[サ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 274
s:[ザ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ザ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 275
s:[シ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[シ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 276
s:[ジ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ジ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 277
s:[ス]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ス])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 278
s:[ズ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ズ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 279
s:[セ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[セ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 280
s:[ゼ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ[])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 281
s:[ソ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ\])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 282
s:[ゾ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 283
s:[タ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ^])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 284
s:[ダ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ダ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 285
s:[チ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ`])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 286
s:[ヂ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヂ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 287
s:[ッ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ッ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 288
s:[ツ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ツ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 289
s:[ヅ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヅ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 290
s:[テ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[テ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 291
s:[デ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[デ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 292
s:[ト]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ト])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 293
s:[ド]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ド])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 294
s:[ナ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ナ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 295
s:[ニ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ニ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 296
s:[ヌ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヌ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 297
s:[ネ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ネ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 298
s:[ノ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ノ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 299
s:[ハ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ハ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 300
s:[バ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[バ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 301
s:[パ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[パ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 302
s:[ヒ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヒ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 303
s:[ビ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ビ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 304
s:[ピ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ピ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 305
s:[フ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[フ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 306
s:[ブ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ブ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 307
s:[プ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[プ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 308
s:[ヘ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヘ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 309
s:[ベ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ベ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 310
s:[ペ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ペ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 311
s:[ホ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ホ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 312
s:[ボ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ{])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 313
s:[ポ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ|])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 314
s:[マ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ}])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 315
s:[ミ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ~])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 316
s:[^ァ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ@])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 317
s:[^ア]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ア])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 318
s:[^ィ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ィ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 319
s:[^イ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^イ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 320
s:[^ゥ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ゥ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 321
s:[^ウ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ウ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 322
s:[^ェ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ェ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 323
s:[^エ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^エ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 324
s:[^ォ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ォ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 325
s:[^オ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^オ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 326
s:[^カ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^カ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 327
s:[^ガ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ガ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 328
s:[^キ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^キ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 329
s:[^ギ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ギ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 330
s:[^ク]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ク])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 331
s:[^グ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^グ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 332
s:[^ケ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ケ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 333
s:[^ゲ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ゲ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 334
s:[^コ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^コ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 335
s:[^ゴ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ゴ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 336
s:[^サ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^サ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 337
s:[^ザ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ザ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 338
s:[^シ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^シ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 339
s:[^ジ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ジ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 340
s:[^ス]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ス])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 341
s:[^ズ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ズ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 342
s:[^セ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^セ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 343
s:[^ゼ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ[])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 344
s:[^ソ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ\])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 345
s:[^ゾ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 346
s:[^タ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ^])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 347
s:[^ダ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ダ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 348
s:[^チ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ`])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 349
s:[^ヂ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヂ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 350
s:[^ッ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ッ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 351
s:[^ツ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ツ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 352
s:[^ヅ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヅ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 353
s:[^テ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^テ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 354
s:[^デ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^デ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 355
s:[^ト]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ト])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 356
s:[^ド]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ド])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 357
s:[^ナ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ナ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 358
s:[^ニ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ニ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 359
s:[^ヌ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヌ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 360
s:[^ネ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ネ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 361
s:[^ノ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ノ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 362
s:[^ハ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ハ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 363
s:[^バ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^バ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 364
s:[^パ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^パ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 365
s:[^ヒ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヒ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 366
s:[^ビ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ビ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 367
s:[^ピ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ピ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 368
s:[^フ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^フ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 369
s:[^ブ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ブ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 370
s:[^プ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^プ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 371
s:[^ヘ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヘ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 372
s:[^ベ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ベ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 373
s:[^ペ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ペ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 374
s:[^ホ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ホ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 375
s:[^ボ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ{])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 376
s:[^ポ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ|])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 377
s:[^マ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ}])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 378
s:[^ミ]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ~])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 379
s@ァ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ@)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 380
s@ア@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ア)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 381
s@ィ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ィ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 382
s@イ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:イ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 383
s@ゥ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ゥ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 384
s@ウ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ウ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 385
s@ェ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ェ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 386
s@エ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:エ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 387
s@ォ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ォ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 388
s@オ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:オ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 389
s@カ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:カ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 390
s@ガ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ガ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 391
s@キ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:キ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 392
s@ギ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ギ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 393
s@ク@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ク)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 394
s@グ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:グ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 395
s@ケ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ケ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 396
s@ゲ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ゲ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 397
s@コ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:コ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 398
s@ゴ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ゴ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 399
s@サ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:サ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 400
s@ザ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ザ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 401
s@シ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:シ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 402
s@ジ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ジ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 403
s@ス@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ス)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 404
s@ズ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ズ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 405
s@セ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:セ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 406
s@ゼ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ[)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 407
s@ソ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ\)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 408
s@ゾ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ])` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 409
s@タ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ^)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 410
s@ダ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ダ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 411
s@チ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ`)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 412
s@ヂ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ヂ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 413
s@ッ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ッ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 414
s@ツ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ツ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 415
s@ヅ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ヅ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 416
s@テ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:テ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 417
s@デ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:デ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 418
s@ト@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ト)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 419
s@ド@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ド)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 420
s@ナ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ナ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 421
s@ニ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ニ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 422
s@ヌ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ヌ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 423
s@ネ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ネ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 424
s@ノ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ノ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 425
s@ハ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ハ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 426
s@バ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:バ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 427
s@パ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:パ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 428
s@ヒ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ヒ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 429
s@ビ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ビ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 430
s@ピ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ピ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 431
s@フ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:フ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 432
s@ブ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ブ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 433
s@プ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:プ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 434
s@ヘ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ヘ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 435
s@ベ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ベ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 436
s@ペ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ペ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 437
s@ホ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ホ)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 438
s@ボ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ{)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 439
s@ポ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ|)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 440
s@マ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 441
s@ミ@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:ソ~)` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 442
s@[ァ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ@])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 443
s@[ア]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ア])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 444
s@[ィ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ィ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 445
s@[イ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[イ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 446
s@[ゥ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ゥ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 447
s@[ウ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ウ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 448
s@[ェ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ェ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 449
s@[エ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[エ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 450
s@[ォ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ォ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 451
s@[オ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[オ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 452
s@[カ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[カ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 453
s@[ガ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ガ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 454
s@[キ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[キ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 455
s@[ギ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ギ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 456
s@[ク]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ク])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 457
s@[グ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[グ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 458
s@[ケ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ケ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 459
s@[ゲ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ゲ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 460
s@[コ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[コ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 461
s@[ゴ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ゴ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 462
s@[サ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[サ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 463
s@[ザ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ザ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 464
s@[シ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[シ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 465
s@[ジ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ジ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 466
s@[ス]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ス])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 467
s@[ズ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ズ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 468
s@[セ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[セ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 469
s@[ゼ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ[])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 470
s@[ソ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ\])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 471
s@[ゾ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 472
s@[タ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ^])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 473
s@[ダ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ダ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 474
s@[チ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ`])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 475
s@[ヂ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヂ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 476
s@[ッ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ッ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 477
s@[ツ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ツ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 478
s@[ヅ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヅ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 479
s@[テ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[テ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 480
s@[デ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[デ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 481
s@[ト]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ト])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 482
s@[ド]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ド])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 483
s@[ナ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ナ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 484
s@[ニ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ニ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 485
s@[ヌ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヌ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 486
s@[ネ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ネ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 487
s@[ノ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ノ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 488
s@[ハ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ハ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 489
s@[バ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[バ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 490
s@[パ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[パ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 491
s@[ヒ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヒ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 492
s@[ビ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ビ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 493
s@[ピ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ピ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 494
s@[フ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[フ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 495
s@[ブ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ブ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 496
s@[プ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[プ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 497
s@[ヘ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ヘ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 498
s@[ベ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ベ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 499
s@[ペ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ペ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 500
s@[ホ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ホ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 501
s@[ボ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ{])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 502
s@[ポ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ|])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 503
s@[マ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ}])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 504
s@[ミ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[ソ~])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 505
s@[^ァ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ@])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 506
s@[^ア]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ア])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 507
s@[^ィ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ィ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 508
s@[^イ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^イ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 509
s@[^ゥ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ゥ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 510
s@[^ウ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ウ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 511
s@[^ェ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ェ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 512
s@[^エ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^エ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 513
s@[^ォ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ォ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 514
s@[^オ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^オ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 515
s@[^カ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^カ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 516
s@[^ガ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ガ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 517
s@[^キ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^キ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 518
s@[^ギ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ギ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 519
s@[^ク]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ク])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 520
s@[^グ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^グ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 521
s@[^ケ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ケ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 522
s@[^ゲ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ゲ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 523
s@[^コ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^コ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 524
s@[^ゴ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ゴ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 525
s@[^サ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^サ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 526
s@[^ザ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ザ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 527
s@[^シ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^シ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 528
s@[^ジ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ジ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 529
s@[^ス]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ス])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 530
s@[^ズ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ズ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 531
s@[^セ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^セ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 532
s@[^ゼ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ[])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 533
s@[^ソ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ\])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 534
s@[^ゾ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 535
s@[^タ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ^])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 536
s@[^ダ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ダ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 537
s@[^チ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ`])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 538
s@[^ヂ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヂ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 539
s@[^ッ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ッ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 540
s@[^ツ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ツ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 541
s@[^ヅ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヅ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 542
s@[^テ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^テ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 543
s@[^デ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^デ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 544
s@[^ト]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ト])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 545
s@[^ド]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ド])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 546
s@[^ナ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ナ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 547
s@[^ニ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ニ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 548
s@[^ヌ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヌ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 549
s@[^ネ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ネ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 550
s@[^ノ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ノ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 551
s@[^ハ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ハ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 552
s@[^バ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^バ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 553
s@[^パ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^パ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 554
s@[^ヒ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヒ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 555
s@[^ビ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ビ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 556
s@[^ピ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ピ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 557
s@[^フ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^フ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 558
s@[^ブ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ブ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 559
s@[^プ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^プ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 560
s@[^ヘ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ヘ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 561
s@[^ベ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ベ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 562
s@[^ペ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ペ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 563
s@[^ホ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ホ])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 564
s@[^ボ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ{])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 565
s@[^ポ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ|])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 566
s@[^マ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ}])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 567
s@[^ミ]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^ソ~])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 568
s/./1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_dot})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 569
s/\B/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_B})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 570
s/\D/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_D})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 571
s/\H/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_H})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 572
s/\N/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_N})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 573
s/\R/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_R})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 574
s/\S/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_S})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 575
s/\V/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_V})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 576
s/\W/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_W})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 577
s/\b/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_b})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 578
s/\d/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_d})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 579
s/\h/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_h})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 580
s/\s/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_s})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 581
s/\v/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_v})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 582
s/\w/1/

END1
s{(\G${mb::_anchor})@{[qr/(?:@{mb::_w})/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 583
s/[\b]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\b])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 584
s/[[:alnum:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:alnum:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 585
s/[[:alpha:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:alpha:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 586
s/[[:ascii:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:ascii:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 587
s/[[:blank:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:blank:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 588
s/[[:cntrl:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:cntrl:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 589
s/[[:digit:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:digit:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 590
s/[[:graph:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:graph:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 591
s/[[:lower:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:lower:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 592
s/[[:print:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:print:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 593
s/[[:punct:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:punct:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 594
s/[[:space:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:space:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 595
s/[[:upper:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:upper:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 596
s/[[:word:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:word:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 597
s/[[:xdigit:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:xdigit:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 598
s/[[:^alnum:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^alnum:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 599
s/[[:^alpha:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^alpha:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 600
s/[[:^ascii:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^ascii:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 601
s/[[:^blank:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^blank:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 602
s/[[:^cntrl:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^cntrl:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 603
s/[[:^digit:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^digit:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 604
s/[[:^graph:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^graph:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 605
s/[[:^lower:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^lower:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 606
s/[[:^print:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^print:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 607
s/[[:^punct:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^punct:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 608
s/[[:^space:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^space:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 609
s/[[:^upper:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^upper:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 610
s/[[:^word:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^word:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 611
s/[[:^xdigit:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[[:^xdigit:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 612
s/[.]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[.])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 613
s/[\B]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\B])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 614
s/[\D]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\D])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 615
s/[\H]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\H])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 616
s/[\N]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\N])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 617
s/[\R]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\R])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 618
s/[\S]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\S])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 619
s/[\V]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\V])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 620
s/[\W]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\W])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 621
s/[\b]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\b])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 622
s/[\d]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\d])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 623
s/[\h]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\h])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 624
s/[\s]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\s])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 625
s/[\v]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\v])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 626
s/[\w]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[\\w])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 627
s/[^.]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^.])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 628
s/[^\B]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\B])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 629
s/[^\D]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\D])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 630
s/[^\H]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\H])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 631
s/[^\N]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\N])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 632
s/[^\R]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\R])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 633
s/[^\S]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\S])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 634
s/[^\V]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\V])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 635
s/[^\W]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\W])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 636
s/[^\b]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\b])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 637
s/[^\d]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\d])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 638
s/[^\h]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\h])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 639
s/[^\s]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\s])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 640
s/[^\v]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\v])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 641
s/[^\w]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^\\w])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 642
s:.:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_dot})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 643
s:\B:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_B})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 644
s:\D:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_D})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 645
s:\H:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_H})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 646
s:\N:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_N})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 647
s:\R:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_R})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 648
s:\S:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_S})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 649
s:\V:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_V})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 650
s:\W:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_W})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 651
s:\b:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_b})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 652
s:\d:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_d})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 653
s:\h:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_h})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 654
s:\s:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_s})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 655
s:\v:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_v})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 656
s:\w:1:

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_w})` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 657
s:[\b]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 658
s:[[:alnum:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:alnum:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 659
s:[[:alpha:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:alpha:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 660
s:[[:ascii:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:ascii:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 661
s:[[:blank:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:blank:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 662
s:[[:cntrl:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:cntrl:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 663
s:[[:digit:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:digit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 664
s:[[:graph:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:graph:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 665
s:[[:lower:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:lower:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 666
s:[[:print:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:print:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 667
s:[[:punct:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:punct:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 668
s:[[:space:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:space:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 669
s:[[:upper:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:upper:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 670
s:[[:word:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:word:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 671
s:[[:xdigit:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:xdigit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 672
s:[[:^alnum:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^alnum:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 673
s:[[:^alpha:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^alpha:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 674
s:[[:^ascii:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^ascii:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 675
s:[[:^blank:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^blank:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 676
s:[[:^cntrl:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^cntrl:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 677
s:[[:^digit:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^digit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 678
s:[[:^graph:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^graph:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 679
s:[[:^lower:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^lower:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 680
s:[[:^print:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^print:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 681
s:[[:^punct:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^punct:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 682
s:[[:^space:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^space:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 683
s:[[:^upper:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^upper:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 684
s:[[:^word:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^word:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 685
s:[[:^xdigit:]]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^xdigit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 686
s:[.]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[.])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 687
s:[\B]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\B])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 688
s:[\D]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\D])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 689
s:[\H]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\H])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 690
s:[\N]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\N])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 691
s:[\R]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\R])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 692
s:[\S]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\S])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 693
s:[\V]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\V])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 694
s:[\W]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\W])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 695
s:[\b]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 696
s:[\d]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\d])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 697
s:[\h]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\h])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 698
s:[\s]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\s])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 699
s:[\v]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\v])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 700
s:[\w]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\w])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 701
s:[^.]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^.])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 702
s:[^\B]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\B])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 703
s:[^\D]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\D])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 704
s:[^\H]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\H])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 705
s:[^\N]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\N])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 706
s:[^\R]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\R])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 707
s:[^\S]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\S])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 708
s:[^\V]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\V])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 709
s:[^\W]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\W])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 710
s:[^\b]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\b])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 711
s:[^\d]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\d])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 712
s:[^\h]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\h])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 713
s:[^\s]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\s])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 714
s:[^\v]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\v])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 715
s:[^\w]:1:

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\w])]}` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 716
s@.@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_dot})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 717
s@\B@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_B})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 718
s@\D@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_D})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 719
s@\H@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_H})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 720
s@\N@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_N})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 721
s@\R@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_R})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 722
s@\S@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_S})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 723
s@\V@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_V})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 724
s@\W@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_W})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 725
s@\b@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_b})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 726
s@\d@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_d})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 727
s@\h@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_h})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 728
s@\s@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_s})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 729
s@\v@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_v})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 730
s@\w@1@

END1
s{(\G${mb::_anchor})@{[qr`(?:@{mb::_w})` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 731
s@[\b]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 732
s@[[:alnum:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:alnum:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 733
s@[[:alpha:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:alpha:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 734
s@[[:ascii:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:ascii:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 735
s@[[:blank:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:blank:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 736
s@[[:cntrl:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:cntrl:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 737
s@[[:digit:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:digit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 738
s@[[:graph:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:graph:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 739
s@[[:lower:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:lower:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 740
s@[[:print:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:print:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 741
s@[[:punct:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:punct:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 742
s@[[:space:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:space:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 743
s@[[:upper:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:upper:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 744
s@[[:word:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:word:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 745
s@[[:xdigit:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:xdigit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 746
s@[[:^alnum:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^alnum:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 747
s@[[:^alpha:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^alpha:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 748
s@[[:^ascii:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^ascii:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 749
s@[[:^blank:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^blank:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 750
s@[[:^cntrl:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^cntrl:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 751
s@[[:^digit:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^digit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 752
s@[[:^graph:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^graph:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 753
s@[[:^lower:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^lower:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 754
s@[[:^print:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^print:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 755
s@[[:^punct:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^punct:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 756
s@[[:^space:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^space:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 757
s@[[:^upper:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^upper:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 758
s@[[:^word:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^word:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 759
s@[[:^xdigit:]]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[[:^xdigit:]])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 760
s@[.]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[.])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 761
s@[\B]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\B])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 762
s@[\D]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\D])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 763
s@[\H]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\H])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 764
s@[\N]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\N])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 765
s@[\R]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\R])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 766
s@[\S]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\S])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 767
s@[\V]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\V])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 768
s@[\W]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\W])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 769
s@[\b]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\b])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 770
s@[\d]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\d])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 771
s@[\h]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\h])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 772
s@[\s]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\s])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 773
s@[\v]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\v])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 774
s@[\w]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[\\w])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 775
s@[^.]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^.])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 776
s@[^\B]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\B])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 777
s@[^\D]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\D])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 778
s@[^\H]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\H])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 779
s@[^\N]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\N])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 780
s@[^\R]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\R])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 781
s@[^\S]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\S])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 782
s@[^\V]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\V])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 783
s@[^\W]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\W])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 784
s@[^\b]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\b])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 785
s@[^\d]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\d])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 786
s@[^\h]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\h])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 787
s@[^\s]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\s])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 788
s@[^\v]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\v])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 789
s@[^\w]@1@

END1
s{(\G${mb::_anchor})@{[qr`@{[mb::_cc(qq[^\\w])]}` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 790
s/[アソゾABC1-3]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[アソ\ソ]ABC1-3])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 791
s/[^アソゾABC1-3]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^アソ\ソ]ABC1-3])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 792
s/[アソゾABC1-3[:alnum:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[アソ\ソ]ABC1-3[:alnum:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 793
s/[^アソゾABC1-3[:alnum:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^アソ\ソ]ABC1-3[:alnum:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 794
s/[アソゾ${_}ABC1-3[:alnum:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[アソ\ソ]${_}ABC1-3[:alnum:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 795
s/[^アソゾ${_}ABC1-3[:alnum:]]/1/

END1
s{(\G${mb::_anchor})@{[qr/@{[mb::_cc(qq[^アソ\ソ]${_}ABC1-3[:alnum:]])]}/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 796
s/Abア[アソゾABC1-3]/1/i

END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[アソ\ソ]ABC1-3])]}/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 797
s/Abア[^アソゾABC1-3]/1/i

END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[^アソ\ソ]ABC1-3])]}/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 798
s/Abア[アソゾABC1-3[:alnum:]]/1/i

END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[アソ\ソ]ABC1-3[:alnum:]])]}/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 799
s/Abア[^アソゾABC1-3[:alnum:]]/1/i

END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[^アソ\ソ]ABC1-3[:alnum:]])]}/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 800
s/Abア[アソゾ${_}ABC1-3[:alnum:]]/1/i

END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[アソ\ソ]${_}ABC1-3[:alnum:]])]}/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 801
s/Abア[^アソゾ${_}ABC1-3[:alnum:]]/1/i

END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/Ab(?:ア)@{[mb::_cc(qq[^アソ\ソ]${_}ABC1-3[:alnum:]])]}/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 802
s # comment 1-1
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
{(\G${mb::_anchor})@{[qr {search} ]}@{[mb::_s_passed()]}} # comment 2-1
# comment 2-2
  # comment 2-3
{$1 . qq {replacement}}e # comment 3-1
# comment 3-2
  # comment 3-3

END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
