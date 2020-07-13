# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
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
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 1
s{1}!1!
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq !1!}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
s{1}"1"
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq "1"}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
s{1}$1$
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq $1$}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
s{1}%1%
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq %1%}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
s{1}&1&
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq &1&}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
s{1}'1'
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
s{1})1)
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq )1)}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
s{1}*1*
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq *1*}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
s{1}+1+
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq +1+}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
s{1},1,
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq ,1,}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
s{1}-1-
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq -1-}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
s{1}.1.
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq .1.}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
s{1}/1/
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
s{1}:1:
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
s{1};1;
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq ;1;}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
s{1}=1=
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq =1=}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
s{1}>1>
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq >1>}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
s{1}?1?
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq ?1?}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
s{1}@1@
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
s{1}\1\
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq \1\}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
s{1}]1]
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq ]1]}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
s{1}^1^
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq ^1^}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
s{1}`1`
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq `1`}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
s{1}|1|
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq |1|}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
s{1}}1}
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq }1}}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
s{1}~1~
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}}{$1 . qq ~1~}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
s{1} !1!
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq !1!}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
s{1} "1"
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq "1"}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
s{1} $1$
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq $1$}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
s{1} %1%
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq %1%}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
s{1} &1&
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq &1&}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
s{1} '1'
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
s{1} )1)
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq )1)}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
s{1} *1*
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq *1*}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
s{1} +1+
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq +1+}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
s{1} ,1,
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq ,1,}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
s{1} -1-
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq -1-}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
s{1} .1.
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq .1.}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
s{1} /1/
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
s{1} :1:
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq :1:}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
s{1} ;1;
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq ;1;}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
s{1} =1=
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq =1=}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
s{1} >1>
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq >1>}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
s{1} ?1?
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq ?1?}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
s{1} @1@
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq @1@}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
s{1} \1\
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq \1\}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
s{1} ]1]
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq ]1]}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
s{1} ^1^
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq ^1^}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
s{1} `1`
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq `1`}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
s{1} |1|
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq |1|}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
s{1} }1}
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq }1}}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
s{1} ~1~
END1
s{(\G${mb::_anchor})@{[qr{1} ]}@{[mb::_s_passed()]}} {$1 . qq ~1~}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
s {1}!1!
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq !1!}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
s {1}"1"
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq "1"}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
s {1}$1$
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq $1$}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
s {1}%1%
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq %1%}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
s {1}&1&
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq &1&}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
s {1}'1'
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
s {1})1)
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq )1)}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
s {1}*1*
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq *1*}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
s {1}+1+
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq +1+}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
s {1},1,
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq ,1,}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
s {1}-1-
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq -1-}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 64
s {1}.1.
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq .1.}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 65
s {1}/1/
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 66
s {1}:1:
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 67
s {1};1;
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq ;1;}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 68
s {1}=1=
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq =1=}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 69
s {1}>1>
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq >1>}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 70
s {1}?1?
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq ?1?}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 71
s {1}@1@
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 72
s {1}\1\
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq \1\}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 73
s {1}]1]
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq ]1]}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 74
s {1}^1^
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq ^1^}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 75
s {1}`1`
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq `1`}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 76
s {1}|1|
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq |1|}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 77
s {1}}1}
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq }1}}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 78
s {1}~1~
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}}{$1 . qq ~1~}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 79
s {1} !1!
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq !1!}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 80
s {1} "1"
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq "1"}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 81
s {1} $1$
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq $1$}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 82
s {1} %1%
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq %1%}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 83
s {1} &1&
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq &1&}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 84
s {1} '1'
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 85
s {1} )1)
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq )1)}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 86
s {1} *1*
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq *1*}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 87
s {1} +1+
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq +1+}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 88
s {1} ,1,
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq ,1,}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 89
s {1} -1-
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq -1-}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 90
s {1} .1.
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq .1.}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 91
s {1} /1/
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 92
s {1} :1:
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq :1:}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 93
s {1} ;1;
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq ;1;}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 94
s {1} =1=
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq =1=}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 95
s {1} >1>
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq >1>}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 96
s {1} ?1?
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq ?1?}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 97
s {1} @1@
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq @1@}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 98
s {1} \1\
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq \1\}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 99
s {1} ]1]
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq ]1]}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 100
s {1} ^1^
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq ^1^}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 101
s {1} `1`
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq `1`}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 102
s {1} |1|
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq |1|}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 103
s {1} }1}
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq }1}}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 104
s {1} ~1~
END1
s {(\G${mb::_anchor})@{[qr {1} ]}@{[mb::_s_passed()]}} {$1 . qq ~1~}e
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
