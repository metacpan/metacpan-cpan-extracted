#!/usr/bin/perl
# $Id: 01-func.t,v 2.0 2003/05/22 18:19:11 dankogai Exp $
# 
# by Dan Kogai <dankogai@dan.co.jp>
# Originally as test.pl by:
# kakasi test program for kakasi v2.2.5 (Perl module v0.1)
#    Ken-ichi Hirose <kenzo-@tama.or.jp>
#

use strict;
use vars qw($seq $test %sample %wakachi %yomikata $allascii);
unshift @INC, 't'; # for MyTestUtils.pm
require MyTestUtils;
my $kakasi = "kakasi";
$seq = 1; 
$test = 34;
$| = 1;

sub do_test{
    my ($argv,$in,$exp,$process) = @_;
    my ($result);
    my (@argv) = split(' ',$argv);

    getopt_argv("kakasi",@argv);
    $result = do_kakasi("$in");
    close_kanwadict();

    ok (($result eq $exp) => $argv);
    return $result;
}

print "1..$test\n";
eval { require Text::Kakasi };
ok(!$@ =>  "use") and eval { Text::Kakasi->import(":all") };
$@ and warn $@;
ok((getopt_argv('kakasi','-w') == 0) =>  "getopt_argv()");
ok((do_kakasi("1") eq '1')           =>  "do_kakasi()");
ok((close_kanwadict() == 0)          =>  "close_kanwadict()");

do_test("-ieuc -osjis",$sample{'euc'},$sample{'sjis'});
do_test("-isjis -osjis"  ,$sample{'sjis'},$sample{'sjis'});
do_test("-inewjis -osjis"  ,$sample{'jis'},$sample{'sjis'});
do_test("-ieuc -onewjis",$sample{'euc'},$sample{'jis'});
do_test("-isjis -onewjis",$sample{'sjis'},$sample{'jis'});
do_test("-inewjis -onewjis",$sample{'jis'},$sample{'jis'});
do_test("-ieuc -oeuc",$sample{'euc'},$sample{'euc'});
do_test("-isjis -oeuc"   ,$sample{'sjis'},$sample{'euc'});
do_test("-inewjis -oeuc"   ,$sample{'jis'},$sample{'euc'});

do_test("-w -ieuc -osjis",$sample{'euc'},$wakachi{'sjis'});
do_test("-w -isjis -osjis"  ,$sample{'sjis'},$wakachi{'sjis'});
do_test("-w -inewjis -osjis"  ,$sample{'jis'},$wakachi{'sjis'});
do_test("-w -ieuc -onewjis",$sample{'euc'},$wakachi{'jis'});
do_test("-w -isjis -onewjis",$sample{'sjis'},$wakachi{'jis'});
do_test("-w -inewjis -onewjis",$sample{'jis'},$wakachi{'jis'});
do_test("-w -ieuc -oeuc",$sample{'euc'},$wakachi{'euc'});
do_test("-w -isjis -oeuc"   ,$sample{'sjis'},$wakachi{'euc'});
do_test("-w -inewjis -oeuc"   ,$sample{'jis'},$wakachi{'euc'});

do_test("-JH -p -f -s -ieuc -osjis",$sample{'euc'},$yomikata{'sjis'});
do_test("-JH -p -f -s -isjis -osjis"  ,$sample{'sjis'},$yomikata{'sjis'});
do_test("-JH -p -f -s -inewjis -osjis"  ,$sample{'jis'},$yomikata{'sjis'});
do_test("-JH -p -f -s -ieuc -onewjis",$sample{'euc'},$yomikata{'jis'});
do_test("-JH -p -f -s -isjis -onewjis",$sample{'sjis'},$yomikata{'jis'});
do_test("-JH -p -f -s -inewjis -onewjis",$sample{'jis'},$yomikata{'jis'});
do_test("-JH -p -f -s -ieuc -oeuc",$sample{'euc'},$yomikata{'euc'});
do_test("-JH -p -f -s -isjis -oeuc"   ,$sample{'sjis'},$yomikata{'euc'});
do_test("-JH -p -f -s -inewjis -oeuc"   ,$sample{'jis'},$yomikata{'euc'});

do_test("-Ha -Ja -Ea -Ka -ieuc -osjis",$sample{'euc'},$allascii);
do_test("-Ha -Ja -Ea -Ka -isjis -osjis"  ,$sample{'sjis'},$allascii);
do_test("-Ha -Ja -Ea -Ka -inewjis -osjis"  ,$sample{'jis'},$allascii);

exit;

# test for -f is not so simple.
# end

##### Master Test Data ##########################################
# begin 644 test.euc
# MI+.DSJ2_I-.DSZ'6:V%K87-I9F]R5VEN,S*AUZ3RI<"EIJ7SI>VAO*7)I+>D
# MQL2ZI*VDHJ3JI*RDR*2FI+2DMJ2DI-ZDN:&C"J2SI.RDSVMA:V%S:78R+C(N
# M-2ND[Z2KI,&]\:2MI/)C>6=W:6XL;6EN9W<S,J3'I;.E\Z71I:2EZZ3'I*VD
# MZPJDZ*2FI,NDMZ2_<&%T8VBD\J6SI?.ET:6DI>NTQ+:MI,[,M:2DROVDRZ3B
# MN\BDPZ3&Q+JDL:3KI.BDIE=I;F1O=W.DS@J\PKG4M\&\L*3+I+>DQJ3>I,BD
# MX:2_RJJDQZ2YH:,*NL>_M\C'I,^PRK*\I,Y796)086=E"CQ54DPZ:'1T<#HO
# M+W=W=RYT86UA+F]R+FIP+R4W16ME;GIO+2].86UA>G4O/@JDQ[CXLZNDMZ3&
# MI*2DWJ2YH:.ARKZPH:*DLZ3.I=JAO*6XI,_)K,W7I,NQ_J2XI,:YN;^WI+6D
# *[*3>I+FAHZ'+"@``
# `
# end
#############################################################
