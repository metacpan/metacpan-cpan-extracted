#!/usr/bin/perl
######################################################################
# eg/bm/mb_regexp.pl - padanan sedar-multibyte dengan mb::qr
#
# Apa yang ditunjukkan:
#   mb::qr(PATTERN) mengkompil ungkapan nalar yang "." , kelas aksara dan
#   tangkapannya bekerja dalam AKSARA multibyte penuh mengikut pengekodan
#   skrip yang dipilih.
#
# Bezanya dengan CORE:
#   "." CORE sepadan dengan satu OKTET, jadi /(.)/g ke atas tiga hiragana
#   Shift_JIS menghasilkan enam kepingan. Corak sama melalui mb::qr
#   menghasilkan tiga, satu setiap aksara. Julat kelas seperti
#   [a-hiragana ... ] membanding aksara penuh, dan tangkapan memulangkan
#   aksara penuh.
#
# Nota: kod sumber dan data \xHH kekal US-ASCII; fail ini juga
# US-ASCII (komen dalam bahasa Melayu).
#
#     perl eg/bm/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tiga hiragana dalam Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# "." CORE ialah satu oktet -- enam kepingan untuk enam byte.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") menjadikan "." satu aksara penuh -- tiga kepingan. Kompil
# sekali, kemudian interpolasi corak terkompil ke dalam padanan.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Julat kelas-aksara pada blok hiragana a..n (\x82\xA0-\x82\xF1).
# Julat membanding aksara penuh, jadi u di dalam dan "A" ASCII tidak.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Tangkapan memulangkan aksara multibyte penuh (dua byte di sini), tidak
# pernah separuh daripadanya.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Cari setiap hiragana dalam rentetan campuran, dalam unit aksara.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
