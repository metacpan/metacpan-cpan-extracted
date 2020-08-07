#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Text::Guess::Language;
use Data::Dumper;

my $words = Text::Guess::Language::Words->words();

my $text1 =<<'TEXT';

Clajfe I, Familie 3.

Se6lion feconde.

La figure 2^. de la meme planche re-
prefente une autre forte de cornes de
Soleil dont la Strukture exterieure repond
a Celle de l'efpece precedente. Elle a fa ro-
be couleur de chair nacree. Ses con-
tours pres de Toeil onc un blanc de nacre
plus pale vers le haut. La couleur eft
auffi plus foncee du cote umbilique fur-
tout vers le nombril : mais eile n'eft , ny
fi pointee, ny ftriee fi profondement. Le
premier cercle a für le dos vers les flancs
deux rangees de pointes afles grandes, ra-
yees &amp; fendües. Ces pointes fönt d'un
rouge obfcur &amp; prennent la couleur brunc
dans le nombril.

L' Interieur de ce coquillage a l'eclat
d'une nacre blanche , claire &amp; argentine.
Sa bouche eft presque ronde &amp; pincee
comme celle de Telpece precedente.

Si on leve adroitement lacrouterougeä-
tre de cette corne , on la trouve nacree ;
au moyen de quoy eile l'eft au dehors &amp;
au dedans: mais elleperd par l'a fes poin-
tes aigues. Cette railbnempeche ordinai-
rement de depouiller celles qui n'ont pas
la couleur de terre, ou grifätre; car les
rouges font tres rares &amp; tres precieufes.

On peut voirFig. 26. une de ces coquil-
les fciecj par confequent ouverte. Elle
montre fon epaifleur ; (aftruSture interieu-
re, la rondeur de la cavite des cercles &amp;
la difference qui fe trouve fubitement &amp;
fanspreparation, entrele diametre du pre-
mier cercle &amp; le diametre du fecond.



2)fl5



Chapitre

TEXT

my $guesses1 = Text::Guess::Language->guesses($text1);

print Dumper($guesses1);

my $text2 =<<'TEXT';


Claﬂê I. Famille 3.
Seélion feconde.

La ﬁgure 25. de la même planche re-
préfente une autre forte de cornes de
Soleil dont la Structure extérieure répond
a celle de l’efpêce précedente. Elle a (a ro-
be couleur de chair nacrée. Ses con-
tours pres de l’oeil ont un blanc de nacre
plus pale vers le haut. La couleur eﬁ:
auﬂî plus foncée du coté umbiliqué fur—
tout vers le nombril: mais elle n’eft, ny
ﬁ pointée, ny ftriée ﬁ profondément. Le
premier cercle a fur le dos vers les ﬂancs
deux ran ées de pointes aH'e's grandes, ra-
yées 8: fëndües. Ces pointes font d’un
rouge obfcur& prennent la couleur brune
dans le nombril.

L’interieur de ce coquillage a l’éclat
d’une nacre blanche , claire & argentine.
Sa bouche ell: presque ronde 8: pincée
comme celle de l’efpêce précedente.

Si on leve adroitement la croute rougeâ-
tre de cette corne, on la trouve nacrée;
au moyen de quoy elle l’eft au dehors 8c
au dedans: mais elle erd par l’a fes poin—
tes aigues. Cette rai on empeche ordinai-
rement de dépouiller celles qui n’ont pas
la couleur de terre, ou grifâtre; car les
rouges font très rares & très precieufes.

On peut voirFig. 26. une de ces coquil-
les fciee, par confequent ouverte. Elle
montre fon epaiﬁ'eur; (ä liruEkure interieu-
re, la rondeur de la cavité des cercles 8C
la difference qui fe trouve fubitement 8c
fans préparation, entre le diametre du pre-
mier cercle 8: le diametre du fécond.

Chapitre


TEXT

my $guesses2 = Text::Guess::Language->guesses($text2);

print Dumper($guesses2);

my $text3 =<<'TEXT';

Classe I. Famille 3.
Section seconde.

La figure 25. de la même planche re-
présente une autre forte de cornes de
Soleil dont la Structure exterieure répond
a celle de l’espêce précedente. Elle a sa ro-
be couleur de chair nacrée. Ses con-
tours près de l’oeil ont un blanc de nacre
plus pale vers le haut. La couleur est:
aussi plus foncée du coté umbiliqué fur—
tout vers le nombril: mais elle n’est, ny
si pointée, ny striée si profondément. Le
premier cercle a sur le dos vers les flancs
deux rangées de pointes assés grandes, ra-
yées & fendües. Ces pointes sont d’un
rouge obscur & prennent la couleur brune
dans le nombril.

L’interieur de ce coquillage a l’éclat
d’une nacre blanche, claire & argentine.
Sa bouche est: prèsque ronde & pincée
comme celle de l’efpêce précedente.

Si on leve adroitement la croute rougeâ-
tre de cette corne, on la trouve nacrée;
au moyen de quoy elle l’est au dehors &
au dedans: mais elle perd par l’a ses poin—
tes aigues. Cette raison empeche ordinai-
rement de dépouiller celles qui n’ont pas
la couleur de terre, ou grisâtre; car les
rouges font très rares & très precieuses.

On peut voir Fig. 26. une de ces coquil-
les sciée, par consequent ouverte. Elle
montre son epaisseur; sa structure interieu-
re, la rondeur de la cavité des cercles &
la difference qui fe trouve subitement &
sans préparation, entre le diametre du pre-
mier cercle & le diametre du sécond.

Chapitre


TEXT

my $guesses3 = Text::Guess::Language->guesses($text3);

print Dumper($guesses3);

for my $guess (($guesses1,$guesses2,$guesses3)) {
  for my $i (0..9) {
    last if ($i >= scalar(@{$guess}));
    print $guess->[$i]->[0],': ',sprintf('%0.2f',$guess->[$i]->[1]),' ';
  }
  print "\n";
}

