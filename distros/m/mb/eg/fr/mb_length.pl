#!/usr/bin/perl
######################################################################
# eg/fr/mb_length.pl - compter les caractères plutôt que les octets avec mb
#
# Ce que cela montre :
#   length() de CORE compte des OCTETS ; mb::length() compte des CARACTÈRES
#   multi-octets entiers selon l'encodage de script choisi. mb::substr() et
#   mb::index() travaillent aussi par caractère, donc un caractère sur deux
#   octets n'est jamais coupé en deux.
#
# Différence avec CORE :
#   length("\x82\xA0") vaut 2 (octets), mais mb::length("\x82\xA0") vaut 1
#   (un hiragana Shift_JIS).
#
# Note : la source et les données \xHH restent en US-ASCII ; ce
# fichier est en UTF-8 (seuls les commentaires sont en français).
#
#     perl eg/fr/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Trois hiragana en Shift_JIS, six octets au total :
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# length() de CORE compte les octets ; mb::length() compte les caractères.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() découpe par caractère, donc un caractère sur deux octets
# n'est pas coupé en deux. Les deux premiers caractères font 4 octets.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() renvoie la position en caractères, pas en octets. Le troisième
# caractère commence à l'octet 4, mais à l'indice de caractère 2.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
