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
__END__
END1
__END__
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
__DATA__
END1
__DATA__
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
=pod
=cut

END1
=pod
=cut

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
;
END1
;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
()
END1
()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
{}
END1
{}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
[]
END1
[]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
(())
END1
(())
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
((()))
END1
((()))
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
{{}}
END1
{{}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
{{{}}}
END1
{{{}}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
[[]]
END1
[[]]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
[[[]]]
END1
[[[]]]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
({})
END1
({})
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
([])
END1
([])
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
{()}
END1
{()}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
{[]}
END1
{[]}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
[()]
END1
[()]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
[{}]
END1
[{}]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
0x0123456789_ABCDEF_abcdef
END1
0x0123456789_ABCDEF_abcdef
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
0b0_1
END1
0b0_1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
0
END1
0
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
0123456_7
END1
0123456_7
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
1
END1
1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
2
END1
2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
3
END1
3
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
4
END1
4
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
5
END1
5
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
6
END1
6
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
7
END1
7
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
8
END1
8
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
9
END1
9
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
12345678_9E012345678_9
END1
12345678_9E012345678_9
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
12345678_9e012345678_9
END1
12345678_9e012345678_9
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
$a %= 1
END1
$a %= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
$a % 1
END1
$a % 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
$a &&= 1
END1
$a &&= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
$a && 1
END1
$a && 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
$a &.= 'A'
END1
$a &.= 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
$a &. 'A'
END1
$a &. 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
$a &= 1
END1
$a &= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
$a & 1
END1
$a & 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
$a **= 1
END1
$a **= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
$a ** 1
END1
$a ** 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
$a *= 1
END1
$a *= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
$a * 1
END1
$a * 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
$a ... 2
END1
$a ... 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
$a .. 2
END1
$a .. 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
$a .= 'A'
END1
$a .= 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
$a . 'A'
END1
$a . 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
$a //= 1
END1
$a //= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
$a // 1
END1
$a // 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
$a /= 1
END1
$a /= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
$a / 1
END1
$a / 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
$a <=> 1
END1
$a <=> 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
$a << 1
END1
$a << 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
$a <= 1
END1
$a <= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
$a < 1
END1
$a < 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
$a ? 1 : 2
END1
$a ? 1 : 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
-A
END1
-A
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
-S
END1
-S
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
-O
END1
-O
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
-R
END1
-R
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 64
-W
END1
-W
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 65
-X
END1
-X
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 66
-b
END1
-b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 67
-c
END1
-c
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 68
-g
END1
-g
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 69
-k
END1
-k
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 70
-l
END1
-l
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 71
-o
END1
-o
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 72
-p
END1
-p
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 73
-t
END1
-t
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 74
-u
END1
-u
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 75
-B
END1
mb::_B
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 76
-C
END1
mb::_C
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 77
-M
END1
mb::_M
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 78
-T
END1
mb::_T
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 79
-d
END1
mb::_d
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 80
-e
END1
mb::_e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 81
-f
END1
mb::_f
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 82
-r
END1
mb::_r
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 83
-s
END1
mb::_s
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 84
-w
END1
mb::_w
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 85
-x
END1
mb::_x
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 86
-z
END1
mb::_z
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 87
...
END1
...
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 88
$a != 1
END1
$a != 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 89
$a !~ 1
END1
$a !~ 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 90
!$a
END1
!$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 91
$a++
END1
$a++
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 92
$a += 1
END1
$a += 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 93
$a + 1
END1
$a + 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 94
$a, 1
END1
$a, 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 95
$a--
END1
$a--
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 96
$a -= 1
END1
$a -= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 97
$a->import
END1
$a->import
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 98
$a - 1
END1
$a - 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 99
$a == 1
END1
$a == 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 100
$a => 1
END1
$a => 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 101
$a =~ 1
END1
$a =~ 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 102
$a = 1
END1
$a = 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 103
$a >> 1
END1
$a >> 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 104
$a >= 1
END1
$a >= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 105
$a > 1
END1
$a > 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 106
\$a
END1
\$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 107
$a ^.= 'A'
END1
$a ^.= 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 108
$a ^. 'A'
END1
$a ^. 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 109
$a ^= 1
END1
$a ^= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 110
$a ^ 1
END1
$a ^ 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 111
$a and 1
END1
$a and 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 112
$a cmp 1
END1
$a cmp 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 113
$a eq 'A'
END1
$a eq 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 114
$a ge 'A'
END1
$a ge 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 115
$a gt 'A'
END1
$a gt 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 116
$a le 'A'
END1
$a le 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 117
$a lt 'A'
END1
$a lt 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 118
$a ne 'A'
END1
$a ne 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 119
not $a
END1
not $a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 120
$a or 1
END1
$a or 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 121
$a x 1
END1
$a x 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 122
$a x= 1
END1
$a x= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 123
$a xor 1
END1
$a xor 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 124
$a ||= 1
END1
$a ||= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 125
$a || 1
END1
$a || 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 126
$a |.= 'A'
END1
$a |.= 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 127
$a |. 'A'
END1
$a |. 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 128
$a |= 1
END1
$a |= 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 129
$a | 1
END1
$a | 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 130
$a ~~ 1
END1
$a ~~ 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 131
$a ~. 'A'
END1
$a ~. 'A'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 132
$a ~= /1/
END1
$a ~= m{\G${mb::_anchor}@{[qr/1/ ]}@{[mb::_m_passed()]}}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 133
$a ~ 1
END1
$a ~ 1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 134
$`
END1
mb::_PREMATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 135
${`}
END1
mb::_PREMATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 136
$PREMATCH
END1
mb::_PREMATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 137
${PREMATCH}
END1
mb::_PREMATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 138
${^PREMATCH}
END1
mb::_PREMATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 139
$&
END1
mb::_MATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 140
${&}
END1
mb::_MATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 141
$MATCH
END1
mb::_MATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 142
${MATCH}
END1
mb::_MATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 143
${^MATCH}
END1
mb::_MATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 144
$0
END1
$0
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 145
$1
END1
mb::_CAPTURE(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 146
$2
END1
mb::_CAPTURE(2)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 147
$3
END1
mb::_CAPTURE(3)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 148
@{^CAPTURE}
END1
mb::_CAPTURE()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 149
@{^CAPTURE}[0]
END1
mb::_CAPTURE()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 150
@{^CAPTURE}[0,1,2]
END1
mb::_CAPTURE()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 151
${^CAPTURE}[0]
END1
mb::_CAPTURE(0+1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 152
${^CAPTURE}[1]
END1
mb::_CAPTURE(1+1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 153
${^CAPTURE}[2]
END1
mb::_CAPTURE(2+1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 154
@-
END1
mb::_LAST_MATCH_START()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 155
@-[0]
END1
mb::_LAST_MATCH_START()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 156
@-[0,1,2]
END1
mb::_LAST_MATCH_START()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 157
@LAST_MATCH_START
END1
mb::_LAST_MATCH_START()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 158
@LAST_MATCH_START[0]
END1
mb::_LAST_MATCH_START()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 159
@LAST_MATCH_START[0,1,2]
END1
mb::_LAST_MATCH_START()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 160
@{LAST_MATCH_START}
END1
mb::_LAST_MATCH_START()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 161
@{LAST_MATCH_START}[0]
END1
mb::_LAST_MATCH_START()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 162
@{LAST_MATCH_START}[0,1,2]
END1
mb::_LAST_MATCH_START()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 163
@{^LAST_MATCH_START}
END1
mb::_LAST_MATCH_START()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 164
@{^LAST_MATCH_START}[0]
END1
mb::_LAST_MATCH_START()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 165
@{^LAST_MATCH_START}[0,1,2]
END1
mb::_LAST_MATCH_START()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 166
$-[1]
END1
mb::_LAST_MATCH_START(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 167
$LAST_MATCH_START[1]
END1
mb::_LAST_MATCH_START(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 168
${LAST_MATCH_START}[1]
END1
mb::_LAST_MATCH_START(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 169
${^LAST_MATCH_START}[1]
END1
mb::_LAST_MATCH_START(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 170
@+
END1
mb::_LAST_MATCH_END()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 171
@+[0]
END1
mb::_LAST_MATCH_END()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 172
@+[0,1,2]
END1
mb::_LAST_MATCH_END()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 173
@LAST_MATCH_END
END1
mb::_LAST_MATCH_END()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 174
@LAST_MATCH_END[0]
END1
mb::_LAST_MATCH_END()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 175
@LAST_MATCH_END[0,1,2]
END1
mb::_LAST_MATCH_END()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 176
@{LAST_MATCH_END}
END1
mb::_LAST_MATCH_END()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 177
@{LAST_MATCH_END}[0]
END1
mb::_LAST_MATCH_END()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 178
@{LAST_MATCH_END}[0,1,2]
END1
mb::_LAST_MATCH_END()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 179
@{^LAST_MATCH_END}
END1
mb::_LAST_MATCH_END()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 180
@{^LAST_MATCH_END}[0]
END1
mb::_LAST_MATCH_END()[0]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 181
@{^LAST_MATCH_END}[0,1,2]
END1
mb::_LAST_MATCH_END()[0,1,2]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 182
$+[1]
END1
mb::_LAST_MATCH_END(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 183
$LAST_MATCH_END[1]
END1
mb::_LAST_MATCH_END(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 184
${LAST_MATCH_END}[1]
END1
mb::_LAST_MATCH_END(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 185
${^LAST_MATCH_END}[1]
END1
mb::_LAST_MATCH_END(1)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 186
mb::do {1}
END1
do {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 187
mb::eval {1}
END1
eval {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 188
$#{1}
END1
$#{1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 189
${$a}
END1
${$a}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 190
@{$a}
END1
@{$a}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 191
%{$a}
END1
%{$a}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 192
&{$a}
END1
&{$a}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 193
*{$a}
END1
*{$a}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 194
do {1}
END1
do {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 195
CORE::do {1}
END1
CORE::do {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 196
eval {1}
END1
eval {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 197
CORE::eval {1}
END1
CORE::eval {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 198
sub {1}
END1
sub {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 199
$#a1
END1
$#a1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 200
$#a1'b2
END1
$#a1'b2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 201
$#a1::b2
END1
$#a1::b2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 202
$a
END1
$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 203
$$a
END1
$$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 204
$$$a
END1
$$$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 205
$a'b
END1
$a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 206
$a::b
END1
$a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 207
${a}
END1
${a}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 208
${1}
END1
${1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 209
$!
END1
$!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 210
$"
END1
$"
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 211
$#
END1
$#
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 212
$$
END1
$$
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 213
$%
END1
$%
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 214
$&
END1
mb::_MATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 215
$'
END1
$'
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 216
$(
END1
$(
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 217
$)
END1
$)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 218
$+
END1
$+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 219
$,
END1
$,
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 220
$-
END1
$-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 221
$.
END1
$.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 222
$/
END1
$/
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 223
$:
END1
$:
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 224
$;
END1
$;
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 225
$<
END1
$<
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 226
$=
END1
$=
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 227
$>
END1
$>
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 228
$?
END1
$?
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 229
$@
END1
$@
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 230
$[
END1
$[
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 231
$\
END1
$\
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 232
$]
END1
$]
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 233
$^
END1
$^
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 234
$_
END1
$_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 235
$`
END1
mb::_PREMATCH()
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 236
$|
END1
$|
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 237
$~
END1
$~
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 238
$a++
END1
$a++
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 239
$a--
END1
$a--
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 240
@a
END1
@a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 241
@a'b
END1
@a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 242
@a::b
END1
@a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 243
@_
END1
@_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 244
@$a
END1
@$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 245
@$a'b
END1
@$a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 246
@$a'b
END1
@$a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 247
@$a::b
END1
@$a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 248
%a
END1
%a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 249
%a'b
END1
%a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 250
%a::b
END1
%a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 251
%!
END1
%!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 252
%+
END1
%+
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 253
%-
END1
%-
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 254
@!
END1
@!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 255
$!
END1
$!
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 256
%$a
END1
%$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 257
%$a'b
END1
%$a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 258
%$a::b
END1
%$a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 259
&a
END1
&a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 260
&a'b
END1
&a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 261
&a::b
END1
&a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 262
&$a
END1
&$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 263
&$a'b
END1
&$a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 264
&$a::b
END1
&$a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 265
*a
END1
*a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 266
*a'b
END1
*a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 267
*a::b
END1
*a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 268
*$a
END1
*$a
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 269
*$a'b
END1
*$a'b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 270
*$a::b
END1
*$a::b
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 271
#comment: At here, mb.pm has 2-quotes and 3-quotes part, but I test by other test scripts.
END1
#comment: At here, mb.pm has 2-quotes and 3-quotes part, but I test by other test scripts.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 272
<<~A
A

END1
<<~A

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 273
<<~\A
A

END1
<<~\A
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 274
<<~'A'
A

END1
<<~'A'
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 275
<<~"A"
A

END1
<<~"A"

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 276
<<~`A`
A

END1
<<~`A`

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 277
<<~	'A'
A

END1
<<~	'A'
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 278
<<~	"A"
A

END1
<<~	"A"

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 279
<<~	`A`
A

END1
<<~	`A`

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 280
<<~ 'A'
A

END1
<<~ 'A'
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 281
<<~ "A"
A

END1
<<~ "A"

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 282
<<~ `A`
A

END1
<<~ `A`

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 283
<<A
A

END1
<<A

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 284
<<\A
A

END1
<<\A
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 285
<<'A'
A

END1
<<'A'
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 286
<<"A"
A

END1
<<"A"

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 287
<<`A`
A

END1
<<`A`

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 288
<<	'A'
A

END1
<<	'A'
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 289
<<	"A"
A

END1
<<	"A"

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 290
<<	`A`
A

END1
<<	`A`

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 291
<< 'A'
A

END1
<< 'A'
A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 292
<< "A"
A

END1
<< "A"

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 293
<< `A`
A

END1
<< `A`

A

END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 294
sub subroutine {1}
END1
sub subroutine {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 295
sub sub'routine {1}
END1
sub sub'routine {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 296
sub sub::routine {1}
END1
sub sub::routine {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 297
sub subroutine () {1}
END1
sub subroutine () {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 298
sub sub'routine () {1}
END1
sub sub'routine () {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 299
sub sub::routine () {1}
END1
sub sub::routine () {1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 300
while(<<>>){1}
END1
while(<<>>){1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 301
while(<${file}>){1}
END1
while(<${file}>){1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 302
while(<$file>){1}
END1
while(<$file>){1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 303
while(<FILE>){1}
END1
while(<FILE>){1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 304
while(<file*glob>){1}
END1
while(<file*glob>){1}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 305
1 while(<<>>)
END1
1 while(<<>>)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 306
1 while(<${file}>)
END1
1 while(<${file}>)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 307
1 while(<$file>)
END1
1 while(<$file>)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 308
1 while(<FILE>)
END1
1 while(<FILE>)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 309
1 while(<file*glob>)
END1
1 while(<file*glob>)
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 310
if(1){2}
END1
if(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 311
if(1){2}elsif(3){4}
END1
if(1){2}elsif(3){4}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 312
unless(1){2}
END1
unless(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 313
while(1){2}
END1
while(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 314
until(1){2}
END1
until(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 315
given(1){2}
END1
given(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 316
when(1){2}
END1
when(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 317
if(1){2}else{3}
END1
if(1){2}else{3}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 318
1 if 2
END1
1 if 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 319
1 unless 2
END1
1 unless 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 320
1 while 2
END1
1 while 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 321
1 until 2
END1
1 until 2
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 322
foreach my $i (1){2}
END1
foreach my $i (1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 323
for my $i (1){2}
END1
for my $i (1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 324
foreach $i (1){2}
END1
foreach $i (1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 325
for $i (1){2}
END1
for $i (1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 326
foreach(1){2}
END1
foreach(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 327
for(1){2}
END1
for(1){2}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 328
foreach(1;2;3){4}
END1
foreach(1;2;3){4}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 329
for(1;2;3){4}
END1
for(1;2;3){4}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 330
#comment2 : At here, mb.pm has split part as 2-quotes, but I test by other test scripts.
END1
#comment2 : At here, mb.pm has split part as 2-quotes, but I test by other test scripts.
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 331
chop
END1
chop
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 332
lc
END1
mb::lc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 333
lcfirst
END1
mb::lcfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 334
uc
END1
mb::uc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 335
ucfirst
END1
mb::ucfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 336
index
END1
index
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 337
rindex
END1
rindex
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 338
chop
END1
chop
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 339
chr
END1
chr
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 340
do
END1
mb::do
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 341
eval
END1
mb::eval
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 342
getc
END1
getc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 343
mb::index_byte
END1
mb::index_byte
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 344
lc
END1
mb::lc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 345
lcfirst
END1
mb::lcfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 346
length
END1
length
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 347
ord
END1
ord
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 348
require
END1
mb::require
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 349
reverse
END1
reverse
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 350
mb::rindex_byte
END1
mb::rindex_byte
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 351
substr
END1
substr
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 352
uc
END1
mb::uc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 353
ucfirst
END1
mb::ucfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 354
CORE::chop
END1
CORE::chop
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 355
CORE::chr
END1
CORE::chr
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 356
CORE::do
END1
CORE::do
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 357
CORE::eval
END1
CORE::eval
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 358
CORE::getc
END1
CORE::getc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 359
CORE::index
END1
CORE::index
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 360
CORE::lc
END1
CORE::lc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 361
CORE::lcfirst
END1
CORE::lcfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 362
CORE::length
END1
CORE::length
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 363
CORE::ord
END1
CORE::ord
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 364
CORE::require
END1
CORE::require
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 365
CORE::reverse
END1
CORE::reverse
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 366
CORE::rindex
END1
CORE::rindex
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 367
CORE::substr
END1
CORE::substr
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 368
CORE::uc
END1
CORE::uc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 369
CORE::ucfirst
END1
CORE::ucfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 370
mb::chop
END1
mb::chop
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 371
mb::chr
END1
mb::chr
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 372
mb::do
END1
mb::do
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 373
mb::eval
END1
mb::eval
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 374
mb::getc
END1
mb::getc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 375
mb::index
END1
mb::index
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 376
mb::lc
END1
mb::lc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 377
mb::lcfirst
END1
mb::lcfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 378
mb::length
END1
mb::length
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 379
mb::ord
END1
mb::ord
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 380
mb::require
END1
mb::require
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 381
mb::reverse
END1
mb::reverse
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 382
mb::rindex
END1
mb::rindex
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 383
mb::substr
END1
mb::substr
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 384
mb::uc
END1
mb::uc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 385
mb::ucfirst
END1
mb::ucfirst
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 386
mb::index
END1
mb::index
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 387
mb::rindex
END1
mb::rindex
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 388
_
END1
_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 389
abs
END1
abs
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 390
chomp
END1
chomp
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 391
cos
END1
cos
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 392
exp
END1
exp
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 393
fc
END1
fc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 394
hex
END1
hex
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 395
int
END1
int
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 396
__LINE__
END1
__LINE__
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 397
log
END1
log
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 398
oct
END1
oct
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 399
pop
END1
pop
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 400
pos
END1
pos
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 401
quotemeta
END1
quotemeta
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 402
rand
END1
rand
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 403
rmdir
END1
rmdir
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 404
shift
END1
shift
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 405
sin
END1
sin
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 406
sqrt
END1
sqrt
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 407
tell
END1
tell
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 408
time
END1
time
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 409
umask
END1
umask
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 410
wantarray
END1
wantarray
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 411
CORE::_
END1
CORE::_
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 412
CORE::abs
END1
CORE::abs
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 413
CORE::chomp
END1
CORE::chomp
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 414
CORE::cos
END1
CORE::cos
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 415
CORE::exp
END1
CORE::exp
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 416
CORE::fc
END1
CORE::fc
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 417
CORE::hex
END1
CORE::hex
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 418
CORE::int
END1
CORE::int
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 419
CORE::__LINE__
END1
CORE::__LINE__
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 420
CORE::log
END1
CORE::log
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 421
CORE::oct
END1
CORE::oct
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 422
CORE::pop
END1
CORE::pop
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 423
CORE::pos
END1
CORE::pos
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 424
CORE::quotemeta
END1
CORE::quotemeta
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 425
CORE::rand
END1
CORE::rand
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 426
CORE::rmdir
END1
CORE::rmdir
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 427
CORE::shift
END1
CORE::shift
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 428
CORE::sin
END1
CORE::sin
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 429
CORE::sqrt
END1
CORE::sqrt
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 430
CORE::tell
END1
CORE::tell
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 431
CORE::time
END1
CORE::time
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 432
CORE::umask
END1
CORE::umask
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 433
CORE::wantarray
END1
CORE::wantarray
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 434
chdir
END1
mb::_chdir
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 435
glob
END1
glob
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 436
dosglob
END1
dosglob
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 437
lstat
END1
mb::_lstat
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 438
opendir
END1
mb::_opendir
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 439
stat
END1
mb::_stat
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 440
unlink
END1
mb::_unlink
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 441
A
END1
A
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 442
A'B
END1
A'B
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 443
A::B
END1
A::B
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
