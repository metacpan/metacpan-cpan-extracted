#!/usr/bin/perl
######################################################################
# eg/fr/mb_practical.pl - rognage à colonnes fixes sans casser les caractères
#
# Ce que cela montre (une petite tâche concrète) :
#   Rogner une ligne Shift_JIS à une LARGEUR D'AFFICHAGE fixe pour une sortie
#   à colonnes fixes, en comptant un caractère demi-chasse comme 1 colonne et
#   un caractère pleine chasse comme 2 colonnes (le rapport classique 1:2), et
#   sans jamais couper un caractère sur deux octets à la frontière.
#
# Différence avec CORE :
#   un CORE substr(EXPR, 0, N) naïf coupe au N-ième OCTET et peut laisser un
#   octet de tête pendant -- une moitié cassée de caractère. Ici on parcourt
#   les caractères entiers avec mb::split(''), on mesure la largeur de chaque
#   caractère par sa longueur en octets (1 octet -> 1 colonne, 2 octets -> 2
#   colonnes) et on s'arrête avant de dépasser le budget. mb::length() confirme
#   que le résultat est un nombre entier de caractères.
#
# Note : la source et les données \xHH restent en US-ASCII ; ce
# fichier est en UTF-8 (seuls les commentaires sont en français).
#
#     perl eg/fr/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C puis trois hiragana pleine chasse a i u puis deux katakana demi-chasse.
#   ASCII A B C            : 1 colonne chacun
#   pleine chasse a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 colonnes chacun
#   demi-chasse ka(\xB6) ki(\xB7)                   : 1 colonne chacun
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # rogner à 7 colonnes d'affichage

# Rognage sur frontière de caractère, sensible à la largeur.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 octet -> 1 colonne, 2 octets -> 2 colonnes
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 colonnes) + a (2) + i (2) = 7 colonnes ; u déborderait et est
# abandonné, donc le caractère sur deux octets final reste entier.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Contraste sur des données uniquement sur deux octets : couper à un nombre
# fixe d'OCTETS peut tomber dans un caractère. Le hiragana a i u est tout sur
# deux octets, donc une longueur impaire signifie que la coupe a divisé un
# caractère ; mb::substr s'arrête toujours sur une frontière (longueur paire).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + un octet de tête pendant
$char_cut  = mb::substr($aiu, 0, 1);    # exactement a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
