#!/usr/bin/perl
######################################################################
# eg/si/mb_split.pl - mb::split මගින් අක්ෂර මායිමේ බෙදීම
#
# පෙන්වන දේ:
#   mb::split('', EXPR) මගින් string එක සම්පූර්ණ multibyte අක්ෂර බවට
#   බෙදයි; mb::split(PATTERN, EXPR) මගින් MBCS delimiter එකෙන් බෙදයි,
#   අක්ෂරයක් ඇතුළත byte එකකට කිසිදා නොගැලපේ.
#
# CORE වලින් වෙනස:
#   CORE split(//) මගින් double-byte hiragana byte දෙකකට ඉරයි; mb::split
#   එය අක්ෂර එකක් ලෙස තබයි. Perl 5.005_03 දක්වා ගැළපේ.
#
# සටහන: source code සහ \xHH data US-ASCII ලෙසම තබයි; මෙම file එක UTF-8 වේ (comment පමණක් සිංහලෙන්).
#
#     perl eg/si/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS hiragana තුනක්: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) byte දකී: මෙහි 6ක්.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) අක්ෂර දකී: තුනක්.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS delimiter එකෙන් බෙදීම. delimiter එක hiragana a (\x82\xA0); mb::split
# එය සම්පූර්ණ අක්ෂරයක් ලෙස ගළපයි, ඕනෑ තැනක යෙදෙන byte \x82 හෝ \xA0 නොව.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split හි list context මගින් අක්ෂර ගණන (chars() මෙන්).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
