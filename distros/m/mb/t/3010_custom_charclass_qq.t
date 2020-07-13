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
    sub { mb::eval(<<'END1'); }, # test no 1
'0' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 2
'1' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 3
'2' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 4
'3' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 5
'4' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 6
'5' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 7
'6' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 8
'7' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 9
'8' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 10
'9' =~ /[\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 11
"\x09" =~ /[\h]/
END1
    sub { mb::eval(<<'END1'); }, # test no 12
"\x20" =~ /[\h]/
END1
    sub { mb::eval(<<'END1'); }, # test no 13
"\t" =~ /[\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 14
"\n" =~ /[\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 15
"\f" =~ /[\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 16
"\r" =~ /[\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 17
"\x20" =~ /[\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 18
"\x0A" =~ /[\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 19
"\x0B" =~ /[\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 20
"\x0C" =~ /[\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 21
"\x0D" =~ /[\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 22
'A' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 23
'B' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 24
'C' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 25
'D' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 26
'E' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 27
'F' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 28
'G' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 29
'H' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 30
'I' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 31
'J' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 32
'K' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 33
'L' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 34
'M' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 35
'N' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 36
'O' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 37
'P' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 38
'Q' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 39
'R' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 40
'S' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 41
'T' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 42
'U' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 43
'V' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 44
'W' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 45
'X' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 46
'Y' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 47
'Z' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 48
'a' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 49
'b' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 50
'c' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 51
'd' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 52
'e' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 53
'f' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 54
'g' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 55
'h' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 56
'i' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 57
'j' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 58
'k' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 59
'l' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 60
'm' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 61
'n' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 62
'o' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 63
'p' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 64
'q' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 65
'r' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 66
's' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 67
't' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 68
'u' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 69
'v' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 70
'w' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 71
'x' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 72
'y' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 73
'z' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 74
'0' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 75
'1' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 76
'2' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 77
'3' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 78
'4' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 79
'5' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 80
'6' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 81
'7' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 82
'8' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 83
'9' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 84
'_' =~ /[\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 85
'0' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 86
'1' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 87
'2' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 88
'3' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 89
'4' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 90
'5' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 91
'6' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 92
'7' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 93
'8' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 94
'9' !~ /[\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 95
"\x09" !~ /[\H]/
END1
    sub { mb::eval(<<'END1'); }, # test no 96
"\x20" !~ /[\H]/
END1
    sub { mb::eval(<<'END1'); }, # test no 97
"\t" !~ /[\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 98
"\n" !~ /[\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 99
"\f" !~ /[\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 100
"\r" !~ /[\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 101
"\x20" !~ /[\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 102
"\x0A" !~ /[\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 103
"\x0B" !~ /[\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 104
"\x0C" !~ /[\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 105
"\x0D" !~ /[\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 106
'A' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 107
'B' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 108
'C' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 109
'D' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 110
'E' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 111
'F' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 112
'G' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 113
'H' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 114
'I' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 115
'J' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 116
'K' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 117
'L' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 118
'M' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 119
'N' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 120
'O' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 121
'P' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 122
'Q' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 123
'R' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 124
'S' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 125
'T' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 126
'U' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 127
'V' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 128
'W' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 129
'X' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 130
'Y' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 131
'Z' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 132
'a' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 133
'b' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 134
'c' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 135
'd' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 136
'e' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 137
'f' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 138
'g' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 139
'h' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 140
'i' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 141
'j' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 142
'k' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 143
'l' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 144
'm' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 145
'n' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 146
'o' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 147
'p' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 148
'q' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 149
'r' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 150
's' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 151
't' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 152
'u' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 153
'v' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 154
'w' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 155
'x' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 156
'y' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 157
'z' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 158
'0' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 159
'1' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 160
'2' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 161
'3' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 162
'4' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 163
'5' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 164
'6' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 165
'7' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 166
'8' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 167
'9' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 168
'_' !~ /[\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 169
'0' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 170
'1' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 171
'2' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 172
'3' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 173
'4' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 174
'5' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 175
'6' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 176
'7' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 177
'8' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 178
'9' !~ /[^\d]/
END1
    sub { mb::eval(<<'END1'); }, # test no 179
"\x09" !~ /[^\h]/
END1
    sub { mb::eval(<<'END1'); }, # test no 180
"\x20" !~ /[^\h]/
END1
    sub { mb::eval(<<'END1'); }, # test no 181
"\t" !~ /[^\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 182
"\n" !~ /[^\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 183
"\f" !~ /[^\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 184
"\r" !~ /[^\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 185
"\x20" !~ /[^\s]/
END1
    sub { mb::eval(<<'END1'); }, # test no 186
"\x0A" !~ /[^\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 187
"\x0B" !~ /[^\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 188
"\x0C" !~ /[^\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 189
"\x0D" !~ /[^\v]/
END1
    sub { mb::eval(<<'END1'); }, # test no 190
'A' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 191
'B' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 192
'C' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 193
'D' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 194
'E' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 195
'F' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 196
'G' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 197
'H' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 198
'I' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 199
'J' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 200
'K' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 201
'L' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 202
'M' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 203
'N' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 204
'O' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 205
'P' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 206
'Q' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 207
'R' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 208
'S' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 209
'T' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 210
'U' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 211
'V' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 212
'W' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 213
'X' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 214
'Y' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 215
'Z' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 216
'a' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 217
'b' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 218
'c' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 219
'd' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 220
'e' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 221
'f' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 223
'g' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 224
'h' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 225
'i' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 226
'j' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 227
'k' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 228
'l' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 229
'm' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 230
'n' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 231
'o' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 232
'p' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 233
'q' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 234
'r' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 235
's' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 236
't' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 237
'u' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 238
'v' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 239
'w' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 240
'x' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 241
'y' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 242
'z' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 243
'0' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 244
'1' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 245
'2' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 246
'3' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 247
'4' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 248
'5' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 249
'6' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 250
'7' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 251
'8' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 252
'9' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 253
'_' !~ /[^\w]/
END1
    sub { mb::eval(<<'END1'); }, # test no 254
'0' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 255
'1' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 256
'2' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 257
'3' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 258
'4' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 259
'5' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 260
'6' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 261
'7' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 262
'8' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 263
'9' =~ /[^\D]/
END1
    sub { mb::eval(<<'END1'); }, # test no 264
"\x09" =~ /[^\H]/
END1
    sub { mb::eval(<<'END1'); }, # test no 265
"\x20" =~ /[^\H]/
END1
    sub { mb::eval(<<'END1'); }, # test no 266
"\t" =~ /[^\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 267
"\n" =~ /[^\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 268
"\f" =~ /[^\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 269
"\r" =~ /[^\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 270
"\x20" =~ /[^\S]/
END1
    sub { mb::eval(<<'END1'); }, # test no 271
"\x0A" =~ /[^\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 272
"\x0B" =~ /[^\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 273
"\x0C" =~ /[^\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 274
"\x0D" =~ /[^\V]/
END1
    sub { mb::eval(<<'END1'); }, # test no 275
'A' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 276
'B' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 277
'C' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 278
'D' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 279
'E' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 280
'F' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 281
'G' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 282
'H' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 283
'I' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 284
'J' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 285
'K' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 286
'L' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 287
'M' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 288
'N' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 289
'O' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 290
'P' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 291
'Q' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 292
'R' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 293
'S' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 293
'T' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 294
'U' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 295
'V' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 296
'W' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 297
'X' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 298
'Y' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 299
'Z' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 300
'a' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 301
'b' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 302
'c' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 303
'd' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 304
'e' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 305
'f' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 306
'g' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 307
'h' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 308
'i' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 309
'j' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 310
'k' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 311
'l' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 312
'm' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 313
'n' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 314
'o' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 315
'p' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 316
'q' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 317
'r' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 318
's' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 319
't' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 320
'u' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 321
'v' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 322
'w' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 323
'x' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 324
'y' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 325
'z' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 326
'0' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 327
'1' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 328
'2' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 329
'3' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 330
'4' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 331
'5' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 332
'6' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 333
'7' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 334
'8' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 335
'9' =~ /[^\W]/
END1
    sub { mb::eval(<<'END1'); }, # test no 336
'_' =~ /[^\W]/
END1
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
