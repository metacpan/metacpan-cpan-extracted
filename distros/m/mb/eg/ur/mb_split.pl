#!/usr/bin/perl
######################################################################
# eg/ur/mb_split.pl - mb::split ke sath character ki hadd par split
#
# Yeh misal kya dikhati hai:
#   mb::split('', EXPR) string ko poore multibyte CHARACTER mein todta
#   hai, aur mb::split(PATTERN, EXPR) kisi MBCS delimiter par split karta
#   hai, kabhi bhi multibyte character ke andar mojood byte se match kiye
#   baghair.
#
# CORE se kya farq hai:
#   CORE split(//, "\x82\xA0") do OCTET ("\x82", "\xA0") wapas deta hai;
#   do-byte hiragana phat jata hai. mb::split('', ...) use ek character
#   ke taur par wapas deta hai. mb::split transpile kiye gaye "split //"
#   ka runtime-managed hamsafar hai aur Perl 5.005_03 tak peeche compatible.
#
# Source US-ASCII hai; multibyte data \xHH byte escape istemal karta hai.
#
#     perl eg/ur/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS mein teen hiragana: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) byte dekhta hai: yahan chhe.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) character dekhta hai: yahan teen.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS delimiter par split. Delimiter hiragana a (\x82\xA0) hai; mb::split
# use poore character ke taur par match karta hai, byte \x82 ya \xA0 ke
# taur par nahin, chahe woh byte kahin bhi aayen.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split ke list context se character ki ginti (ek chars() helper ki tarah).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
