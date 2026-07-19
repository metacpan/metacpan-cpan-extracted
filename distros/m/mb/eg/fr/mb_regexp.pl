#!/usr/bin/perl
######################################################################
# eg/fr/mb_regexp.pl - correspondance sensible au multi-octets avec mb::qr
#
# Ce que cela montre :
#   mb::qr(PATTERN) compile une expression régulière dont "." , les classes
#   de caractères et les captures travaillent sur des CARACTÈRES multi-octets
#   entiers selon l'encodage de script choisi.
#
# Différence avec CORE :
#   un "." de CORE correspond à un seul OCTET, donc /(.)/g sur trois hiragana
#   Shift_JIS donne six morceaux. Le même motif via mb::qr en donne trois, un
#   par caractère. Un intervalle de classe comme [a-hiragana ... ] compare des
#   caractères entiers, et une capture renvoie un caractère entier.
#
# Note : la source et les données \xHH restent en US-ASCII ; ce
# fichier est en UTF-8 (seuls les commentaires sont en français).
#
#     perl eg/fr/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Trois hiragana en Shift_JIS : a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# "." de CORE est un octet -- six morceaux pour six octets.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") fait de "." un caractère entier -- trois morceaux. Compile
# une fois, puis interpole le motif compilé dans la correspondance.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Intervalle de classe sur le bloc hiragana a..n (\x82\xA0-\x82\xF1).
# L'intervalle compare des caractères entiers : u est dedans, "A" ASCII non.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Une capture renvoie un caractère multi-octets entier (deux octets ici),
# jamais une moitié.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Trouver chaque hiragana dans une chaîne mixte, par caractère.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
