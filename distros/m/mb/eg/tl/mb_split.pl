#!/usr/bin/perl
######################################################################
# eg/tl/mb_split.pl - paghahati sa hangganan ng karakter gamit ang mb::split
#
# Ano ang ipinapakita:
#   Hinahati ng mb::split('', EXPR) ang string tungo sa buong multibyte
#   na KARAKTER, at hinahati ng mb::split(PATTERN, EXPR) sa isang MBCS na
#   delimiter nang hindi kailanman tumutugma sa byte na nasa loob ng isang
#   multibyte na karakter.
#
# Pagkakaiba sa CORE:
#   Ang CORE split(//, "\x82\xA0") ay nagbabalik ng dalawang OCTET
#   ("\x82", "\xA0"); napupunit ang dalawang-byte na hiragana. Ibinabalik
#   ito ng mb::split('', ...) bilang isang karakter. Ang mb::split ay ang
#   runtime-managed na katapat ng transpiled na "split //", tugma pabalik
#   hanggang Perl 5.005_03.
#
# US-ASCII ang source; gumagamit ang multibyte data ng \xHH byte escape.
#
#     perl eg/tl/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tatlong hiragana sa Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# Nakikita ng CORE split(//, ...) ang byte: anim dito.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# Nakikita ng mb::split('', ...) ang karakter: tatlo dito.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# Paghahati sa isang MBCS na delimiter. Ang delimiter ay ang hiragana a
# (\x82\xA0); tinutugma ito ng mb::split bilang buong karakter, hindi
# bilang byte \x82 o \xA0 saan man lumitaw ang mga byte na iyon.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# Pagbilang ng karakter sa pamamagitan ng list context ng mb::split
# (tulad ng isang chars() helper).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
