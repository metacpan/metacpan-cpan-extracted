package WordList::Phrase::FR::Idiom::Wiktionary;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",4,"num_words_contains_whitespace",370,"num_words",377,"num_words_contains_unicode",135,"num_words_contains_nonword_chars",373,"avg_word_len",17.8143236074271,"longest_word_len",48); # STATS

1;
# ABSTRACT: French idioms from wiktionary.org

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::FR::Idiom::Wiktionary - French idioms from wiktionary.org

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::FR::Idiom::Wiktionary (from Perl distribution WordList-Phrase-FR-Idiom-Wiktionary), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::FR::Idiom::Wiktionary;

 my $wl = WordList::Phrase::FR::Idiom::Wiktionary->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 17.8143236074271 |
 | longest_word_len                 | 48               |
 | num_words                        | 377              |
 | num_words_contains_nonword_chars | 373              |
 | num_words_contains_unicode       | 135              |
 | num_words_contains_whitespace    | 370              |
 | shortest_word_len                | 4                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-FR-Idiom-Wiktionary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-FR-Idiom-Wiktionary>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-FR-Idiom-Wiktionary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wiktionary.org/wiki/Category:French_idioms>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Chine continentale
absent le chat, les souris dansent
acharnement thérapeutique
acheter chat en poche
acte manqué
affaire de cœur
allez savoir
allez voir là-bas si j'y suis
appeler un chat un chat
après ski
attacher Pierre avec Paul
attacher sa tuque
attacher sa tuque avec de la broche
au berceau
au fond
au grand jour
au sein de
au violon
auberge espagnole
aux abois
aux abonnés absents
aux calendes grecques
aux portes de la mort
avec des bouts de ficelle
aveuglement volontaire
avoir d'autres chats à fouetter
avoir dans la peau
avoir des cornes
avoir des yeux derrière la tête
avoir du biceps
avoir du monde au balcon
avoir du plomb dans l'aile
avoir l'air
avoir la cuisse légère
avoir la gueule de bois
avoir la moutarde qui monte au nez
avoir la poisse
avoir la tête qui tourne
avoir le cafard
avoir le cul bordé de nouilles
avoir le cœur sur la main
avoir le melon
avoir le vent en poupe
avoir les chevilles grosses
avoir les jambes en coton
avoir mangé du lion
avoir un coup de pompe
avoir un grain
avoir une araignée au plafond
avoir une brioche au four
avoir une dent contre
avoir une faim de loup
baisser le rideau
baisser les bras
baraki
battre de l'aile
battre en brèche
bel et bien
bien fendu
blanc bonnet, bonnet blanc
bon an mal an
bon an, mal an
bourrer le crâne
bourré à craquer
branle-bas
briser les couilles
brûler la chandelle par les deux bouts
buissonnier
casser le cul
casser les couilles
casser les pieds
ce n'est pas le Pérou
changer de main
changer son fusil d'épaule
charger la barque
chier dans son froc
cinq à sept
cinquième roue du carrosse
cirer les pompes
cligner des yeux
comme un cheveu sur la soupe
compter sur
contre toute attente
couille dans le potage
couler un bronze
coup de bourre
coup de cœur
coup de foudre
coup de mou
couper les cheveux en quatre
courir sur le haricot
couter la peau du cul
coûter la peau du dos
coûter les yeux de la tête
cracher dans la soupe
crever la dalle
crise des nerfs
croiser les doigts
croquer la pomme
d'ailleurs
d'occasion
d'un poil
dans le même temps
dans son assiette
de A à Z
de fond en comble
de justesse
de plus en plus
deux poids et deux mesures
devenir chèvre
devoir une fière chandelle à quelqu'un
diable vauvert
donner le tournis
donner sa langue au chat
dos d'âne
du fil à retordre
du fond du cœur
du pareil au même
dégât des eaux
effeuiller la marguerite
en avoir le cœur net
en chair et en os
en chien de fusil
en cloque
en dessous de la ceinture
en direct
en faire tout un fromage
en lice
en revenir
en vouloir
enculer les mouches
entre chien et loup
entre l'arbre et l'écorce
entre le marteau et l'enclume
entrer comme un gant
envoyer son gantelet
faire d'une pierre deux coups
faire des salamalecs
faire exprès
faire l'autruche
faire la tête
faire la une
faire le grand saut
faire le gros dos
faire le plein
faire le pont
faire le trottoir
faire marcher
faire minette
faire mouche
faire noir
faire tache
faire un pied de nez
faire un sang d'encre
faire une montagne d'une taupinière
fait divers
fermer les yeux
feu vert
ficher le camp
filer à l'anglaise
franchir le Rubicon
frapper les grands coups
frapper un ennemi à terre
frapper un grand coup
froncer les sourcils
gagner son bifteck
garder son sang-froid
gibier de potence
grand maximum
grande surface
grasse matinée
gros bonnet
gros lot
gros temps
grosse légume
hors de question
humour noir
il n'y a pas mort d'homme
il ne fallait pas
il y a plusieurs façons de plumer un canard
jeter l'éponge
jeter le bébé avec l'eau du bain
jeter le gant
jeter un œil
jeu d'enfant
joindre les deux bouts
jouer avec le feu
jouer avec ses armes
l'esprit de l'escalier
l'ogre de Corse
la semaine des quatre jeudis
la vache
laboratoire d'idées
laisser faire
le beurre et l'argent du beurre
le chat parti, les souris dansent
le sort en est jeté
les dés sont jetés
les grands esprits se rencontrent
lire entre les lignes
lire sur les lèvres
main verte
manger à tous les râteliers
marche ou crève
marcher sur des œufs
marin d'eau douce
mener en bateau
mer à boire
merci mille fois
mettre au monde
mettre de l'huile sur le feu
mettre du beurre dans les épinards
mettre en bouteille
mettre fin à
mettre l'accent sur
mettre à la porte
mon petit doigt m'a dit
monter à la tête
mordre la poussière
mort de rire
mouton de Panurge
mouton noir
myope comme une taupe
ne pas savoir sur quel pied danser
neuvième art
nez à nez
nid d'amour
no comment
nuit blanche
par contre
parler français comme une vache espagnole
partir du mauvais pied
pas mal
passage à l'acte
passage à tabac
passage à vide
passer au crible
passer de vie à trépas
passer l'arme à gauche
passer le Rubicon
passer sur le billard
passer un savon
passer à la moulinette
payer les pots cassés
pendre la crémaillère
perdre son latin
perdre son sang-froid
petite mort
peut être
piquer un roupillon
piquer une colère
pièce de résistance
plan cul
plein à craquer
pleuvoir des cordes
pleuvoir des hallebardes
pleuvoir à verse
pogner
pomme de discorde
portrait craché
poule mouillée
prendre en compte
prendre l'eau
prendre sa retraite
prendre son pied
prendre à part
purement et simplement
pétard mouillé
péter les plombs
péter un câble
péter un plomb
quand les poules auront des dents
quand on parle du loup
ramasser le gantelet
rebrousser chemin
relever le gant
remplumer
rendre l'âme
rendre la monnaie de sa pièce
rentrer par une oreille et ressortir par l'autre
retrousser ses manches
s'endormir sur ses lauriers
s'y casser les dents
s'étirer les jambes
sauve qui peut
se barrer
se casser
se casser la nénette
se changer les idées
se faire chier
se glisser dans
se mettre le doigt dans l'œil
se mettre martel en tête
se piquer le nez
se pousser
se reposer sur ses lauriers
se serrer la ceinture
se serrer les coudes
se sortir les doigts du cul
se taper la cloche
se tirer une balle dans le pied
si par hasard
sur l'ongle
sur la même longueur d'onde
sur la sellette
sur le billard
sur le bout de la langue
sur le champ
sur ses grands chevaux
séance tenante
taillable et corvéable à merci
taper sur les nerfs
tapis rouge
tenants et aboutissants
tendre la perche
tenir au courant
tenir la chandelle
tenir la route
tenir le coup
tenir sa langue
tirer les ficelles
tirer son épingle du jeu
tiré par les cheveux
tomber sur le nez
tomber à pic
tourner autour du pot
tous les 36 du mois
tous les quinze jours
tout de suite
tout à fait
toutes voiles dehors
trouver chaussure à son pied
trouver la mort
tête à claques
tôt ou tard
une fois pour toutes
une nouvelle fois
venter à écorner les bœufs
vice anglais
vivre d'amour et d'eau fraiche
voir le jour
voir le loup
vulgum pecus
à bras ouverts
à brûle-pourpoint
à contre-courant
à cor et à cri
à fond
à l'anglaise
à l'encontre de
à l'envi
à la
à la bonne heure
à la clé
à la main
à la suite
à la suite de
à la tienne
à la une
à la vôtre
à merveille
à peu près
à ta santé
à tout bout de champ
à toute allure
à voile et à vapeur
à votre santé
ça va barder
éminence grise
épater le bourgeois
être au four et au moulin
être dans de beaux draps
être dans la merde jusqu'au cou
être dur de la feuille
être plus catholique que le pape
être plus royaliste que le roi
être à la bourre
