#!/usr/bin/perl
######################################################################
# eg/si/mb_tr.pl - mb::tr මගින් අක්ෂර-ඒකක transliteration
#
# පෙන්වන දේ:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) මගින් සම්පූර්ණ multibyte
#   අක්ෂර පරිවර්තනය කරයි. /r නැතුව පළමු argument එක ස්ථානයේම වෙනස්කර count
#   ලබාදෙයි; /r සමඟ result එක ලබාදී argument එක නොවෙනස්ව තබයි.
#
# CORE වලින් වෙනස:
#   CORE tr/// byte වශයෙන් ක්‍රියාකරයි, එ නිසා DAMEMOJI විනාශ කළ හැක —
#   දෙවන byte එක ASCII meta අකුරක් වන (උදා: So \x83\x5C, අග \x5C backslash).
#   mb::tr මගින් So අක්ෂර එකක් ලෙස දැක නොවෙනස්ව තබයි.
#
# සටහන: mb::tr හි hyphen range (a-z) US-ASCII කෙළවර සඳහා පමණක් විහිදේ;
# SEARCH හි multibyte අක්ෂර එකින් එක ලැයිස්තුගත කළ යුතුය.
#
# සටහන: source code සහ \xHH data US-ASCII ලෙසම තබයි; මෙම file එක UTF-8 වේ (comment පමණක් සිංහලෙන්).
#
#     perl eg/si/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH මගින් full-width ඉලක්කම් 10ම සම්පූර්ණ අක්ෂර ලෙස ලැයිස්තුගත කරයි;
# REPLACE යනු US-ASCII range "0-9" (mb::tr විහිදුවන ASCII hyphen range).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# full-width "1" "3" "6" -> half-width "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI ආරක්ෂාව. string එක A So(\x83\x5C) B. backslash byte \x5C ඉලක්ක
# කරන CORE tr අක්ෂරය විනාශ කරයි; mb::tr ASCII අකුරු පමණක් map කර So
# නොවෙනස්ව තබයි.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr මගින් So හි අග byte එකට වදියි
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r modifier: විනාශකාරී නොවේ, පරිවර්තිත පිටපත ලබාදෙයි.
$keep = "\x82\x50\x82\x51";                 # full-width 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
