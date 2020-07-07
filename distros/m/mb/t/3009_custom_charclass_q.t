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
    sub { mb::eval(<<'END1'); }, # test no 1
'0' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 2
'1' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 3
'2' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 4
'3' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 5
'4' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 6
'5' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 7
'6' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 8
'7' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 9
'8' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 10
'9' =~ m'[\d]'
END1
    sub { mb::eval(<<'END1'); }, # test no 11
"\x09" =~ m'[\h]'
END1
    sub { mb::eval(<<'END1'); }, # test no 12
"\x20" =~ m'[\h]'
END1
    sub { mb::eval(<<'END1'); }, # test no 13
"\t" =~ m'[\s]'
END1
    sub { mb::eval(<<'END1'); }, # test no 14
"\n" =~ m'[\s]'
END1
    sub { mb::eval(<<'END1'); }, # test no 15
"\f" =~ m'[\s]'
END1
    sub { mb::eval(<<'END1'); }, # test no 16
"\r" =~ m'[\s]'
END1
    sub { mb::eval(<<'END1'); }, # test no 17
"\x20" =~ m'[\s]'
END1
    sub { mb::eval(<<'END1'); }, # test no 18
"\x0A" =~ m'[\v]'
END1
    sub { mb::eval(<<'END1'); }, # test no 19
"\x0B" =~ m'[\v]'
END1
    sub { mb::eval(<<'END1'); }, # test no 20
"\x0C" =~ m'[\v]'
END1
    sub { mb::eval(<<'END1'); }, # test no 21
"\x0D" =~ m'[\v]'
END1
    sub { mb::eval(<<'END1'); }, # test no 22
'A' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 23
'B' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 24
'C' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 25
'D' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 26
'E' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 27
'F' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 28
'G' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 29
'H' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 30
'I' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 31
'J' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 32
'K' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 33
'L' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 34
'M' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 35
'N' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 36
'O' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 37
'P' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 38
'Q' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 39
'R' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 40
'S' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 41
'T' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 42
'U' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 43
'V' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 44
'W' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 45
'X' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 46
'Y' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 47
'Z' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 48
'a' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 49
'b' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 50
'c' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 51
'd' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 52
'e' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 53
'f' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 54
'g' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 55
'h' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 56
'i' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 57
'j' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 58
'k' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 59
'l' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 60
'm' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 61
'n' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 62
'o' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 63
'p' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 64
'q' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 65
'r' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 66
's' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 67
't' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 68
'u' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 69
'v' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 70
'w' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 71
'x' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 72
'y' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 73
'z' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 74
'0' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 75
'1' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 76
'2' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 77
'3' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 78
'4' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 79
'5' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 80
'6' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 81
'7' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 82
'8' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 83
'9' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 84
'_' =~ m'[\w]'
END1
    sub { mb::eval(<<'END1'); }, # test no 85
'0' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 86
'1' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 87
'2' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 88
'3' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 89
'4' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 90
'5' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 91
'6' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 92
'7' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 93
'8' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 94
'9' !~ m'[\D]'
END1
    sub { mb::eval(<<'END1'); }, # test no 95
"\x09" !~ m'[\H]'
END1
    sub { mb::eval(<<'END1'); }, # test no 96
"\x20" !~ m'[\H]'
END1
    sub { mb::eval(<<'END1'); }, # test no 97
"\t" !~ m'[\S]'
END1
    sub { mb::eval(<<'END1'); }, # test no 98
"\n" !~ m'[\S]'
END1
    sub { mb::eval(<<'END1'); }, # test no 99
"\f" !~ m'[\S]'
END1
    sub { mb::eval(<<'END1'); }, # test no 100
"\r" !~ m'[\S]'
END1
    sub { mb::eval(<<'END1'); }, # test no 101
"\x20" !~ m'[\S]'
END1
    sub { mb::eval(<<'END1'); }, # test no 102
"\x0A" !~ m'[\V]'
END1
    sub { mb::eval(<<'END1'); }, # test no 103
"\x0B" !~ m'[\V]'
END1
    sub { mb::eval(<<'END1'); }, # test no 104
"\x0C" !~ m'[\V]'
END1
    sub { mb::eval(<<'END1'); }, # test no 105
"\x0D" !~ m'[\V]'
END1
    sub { mb::eval(<<'END1'); }, # test no 106
'A' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 107
'B' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 108
'C' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 109
'D' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 110
'E' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 111
'F' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 112
'G' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 113
'H' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 114
'I' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 115
'J' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 116
'K' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 117
'L' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 118
'M' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 119
'N' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 120
'O' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 121
'P' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 122
'Q' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 123
'R' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 124
'S' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 125
'T' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 126
'U' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 127
'V' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 128
'W' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 129
'X' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 130
'Y' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 131
'Z' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 132
'a' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 133
'b' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 134
'c' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 135
'd' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 136
'e' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 137
'f' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 138
'g' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 139
'h' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 140
'i' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 141
'j' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 142
'k' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 143
'l' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 144
'm' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 145
'n' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 146
'o' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 147
'p' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 148
'q' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 149
'r' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 150
's' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 151
't' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 152
'u' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 153
'v' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 154
'w' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 155
'x' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 156
'y' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 157
'z' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 158
'0' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 159
'1' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 160
'2' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 161
'3' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 162
'4' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 163
'5' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 164
'6' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 165
'7' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 166
'8' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 167
'9' !~ m'[\W]'
END1
    sub { mb::eval(<<'END1'); }, # test no 168
'_' !~ m'[\W]'
END1
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
