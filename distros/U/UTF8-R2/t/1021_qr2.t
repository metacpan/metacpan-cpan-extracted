# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AIllegal hex digit ignored at /                      ? return :
        /\AIllegal hexadecimal digit '\|' ignored at /         ? return :
        /\AIllegal hexadecimal digit '\{' ignored at /         ? return :
        /\AUnrecognized escape \\h passed through at /         ? return :
        /\AUnrecognized escape \\v passed through at /         ? return :
        /\AUnrecognized escape \\R passed through at /         ? return :
        /\AUnrecognized escape \\H passed through at /         ? return :
        /\AUnrecognized escape \\V passed through at /         ? return :
        /\A\\C is deprecated in regex; marked by <-- HERE in / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { ("あい12ABC" =~ UTF8::R2::qr(qr/./))                         },
    sub { ("あい12ABC" =~ UTF8::R2::qr(qr/./))      && ($& eq 'あ')    },
    sub { ("あい12ABC" =~ UTF8::R2::qr(qr/.{2}/))   && ($& eq 'あい')  },
    sub { ("あい12ABC" =~ UTF8::R2::qr(qr/.{2}/))   && ($` eq '')      },
    sub { ("あい12ABC" =~ UTF8::R2::qr(qr/.{2}/))   && ($' eq '12ABC') },
    sub { ("あい12ABC" =~ UTF8::R2::qr(qr/(.{3})/)) && ($1 eq 'あい1') },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { not ("あい12ABC" !~ UTF8::R2::qr(qr/./))                         },
    sub { not ("あい12ABC" !~ UTF8::R2::qr(qr/./))      && ($& eq 'あ')    },
    sub { not ("あい12ABC" !~ UTF8::R2::qr(qr/.{2}/))   && ($& eq 'あい')  },
    sub { not ("あい12ABC" !~ UTF8::R2::qr(qr/.{2}/))   && ($` eq '')      },
    sub { not ("あい12ABC" !~ UTF8::R2::qr(qr/.{2}/))   && ($' eq '12ABC') },
    sub { not ("あい12ABC" !~ UTF8::R2::qr(qr/(.{3})/)) && ($1 eq 'あい1') },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { "0" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "1" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "2" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "3" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "4" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "5" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "6" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "7" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "8" =~ UTF8::R2::qr(qr/[\d]/) },
    sub { "9" =~ UTF8::R2::qr(qr/[\d]/) },
# 31
    sub { not ("A" =~ UTF8::R2::qr(qr/[\d]/)) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { "A" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "B" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "C" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "D" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "E" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "F" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "G" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "H" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "I" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "J" =~ UTF8::R2::qr(qr/[\w]/) },
# 51
    sub { "K" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "L" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "M" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "N" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "O" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "P" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "Q" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "R" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "S" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "T" =~ UTF8::R2::qr(qr/[\w]/) },
# 61
    sub { "U" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "V" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "W" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "X" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "Y" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "Z" =~ UTF8::R2::qr(qr/[\w]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 71
    sub { "a" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "b" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "c" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "d" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "e" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "f" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "g" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "h" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "i" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "j" =~ UTF8::R2::qr(qr/[\w]/) },
# 81
    sub { "k" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "l" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "m" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "n" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "o" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "p" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "q" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "r" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "s" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "t" =~ UTF8::R2::qr(qr/[\w]/) },
# 91
    sub { "u" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "v" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "w" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "x" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "y" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "z" =~ UTF8::R2::qr(qr/[\w]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 101
    sub { "0" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "1" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "2" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "3" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "4" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "5" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "6" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "7" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "8" =~ UTF8::R2::qr(qr/[\w]/) },
    sub { "9" =~ UTF8::R2::qr(qr/[\w]/) },
# 111
    sub { "_" =~ UTF8::R2::qr(qr/[\w]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 121
    sub { not ("あ" =~ UTF8::R2::qr(qr/[\w]/)) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 131
    sub {     ("\t"   =~ UTF8::R2::qr(qr/[\s]/)) },
    sub {     ("\n"   =~ UTF8::R2::qr(qr/[\s]/)) },
    sub { not ("\x0B" =~ UTF8::R2::qr(qr/[\s]/)) },
    sub {     ("\f"   =~ UTF8::R2::qr(qr/[\s]/)) },
    sub {     ("\r"   =~ UTF8::R2::qr(qr/[\s]/)) },
    sub {     ("\x20" =~ UTF8::R2::qr(qr/[\s]/)) },
    sub { not ("\x85" =~ UTF8::R2::qr(qr/[\s]/)) },
    sub { not ("\xA0" =~ UTF8::R2::qr(qr/[\s]/)) },
    sub {1},
    sub {1},
# 141
    sub { ($] < 5.010) or     ("\t"   =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or not ("\n"   =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or not ("\x0B" =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or not ("\f"   =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or not ("\r"   =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or     ("\x20" =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or not ("\x85" =~ UTF8::R2::qr(qr/[\h]/)) },
    sub { ($] < 5.010) or not ("\xA0" =~ UTF8::R2::qr(qr/[\h]/)) },
    sub {1},
    sub {1},
# 151
    sub { ($] < 5.010) or not ("\t"   =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or     ("\n"   =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or     ("\x0B" =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or     ("\f"   =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or     ("\r"   =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or not ("\x20" =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or not ("\x85" =~ UTF8::R2::qr(qr/[\v]/)) },
    sub { ($] < 5.010) or not ("\xA0" =~ UTF8::R2::qr(qr/[\v]/)) },
    sub {1},
    sub {1},
# 161
    sub { 1 or eval q{ not (""   =~ UTF8::R2::qr(qr/[\C]/))                                           }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/[\C]/))                                           }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/[\C]/))   && ($& eq "\xE3")                       }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/[\C]/))   && ($& eq "\xE3") && ($' eq "\x81\x82") }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/([\C])/))                                         }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/([\C])/)) && ($1 eq "\xE3")                       }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/([\C])/)) && ($1 eq "\xE3") && ($' eq "\x81\x82") }},
    sub {1},
    sub {1},
    sub {1},
# 171
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/[\N]/))                   }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/[\N]/))   && ($& eq 'あ') }},
    sub { 1 or eval q{     ("あ" =~ UTF8::R2::qr(qr/([\N])/)) && ($1 eq 'あ') }},
    sub { 1 or eval q{ not ("\n" =~ UTF8::R2::qr(qr/[\N]/))                   }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 181
    sub { 1 or eval q{ not ("あ"   =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{     ("\r\n" =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{     ("\r\n" =~ UTF8::R2::qr(qr/[\R]/))   && ($& eq "\r\n") }},
    sub { 1 or eval q{     ("\r\n" =~ UTF8::R2::qr(qr/([\R])/)) && ($1 eq "\r\n") }},
    sub { 1 or eval q{ not ("\t"   =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{     ("\n"   =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{     ("\x0B" =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{     ("\f"   =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{     ("\r"   =~ UTF8::R2::qr(qr/[\R]/))                     }},
    sub { 1 or eval q{ not ("\x20" =~ UTF8::R2::qr(qr/[\R]/))                     }},
# 191
    sub { 1 or eval q{ not ("\x85" =~ UTF8::R2::qr(qr/[\R]/))   }},
    sub { 1 or eval q{ not ("\xA0" =~ UTF8::R2::qr(qr/[\R]/))   }},
    sub { 1 or eval q{ not ("\r\n" =~ UTF8::R2::qr(qr/[\R]\n/)) }},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 201
    sub { "0" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "1" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "2" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "3" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "4" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "5" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "6" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "7" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "8" !~ UTF8::R2::qr(qr/[\D]/) },
    sub { "9" !~ UTF8::R2::qr(qr/[\D]/) },
# 211
    sub { not ("A" !~ UTF8::R2::qr(qr/[\D]/)) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 221
    sub { "A" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "B" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "C" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "D" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "E" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "F" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "G" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "H" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "I" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "J" !~ UTF8::R2::qr(qr/[\W]/) },
# 231
    sub { "K" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "L" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "M" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "N" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "O" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "P" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "Q" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "R" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "S" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "T" !~ UTF8::R2::qr(qr/[\W]/) },
# 241
    sub { "U" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "V" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "W" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "X" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "Y" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "Z" !~ UTF8::R2::qr(qr/[\W]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 251
    sub { "a" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "b" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "c" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "d" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "e" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "f" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "g" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "h" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "i" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "j" !~ UTF8::R2::qr(qr/[\W]/) },
# 261
    sub { "k" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "l" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "m" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "n" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "o" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "p" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "q" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "r" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "s" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "t" !~ UTF8::R2::qr(qr/[\W]/) },
# 271
    sub { "u" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "v" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "w" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "x" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "y" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "z" !~ UTF8::R2::qr(qr/[\W]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 281
    sub { "0" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "1" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "2" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "3" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "4" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "5" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "6" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "7" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "8" !~ UTF8::R2::qr(qr/[\W]/) },
    sub { "9" !~ UTF8::R2::qr(qr/[\W]/) },
# 291
    sub { "_" !~ UTF8::R2::qr(qr/[\W]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 301
    sub { not ("あ" !~ UTF8::R2::qr(qr/[\W]/)) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 311
    sub {     ("\t"   !~ UTF8::R2::qr(qr/[\S]/)) },
    sub {     ("\n"   !~ UTF8::R2::qr(qr/[\S]/)) },
    sub { not ("\x0B" !~ UTF8::R2::qr(qr/[\S]/)) },
    sub {     ("\f"   !~ UTF8::R2::qr(qr/[\S]/)) },
    sub {     ("\r"   !~ UTF8::R2::qr(qr/[\S]/)) },
    sub {     ("\x20" !~ UTF8::R2::qr(qr/[\S]/)) },
    sub { not ("\x85" !~ UTF8::R2::qr(qr/[\S]/)) },
    sub { not ("\xA0" !~ UTF8::R2::qr(qr/[\S]/)) },
    sub {1},
    sub {1},
# 321
    sub { ($] < 5.010) or     ("\t"   !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or not ("\n"   !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or not ("\x0B" !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or not ("\f"   !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or not ("\r"   !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or     ("\x20" !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or not ("\x85" !~ UTF8::R2::qr(qr/[\H]/)) },
    sub { ($] < 5.010) or not ("\xA0" !~ UTF8::R2::qr(qr/[\H]/)) },
    sub {1},
    sub {1},
# 331
    sub { ($] < 5.010) or not ("\t"   !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or     ("\n"   !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or     ("\x0B" !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or     ("\f"   !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or     ("\r"   !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or not ("\x20" !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or not ("\x85" !~ UTF8::R2::qr(qr/[\V]/)) },
    sub { ($] < 5.010) or not ("\xA0" !~ UTF8::R2::qr(qr/[\V]/)) },
    sub {1},
    sub {1},
# 341
    sub { "\b" =~ UTF8::R2::qr(qr/[\b]/) },
    sub { "]"  =~ UTF8::R2::qr(qr/[\]]/) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 351
    sub {             ("あAいう12" =~ UTF8::R2::qr(qr/[いう]/))                      },
    sub {             ("あAいう12" =~ UTF8::R2::qr(qr/[いう]/))    && ($& eq 'い')   },
    sub {             ("あAいう12" =~ UTF8::R2::qr(qr/([いう])/))  && ($1 eq 'い')   },
    sub {             ("あAいう12" =~ UTF8::R2::qr(qr/[いう]+/))   && ($& eq 'いう') },
    sub {             ("あAいう12" =~ UTF8::R2::qr(qr/([いう]+)/)) && ($1 eq 'いう') },
    sub { my $i='い'; ("あAいう12" =~ UTF8::R2::qr(qr/[${i}う]/))  && ($& eq 'い')   },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 361
    sub {                       ("あAいう12" =~ UTF8::R2::qr(qr/[^いう]/))                     },
    sub { ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/[^いう]/))    && ($& eq 'あ')  },
    sub { ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/([^いう])/))  && ($1 eq 'あ')  },
    sub { ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/[^いう]+/))   && ($& eq 'あA') },
    sub { ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/([^いう]+)/)) && ($1 eq 'あA') },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 371
    sub {                               not ("あAいう12" =~ UTF8::R2::qr(qr/[えお]/))                    },
    sub {                                   ("あAいう12" =~ UTF8::R2::qr(qr/[^えお]/))                   },
    sub {             ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/[^えお]/))   && ($& eq 'あ') },
    sub {             ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/([^えお])/)) && ($1 eq 'あ') },
    sub { my $e='え'; ($] =~ /\A5\.006/) or ("あAいう12" =~ UTF8::R2::qr(qr/[^${e}お]/)) && ($& eq 'あ') },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 381
    sub { "\x00"             =~ UTF8::R2::qr(qr/[\x{00}]/)       },
    sub { "\x7F"             =~ UTF8::R2::qr(qr/[\x{7F}]/)       },
    sub { "\xC2\x80"         =~ UTF8::R2::qr(qr/[\x{C280}]/)     },
    sub { "\xDF\xBA"         =~ UTF8::R2::qr(qr/[\x{DFBA}]/)     },
    sub { "\xE0\xA0\x80"     =~ UTF8::R2::qr(qr/[\x{E0A080}]/)   },
    sub { "\xE0\xBF\x9A"     =~ UTF8::R2::qr(qr/[\x{E0BF9A}]/)   },
    sub { return 'SKIP'; }, # "\xF0\x90\x80\x80" =~ UTF8::R2::qr(qr/[\x{F0908080}]/) # avoid: Use of code point 0xF0908080 is not allowed; the permissible max is 0x7FFFFFFF
    sub { return 'SKIP'; }, # "\xF0\x90\xB9\xBE" =~ UTF8::R2::qr(qr/[\x{F090B9BE}]/) # avoid: Use of code point 0xF0908080 is not allowed; the permissible max is 0x7FFFFFFF
    sub {1},
    sub {1},
# 391
    sub { ($] < 5.008) or eval q{ "\x00"             =~ UTF8::R2::qr(qr/[\x{00}-\x{7F}]/)             } },
    sub { ($] < 5.008) or eval q{ "\x7F"             =~ UTF8::R2::qr(qr/[\x{00}-\x{7F}]/)             } },
    sub { ($] < 5.008) or eval q{ "\xC2\x80"         =~ UTF8::R2::qr(qr/[\x{C280}-\x{DFBA}]/)         } },
    sub { ($] < 5.008) or eval q{ "\xDF\xBA"         =~ UTF8::R2::qr(qr/[\x{C280}-\x{DFBA}]/)         } },
    sub { ($] < 5.008) or eval q{ "\xE0\xA0\x80"     =~ UTF8::R2::qr(qr/[\x{E0A080}-\x{E0BF9A}]/)     } },
    sub { ($] < 5.008) or eval q{ "\xE0\xBF\x9A"     =~ UTF8::R2::qr(qr/[\x{E0A080}-\x{E0BF9A}]/)     } },
    sub { return 'SKIP'; }, # "\xF0\x90\x80\x80" =~ UTF8::R2::qr(qr/[\x{F0908080}-\x{F090B9BE}]/) # avoid: Use of code point 0xF0908080 is not allowed; the permissible max is 0x7FFFFFFF
    sub { return 'SKIP'; }, # "\xF0\x90\xB9\xBE" =~ UTF8::R2::qr(qr/[\x{F0908080}-\x{F090B9BE}]/) # avoid: Use of code point 0xF0908080 is not allowed; the permissible max is 0x7FFFFFFF
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
