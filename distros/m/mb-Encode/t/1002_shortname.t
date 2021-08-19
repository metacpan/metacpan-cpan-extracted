######################################################################
#
# 1002_shortname.t
#
# Copyright (c) 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb::Encode qw(
    to_big5       big5       by_big5
    to_big5hkscs  big5hkscs  by_big5hkscs
    to_cp932      cp932      by_cp932
    to_cp936      cp936      by_cp936
    to_cp949      cp949      by_cp949
    to_cp950      cp950      by_cp950
    to_eucjp      eucjp      by_eucjp
    to_gbk        gbk        by_gbk
    to_sjis       sjis       by_sjis
    to_uhc        uhc        by_uhc
);
use vars qw(@test);

@test = (
# 1
    sub { my $want="\xA8\xC8"; my $got=to_big5     ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xA8\xC8"; my $got=to_big5hkscs("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x98\xB1"; my $got=to_cp932    ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x81\x86"; my $got=to_cp936    ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xE4\xAC"; my $got=to_cp949    ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xA8\xC8"; my $got=to_cp950    ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xD0\xB3"; my $got=to_eucjp    ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x81\x86"; my $got=to_gbk      ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x98\xB1"; my $got=to_sjis     ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xE4\xAC"; my $got=to_uhc      ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },

# 11
    sub { my $want="\xA8\xC8"; my $got=big5        ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xA8\xC8"; my $got=big5hkscs   ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x98\xB1"; my $got=cp932       ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x81\x86"; my $got=cp936       ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xE4\xAC"; my $got=cp949       ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xA8\xC8"; my $got=cp950       ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xD0\xB3"; my $got=eucjp       ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x81\x86"; my $got=gbk         ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x98\xB1"; my $got=sjis        ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\xE4\xAC"; my $got=uhc         ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },

# 21
    sub { my $want="亞"; my $got=by_big5     ("\xA8\xC8"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_big5hkscs("\xA8\xC8"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_cp932    ("\x98\xB1"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_cp936    ("\x81\x86"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_cp949    ("\xE4\xAC"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_cp950    ("\xA8\xC8"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_eucjp    ("\xD0\xB3"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_gbk      ("\x81\x86"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_sjis     ("\x98\xB1"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=by_uhc      ("\xE4\xAC"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
#
);

if ($] < 5.008_001) {
    @test = (sub {1}) x scalar(@test);
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
