#!/usr/bin/perl
######################################################################
# eg/ne/mb_practical.pl - अक्षर नबिगारी निश्चित-कोलम काट्ने
#
# के देखाउँछ (सानो व्यावहारिक काम):
#   Shift_JIS लाइनलाई निश्चित प्रदर्शन-चौडाइमा काट्ने — आधा-चौडाइ अक्षर 1
#   कोलम, पूरा-चौडाइ अक्षर 2 कोलम (उही 1:2 अनुपात) — दुई-बाइट अक्षरलाई
#   सीमामा नटुक्र्याई।
#
# CORE भन्दा फरक:
#   सोझो CORE substr ले N-औं बाइटमा काट्छ र आधा अक्षर छोड्न सक्छ। यहाँ
#   mb::split('') ले पूरा अक्षर हिँड्छ, बाइट लम्बाइले चौडाइ नाप्छ र बजेट
#   नाघ्नुअघि रोकिन्छ। mb::length() ले पूरा अक्षर भएको पुष्टि गर्छ।
#
# द्रष्टव्य: स्रोत कोड र \xHH डेटा US-ASCII मै रहन्छ; यो फाइल UTF-8 हो (टिप्पणी मात्र नेपालीमा)।
#
#     perl eg/ne/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C, त्यसपछि तीन पूरा-चौडाइ हिरागाना a i u, अनि दुई आधा-चौडाइ काताकाना।
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 7 प्रदर्शन कोलममा काट्ने

# अक्षर-सीमा सुरक्षित, चौडाइ-सचेत काट्ने।
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 बाइट -> 1 कोलम, 2 बाइट -> 2 कोलम
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 कोलम) + a (2) + i (2) = 7 कोलम; u ले नाघ्ने भएर हटाइन्छ,
# त्यसैले पुछारको दुई-बाइट अक्षर पूरै रहन्छ।
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# दुई-बाइट-मात्र डेटामा तुलना: निश्चित बाइट सङ्ख्यामा काट्दा अक्षरभित्र
# पर्न सक्छ। हिरागाना a i u सबै दुई-बाइट, त्यसैले बिजोर बाइट लम्बाइले
# कटाइले अक्षर च्यात्यो भन्ने जनाउँछ; mb::substr सधैँ अक्षर सीमामा रोकिन्छ
# (यहाँ जोर बाइट लम्बाइ)।
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + झुन्डिएको अग्रबाइट
$char_cut  = mb::substr($aiu, 0, 1);    # ठ्याक्कै a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
