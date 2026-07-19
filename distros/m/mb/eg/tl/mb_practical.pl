#!/usr/bin/perl
######################################################################
# eg/tl/mb_practical.pl - fixed-column na pagputol nang hindi sinisira ang karakter
#
# Ano ang ipinapakita (maliit na totoong gawain):
#   Putulin ang isang Shift_JIS na linya sa isang nakapirming DISPLAY
#   WIDTH para sa fixed-column na output, binibilang ang half-width na
#   karakter bilang 1 column at ang full-width na karakter bilang 2 column
#   (ang klasikong ratio na 1:2), at hindi kailanman hinahati ang isang
#   dalawang-byte na karakter sa hangganan.
#
# Pagkakaiba sa CORE:
#   Ang walang-muwang na CORE substr(EXPR, 0, N) ay pumuputol sa ika-N na
#   OCTET at maaaring mag-iwan ng nakabitin na lead byte -- sirang kalahati
#   ng isang karakter. Dito, dinaraanan natin ang buong karakter gamit ang
#   mb::split(''), sinusukat ang lapad ng bawat karakter ayon sa haba ng
#   byte nito (1 byte -> 1 column, 2 byte -> 2 column), at humihinto bago
#   lumampas sa budget. Kinukumpirma ng mb::length() na ang resulta ay
#   buong bilang ng karakter.
#
# US-ASCII ang source; gumagamit ang multibyte data ng \xHH byte escape.
# Runtime interface lamang, kaya tumatakbo ito sa bawat perl mula 5.005_03 pataas.
#
#     perl eg/tl/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C tapos tatlong full-width na hiragana a i u tapos dalawang
# half-width na katakana.
#   ASCII A B C            : 1 column bawat isa
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 column bawat isa
#   half-width ka(\xB6) ki(\xB7)                   : 1 column bawat isa
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # putulin sa 7 display column

# Ligtas-sa-hangganan-ng-karakter, width-aware na pagputol.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 column, 2 byte -> 2 column
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 column) + a (2) + i (2) = 7 column; lalampas ang u kaya ito ay
# tinatanggal, kaya nananatiling buo ang huling dalawang-byte na karakter.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Kaibahan sa dalawang-byte-lamang na data: ang pagputol sa nakapirming
# bilang ng OCTET ay maaaring dumapo sa loob ng isang karakter. Ang
# hiragana a i u ay pawang dalawang-byte, kaya ang gansal na haba ng byte
# ay nangangahulugang hinati ng putol ang isang karakter; laging humihinto
# ang mb::substr sa hangganan ng karakter (pantay na haba ng byte dito).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + nakabitin na lead byte
$char_cut  = mb::substr($aiu, 0, 1);    # eksaktong a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
