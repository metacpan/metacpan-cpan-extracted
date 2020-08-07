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

