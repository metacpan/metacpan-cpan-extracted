#!/usr/bin/perl
######################################################################
# eg/en/mb_tr.pl - character-unit transliteration with mb::tr
#
# What this shows:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) transliterates whole
#   multibyte CHARACTERS. Without /r it edits its first argument in place
#   and returns the count; with /r it returns the result and leaves the
#   argument untouched.
#
# How it differs from CORE:
#   CORE tr/// works octet by octet, so it can corrupt a DAMEMOJI -- a
#   double-byte character whose SECOND byte is an ASCII metacharacter,
#   e.g. So(\x83\x5C), whose trailing byte \x5C is a backslash. A CORE
#   tr on \x5C would hit that trailing byte; mb::tr sees So as one
#   character and leaves it alone.
#
# Note: in mb::tr a hyphen range (a-z) is expanded for US-ASCII endpoints
# only; multibyte characters in SEARCH must be listed one by one (which
# is exactly how the transpiler expands an MBCS tr///).
#
# The source is US-ASCII; multibyte data uses \xHH byte escapes.
#
#     perl eg/en/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH lists all ten full-width digits as whole characters; REPLACE is
# the US-ASCII range "0-9" (an ASCII hyphen range, which mb::tr expands).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Full-width "1" "3" "6" -> half-width "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI safety. The string is A So(\x83\x5C) B. A CORE tr targeting the
# backslash byte \x5C corrupts the character; mb::tr, mapping only the
# ASCII letters, leaves So intact.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr hits the trailing byte of So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r modifier: non-destructive, returns the transliterated copy.
$keep = "\x82\x50\x82\x51";                 # full-width 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
