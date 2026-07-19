#!/usr/bin/perl
######################################################################
# eg/my/mb_practical.pl - စာလုံးမပျက်စေဘဲ ပုံသေ-column ဖြတ်ခြင်း
#
# ပြသသည်မှာ (သေးငယ်သော လက်တွေ့လုပ်ငန်း):
#   Shift_JIS line တစ်ကြောင်းကို ပုံသေ display width သို့ဖြတ်ခြင်း — half-width
#   စာလုံး column 1, full-width စာလုံး column 2 (ပုံမှန် 1:2 အချိုး)၊ double-byte
#   စာလုံးကို နယ်နိမိတ်တွင် မဖြတ်ဘဲ။
#
# CORE နှင့် ကွာခြားချက်:
#   ရိုးရိုး CORE substr က N-ခုမြောက် byte တွင်ဖြတ်ပြီး စာလုံးတစ်ဝက်ကျန်နိုင်သည်။
#   ဤတွင် mb::split('') ဖြင့် စာလုံးအပြည့်လျှောက်၊ byte အလျားဖြင့် width တိုင်း၊
#   budget မကျော်မီ ရပ်သည်။ mb::length() က စာလုံးအပြည့်ဖြစ်ကြောင်း အတည်ပြုသည်။
#
# မှတ်ချက်: source code နှင့် \xHH data ကို US-ASCII အဖြစ်ထားသည်; ဤ file သည် UTF-8 ဖြစ်သည် (comment သာ ဗမာလို)။
#
#     perl eg/my/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C, ထို့နောက် full-width hiragana သုံးလုံး a i u, ထို့နောက် half-width katakana နှစ်လုံး။
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # display column 7 သို့ဖြတ်ခြင်း

# စာလုံး-နယ်နိမိတ် လုံခြုံ၊ width-သိ ဖြတ်ခြင်း။
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # byte 1 -> column 1, byte 2 -> column 2
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (column 3) + a (2) + i (2) = column 7; u ကျော်လွန်မည်ဖြစ်၍ ဖယ်ထုတ်သည်၊
# ထို့ကြောင့် နောက်ဆုံး double-byte စာလုံး အပြည့်ကျန်သည်။
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# double-byte-only data ပေါ်တွင် နှိုင်းယှဉ်ချက်: ပုံသေ byte အရေအတွက်ဖြင့်ဖြတ်လျှင်
# စာလုံးအတွင်းကျနိုင်သည်။ hiragana a i u အားလုံး double-byte, ထို့ကြောင့် မကိန်း
# byte အလျားက ဖြတ်ခြင်းက စာလုံးကိုခွဲသည်ဟုဆိုသည်; mb::substr က အမြဲ စာလုံး
# နယ်နိမိတ်တွင်ရပ်သည် (ဤတွင် စုံ byte အလျား)။
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + တွဲလောင်း lead byte
$char_cut  = mb::substr($aiu, 0, 1);    # အတိအကျ a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
