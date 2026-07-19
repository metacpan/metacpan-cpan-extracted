#!/usr/bin/perl
######################################################################
# eg/id/mb_split.pl - memisah pada batas karakter dengan mb::split
#
# Apa yang ditunjukkan:
#   mb::split('', EXPR) memecah string menjadi KARAKTER multibyte utuh,
#   dan mb::split(PATTERN, EXPR) memisah pada delimiter MBCS tanpa pernah
#   cocok dengan byte yang berada di dalam karakter multibyte.
#
# Bedanya dengan CORE:
#   CORE split(//, "\x82\xA0") mengembalikan dua OKTET ("\x82", "\xA0");
#   hiragana dua-byte itu tercabik. mb::split('', ...) mengembalikannya
#   sebagai satu karakter. mb::split adalah padanan yang dikelola saat
#   runtime dari "split //" hasil transpile, kompatibel sampai Perl 5.005_03.
#
# Sumber ini US-ASCII; data multibyte memakai escape byte \xHH.
#
#     perl eg/id/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tiga hiragana Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) melihat byte: enam di sini.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) melihat karakter: tiga di sini.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# Memisah pada delimiter MBCS. Delimiternya hiragana a (\x82\xA0);
# mb::split mencocokkannya sebagai satu karakter utuh, bukan sebagai byte
# \x82 atau \xA0 di mana pun byte itu kebetulan muncul.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# Hitung karakter lewat konteks list mb::split (seperti helper chars()).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
