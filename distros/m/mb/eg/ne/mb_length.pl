#!/usr/bin/perl
######################################################################
# eg/ne/mb_length.pl - mb द्वारा अक्षर सङ्ख्या र बाइट सङ्ख्याको भिन्नता
#
# के देखाउँछ:
#   CORE को length() ले बाइट गन्छ; mb::length() ले छानिएको स्क्रिप्ट
#   एन्कोडिङअनुसार पूरा मल्टिबाइट अक्षरलाई 1 गन्छ। mb::substr() र
#   mb::index() पनि अक्षर एकाइमा चल्छन्, दुई-बाइट अक्षर बीचबाट काटिँदैन।
#
# CORE भन्दा फरक:
#   length ले दुई-बाइट हिरागानालाई 2 (बाइट) दिन्छ, तर mb::length ले 1
#   (एउटा Shift_JIS हिरागाना अक्षर) दिन्छ।
#
# द्रष्टव्य: स्रोत कोड र \xHH डेटा US-ASCII मै रहन्छ; यो फाइल UTF-8 हो (टिप्पणी मात्र नेपालीमा)।
#
#     perl eg/ne/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS का तीन हिरागाना, जम्मा 6 बाइट:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() ले बाइट गन्छ; mb::length() ले अक्षर गन्छ।
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() अक्षर एकाइमा काट्छ, दुई-बाइट अक्षर आधा हुँदैन।
# पहिलो 2 अक्षर ठ्याक्कै 4 बाइटको स्ट्रिङ हो।
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() ले बाइट होइन, अक्षर स्थिति दिन्छ। तेस्रो अक्षर बाइट
# 4 बाट सुरु हुन्छ, तर अक्षर सूचकाङ्क 2 मा।
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
