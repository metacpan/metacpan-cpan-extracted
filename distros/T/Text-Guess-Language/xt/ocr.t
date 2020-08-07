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
38 Scr ci'IIenCt&amp;n, tiritte^® efitlec^t
5)cr i\met)tc 5lbfd)nitt«

F.25. ^ na- zeiget Die 25 Figur auf eben btefem
Tupfer = blatte, fcei-ett ©ebdubc Den üorigcrt
gieid) i^, ^ic ftnt) f;eUcr, rot^ pcrtmutterigec
%avbt, t&gt;ic an Den fleiiiewn ©croinDeii auf Der
platten oberen ^ic^du immer blaifer, unt&gt; m
Der genabelten in Der Sßertiefung Dunfelec
lüivD»

(Sie finD nid^t fo f?(trf gereift unD gejacft,
hingegen finD Die 3«(f en an Den |!ai*fen (Saum
oDer !)tücf =9veifen Der dujTeren 0eminDe gr6f=
fer unD gröber gcr^eilt oDer eingeferbet, Die ge=
f(i)drfren Sc^dm fiiiD Dunfeler rotl^, aB Der ge=
reifte ©runD Deö ^orn^ unD fallen im3^abel=
J?oc^e brdunlic^.

SnmenDig ^aben fie m fitbermeitTeö ^n--
jenDeö Perlmutter, Der !D?unD ijl Den i)origen
gleich, runDlic^ gebogen,

SÖenn man Diefen J^6rnern i^r r6t^tid)eö
:^'leiD Dur^ :^un|l abjiel^et, erfc^einen fte au^--
unD inroenDig gleich fcif)6n^erlmutter=gldnjenD,
fie perlierenaberDaDurd) (tn)ai t»on Der(S(^dr=
fe i^rer 3(»cfen, unD eö gefd)iel)et Da^er feiten
an anDern, aB Die eine graue (ErD=^^rbe l^a=
ben. ^mmnfen Die roti^en raar unD fojlbar
ftnD,

©n Dur(^gefc^uitteneg (Sonnen =J^orn jei*
F.26. gct Die 26te Figur, auö melc^er Die £)i(f e Deö
jporn^, Der inmenDige Durc^gdngige ^erlmut=
tcr^Olanj, unD Die 3iunDe forool, aB aud) Die
gd^linge Sßerjungerung Der ©eivinDe, Wö^rju*
nehmen.



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
i)

VI

38 DererstenOrdn.drittesGeschlecht.
Der zwente Abschnitt.

ine andere Art Indianischer Sonnen-Hör-
ner zeiget die 25 Figur auf eben diesem
Kupfer-Blatte, deren Gebäude den Vorigen
gleich ist. Sie sind heller, roth perlmutteriger
Farbe, die an den kleineren Gewinden auf der
platten öberen Seite immer blasser, und an
der genabelten in der Vertiefung dunkeler
wird.

Sie sind nicht so stark gereift und gezackt,
hingegen sind die Zacken an den starken Saum
oder Rück-Reisen der cinsseren Gewinde grös-
ser nnd gröber getheilt oder eingekerbet, die ge-
schiirften Zacken sind dunkeler roth, als der ge-
reifte Grund des Horns und fallen im Nabel-
Loche bräunlich.

Inwendig haben sie ein silbertveisses glän-
zendes Perlmntter, der Mund ist den vorigen
gleich, rundlich gebogen.

Wenn man diesen Hörnern ihr röthliche-s
Kleid durch Kunst abziehen erscheinen sie ans-
und inwendig gleich schön Perlmutter-glcinzend,
sie Verlieren aber dadurch etwas von der Schär-
fe ihrer Zacken, und es geschiehet daher selten
an andern, als die eine graue Erd-Farbe ha-
Pein Jnnnaßen die rothen raar und kostbar
ind.

Ein durchgeschnittenes Sonnen-Horn zei-

1'126- get die 26te Figur, aus welcher die Dicke des

Horns, der inwendige durchgängigePerlniut-
ice-Glanz, und die Runde soon, als auch die
gåhlinge Verjüngerung der Gewinde, wahrzu-
nehmen.

Das

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
38 Der ersten Ordn. drittes Geschlecht.
Der zweyte Abschnitt.

Eine andere Art Indianischer Sonnen-Hör-
ner zeiget die 25 Figur auf eben diesem
Kupfer-Blatte, deren Gebäude den vorigen
gleich ist. Sie sind heller, roth perlmutteriger
Farbe, die an den kleineren Gewinden auf der
platten öberen Seite immer blasser, und an
der genabelten in der Vertiefung dunkeler
wird.

Sie sind nicht so stark gereift und gezackt,
hingegen sind die Zacken an den starken Saum
oder Rück-Reifen der äusseren Gewinde grös-
ser nnd gröber getheilt oder eingekerbet, die ge-
schärften Zacken sind dunkeler roth, als der ge-
reifte Grund des Horns und fallen im Nabel-
Loche bräunlich.

Inwendig haben sie ein silberweisses glän-
zendes Perlmutter, der Mund ist den vorigen
gleich, rundlich gebogen.

Wenn man diesen Hörnern ihr röthliches
Kleid durch Kunst abziehet, erscheinen sie aus-
und inwendig gleich schön Perlmutter-glänzend,
sie verlieren aber dadurch etwas von der Schär-
fe ihrer Zacken, und es geschiehet daher selten
an andern, als die eine graue Erd-Farbe ha-
ben. Jmmaßen die rothen raar und kostbar
sind.

Ein durchgeschnittenes Sonnen-Horn zei-
get die 26te Figur, aus welcher die Dicke des
Horns, der inwendige durchgängige Perlmut-
ter-Glanz, und die Ründe sowol, als auch die
gählinge Verjüngerung der Gewinde, wahrzu-
nehmen.

Das

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

