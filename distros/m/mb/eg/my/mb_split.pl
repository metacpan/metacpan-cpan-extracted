#!/usr/bin/perl
######################################################################
# eg/my/mb_split.pl - mb::split ဖြင့် စာလုံးနယ်နိမိတ်တွင် ခွဲခြင်း
#
# ပြသသည်မှာ:
#   mb::split('', EXPR) က string ကို multibyte စာလုံးအပြည့်အဖြစ်ခွဲသည်;
#   mb::split(PATTERN, EXPR) က MBCS delimiter ဖြင့်ခွဲသည်၊ စာလုံးတစ်လုံး
#   အတွင်းရှိ byte နှင့် ဘယ်တော့မှ မကိုက်ညီပါ။
#
# CORE နှင့် ကွာခြားချက်:
#   CORE split(//) က double-byte hiragana ကို byte နှစ်လုံးဆွဲဆုတ်သည်;
#   mb::split က ၎င်းကို စာလုံးတစ်လုံးအဖြစ်ထားသည်။ Perl 5.005_03 အထိ။
#
# မှတ်ချက်: source code နှင့် \xHH data ကို US-ASCII အဖြစ်ထားသည်; ဤ file သည် UTF-8 ဖြစ်သည် (comment သာ ဗမာလို)။
#
#     perl eg/my/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS hiragana သုံးလုံး: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)။
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) က byte မြင်သည်: ဤတွင် 6 ခု။
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) က စာလုံးမြင်သည်: သုံးလုံး။
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS delimiter ဖြင့်ခွဲခြင်း။ delimiter မှာ hiragana a (\x82\xA0); mb::split
# က ၎င်းကို စာလုံးအပြည့်အဖြစ်ကိုက်သည်၊ ဘယ်နေရာမှာမဆို ပေါ်သည့် byte \x82 သို့ \xA0 မဟုတ်။
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split ၏ list context ဖြင့် စာလုံးရေတွက်ခြင်း (chars() ကဲ့သို့)။
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
