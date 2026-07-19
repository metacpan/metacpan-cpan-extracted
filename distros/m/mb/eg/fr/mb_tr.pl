#!/usr/bin/perl
######################################################################
# eg/fr/mb_tr.pl - translittération par caractère avec mb::tr
#
# Ce que cela montre :
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) translittère des CARACTÈRES
#   multi-octets entiers. Sans /r il modifie son premier argument sur place
#   et renvoie le compte ; avec /r il renvoie le résultat et laisse
#   l'argument intact.
#
# Différence avec CORE :
#   CORE tr/// travaille octet par octet, il peut donc corrompre un DAMEMOJI
#   -- un caractère sur deux octets dont le SECOND octet est un métacaractère
#   ASCII, p.ex. So(\x83\x5C), dont l'octet final \x5C est une barre
#   oblique inverse. Un CORE tr sur \x5C frapperait cet octet final ;
#   mb::tr voit So comme un caractère et le laisse tranquille.
#
# Note : dans mb::tr un intervalle à tiret (a-z) n'est développé que pour des
# bornes US-ASCII ; les caractères multi-octets de SEARCH doivent être listés
# un par un (exactement comme le transpileur développe un tr/// MBCS).
#
# Note : la source et les données \xHH restent en US-ASCII ; ce
# fichier est en UTF-8 (seuls les commentaires sont en français).
#
#     perl eg/fr/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Chiffres pleine chasse en Shift_JIS : 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH liste les dix chiffres pleine chasse un par un ; REPLACE est
# l'intervalle US-ASCII "0-9" (un intervalle à tiret ASCII développé par mb::tr).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Pleine chasse "1" "3" "6" -> demi-chasse "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# Sécurité DAMEMOJI. La chaîne est A So(\x83\x5C) B. Un CORE tr visant
# l'octet barre oblique inverse \x5C corrompt le caractère ; mb::tr, qui ne
# mappe que les lettres ASCII, laisse So intact.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr frappe l'octet final de So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# Modificateur /r : non destructif, renvoie la copie translittérée.
$keep = "\x82\x50\x82\x51";                 # pleine chasse 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
