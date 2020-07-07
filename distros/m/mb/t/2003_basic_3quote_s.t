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
s!1!1!
END1
s{(\G${mb::_anchor})@{[qr!1! ]}@{[mb::_s_passed()]}}{$1 . qq !1!}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
s"1"1"
END1
s{(\G${mb::_anchor})@{[qr"1" ]}@{[mb::_s_passed()]}}{$1 . qq "1"}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
s$1$1$
END1
s{(\G${mb::_anchor})@{[qr$1$ ]}@{[mb::_s_passed()]}}{$1 . qq $1$}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
s%1%1%
END1
s{(\G${mb::_anchor})@{[qr%1% ]}@{[mb::_s_passed()]}}{$1 . qq %1%}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
s&1&1&
END1
s{(\G${mb::_anchor})@{[qr&1& ]}@{[mb::_s_passed()]}}{$1 . qq &1&}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
s'1'1'
END1
s{(\G${mb::_anchor})@{[qr'1' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
s)1)1)
END1
s{(\G${mb::_anchor})@{[qr)1) ]}@{[mb::_s_passed()]}}{$1 . qq )1)}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
s*1*1*
END1
s{(\G${mb::_anchor})@{[qr*1* ]}@{[mb::_s_passed()]}}{$1 . qq *1*}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
s+1+1+
END1
s{(\G${mb::_anchor})@{[qr+1+ ]}@{[mb::_s_passed()]}}{$1 . qq +1+}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
s,1,1,
END1
s{(\G${mb::_anchor})@{[qr,1, ]}@{[mb::_s_passed()]}}{$1 . qq ,1,}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 11
s-1-1-
END1
s{(\G${mb::_anchor})@{[qr-1- ]}@{[mb::_s_passed()]}}{$1 . qq -1-}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 12
s.1.1.
END1
s{(\G${mb::_anchor})@{[qr.1. ]}@{[mb::_s_passed()]}}{$1 . qq .1.}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 13
s/1/1/
END1
s{(\G${mb::_anchor})@{[qr/1/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 14
s:1:1:
END1
s{(\G${mb::_anchor})@{[qr`1` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 15
s;1;1;
END1
s{(\G${mb::_anchor})@{[qr;1; ]}@{[mb::_s_passed()]}}{$1 . qq ;1;}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 16
s=1=1=
END1
s{(\G${mb::_anchor})@{[qr=1= ]}@{[mb::_s_passed()]}}{$1 . qq =1=}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 17
s>1>1>
END1
s{(\G${mb::_anchor})@{[qr>1> ]}@{[mb::_s_passed()]}}{$1 . qq >1>}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 18
s?1?1?
END1
s{(\G${mb::_anchor})@{[qr?1? ]}@{[mb::_s_passed()]}}{$1 . qq ?1?}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 19
s@1@1@
END1
s{(\G${mb::_anchor})@{[qr`1` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 20
s\1\1\
END1
s{(\G${mb::_anchor})@{[qr\1\ ]}@{[mb::_s_passed()]}}{$1 . qq \1\}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 21
s]1]1]
END1
s{(\G${mb::_anchor})@{[qr]1] ]}@{[mb::_s_passed()]}}{$1 . qq ]1]}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 22
s^1^1^
END1
s{(\G${mb::_anchor})@{[qr^1^ ]}@{[mb::_s_passed()]}}{$1 . qq ^1^}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 23
s`1`1`
END1
s{(\G${mb::_anchor})@{[qr`1` ]}@{[mb::_s_passed()]}}{$1 . qq `1`}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 24
s|1|1|
END1
s{(\G${mb::_anchor})@{[qr|1| ]}@{[mb::_s_passed()]}}{$1 . qq |1|}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 25
s}1}1}
END1
s{(\G${mb::_anchor})@{[qr}1} ]}@{[mb::_s_passed()]}}{$1 . qq }1}}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 26
s~1~1~
END1
s{(\G${mb::_anchor})@{[qr~1~ ]}@{[mb::_s_passed()]}}{$1 . qq ~1~}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 27
s !1!1!
END1
s {(\G${mb::_anchor})@{[qr !1! ]}@{[mb::_s_passed()]}}{$1 . qq !1!}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 28
s "1"1"
END1
s {(\G${mb::_anchor})@{[qr "1" ]}@{[mb::_s_passed()]}}{$1 . qq "1"}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 29
s $1$1$
END1
s {(\G${mb::_anchor})@{[qr $1$ ]}@{[mb::_s_passed()]}}{$1 . qq $1$}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 30
s %1%1%
END1
s {(\G${mb::_anchor})@{[qr %1% ]}@{[mb::_s_passed()]}}{$1 . qq %1%}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 31
s &1&1&
END1
s {(\G${mb::_anchor})@{[qr &1& ]}@{[mb::_s_passed()]}}{$1 . qq &1&}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 32
s '1'1'
END1
s {(\G${mb::_anchor})@{[qr '1' ]}@{[mb::_s_passed()]}}{$1 . '1'}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 33
s )1)1)
END1
s {(\G${mb::_anchor})@{[qr )1) ]}@{[mb::_s_passed()]}}{$1 . qq )1)}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 34
s *1*1*
END1
s {(\G${mb::_anchor})@{[qr *1* ]}@{[mb::_s_passed()]}}{$1 . qq *1*}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 35
s +1+1+
END1
s {(\G${mb::_anchor})@{[qr +1+ ]}@{[mb::_s_passed()]}}{$1 . qq +1+}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 36
s ,1,1,
END1
s {(\G${mb::_anchor})@{[qr ,1, ]}@{[mb::_s_passed()]}}{$1 . qq ,1,}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 37
s -1-1-
END1
s {(\G${mb::_anchor})@{[qr -1- ]}@{[mb::_s_passed()]}}{$1 . qq -1-}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 38
s .1.1.
END1
s {(\G${mb::_anchor})@{[qr .1. ]}@{[mb::_s_passed()]}}{$1 . qq .1.}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 39
s /1/1/
END1
s {(\G${mb::_anchor})@{[qr /1/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 40
s 21212
END1
s {(\G${mb::_anchor})@{[qr 212 ]}@{[mb::_s_passed()]}}{$1 . qq 212}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 41
s A1A1A
END1
s {(\G${mb::_anchor})@{[qr A1A ]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 42
s _1_1_
END1
s {(\G${mb::_anchor})@{[qr _1_ ]}@{[mb::_s_passed()]}}{$1 . qq _1_}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 43
s :1:1:
END1
s {(\G${mb::_anchor})@{[qr `1` ]}@{[mb::_s_passed()]}}{$1 . qq :1:}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 44
s ;1;1;
END1
s {(\G${mb::_anchor})@{[qr ;1; ]}@{[mb::_s_passed()]}}{$1 . qq ;1;}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 45
s =1=1=
END1
s {(\G${mb::_anchor})@{[qr =1= ]}@{[mb::_s_passed()]}}{$1 . qq =1=}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 46
s >1>1>
END1
s {(\G${mb::_anchor})@{[qr >1> ]}@{[mb::_s_passed()]}}{$1 . qq >1>}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 47
s ?1?1?
END1
s {(\G${mb::_anchor})@{[qr ?1? ]}@{[mb::_s_passed()]}}{$1 . qq ?1?}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 48
s @1@1@
END1
s {(\G${mb::_anchor})@{[qr `1` ]}@{[mb::_s_passed()]}}{$1 . qq @1@}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 49
s \1\1\
END1
s {(\G${mb::_anchor})@{[qr \1\ ]}@{[mb::_s_passed()]}}{$1 . qq \1\}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 50
s ]1]1]
END1
s {(\G${mb::_anchor})@{[qr ]1] ]}@{[mb::_s_passed()]}}{$1 . qq ]1]}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 51
s ^1^1^
END1
s {(\G${mb::_anchor})@{[qr ^1^ ]}@{[mb::_s_passed()]}}{$1 . qq ^1^}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 52
s `1`1`
END1
s {(\G${mb::_anchor})@{[qr `1` ]}@{[mb::_s_passed()]}}{$1 . qq `1`}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 53
s |1|1|
END1
s {(\G${mb::_anchor})@{[qr |1| ]}@{[mb::_s_passed()]}}{$1 . qq |1|}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 54
s }1}1}
END1
s {(\G${mb::_anchor})@{[qr }1} ]}@{[mb::_s_passed()]}}{$1 . qq }1}}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 55
s ~1~1~
END1
s {(\G${mb::_anchor})@{[qr ~1~ ]}@{[mb::_s_passed()]}}{$1 . qq ~1~}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 56
s/1/1/
END1
s{(\G${mb::_anchor})@{[qr/1/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 57
s/1/1/e
END1
s{(\G${mb::_anchor})@{[qr/1/ ]}@{[mb::_s_passed()]}}{$1 . mb::eval q/1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 58
s/1/1/g
END1
s{(\G${mb::_anchor})@{[qr/1/ ]}@{[mb::_s_passed()]}}{$1 . qq /1/}eg
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 59
s/1/1/i
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/1/)]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 60
s/1/1/m
END1
s{(\G${mb::_anchor})@{[qr/1/m ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 61
s/1/1/o
END1
s{(\G${mb::_anchor})@{[qr/1/o ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 62
s/1/1/s
END1
s{(\G${mb::_anchor})@{[qr/1/s ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 63
s/1/1/x
END1
s{(\G${mb::_anchor})@{[qr/1/x ]}@{[mb::_s_passed()]}}{$1 . qq /1/}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 64
s/1/1/egimosx
END1
s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/1/mosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval q/1/}eg
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 65
s A1A1A
END1
s {(\G${mb::_anchor})@{[qr A1A ]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 66
s A1A1Ae
END1
s {(\G${mb::_anchor})@{[qr A1A ]}@{[mb::_s_passed()]}}{$1 . mb::eval qA1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 67
s A1A1Ag
END1
s {(\G${mb::_anchor})@{[qr A1A ]}@{[mb::_s_passed()]}}{$1 . qq A1A}eg
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 68
s A1A1Ai
END1
s {(\G${mb::_anchor})@{[mb::_ignorecase(qr A1A)]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 69
s A1A1Am
END1
s {(\G${mb::_anchor})@{[qr A1Am ]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 70
s A1A1Ao
END1
s {(\G${mb::_anchor})@{[qr A1Ao ]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 71
s A1A1As
END1
s {(\G${mb::_anchor})@{[qr A1As ]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 72
s A1A1Ax
END1
s {(\G${mb::_anchor})@{[qr A1Ax ]}@{[mb::_s_passed()]}}{$1 . qq A1A}e
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 73
s A1A1Aegimosx
END1
s {(\G${mb::_anchor})@{[mb::_ignorecase(qr A1Amosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval qA1A}eg
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
