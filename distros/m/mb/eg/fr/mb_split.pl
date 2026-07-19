#!/usr/bin/perl
######################################################################
# eg/fr/mb_split.pl - découper aux frontières de caractère avec mb::split
#
# Ce que cela montre :
#   mb::split('', EXPR) découpe une chaîne en CARACTÈRES multi-octets
#   entiers, et mb::split(PATTERN, EXPR) découpe sur un délimiteur MBCS sans
#   jamais correspondre à un octet interne d'un caractère multi-octets.
#
# Différence avec CORE :
#   CORE split(//, "\x82\xA0") renvoie deux OCTETS ("\x82", "\xA0") ; le
#   hiragana sur deux octets est déchiré. mb::split('', ...) le renvoie comme
#   un seul caractère. mb::split est l'équivalent géré à l'exécution du
#   "split //" transpilé et reste compatible jusqu'à Perl 5.005_03.
#
# Note : la source et les données \xHH restent en US-ASCII ; ce
# fichier est en UTF-8 (seuls les commentaires sont en français).
#
#     perl eg/fr/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Trois hiragana en Shift_JIS : a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) voit des octets : six ici.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) voit des caractères : trois.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# Découpage sur un délimiteur MBCS. Le délimiteur est le hiragana a
# (\x82\xA0) ; mb::split le reconnaît comme un caractère entier, pas comme
# l'octet \x82 ou \xA0 où qu'ils apparaissent.
#     A a B a C  ->  champs : A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# Comptage de caractères via le contexte de liste de mb::split (comme chars()).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
