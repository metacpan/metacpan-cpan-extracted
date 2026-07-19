#!/usr/bin/perl
######################################################################
# eg/bm/mb_split.pl - membelah pada sempadan aksara dengan mb::split
#
# Apa yang ditunjukkan:
#   mb::split('', EXPR) membelah rentetan kepada AKSARA multibyte penuh,
#   dan mb::split(PATTERN, EXPR) membelah pada pembatas MBCS tanpa pernah
#   sepadan dengan byte yang terletak di dalam aksara multibyte.
#
# Bezanya dengan CORE:
#   CORE split(//, "\x82\xA0") memulangkan dua OKTET ("\x82", "\xA0");
#   hiragana dua-byte dikoyakkan. mb::split('', ...) memulangkannya sebagai
#   satu aksara. mb::split ialah padanan waktu-jalan bagi "split //" yang
#   ditranspil dan serasi hingga Perl 5.005_03.
#
# Nota: kod sumber dan data \xHH kekal US-ASCII; fail ini juga
# US-ASCII (komen dalam bahasa Melayu).
#
#     perl eg/bm/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tiga hiragana dalam Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) nampak byte: enam di sini.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) nampak aksara: tiga.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# Membelah pada pembatas MBCS. Pembatas ialah hiragana a
# (\x82\xA0); mb::split memadankannya sebagai aksara penuh, bukan byte
# \x82 atau \xA0 di mana sahaja byte itu muncul.
#     A a B a C  ->  medan: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# Kiraan aksara melalui konteks senarai mb::split (seperti pembantu chars()).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
