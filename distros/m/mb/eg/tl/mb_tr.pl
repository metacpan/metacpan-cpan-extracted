#!/usr/bin/perl
######################################################################
# eg/tl/mb_tr.pl - transliterasyon sa yunit ng karakter gamit ang mb::tr
#
# Ano ang ipinapakita:
#   Nagta-transliterate ang mb::tr(STRING, SEARCH, REPLACE [, MODIFIER])
#   ng buong multibyte na KARAKTER. Kapag walang /r, ine-edit nito ang
#   unang argumento sa lugar at ibinabalik ang bilang; kapag may /r,
#   ibinabalik nito ang resulta at hindi ginagalaw ang argumento.
#
# Pagkakaiba sa CORE:
#   Gumagana ang CORE tr/// nang octet-bawat-octet, kaya maaari nitong
#   sirain ang isang DAMEMOJI -- dalawang-byte na karakter na ang PANGALAWANG
#   byte ay isang ASCII metacharacter, hal. So(\x83\x5C), na ang huling byte
#   \x5C ay backslash. Tatamaan ng CORE tr sa \x5C ang huling byte na iyon;
#   nakikita ng mb::tr ang So bilang isang karakter at hindi ito ginagalaw.
#
# Tandaan: sa mb::tr, ang hyphen range (a-z) ay pinalalawak para lamang sa
# US-ASCII na dulo; ang mga multibyte na karakter sa SEARCH ay dapat
# ilista nang isa-isa (gaya mismo ng pagpapalawak ng transpiler sa isang
# MBCS na tr///).
#
# US-ASCII ang source; gumagamit ang multibyte data ng \xHH byte escape.
#
#     perl eg/tl/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width na digit sa Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58). Inililista
# ng SEARCH ang lahat ng sampung full-width na digit bilang buong
# karakter; ang REPLACE ay ang US-ASCII na range na "0-9" (isang ASCII
# hyphen range na pinalalawak ng mb::tr).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Full-width na "1" "3" "6" -> half-width na "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# Kaligtasan ng DAMEMOJI. Ang string ay A So(\x83\x5C) B. Sinisira ng CORE
# tr na tumatarget sa backslash byte \x5C ang karakter; ang mb::tr, na
# nagma-map lamang ng ASCII na titik, ay hindi ginagalaw ang So.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # tinatamaan ng CORE tr ang huling byte ng So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r modifier: non-destructive, ibinabalik ang na-transliterate na kopya.
$keep = "\x82\x50\x82\x51";                 # full-width na 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
