#!/usr/bin/perl
######################################################################
# eg/ur/mb_tr.pl - mb::tr ke sath character-unit transliteration
#
# Yeh misal kya dikhati hai:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) poore multibyte CHARACTER
#   ki transliteration karta hai. /r ke baghair yeh apne pehle argument
#   ko usi jagah edit karta hai aur count wapas deta hai; /r ke sath yeh
#   nateeja wapas deta hai aur argument ko chhedta nahin.
#
# CORE se kya farq hai:
#   CORE tr/// octet-dar-octet kaam karta hai, is liye yeh kisi DAMEMOJI
#   ko kharab kar sakta hai -- aisa do-byte character jis ka DUSRA byte
#   ek ASCII metacharacter ho, misalan So(\x83\x5C), jis ka aakhri byte
#   \x5C backslash hai. \x5C par CORE tr us aakhri byte par lagega;
#   mb::tr So ko ek character ke taur par dekhta hai aur use chhodta hai.
#
# Note: mb::tr mein hyphen range (a-z) sirf US-ASCII siron ke liye phailti
# hai; SEARCH mein multibyte characters ko ek-ek kar ke list karna hota
# hai (bilkul waise jaise transpiler kisi MBCS tr/// ko phailata hai).
#
# Source US-ASCII hai; multibyte data \xHH byte escape istemal karta hai.
#
#     perl eg/ur/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS mein full-width digits: 0(\x82\x4F) .. 9(\x82\x58). SEARCH sabhi
# das full-width digits ko poore character ke taur par list karta hai;
# REPLACE US-ASCII range "0-9" hai (ek ASCII hyphen range, jise mb::tr phailata hai).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Full-width "1" "3" "6" -> half-width "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI ki hifazat. String A So(\x83\x5C) B hai. Backslash byte \x5C ko
# target karne wala CORE tr character ko kharab karta hai; mb::tr, jo sirf
# ASCII letters ko map karta hai, So ko salamat rakhta hai.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr So ke aakhri byte par lagta hai
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r modifier: non-destructive, transliterate ki hui copy wapas deta hai.
$keep = "\x82\x50\x82\x51";                 # full-width 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
