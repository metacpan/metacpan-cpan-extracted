# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 1
'1'
END1
'1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
"1"
END1
"1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
`1`
END1
`1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
/1/
END1
m{\G${mb::_anchor}@{[qr/1/ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
/1/g
END1
m{\G${mb::_anchor}@{[qr/1/ ]}@{[mb::_m_passed()]}}g
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
/1/gc
END1
m{\G${mb::_anchor}@{[qr/1/ ]}@{[mb::_m_passed()]}}gc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
/1/i
END1
m{\G${mb::_anchor}@{[mb::_ignorecase(qr/1/)]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
/1/o
END1
m{\G${mb::_anchor}@{[qr/1/o ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
/1/m
END1
m{\G${mb::_anchor}@{[qr/1/m ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
/1/s
END1
m{\G${mb::_anchor}@{[qr/1/s ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
/1/x
END1
m{\G${mb::_anchor}@{[qr/1/x ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
/1/iomsxgc
END1
m{\G${mb::_anchor}@{[mb::_ignorecase(qr/1/omsx)]}@{[mb::_m_passed()]}}gc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
?1?
END1
m{\G${mb::_anchor}@{[qr?1? ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
split /1/
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
split /1/i
END1
mb::_split qr{@{[mb::_ignorecase(qr/1/m)]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
split /1/o
END1
mb::_split qr{@{[qr/1/om ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
split /1/m
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
split /1/s
END1
mb::_split qr{@{[qr/1/sm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
split /1/x
END1
mb::_split qr{@{[qr/1/xm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
split /1/iomsx
END1
mb::_split qr{@{[mb::_ignorecase(qr/1/omsx)]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
mb::split /1/
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
mb::split /1/i
END1
mb::_split qr{@{[mb::_ignorecase(qr/1/m)]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
mb::split /1/o
END1
mb::_split qr{@{[qr/1/om ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
mb::split /1/m
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
mb::split /1/s
END1
mb::_split qr{@{[qr/1/sm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
mb::split /1/x
END1
mb::_split qr{@{[qr/1/xm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
mb::split /1/iomsx
END1
mb::_split qr{@{[mb::_ignorecase(qr/1/omsx)]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
mb::split(/1/)
END1
mb::_split(qr{@{[qr/1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
mb::split(/1/i)
END1
mb::_split(qr{@{[mb::_ignorecase(qr/1/m)]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
mb::split(/1/o)
END1
mb::_split(qr{@{[qr/1/om ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
mb::split(/1/m)
END1
mb::_split(qr{@{[qr/1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
mb::split(/1/s)
END1
mb::_split(qr{@{[qr/1/sm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
mb::split(/1/x)
END1
mb::_split(qr{@{[qr/1/xm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
mb::split(/1/iomsx)
END1
mb::_split(qr{@{[mb::_ignorecase(qr/1/omsx)]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
<<>>
END1
<<>>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
<>
END1
<>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
<FILE>
END1
<FILE>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
<${file}>
END1
<${file}>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
<$file>
END1
<$file>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
<file*glob>
END1
<file*glob>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
qw!1!
END1
qw!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
qw"1"
END1
qw"1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
qw#1#
END1
qw#1#
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
qw$1$
END1
qw$1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
qw%1%
END1
qw%1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
qw&1&
END1
qw&1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
qw'1'
END1
qw'1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
qw(1)
END1
qw(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
qw)1)
END1
qw)1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
qw*1*
END1
qw*1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
qw+1+
END1
qw+1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
qw,1,
END1
qw,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
qw-1-
END1
qw-1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
qw.1.
END1
qw.1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
qw/1/
END1
qw/1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
qw:1:
END1
qw:1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
qw;1;
END1
qw;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
qw<1>
END1
qw<1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
qw=1=
END1
qw=1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
qw>1>
END1
qw>1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
qw?1?
END1
qw?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
qw@1@
END1
qw@1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
qw[1]
END1
qw[1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 64
qw\1\
END1
qw\1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 65
qw]1]
END1
qw]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 66
qw^1^
END1
qw^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 67
qw`1`
END1
qw`1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 68
qw{1}
END1
qw{1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 69
qw|1|
END1
qw|1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 70
qw}1}
END1
qw}1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 71
qw~1~
END1
qw~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 72
qw !1!
END1
qw !1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 73
qw "1"
END1
qw "1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 74
qw $1$
END1
qw $1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 75
qw %1%
END1
qw %1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 76
qw &1&
END1
qw &1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 77
qw '1'
END1
qw '1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 78
qw (1)
END1
qw (1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 79
qw )1)
END1
qw )1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 80
qw *1*
END1
qw *1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 81
qw +1+
END1
qw +1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 82
qw ,1,
END1
qw ,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 83
qw -1-
END1
qw -1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 84
qw .1.
END1
qw .1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 85
qw /1/
END1
qw /1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 86
qw 212
END1
qw 212
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 87
qw A1A
END1
qw A1A
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 88
qw _1_
END1
qw _1_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 89
qw :1:
END1
qw :1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 90
qw ;1;
END1
qw ;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 91
qw <1>
END1
qw <1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 92
qw =1=
END1
qw =1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 93
qw >1>
END1
qw >1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 94
qw ?1?
END1
qw ?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 95
qw @1@
END1
qw @1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 96
qw [1]
END1
qw [1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 97
qw \1\
END1
qw \1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 98
qw ]1]
END1
qw ]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 99
qw ^1^
END1
qw ^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 100
qw `1`
END1
qw `1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 101
qw {1}
END1
qw {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 102
qw |1|
END1
qw |1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 103
qw }1}
END1
qw }1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 104
qw ~1~
END1
qw ~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 105
q!1!
END1
q!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 106
q"1"
END1
q"1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 107
q#1#
END1
q#1#
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 108
q$1$
END1
q$1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 109
q%1%
END1
q%1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 110
q&1&
END1
q&1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 111
q'1'
END1
q'1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 112
q(1)
END1
q(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 113
q)1)
END1
q)1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 114
q*1*
END1
q*1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 115
q+1+
END1
q+1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 116
q,1,
END1
q,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 117
q-1-
END1
q-1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 118
q.1.
END1
q.1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 119
q/1/
END1
q/1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 120
q:1:
END1
q:1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 121
q;1;
END1
q;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 122
q<1>
END1
q<1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 123
q=1=
END1
q=1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 124
q>1>
END1
q>1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 125
q?1?
END1
q?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 126
q@1@
END1
q@1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 127
q[1]
END1
q[1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 128
q\1\
END1
q\1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 129
q]1]
END1
q]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 130
q^1^
END1
q^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 131
q`1`
END1
q`1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 132
q{1}
END1
q{1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 133
q|1|
END1
q|1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 134
q}1}
END1
q}1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 135
q~1~
END1
q~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 136
q !1!
END1
q !1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 137
q "1"
END1
q "1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 138
q $1$
END1
q $1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 139
q %1%
END1
q %1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 140
q &1&
END1
q &1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 141
q '1'
END1
q '1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 142
q (1)
END1
q (1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 143
q )1)
END1
q )1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 144
q *1*
END1
q *1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 145
q +1+
END1
q +1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 146
q ,1,
END1
q ,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 147
q -1-
END1
q -1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 148
q .1.
END1
q .1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 149
q /1/
END1
q /1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 150
q 212
END1
q 212
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 151
q A1A
END1
q A1A
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 152
q _1_
END1
q _1_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 153
q :1:
END1
q :1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 154
q ;1;
END1
q ;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 155
q <1>
END1
q <1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 156
q =1=
END1
q =1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 157
q >1>
END1
q >1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 158
q ?1?
END1
q ?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 159
q @1@
END1
q @1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 160
q [1]
END1
q [1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 161
q \1\
END1
q \1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 162
q ]1]
END1
q ]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 163
q ^1^
END1
q ^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 164
q `1`
END1
q `1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 165
q {1}
END1
q {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 166
q |1|
END1
q |1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 167
q }1}
END1
q }1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 168
q ~1~
END1
q ~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 169
qq!1!
END1
qq!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 170
qq"1"
END1
qq"1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 171
qq#1#
END1
qq#1#
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 172
qq$1$
END1
qq$1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 173
qq%1%
END1
qq%1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 174
qq&1&
END1
qq&1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 175
qq'1'
END1
qq'1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 176
qq(1)
END1
qq(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 177
qq)1)
END1
qq)1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 178
qq*1*
END1
qq*1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 179
qq+1+
END1
qq+1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 180
qq,1,
END1
qq,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 181
qq-1-
END1
qq-1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 182
qq.1.
END1
qq.1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 183
qq/1/
END1
qq/1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 184
qq:1:
END1
qq:1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 185
qq;1;
END1
qq;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 186
qq<1>
END1
qq<1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 187
qq=1=
END1
qq=1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 188
qq>1>
END1
qq>1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 189
qq?1?
END1
qq?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 190
qq@1@
END1
qq@1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 191
qq[1]
END1
qq[1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 192
qq\1\
END1
qq\1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 193
qq]1]
END1
qq]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 194
qq^1^
END1
qq^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 195
qq`1`
END1
qq`1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 196
qq{1}
END1
qq{1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 197
qq|1|
END1
qq|1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 198
qq}1}
END1
qq}1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 199
qq~1~
END1
qq~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 200
qq !1!
END1
qq !1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 201
qq "1"
END1
qq "1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 202
qq $1$
END1
qq $1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 203
qq %1%
END1
qq %1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 204
qq &1&
END1
qq &1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 205
qq '1'
END1
qq '1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 206
qq (1)
END1
qq (1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 207
qq )1)
END1
qq )1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 208
qq *1*
END1
qq *1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 209
qq +1+
END1
qq +1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 210
qq ,1,
END1
qq ,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 211
qq -1-
END1
qq -1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 212
qq .1.
END1
qq .1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 213
qq /1/
END1
qq /1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 214
qq 212
END1
qq 212
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 215
qq A1A
END1
qq A1A
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 216
qq _1_
END1
qq _1_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 217
qq :1:
END1
qq :1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 218
qq ;1;
END1
qq ;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 219
qq <1>
END1
qq <1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 220
qq =1=
END1
qq =1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 221
qq >1>
END1
qq >1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 222
qq ?1?
END1
qq ?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 223
qq @1@
END1
qq @1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 224
qq [1]
END1
qq [1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 225
qq \1\
END1
qq \1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 226
qq ]1]
END1
qq ]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 227
qq ^1^
END1
qq ^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 228
qq `1`
END1
qq `1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 229
qq {1}
END1
qq {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 230
qq |1|
END1
qq |1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 231
qq }1}
END1
qq }1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 232
qq ~1~
END1
qq ~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 233
qx!1!
END1
qx!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 234
qx"1"
END1
qx"1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 235
qx#1#
END1
qx#1#
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 236
qx$1$
END1
qx$1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 237
qx%1%
END1
qx%1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 238
qx&1&
END1
qx&1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 239
qx'1'
END1
qx'1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 240
qx(1)
END1
qx(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 241
qx)1)
END1
qx)1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 242
qx*1*
END1
qx*1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 243
qx+1+
END1
qx+1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 244
qx,1,
END1
qx,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 245
qx-1-
END1
qx-1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 246
qx.1.
END1
qx.1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 247
qx/1/
END1
qx/1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 248
qx:1:
END1
qx:1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 249
qx;1;
END1
qx;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 250
qx<1>
END1
qx<1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 251
qx=1=
END1
qx=1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 252
qx>1>
END1
qx>1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 253
qx?1?
END1
qx?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 254
qx@1@
END1
qx@1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 255
qx[1]
END1
qx[1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 256
qx\1\
END1
qx\1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 257
qx]1]
END1
qx]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 258
qx^1^
END1
qx^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 259
qx`1`
END1
qx`1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 260
qx{1}
END1
qx{1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 261
qx|1|
END1
qx|1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 262
qx}1}
END1
qx}1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 263
qx~1~
END1
qx~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 264
qx !1!
END1
qx !1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 265
qx "1"
END1
qx "1"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 266
qx $1$
END1
qx $1$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 267
qx %1%
END1
qx %1%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 268
qx &1&
END1
qx &1&
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 269
qx '1'
END1
qx '1'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 270
qx (1)
END1
qx (1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 271
qx )1)
END1
qx )1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 272
qx *1*
END1
qx *1*
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 273
qx +1+
END1
qx +1+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 274
qx ,1,
END1
qx ,1,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 275
qx -1-
END1
qx -1-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 276
qx .1.
END1
qx .1.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 277
qx /1/
END1
qx /1/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 278
qx 212
END1
qx 212
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 279
qx A1A
END1
qx A1A
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 280
qx _1_
END1
qx _1_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 281
qx :1:
END1
qx :1:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 282
qx ;1;
END1
qx ;1;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 283
qx <1>
END1
qx <1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 284
qx =1=
END1
qx =1=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 285
qx >1>
END1
qx >1>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 286
qx ?1?
END1
qx ?1?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 287
qx @1@
END1
qx @1@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 288
qx [1]
END1
qx [1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 289
qx \1\
END1
qx \1\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 290
qx ]1]
END1
qx ]1]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 291
qx ^1^
END1
qx ^1^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 292
qx `1`
END1
qx `1`
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 293
qx {1}
END1
qx {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 294
qx |1|
END1
qx |1|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 295
qx }1}
END1
qx }1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 296
qx ~1~
END1
qx ~1~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 297
m!1!
END1
m{\G${mb::_anchor}@{[qr!1! ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 298
m"1"
END1
m{\G${mb::_anchor}@{[qr"1" ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 299
m#1#
END1
m{\G${mb::_anchor}@{[qr#1# ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 300
m$1$
END1
m{\G${mb::_anchor}@{[qr$1$ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 301
m%1%
END1
m{\G${mb::_anchor}@{[qr%1% ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 302
m&1&
END1
m{\G${mb::_anchor}@{[qr&1& ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 303
m'1'
END1
m{\G${mb::_anchor}@{[qr'1' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 304
m(1)
END1
m{\G${mb::_anchor}@{[qr(1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 305
m)1)
END1
m{\G${mb::_anchor}@{[qr)1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 306
m*1*
END1
m{\G${mb::_anchor}@{[qr*1* ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 307
m+1+
END1
m{\G${mb::_anchor}@{[qr+1+ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 308
m,1,
END1
m{\G${mb::_anchor}@{[qr,1, ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 309
m-1-
END1
m{\G${mb::_anchor}@{[qr-1- ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 310
m.1.
END1
m{\G${mb::_anchor}@{[qr.1. ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 311
m/1/
END1
m{\G${mb::_anchor}@{[qr/1/ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 312
m:1:
END1
m{\G${mb::_anchor}@{[qr`1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 313
m;1;
END1
m{\G${mb::_anchor}@{[qr;1; ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 314
m<1>
END1
m{\G${mb::_anchor}@{[qr<1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 315
m=1=
END1
m{\G${mb::_anchor}@{[qr=1= ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 316
m>1>
END1
m{\G${mb::_anchor}@{[qr>1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 317
m?1?
END1
m{\G${mb::_anchor}@{[qr?1? ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 318
m@1@
END1
m{\G${mb::_anchor}@{[qr`1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 319
m[1]
END1
m{\G${mb::_anchor}@{[qr[1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 320
m\1\
END1
m{\G${mb::_anchor}@{[qr\1\ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 321
m]1]
END1
m{\G${mb::_anchor}@{[qr]1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 322
m^1^
END1
m{\G${mb::_anchor}@{[qr^1^ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 323
m`1`
END1
m{\G${mb::_anchor}@{[qr`1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 324
m{1}
END1
m{\G${mb::_anchor}@{[qr{1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 325
m|1|
END1
m{\G${mb::_anchor}@{[qr|1| ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 326
m}1}
END1
m{\G${mb::_anchor}@{[qr}1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 327
m~1~
END1
m{\G${mb::_anchor}@{[qr~1~ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 328
m !1!
END1
m {\G${mb::_anchor}@{[qr !1! ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 329
m "1"
END1
m {\G${mb::_anchor}@{[qr "1" ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 330
m $1$
END1
m {\G${mb::_anchor}@{[qr $1$ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 331
m %1%
END1
m {\G${mb::_anchor}@{[qr %1% ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 332
m &1&
END1
m {\G${mb::_anchor}@{[qr &1& ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 333
m '1'
END1
m {\G${mb::_anchor}@{[qr '1' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 334
m (1)
END1
m {\G${mb::_anchor}@{[qr (1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 335
m )1)
END1
m {\G${mb::_anchor}@{[qr )1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 336
m *1*
END1
m {\G${mb::_anchor}@{[qr *1* ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 337
m +1+
END1
m {\G${mb::_anchor}@{[qr +1+ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 338
m ,1,
END1
m {\G${mb::_anchor}@{[qr ,1, ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 339
m -1-
END1
m {\G${mb::_anchor}@{[qr -1- ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 340
m .1.
END1
m {\G${mb::_anchor}@{[qr .1. ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 341
m /1/
END1
m {\G${mb::_anchor}@{[qr /1/ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 342
m 212
END1
m {\G${mb::_anchor}@{[qr 212 ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 343
m A1A
END1
m {\G${mb::_anchor}@{[qr A1A ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 344
m _1_
END1
m {\G${mb::_anchor}@{[qr _1_ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 345
m :1:
END1
m {\G${mb::_anchor}@{[qr `1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 346
m ;1;
END1
m {\G${mb::_anchor}@{[qr ;1; ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 347
m <1>
END1
m {\G${mb::_anchor}@{[qr <1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 348
m =1=
END1
m {\G${mb::_anchor}@{[qr =1= ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 349
m >1>
END1
m {\G${mb::_anchor}@{[qr >1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 350
m ?1?
END1
m {\G${mb::_anchor}@{[qr ?1? ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 351
m @1@
END1
m {\G${mb::_anchor}@{[qr `1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 352
m [1]
END1
m {\G${mb::_anchor}@{[qr [1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 353
m \1\
END1
m {\G${mb::_anchor}@{[qr \1\ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 354
m ]1]
END1
m {\G${mb::_anchor}@{[qr ]1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 355
m ^1^
END1
m {\G${mb::_anchor}@{[qr ^1^ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 356
m `1`
END1
m {\G${mb::_anchor}@{[qr `1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 357
m {1}
END1
m {\G${mb::_anchor}@{[qr {1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 358
m |1|
END1
m {\G${mb::_anchor}@{[qr |1| ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 359
m }1}
END1
m {\G${mb::_anchor}@{[qr }1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 360
m ~1~
END1
m {\G${mb::_anchor}@{[qr ~1~ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 361
qr!1!
END1
qr{\G${mb::_anchor}@{[qr!1! ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 362
qr"1"
END1
qr{\G${mb::_anchor}@{[qr"1" ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 363
qr#1#
END1
qr{\G${mb::_anchor}@{[qr#1# ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 364
qr$1$
END1
qr{\G${mb::_anchor}@{[qr$1$ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 365
qr%1%
END1
qr{\G${mb::_anchor}@{[qr%1% ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 366
qr&1&
END1
qr{\G${mb::_anchor}@{[qr&1& ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 367
qr'1'
END1
qr{\G${mb::_anchor}@{[qr'1' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 368
qr(1)
END1
qr{\G${mb::_anchor}@{[qr(1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 369
qr)1)
END1
qr{\G${mb::_anchor}@{[qr)1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 370
qr*1*
END1
qr{\G${mb::_anchor}@{[qr*1* ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 371
qr+1+
END1
qr{\G${mb::_anchor}@{[qr+1+ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 372
qr,1,
END1
qr{\G${mb::_anchor}@{[qr,1, ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 373
qr-1-
END1
qr{\G${mb::_anchor}@{[qr-1- ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 374
qr.1.
END1
qr{\G${mb::_anchor}@{[qr.1. ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 375
qr/1/
END1
qr{\G${mb::_anchor}@{[qr/1/ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 376
qr:1:
END1
qr{\G${mb::_anchor}@{[qr`1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 377
qr;1;
END1
qr{\G${mb::_anchor}@{[qr;1; ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 378
qr<1>
END1
qr{\G${mb::_anchor}@{[qr<1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 379
qr=1=
END1
qr{\G${mb::_anchor}@{[qr=1= ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 380
qr>1>
END1
qr{\G${mb::_anchor}@{[qr>1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 381
qr?1?
END1
qr{\G${mb::_anchor}@{[qr?1? ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 382
qr@1@
END1
qr{\G${mb::_anchor}@{[qr`1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 383
qr[1]
END1
qr{\G${mb::_anchor}@{[qr[1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 384
qr\1\
END1
qr{\G${mb::_anchor}@{[qr\1\ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 385
qr]1]
END1
qr{\G${mb::_anchor}@{[qr]1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 386
qr^1^
END1
qr{\G${mb::_anchor}@{[qr^1^ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 387
qr`1`
END1
qr{\G${mb::_anchor}@{[qr`1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 388
qr{1}
END1
qr{\G${mb::_anchor}@{[qr{1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 389
qr|1|
END1
qr{\G${mb::_anchor}@{[qr|1| ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 390
qr}1}
END1
qr{\G${mb::_anchor}@{[qr}1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 391
qr~1~
END1
qr{\G${mb::_anchor}@{[qr~1~ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 392
qr !1!
END1
qr {\G${mb::_anchor}@{[qr !1! ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 393
qr "1"
END1
qr {\G${mb::_anchor}@{[qr "1" ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 394
qr $1$
END1
qr {\G${mb::_anchor}@{[qr $1$ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 395
qr %1%
END1
qr {\G${mb::_anchor}@{[qr %1% ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 396
qr &1&
END1
qr {\G${mb::_anchor}@{[qr &1& ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 397
qr '1'
END1
qr {\G${mb::_anchor}@{[qr '1' ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 398
qr (1)
END1
qr {\G${mb::_anchor}@{[qr (1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 399
qr )1)
END1
qr {\G${mb::_anchor}@{[qr )1) ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 400
qr *1*
END1
qr {\G${mb::_anchor}@{[qr *1* ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 401
qr +1+
END1
qr {\G${mb::_anchor}@{[qr +1+ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 402
qr ,1,
END1
qr {\G${mb::_anchor}@{[qr ,1, ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 403
qr -1-
END1
qr {\G${mb::_anchor}@{[qr -1- ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 404
qr .1.
END1
qr {\G${mb::_anchor}@{[qr .1. ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 405
qr /1/
END1
qr {\G${mb::_anchor}@{[qr /1/ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 406
qr 212
END1
qr {\G${mb::_anchor}@{[qr 212 ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 407
qr A1A
END1
qr {\G${mb::_anchor}@{[qr A1A ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 408
qr _1_
END1
qr {\G${mb::_anchor}@{[qr _1_ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 409
qr :1:
END1
qr {\G${mb::_anchor}@{[qr `1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 410
qr ;1;
END1
qr {\G${mb::_anchor}@{[qr ;1; ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 411
qr <1>
END1
qr {\G${mb::_anchor}@{[qr <1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 412
qr =1=
END1
qr {\G${mb::_anchor}@{[qr =1= ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 413
qr >1>
END1
qr {\G${mb::_anchor}@{[qr >1> ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 414
qr ?1?
END1
qr {\G${mb::_anchor}@{[qr ?1? ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 415
qr @1@
END1
qr {\G${mb::_anchor}@{[qr `1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 416
qr [1]
END1
qr {\G${mb::_anchor}@{[qr [1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 417
qr \1\
END1
qr {\G${mb::_anchor}@{[qr \1\ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 418
qr ]1]
END1
qr {\G${mb::_anchor}@{[qr ]1] ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 419
qr ^1^
END1
qr {\G${mb::_anchor}@{[qr ^1^ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 420
qr `1`
END1
qr {\G${mb::_anchor}@{[qr `1` ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 421
qr {1}
END1
qr {\G${mb::_anchor}@{[qr {1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 422
qr |1|
END1
qr {\G${mb::_anchor}@{[qr |1| ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 423
qr }1}
END1
qr {\G${mb::_anchor}@{[qr }1} ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 424
qr ~1~
END1
qr {\G${mb::_anchor}@{[qr ~1~ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 425
split m!1!
END1
mb::_split qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 426
split m"1"
END1
mb::_split qr{@{[qr"1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 427
split m#1#
END1
mb::_split qr{@{[qr#1#m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 428
split m$1$
END1
mb::_split qr{@{[qr$1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 429
split m%1%
END1
mb::_split qr{@{[qr%1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 430
split m&1&
END1
mb::_split qr{@{[qr&1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 431
split m'1'
END1
mb::_split qr{@{[qr'1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 432
split m(1)
END1
mb::_split qr{@{[qr(1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 433
split m)1)
END1
mb::_split qr{@{[qr)1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 434
split m*1*
END1
mb::_split qr{@{[qr*1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 435
split m+1+
END1
mb::_split qr{@{[qr+1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 436
split m,1,
END1
mb::_split qr{@{[qr,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 437
split m-1-
END1
mb::_split qr{@{[qr-1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 438
split m.1.
END1
mb::_split qr{@{[qr.1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 439
split m/1/
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 440
split m:1:
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 441
split m;1;
END1
mb::_split qr{@{[qr;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 442
split m<1>
END1
mb::_split qr{@{[qr<1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 443
split m=1=
END1
mb::_split qr{@{[qr=1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 444
split m>1>
END1
mb::_split qr{@{[qr>1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 445
split m?1?
END1
mb::_split qr{@{[qr?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 446
split m@1@
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 447
split m[1]
END1
mb::_split qr{@{[qr[1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 448
split m\1\
END1
mb::_split qr{@{[qr\1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 449
split m]1]
END1
mb::_split qr{@{[qr]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 450
split m^1^
END1
mb::_split qr{@{[qr^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 451
split m`1`
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 452
split m{1}
END1
mb::_split qr{@{[qr{1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 453
split m|1|
END1
mb::_split qr{@{[qr|1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 454
split m}1}
END1
mb::_split qr{@{[qr}1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 455
split m~1~
END1
mb::_split qr{@{[qr~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 456
split m !1!
END1
mb::_split qr {@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 457
split m "1"
END1
mb::_split qr {@{[qr "1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 458
split m $1$
END1
mb::_split qr {@{[qr $1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 459
split m %1%
END1
mb::_split qr {@{[qr %1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 460
split m &1&
END1
mb::_split qr {@{[qr &1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 461
split m '1'
END1
mb::_split qr {@{[qr '1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 462
split m (1)
END1
mb::_split qr {@{[qr (1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 463
split m )1)
END1
mb::_split qr {@{[qr )1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 464
split m *1*
END1
mb::_split qr {@{[qr *1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 465
split m +1+
END1
mb::_split qr {@{[qr +1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 466
split m ,1,
END1
mb::_split qr {@{[qr ,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 467
split m -1-
END1
mb::_split qr {@{[qr -1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 468
split m .1.
END1
mb::_split qr {@{[qr .1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 469
split m /1/
END1
mb::_split qr {@{[qr /1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 470
split m 212
END1
mb::_split qr {@{[qr 212m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 471
split m A1A
END1
mb::_split qr {@{[qr A1Am ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 472
split m _1_
END1
mb::_split qr {@{[qr _1_m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 473
split m :1:
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 474
split m ;1;
END1
mb::_split qr {@{[qr ;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 475
split m <1>
END1
mb::_split qr {@{[qr <1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 476
split m =1=
END1
mb::_split qr {@{[qr =1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 477
split m >1>
END1
mb::_split qr {@{[qr >1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 478
split m ?1?
END1
mb::_split qr {@{[qr ?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 479
split m @1@
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 480
split m [1]
END1
mb::_split qr {@{[qr [1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 481
split m \1\
END1
mb::_split qr {@{[qr \1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 482
split m ]1]
END1
mb::_split qr {@{[qr ]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 483
split m ^1^
END1
mb::_split qr {@{[qr ^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 484
split m `1`
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 485
split m {1}
END1
mb::_split qr {@{[qr {1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 486
split m |1|
END1
mb::_split qr {@{[qr |1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 487
split m }1}
END1
mb::_split qr {@{[qr }1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 488
split m ~1~
END1
mb::_split qr {@{[qr ~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 489
split qr!1!
END1
mb::_split qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 490
split qr"1"
END1
mb::_split qr{@{[qr"1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 491
split qr#1#
END1
mb::_split qr{@{[qr#1#m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 492
split qr$1$
END1
mb::_split qr{@{[qr$1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 493
split qr%1%
END1
mb::_split qr{@{[qr%1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 494
split qr&1&
END1
mb::_split qr{@{[qr&1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 495
split qr'1'
END1
mb::_split qr{@{[qr'1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 496
split qr(1)
END1
mb::_split qr{@{[qr(1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 497
split qr)1)
END1
mb::_split qr{@{[qr)1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 498
split qr*1*
END1
mb::_split qr{@{[qr*1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 499
split qr+1+
END1
mb::_split qr{@{[qr+1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 500
split qr,1,
END1
mb::_split qr{@{[qr,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 501
split qr-1-
END1
mb::_split qr{@{[qr-1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 502
split qr.1.
END1
mb::_split qr{@{[qr.1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 503
split qr/1/
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 504
split qr:1:
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 505
split qr;1;
END1
mb::_split qr{@{[qr;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 506
split qr<1>
END1
mb::_split qr{@{[qr<1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 507
split qr=1=
END1
mb::_split qr{@{[qr=1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 508
split qr>1>
END1
mb::_split qr{@{[qr>1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 509
split qr?1?
END1
mb::_split qr{@{[qr?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 510
split qr@1@
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 511
split qr[1]
END1
mb::_split qr{@{[qr[1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 512
split qr\1\
END1
mb::_split qr{@{[qr\1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 513
split qr]1]
END1
mb::_split qr{@{[qr]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 514
split qr^1^
END1
mb::_split qr{@{[qr^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 515
split qr`1`
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 516
split qr{1}
END1
mb::_split qr{@{[qr{1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 517
split qr|1|
END1
mb::_split qr{@{[qr|1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 518
split qr}1}
END1
mb::_split qr{@{[qr}1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 519
split qr~1~
END1
mb::_split qr{@{[qr~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 520
split qr !1!
END1
mb::_split qr {@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 521
split qr "1"
END1
mb::_split qr {@{[qr "1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 522
split qr $1$
END1
mb::_split qr {@{[qr $1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 523
split qr %1%
END1
mb::_split qr {@{[qr %1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 524
split qr &1&
END1
mb::_split qr {@{[qr &1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 525
split qr '1'
END1
mb::_split qr {@{[qr '1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 526
split qr (1)
END1
mb::_split qr {@{[qr (1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 527
split qr )1)
END1
mb::_split qr {@{[qr )1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 528
split qr *1*
END1
mb::_split qr {@{[qr *1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 529
split qr +1+
END1
mb::_split qr {@{[qr +1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 530
split qr ,1,
END1
mb::_split qr {@{[qr ,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 531
split qr -1-
END1
mb::_split qr {@{[qr -1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 532
split qr .1.
END1
mb::_split qr {@{[qr .1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 533
split qr /1/
END1
mb::_split qr {@{[qr /1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 534
split qr 212
END1
mb::_split qr {@{[qr 212m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 535
split qr A1A
END1
mb::_split qr {@{[qr A1Am ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 536
split qr _1_
END1
mb::_split qr {@{[qr _1_m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 537
split qr :1:
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 538
split qr ;1;
END1
mb::_split qr {@{[qr ;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 539
split qr <1>
END1
mb::_split qr {@{[qr <1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 540
split qr =1=
END1
mb::_split qr {@{[qr =1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 541
split qr >1>
END1
mb::_split qr {@{[qr >1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 542
split qr ?1?
END1
mb::_split qr {@{[qr ?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 543
split qr @1@
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 544
split qr [1]
END1
mb::_split qr {@{[qr [1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 545
split qr \1\
END1
mb::_split qr {@{[qr \1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 546
split qr ]1]
END1
mb::_split qr {@{[qr ]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 547
split qr ^1^
END1
mb::_split qr {@{[qr ^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 548
split qr `1`
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 549
split qr {1}
END1
mb::_split qr {@{[qr {1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 550
split qr |1|
END1
mb::_split qr {@{[qr |1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 551
split qr }1}
END1
mb::_split qr {@{[qr }1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 552
split qr ~1~
END1
mb::_split qr {@{[qr ~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 553
split(m!1!)
END1
mb::_split(qr{@{[qr!1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 554
split(m"1")
END1
mb::_split(qr{@{[qr"1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 555
split(m#1#)
END1
mb::_split(qr{@{[qr#1#m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 556
split(m$1$)
END1
mb::_split(qr{@{[qr$1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 557
split(m%1%)
END1
mb::_split(qr{@{[qr%1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 558
split(m&1&)
END1
mb::_split(qr{@{[qr&1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 559
split(m'1')
END1
mb::_split(qr{@{[qr'1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 560
split(m(1))
END1
mb::_split(qr{@{[qr(1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 561
split(m)1))
END1
mb::_split(qr{@{[qr)1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 562
split(m*1*)
END1
mb::_split(qr{@{[qr*1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 563
split(m+1+)
END1
mb::_split(qr{@{[qr+1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 564
split(m,1,)
END1
mb::_split(qr{@{[qr,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 565
split(m-1-)
END1
mb::_split(qr{@{[qr-1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 566
split(m.1.)
END1
mb::_split(qr{@{[qr.1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 567
split(m/1/)
END1
mb::_split(qr{@{[qr/1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 568
split(m:1:)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 569
split(m;1;)
END1
mb::_split(qr{@{[qr;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 570
split(m<1>)
END1
mb::_split(qr{@{[qr<1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 571
split(m=1=)
END1
mb::_split(qr{@{[qr=1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 572
split(m>1>)
END1
mb::_split(qr{@{[qr>1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 573
split(m?1?)
END1
mb::_split(qr{@{[qr?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 574
split(m@1@)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 575
split(m[1])
END1
mb::_split(qr{@{[qr[1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 576
split(m\1\)
END1
mb::_split(qr{@{[qr\1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 577
split(m]1])
END1
mb::_split(qr{@{[qr]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 578
split(m^1^)
END1
mb::_split(qr{@{[qr^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 579
split(m`1`)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 580
split(m{1})
END1
mb::_split(qr{@{[qr{1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 581
split(m|1|)
END1
mb::_split(qr{@{[qr|1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 582
split(m}1})
END1
mb::_split(qr{@{[qr}1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 583
split(m~1~)
END1
mb::_split(qr{@{[qr~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 584
split(m !1!)
END1
mb::_split(qr {@{[qr !1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 585
split(m "1")
END1
mb::_split(qr {@{[qr "1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 586
split(m $1$)
END1
mb::_split(qr {@{[qr $1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 587
split(m %1%)
END1
mb::_split(qr {@{[qr %1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 588
split(m &1&)
END1
mb::_split(qr {@{[qr &1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 589
split(m '1')
END1
mb::_split(qr {@{[qr '1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 590
split(m (1))
END1
mb::_split(qr {@{[qr (1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 591
split(m )1))
END1
mb::_split(qr {@{[qr )1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 592
split(m *1*)
END1
mb::_split(qr {@{[qr *1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 593
split(m +1+)
END1
mb::_split(qr {@{[qr +1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 594
split(m ,1,)
END1
mb::_split(qr {@{[qr ,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 595
split(m -1-)
END1
mb::_split(qr {@{[qr -1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 596
split(m .1.)
END1
mb::_split(qr {@{[qr .1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 597
split(m /1/)
END1
mb::_split(qr {@{[qr /1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 598
split(m 212)
END1
mb::_split(qr {@{[qr 212m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 599
split(m A1A)
END1
mb::_split(qr {@{[qr A1Am ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 600
split(m _1_)
END1
mb::_split(qr {@{[qr _1_m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 601
split(m :1:)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 602
split(m ;1;)
END1
mb::_split(qr {@{[qr ;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 603
split(m <1>)
END1
mb::_split(qr {@{[qr <1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 604
split(m =1=)
END1
mb::_split(qr {@{[qr =1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 605
split(m >1>)
END1
mb::_split(qr {@{[qr >1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 606
split(m ?1?)
END1
mb::_split(qr {@{[qr ?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 607
split(m @1@)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 608
split(m [1])
END1
mb::_split(qr {@{[qr [1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 609
split(m \1\)
END1
mb::_split(qr {@{[qr \1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 610
split(m ]1])
END1
mb::_split(qr {@{[qr ]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 611
split(m ^1^)
END1
mb::_split(qr {@{[qr ^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 612
split(m `1`)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 613
split(m {1})
END1
mb::_split(qr {@{[qr {1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 614
split(m |1|)
END1
mb::_split(qr {@{[qr |1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 615
split(m }1})
END1
mb::_split(qr {@{[qr }1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 616
split(m ~1~)
END1
mb::_split(qr {@{[qr ~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 617
split(qr!1!)
END1
mb::_split(qr{@{[qr!1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 618
split(qr"1")
END1
mb::_split(qr{@{[qr"1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 619
split(qr#1#)
END1
mb::_split(qr{@{[qr#1#m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 620
split(qr$1$)
END1
mb::_split(qr{@{[qr$1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 621
split(qr%1%)
END1
mb::_split(qr{@{[qr%1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 622
split(qr&1&)
END1
mb::_split(qr{@{[qr&1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 623
split(qr'1')
END1
mb::_split(qr{@{[qr'1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 624
split(qr(1))
END1
mb::_split(qr{@{[qr(1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 625
split(qr)1))
END1
mb::_split(qr{@{[qr)1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 626
split(qr*1*)
END1
mb::_split(qr{@{[qr*1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 627
split(qr+1+)
END1
mb::_split(qr{@{[qr+1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 628
split(qr,1,)
END1
mb::_split(qr{@{[qr,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 629
split(qr-1-)
END1
mb::_split(qr{@{[qr-1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 630
split(qr.1.)
END1
mb::_split(qr{@{[qr.1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 631
split(qr/1/)
END1
mb::_split(qr{@{[qr/1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 632
split(qr:1:)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 633
split(qr;1;)
END1
mb::_split(qr{@{[qr;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 634
split(qr<1>)
END1
mb::_split(qr{@{[qr<1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 635
split(qr=1=)
END1
mb::_split(qr{@{[qr=1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 636
split(qr>1>)
END1
mb::_split(qr{@{[qr>1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 637
split(qr?1?)
END1
mb::_split(qr{@{[qr?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 638
split(qr@1@)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 639
split(qr[1])
END1
mb::_split(qr{@{[qr[1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 640
split(qr\1\)
END1
mb::_split(qr{@{[qr\1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 641
split(qr]1])
END1
mb::_split(qr{@{[qr]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 642
split(qr^1^)
END1
mb::_split(qr{@{[qr^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 643
split(qr`1`)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 644
split(qr{1})
END1
mb::_split(qr{@{[qr{1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 645
split(qr|1|)
END1
mb::_split(qr{@{[qr|1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 646
split(qr}1})
END1
mb::_split(qr{@{[qr}1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 647
split(qr~1~)
END1
mb::_split(qr{@{[qr~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 648
split(qr !1!)
END1
mb::_split(qr {@{[qr !1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 649
split(qr "1")
END1
mb::_split(qr {@{[qr "1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 650
split(qr $1$)
END1
mb::_split(qr {@{[qr $1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 651
split(qr %1%)
END1
mb::_split(qr {@{[qr %1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 652
split(qr &1&)
END1
mb::_split(qr {@{[qr &1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 653
split(qr '1')
END1
mb::_split(qr {@{[qr '1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 654
split(qr (1))
END1
mb::_split(qr {@{[qr (1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 655
split(qr )1))
END1
mb::_split(qr {@{[qr )1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 656
split(qr *1*)
END1
mb::_split(qr {@{[qr *1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 657
split(qr +1+)
END1
mb::_split(qr {@{[qr +1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 658
split(qr ,1,)
END1
mb::_split(qr {@{[qr ,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 659
split(qr -1-)
END1
mb::_split(qr {@{[qr -1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 660
split(qr .1.)
END1
mb::_split(qr {@{[qr .1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 661
split(qr /1/)
END1
mb::_split(qr {@{[qr /1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 662
split(qr 212)
END1
mb::_split(qr {@{[qr 212m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 663
split(qr A1A)
END1
mb::_split(qr {@{[qr A1Am ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 664
split(qr _1_)
END1
mb::_split(qr {@{[qr _1_m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 665
split(qr :1:)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 666
split(qr ;1;)
END1
mb::_split(qr {@{[qr ;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 667
split(qr <1>)
END1
mb::_split(qr {@{[qr <1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 668
split(qr =1=)
END1
mb::_split(qr {@{[qr =1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 669
split(qr >1>)
END1
mb::_split(qr {@{[qr >1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 670
split(qr ?1?)
END1
mb::_split(qr {@{[qr ?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 671
split(qr @1@)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 672
split(qr [1])
END1
mb::_split(qr {@{[qr [1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 673
split(qr \1\)
END1
mb::_split(qr {@{[qr \1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 674
split(qr ]1])
END1
mb::_split(qr {@{[qr ]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 675
split(qr ^1^)
END1
mb::_split(qr {@{[qr ^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 676
split(qr `1`)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 677
split(qr {1})
END1
mb::_split(qr {@{[qr {1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 678
split(qr |1|)
END1
mb::_split(qr {@{[qr |1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 679
split(qr }1})
END1
mb::_split(qr {@{[qr }1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 680
split(qr ~1~)
END1
mb::_split(qr {@{[qr ~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 681
mb::split m!1!
END1
mb::_split qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 682
mb::split m"1"
END1
mb::_split qr{@{[qr"1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 683
mb::split m#1#
END1
mb::_split qr{@{[qr#1#m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 684
mb::split m$1$
END1
mb::_split qr{@{[qr$1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 685
mb::split m%1%
END1
mb::_split qr{@{[qr%1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 686
mb::split m&1&
END1
mb::_split qr{@{[qr&1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 687
mb::split m'1'
END1
mb::_split qr{@{[qr'1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 688
mb::split m(1)
END1
mb::_split qr{@{[qr(1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 689
mb::split m)1)
END1
mb::_split qr{@{[qr)1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 690
mb::split m*1*
END1
mb::_split qr{@{[qr*1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 691
mb::split m+1+
END1
mb::_split qr{@{[qr+1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 692
mb::split m,1,
END1
mb::_split qr{@{[qr,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 693
mb::split m-1-
END1
mb::_split qr{@{[qr-1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 694
mb::split m.1.
END1
mb::_split qr{@{[qr.1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 695
mb::split m/1/
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 696
mb::split m:1:
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 697
mb::split m;1;
END1
mb::_split qr{@{[qr;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 698
mb::split m<1>
END1
mb::_split qr{@{[qr<1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 699
mb::split m=1=
END1
mb::_split qr{@{[qr=1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 700
mb::split m>1>
END1
mb::_split qr{@{[qr>1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 701
mb::split m?1?
END1
mb::_split qr{@{[qr?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 702
mb::split m@1@
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 703
mb::split m[1]
END1
mb::_split qr{@{[qr[1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 704
mb::split m\1\
END1
mb::_split qr{@{[qr\1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 705
mb::split m]1]
END1
mb::_split qr{@{[qr]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 706
mb::split m^1^
END1
mb::_split qr{@{[qr^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 707
mb::split m`1`
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 708
mb::split m{1}
END1
mb::_split qr{@{[qr{1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 709
mb::split m|1|
END1
mb::_split qr{@{[qr|1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 710
mb::split m}1}
END1
mb::_split qr{@{[qr}1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 711
mb::split m~1~
END1
mb::_split qr{@{[qr~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 712
mb::split m !1!
END1
mb::_split qr {@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 713
mb::split m "1"
END1
mb::_split qr {@{[qr "1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 714
mb::split m $1$
END1
mb::_split qr {@{[qr $1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 715
mb::split m %1%
END1
mb::_split qr {@{[qr %1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 716
mb::split m &1&
END1
mb::_split qr {@{[qr &1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 717
mb::split m '1'
END1
mb::_split qr {@{[qr '1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 718
mb::split m (1)
END1
mb::_split qr {@{[qr (1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 719
mb::split m )1)
END1
mb::_split qr {@{[qr )1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 720
mb::split m *1*
END1
mb::_split qr {@{[qr *1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 721
mb::split m +1+
END1
mb::_split qr {@{[qr +1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 722
mb::split m ,1,
END1
mb::_split qr {@{[qr ,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 723
mb::split m -1-
END1
mb::_split qr {@{[qr -1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 724
mb::split m .1.
END1
mb::_split qr {@{[qr .1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 725
mb::split m /1/
END1
mb::_split qr {@{[qr /1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 726
mb::split m 212
END1
mb::_split qr {@{[qr 212m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 727
mb::split m A1A
END1
mb::_split qr {@{[qr A1Am ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 728
mb::split m _1_
END1
mb::_split qr {@{[qr _1_m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 729
mb::split m :1:
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 730
mb::split m ;1;
END1
mb::_split qr {@{[qr ;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 731
mb::split m <1>
END1
mb::_split qr {@{[qr <1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 732
mb::split m =1=
END1
mb::_split qr {@{[qr =1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 733
mb::split m >1>
END1
mb::_split qr {@{[qr >1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 734
mb::split m ?1?
END1
mb::_split qr {@{[qr ?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 735
mb::split m @1@
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 736
mb::split m [1]
END1
mb::_split qr {@{[qr [1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 737
mb::split m \1\
END1
mb::_split qr {@{[qr \1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 738
mb::split m ]1]
END1
mb::_split qr {@{[qr ]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 739
mb::split m ^1^
END1
mb::_split qr {@{[qr ^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 740
mb::split m `1`
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 741
mb::split m {1}
END1
mb::_split qr {@{[qr {1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 742
mb::split m |1|
END1
mb::_split qr {@{[qr |1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 743
mb::split m }1}
END1
mb::_split qr {@{[qr }1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 744
mb::split m ~1~
END1
mb::_split qr {@{[qr ~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 745
mb::split qr!1!
END1
mb::_split qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 746
mb::split qr"1"
END1
mb::_split qr{@{[qr"1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 747
mb::split qr#1#
END1
mb::_split qr{@{[qr#1#m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 748
mb::split qr$1$
END1
mb::_split qr{@{[qr$1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 749
mb::split qr%1%
END1
mb::_split qr{@{[qr%1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 750
mb::split qr&1&
END1
mb::_split qr{@{[qr&1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 751
mb::split qr'1'
END1
mb::_split qr{@{[qr'1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 752
mb::split qr(1)
END1
mb::_split qr{@{[qr(1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 753
mb::split qr)1)
END1
mb::_split qr{@{[qr)1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 754
mb::split qr*1*
END1
mb::_split qr{@{[qr*1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 755
mb::split qr+1+
END1
mb::_split qr{@{[qr+1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 756
mb::split qr,1,
END1
mb::_split qr{@{[qr,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 757
mb::split qr-1-
END1
mb::_split qr{@{[qr-1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 758
mb::split qr.1.
END1
mb::_split qr{@{[qr.1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 759
mb::split qr/1/
END1
mb::_split qr{@{[qr/1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 760
mb::split qr:1:
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 761
mb::split qr;1;
END1
mb::_split qr{@{[qr;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 762
mb::split qr<1>
END1
mb::_split qr{@{[qr<1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 763
mb::split qr=1=
END1
mb::_split qr{@{[qr=1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 764
mb::split qr>1>
END1
mb::_split qr{@{[qr>1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 765
mb::split qr?1?
END1
mb::_split qr{@{[qr?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 766
mb::split qr@1@
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 767
mb::split qr[1]
END1
mb::_split qr{@{[qr[1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 768
mb::split qr\1\
END1
mb::_split qr{@{[qr\1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 769
mb::split qr]1]
END1
mb::_split qr{@{[qr]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 770
mb::split qr^1^
END1
mb::_split qr{@{[qr^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 771
mb::split qr`1`
END1
mb::_split qr{@{[qr`1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 772
mb::split qr{1}
END1
mb::_split qr{@{[qr{1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 773
mb::split qr|1|
END1
mb::_split qr{@{[qr|1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 774
mb::split qr}1}
END1
mb::_split qr{@{[qr}1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 775
mb::split qr~1~
END1
mb::_split qr{@{[qr~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 776
mb::split qr !1!
END1
mb::_split qr {@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 777
mb::split qr "1"
END1
mb::_split qr {@{[qr "1"m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 778
mb::split qr $1$
END1
mb::_split qr {@{[qr $1$m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 779
mb::split qr %1%
END1
mb::_split qr {@{[qr %1%m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 780
mb::split qr &1&
END1
mb::_split qr {@{[qr &1&m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 781
mb::split qr '1'
END1
mb::_split qr {@{[qr '1'm ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 782
mb::split qr (1)
END1
mb::_split qr {@{[qr (1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 783
mb::split qr )1)
END1
mb::_split qr {@{[qr )1)m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 784
mb::split qr *1*
END1
mb::_split qr {@{[qr *1*m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 785
mb::split qr +1+
END1
mb::_split qr {@{[qr +1+m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 786
mb::split qr ,1,
END1
mb::_split qr {@{[qr ,1,m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 787
mb::split qr -1-
END1
mb::_split qr {@{[qr -1-m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 788
mb::split qr .1.
END1
mb::_split qr {@{[qr .1.m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 789
mb::split qr /1/
END1
mb::_split qr {@{[qr /1/m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 790
mb::split qr 212
END1
mb::_split qr {@{[qr 212m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 791
mb::split qr A1A
END1
mb::_split qr {@{[qr A1Am ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 792
mb::split qr _1_
END1
mb::_split qr {@{[qr _1_m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 793
mb::split qr :1:
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 794
mb::split qr ;1;
END1
mb::_split qr {@{[qr ;1;m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 795
mb::split qr <1>
END1
mb::_split qr {@{[qr <1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 796
mb::split qr =1=
END1
mb::_split qr {@{[qr =1=m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 797
mb::split qr >1>
END1
mb::_split qr {@{[qr >1>m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 798
mb::split qr ?1?
END1
mb::_split qr {@{[qr ?1?m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 799
mb::split qr @1@
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 800
mb::split qr [1]
END1
mb::_split qr {@{[qr [1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 801
mb::split qr \1\
END1
mb::_split qr {@{[qr \1\m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 802
mb::split qr ]1]
END1
mb::_split qr {@{[qr ]1]m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 803
mb::split qr ^1^
END1
mb::_split qr {@{[qr ^1^m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 804
mb::split qr `1`
END1
mb::_split qr {@{[qr `1`m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 805
mb::split qr {1}
END1
mb::_split qr {@{[qr {1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 806
mb::split qr |1|
END1
mb::_split qr {@{[qr |1|m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 807
mb::split qr }1}
END1
mb::_split qr {@{[qr }1}m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 808
mb::split qr ~1~
END1
mb::_split qr {@{[qr ~1~m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 809
mb::split(m!1!)
END1
mb::_split(qr{@{[qr!1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 810
mb::split(m"1")
END1
mb::_split(qr{@{[qr"1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 811
mb::split(m#1#)
END1
mb::_split(qr{@{[qr#1#m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 812
mb::split(m$1$)
END1
mb::_split(qr{@{[qr$1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 813
mb::split(m%1%)
END1
mb::_split(qr{@{[qr%1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 814
mb::split(m&1&)
END1
mb::_split(qr{@{[qr&1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 815
mb::split(m'1')
END1
mb::_split(qr{@{[qr'1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 816
mb::split(m(1))
END1
mb::_split(qr{@{[qr(1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 817
mb::split(m)1))
END1
mb::_split(qr{@{[qr)1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 818
mb::split(m*1*)
END1
mb::_split(qr{@{[qr*1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 819
mb::split(m+1+)
END1
mb::_split(qr{@{[qr+1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 820
mb::split(m,1,)
END1
mb::_split(qr{@{[qr,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 821
mb::split(m-1-)
END1
mb::_split(qr{@{[qr-1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 822
mb::split(m.1.)
END1
mb::_split(qr{@{[qr.1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 823
mb::split(m/1/)
END1
mb::_split(qr{@{[qr/1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 824
mb::split(m:1:)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 825
mb::split(m;1;)
END1
mb::_split(qr{@{[qr;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 826
mb::split(m<1>)
END1
mb::_split(qr{@{[qr<1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 827
mb::split(m=1=)
END1
mb::_split(qr{@{[qr=1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 828
mb::split(m>1>)
END1
mb::_split(qr{@{[qr>1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 829
mb::split(m?1?)
END1
mb::_split(qr{@{[qr?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 830
mb::split(m@1@)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 831
mb::split(m[1])
END1
mb::_split(qr{@{[qr[1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 832
mb::split(m\1\)
END1
mb::_split(qr{@{[qr\1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 833
mb::split(m]1])
END1
mb::_split(qr{@{[qr]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 834
mb::split(m^1^)
END1
mb::_split(qr{@{[qr^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 835
mb::split(m`1`)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 836
mb::split(m{1})
END1
mb::_split(qr{@{[qr{1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 837
mb::split(m|1|)
END1
mb::_split(qr{@{[qr|1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 838
mb::split(m}1})
END1
mb::_split(qr{@{[qr}1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 839
mb::split(m~1~)
END1
mb::_split(qr{@{[qr~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 840
mb::split(m !1!)
END1
mb::_split(qr {@{[qr !1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 841
mb::split(m "1")
END1
mb::_split(qr {@{[qr "1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 842
mb::split(m $1$)
END1
mb::_split(qr {@{[qr $1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 843
mb::split(m %1%)
END1
mb::_split(qr {@{[qr %1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 844
mb::split(m &1&)
END1
mb::_split(qr {@{[qr &1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 845
mb::split(m '1')
END1
mb::_split(qr {@{[qr '1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 846
mb::split(m (1))
END1
mb::_split(qr {@{[qr (1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 847
mb::split(m )1))
END1
mb::_split(qr {@{[qr )1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 848
mb::split(m *1*)
END1
mb::_split(qr {@{[qr *1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 849
mb::split(m +1+)
END1
mb::_split(qr {@{[qr +1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 850
mb::split(m ,1,)
END1
mb::_split(qr {@{[qr ,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 851
mb::split(m -1-)
END1
mb::_split(qr {@{[qr -1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 852
mb::split(m .1.)
END1
mb::_split(qr {@{[qr .1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 853
mb::split(m /1/)
END1
mb::_split(qr {@{[qr /1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 854
mb::split(m 212)
END1
mb::_split(qr {@{[qr 212m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 855
mb::split(m A1A)
END1
mb::_split(qr {@{[qr A1Am ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 856
mb::split(m _1_)
END1
mb::_split(qr {@{[qr _1_m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 857
mb::split(m :1:)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 858
mb::split(m ;1;)
END1
mb::_split(qr {@{[qr ;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 859
mb::split(m <1>)
END1
mb::_split(qr {@{[qr <1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 860
mb::split(m =1=)
END1
mb::_split(qr {@{[qr =1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 861
mb::split(m >1>)
END1
mb::_split(qr {@{[qr >1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 862
mb::split(m ?1?)
END1
mb::_split(qr {@{[qr ?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 863
mb::split(m @1@)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 864
mb::split(m [1])
END1
mb::_split(qr {@{[qr [1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 865
mb::split(m \1\)
END1
mb::_split(qr {@{[qr \1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 866
mb::split(m ]1])
END1
mb::_split(qr {@{[qr ]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 867
mb::split(m ^1^)
END1
mb::_split(qr {@{[qr ^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 868
mb::split(m `1`)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 869
mb::split(m {1})
END1
mb::_split(qr {@{[qr {1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 870
mb::split(m |1|)
END1
mb::_split(qr {@{[qr |1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 871
mb::split(m }1})
END1
mb::_split(qr {@{[qr }1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 872
mb::split(m ~1~)
END1
mb::_split(qr {@{[qr ~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 873
mb::split(qr!1!)
END1
mb::_split(qr{@{[qr!1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 874
mb::split(qr"1")
END1
mb::_split(qr{@{[qr"1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 875
mb::split(qr#1#)
END1
mb::_split(qr{@{[qr#1#m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 876
mb::split(qr$1$)
END1
mb::_split(qr{@{[qr$1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 877
mb::split(qr%1%)
END1
mb::_split(qr{@{[qr%1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 878
mb::split(qr&1&)
END1
mb::_split(qr{@{[qr&1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 879
mb::split(qr'1')
END1
mb::_split(qr{@{[qr'1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 880
mb::split(qr(1))
END1
mb::_split(qr{@{[qr(1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 881
mb::split(qr)1))
END1
mb::_split(qr{@{[qr)1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 882
mb::split(qr*1*)
END1
mb::_split(qr{@{[qr*1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 883
mb::split(qr+1+)
END1
mb::_split(qr{@{[qr+1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 884
mb::split(qr,1,)
END1
mb::_split(qr{@{[qr,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 885
mb::split(qr-1-)
END1
mb::_split(qr{@{[qr-1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 886
mb::split(qr.1.)
END1
mb::_split(qr{@{[qr.1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 887
mb::split(qr/1/)
END1
mb::_split(qr{@{[qr/1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 888
mb::split(qr:1:)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 889
mb::split(qr;1;)
END1
mb::_split(qr{@{[qr;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 890
mb::split(qr<1>)
END1
mb::_split(qr{@{[qr<1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 891
mb::split(qr=1=)
END1
mb::_split(qr{@{[qr=1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 892
mb::split(qr>1>)
END1
mb::_split(qr{@{[qr>1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 893
mb::split(qr?1?)
END1
mb::_split(qr{@{[qr?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 894
mb::split(qr@1@)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 895
mb::split(qr[1])
END1
mb::_split(qr{@{[qr[1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 896
mb::split(qr\1\)
END1
mb::_split(qr{@{[qr\1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 897
mb::split(qr]1])
END1
mb::_split(qr{@{[qr]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 898
mb::split(qr^1^)
END1
mb::_split(qr{@{[qr^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 899
mb::split(qr`1`)
END1
mb::_split(qr{@{[qr`1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 900
mb::split(qr{1})
END1
mb::_split(qr{@{[qr{1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 901
mb::split(qr|1|)
END1
mb::_split(qr{@{[qr|1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 902
mb::split(qr}1})
END1
mb::_split(qr{@{[qr}1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 903
mb::split(qr~1~)
END1
mb::_split(qr{@{[qr~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 904
mb::split(qr !1!)
END1
mb::_split(qr {@{[qr !1!m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 905
mb::split(qr "1")
END1
mb::_split(qr {@{[qr "1"m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 906
mb::split(qr $1$)
END1
mb::_split(qr {@{[qr $1$m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 907
mb::split(qr %1%)
END1
mb::_split(qr {@{[qr %1%m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 908
mb::split(qr &1&)
END1
mb::_split(qr {@{[qr &1&m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 909
mb::split(qr '1')
END1
mb::_split(qr {@{[qr '1'm ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 910
mb::split(qr (1))
END1
mb::_split(qr {@{[qr (1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 911
mb::split(qr )1))
END1
mb::_split(qr {@{[qr )1)m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 912
mb::split(qr *1*)
END1
mb::_split(qr {@{[qr *1*m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 913
mb::split(qr +1+)
END1
mb::_split(qr {@{[qr +1+m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 914
mb::split(qr ,1,)
END1
mb::_split(qr {@{[qr ,1,m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 915
mb::split(qr -1-)
END1
mb::_split(qr {@{[qr -1-m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 916
mb::split(qr .1.)
END1
mb::_split(qr {@{[qr .1.m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 917
mb::split(qr /1/)
END1
mb::_split(qr {@{[qr /1/m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 918
mb::split(qr 212)
END1
mb::_split(qr {@{[qr 212m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 919
mb::split(qr A1A)
END1
mb::_split(qr {@{[qr A1Am ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 920
mb::split(qr _1_)
END1
mb::_split(qr {@{[qr _1_m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 921
mb::split(qr :1:)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 922
mb::split(qr ;1;)
END1
mb::_split(qr {@{[qr ;1;m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 923
mb::split(qr <1>)
END1
mb::_split(qr {@{[qr <1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 924
mb::split(qr =1=)
END1
mb::_split(qr {@{[qr =1=m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 925
mb::split(qr >1>)
END1
mb::_split(qr {@{[qr >1>m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 926
mb::split(qr ?1?)
END1
mb::_split(qr {@{[qr ?1?m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 927
mb::split(qr @1@)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 928
mb::split(qr [1])
END1
mb::_split(qr {@{[qr [1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 929
mb::split(qr \1\)
END1
mb::_split(qr {@{[qr \1\m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 930
mb::split(qr ]1])
END1
mb::_split(qr {@{[qr ]1]m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 931
mb::split(qr ^1^)
END1
mb::_split(qr {@{[qr ^1^m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 932
mb::split(qr `1`)
END1
mb::_split(qr {@{[qr `1`m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 933
mb::split(qr {1})
END1
mb::_split(qr {@{[qr {1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 934
mb::split(qr |1|)
END1
mb::_split(qr {@{[qr |1|m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 935
mb::split(qr }1})
END1
mb::_split(qr {@{[qr }1}m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 936
mb::split(qr ~1~)
END1
mb::_split(qr {@{[qr ~1~m ]}})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 937
qw #comment
!1!
END1
qw #comment
!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 938
q #comment
!1!
END1
q #comment
!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 939
qq #comment
!1!
END1
qq #comment
!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 940
qx #comment
!1!
END1
qx #comment
!1!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 941
m #comment
!1!
END1
m #comment
{\G${mb::_anchor}@{[qr !1! ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 942
qr #comment
!1!
END1
qr #comment
{\G${mb::_anchor}@{[qr !1! ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 943
split #comment
m!1!
END1
mb::_split #comment
qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 944
split #comment
qr!1!
END1
mb::_split #comment
qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 945
mb::split #comment
m!1!
END1
mb::_split #comment
qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 946
mb::split #comment
qr!1!
END1
mb::_split #comment
qr{@{[qr!1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 947
split m #comment
!1!
END1
mb::_split qr #comment
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 948
split qr #comment
!1!
END1
mb::_split qr #comment
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 949
mb::split m #comment
!1!
END1
mb::_split qr #comment
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 950
mb::split qr #comment
!1!
END1
mb::_split qr #comment
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 951
split #comment1
m #comment2
!1!
END1
mb::_split #comment1
qr #comment2
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 952
split #comment1
qr #comment2
!1!
END1
mb::_split #comment1
qr #comment2
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 953
mb::split #comment1
m #comment2
!1!
END1
mb::_split #comment1
qr #comment2
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 954
mb::split #comment1
qr #comment2
!1!
END1
mb::_split #comment1
qr #comment2
{@{[qr !1!m ]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 955
split( #comment
m!1!
)
END1
mb::_split( #comment
qr{@{[qr!1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 956
split( #comment
qr!1!
)
END1
mb::_split( #comment
qr{@{[qr!1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 957
mb::split( #comment
m!1!
)
END1
mb::_split( #comment
qr{@{[qr!1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 958
mb::split( #comment
qr!1!
)
END1
mb::_split( #comment
qr{@{[qr!1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 959
split( m #comment
!1!
)
END1
mb::_split( qr #comment
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 960
split( qr #comment
!1!
)
END1
mb::_split( qr #comment
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 961
mb::split( m #comment
!1!
)
END1
mb::_split( qr #comment
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 962
mb::split( qr #comment
!1!
)
END1
mb::_split( qr #comment
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 963
split( #comment1
m #comment2
!1!
)
END1
mb::_split( #comment1
qr #comment2
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 964
split( #comment1
qr #comment2
!1!
)
END1
mb::_split( #comment1
qr #comment2
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 965
mb::split( #comment1
m #comment2
!1!
)
END1
mb::_split( #comment1
qr #comment2
{@{[qr !1!m ]}}
)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 966
mb::split( #comment1
qr #comment2
!1!
)
END1
mb::_split( #comment1
qr #comment2
{@{[qr !1!m ]}}
)
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
