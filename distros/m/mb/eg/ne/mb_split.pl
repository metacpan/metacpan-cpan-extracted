#!/usr/bin/perl
######################################################################
# eg/ne/mb_split.pl - mb::split द्वारा अक्षर सीमामा विभाजन
#
# के देखाउँछ:
#   mb::split('', EXPR) ले स्ट्रिङलाई पूरा मल्टिबाइट अक्षरमा तोड्छ, र
#   mb::split(PATTERN, EXPR) ले MBCS विभाजकमा टुक्र्याउँछ — अक्षरभित्रको
#   बाइटसँग कहिल्यै मेल खाँदैन।
#
# CORE भन्दा फरक:
#   CORE split(//) ले दुई-बाइट हिरागानालाई दुई बाइटमा च्यात्छ; mb::split
#   ले त्यसलाई एक अक्षर राख्छ। Perl 5.005_03 सम्म सुसंगत।
#
# द्रष्टव्य: स्रोत कोड र \xHH डेटा US-ASCII मै रहन्छ; यो फाइल UTF-8 हो (टिप्पणी मात्र नेपालीमा)।
#
#     perl eg/ne/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS का तीन हिरागाना: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)।
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) ले बाइट देख्छ: यहाँ छ वटा।
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) ले अक्षर देख्छ: तीन वटा।
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS विभाजकमा टुक्र्याउने। विभाजक हिरागाना a (\x82\xA0) हो; mb::split
# ले त्यसलाई पूरा अक्षर मान्छ, जहाँतहीँ देखिने बाइट \x82 वा \xA0 होइन।
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split को सूची-सन्दर्भबाट अक्षर गणना (chars() जस्तै)।
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
