#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;

my $class = 'Text::Guess::Language';

use_ok($class);

my $text =<<TEXT;

Opća deklaracija o pravima čovjeka

Eleanor Roosevelt & Opća deklaracija o pravima čovjeka (1949)
Opća deklaracija o pravima čovjeka je prvi sveobuhvatni instrument zaštite ljudskih prava, proglašen od strane jedne opće međunarodne organizacije, Ujedinjenih naroda. Proglasila ju je je na Opća skupština UN 1948. godine.

Iako je donesena ne kao ugovor, nego samo kao rezolucija koja nema nikakvu pravnu snagu, sa ciljem da osigura "zajedničko razumijevanje" ljudskih prava i sloboda koja se spominju u Povelji UN, tijekom slijedećih desetljeća doživjela je dramatičnu transformaciju. »Danas rijetki pravnici poriču da je deklaracija normativni instrument koji stvara, barem neke, pravne obveze za države članice UN.« (Buergenthal, str. 31)

Članak 1. svečano proglašava:
»Sva ljudska bića rađaju se slobodna i jednaka u dostojanstvu i pravima. Ona su obdarena razumom i savješću pa jedna prema drugima trebaju postupati u duhu bratstva.«
S tim je u vezi članak 28, koji proglašava ljudsko pravo da država i međunarodna zajednica priznaju njegova/njezina prava:

»Svatko ima pravo na društveni i međunarodni poredak u kojemu se prava i slobode utvrđene ovom Deklaracijom mogu u punoj mjeri ostvariti.«
Daljnje odredbe sadrže tzv. "katalog ljudskih prava", u kojem se:

zabranjuje ropstvo (čl. 4),
zabranjuje tortura (čl. 5.),
zabranjuje diskriminacija (čl. 2. i 7.), te uređuje
pravo na život (čl. 3.),
pravo na slobodu (čl. 3.),
pravo na osobnu sigurnosti (čl. 3.),
pravo svake osobe na pravično suđenje i zabrane samovoljnog uhićenja (čl. 9. - 12.),
pravu na zaštitu privatnosti (čl. 12.),
pravo čovjeka da se slobodno kreće unutar svoje države, da njen teritorij napusti i da se u svoju državu smije slobodno vratiti (čl. 13.),
pravo na utočište (azil) u drugim zemljama, od nepravednog progona u svojoj zemlji (čl. 14.),
pravo čovjeka da bude državljanin barem jedne zemlje i da se može odreći državljanstva (čl. 15.),
pravo punoljetnih muškaraca i žena da sklope brak i time osnuju obitelj, koja se štiti kao temeljna društvena jedinica (čl. 16.),
pravo na vlasništvo (čl. 17.), pravo na slobodu mišljenja i vjeroispovijedi (čl. 18.),
pravo na slobodu mišljenja i izražavanja, koja uključuje pravo na širenje ideja putem bilo kojeg medija (čl. 19.),
pravo na slobodu okupljanja i udruživanja (čl. 20.),
pravo na sudjelovanje u upravljanju svojom zemljom, putem izbora i pravom na pristup javnim dužnostima (čl. 21.),
pravo na socijalnu sigurnost u svrhu osiguranja temeljnog dostojanstva čovjeka (čl. 22.),
pravo čovjeka da radi i slobodno izabere zaposlenje, te da bude plaćen bez diskriminacije - jednako kao i drugi ljudi koji rade jednaki posao (čl. 23.),
pravo na sindikalno organiziranje radnika (čl. 23.),
pravo na dnevni odmor i plaćeni dopust od rada (čl. 24.),
pravo na dostojni životni standard (čl. 25.),
pravo na zaštitu materinstva i djetinjstva, koje uključuje i zaštitu izvanbračne djece (čl. 26.),
pravo na obrazovanje, koje uključuje obvezno osnovno obrazovanje, besplatno srednjoškolsko obrazovanje, te pravo na pristup visokoškolskom obrazovanju "jednako dostupno svima na osnovi uspjeha" (čl. 26.),
pravo prvenstva roditelja u izboru vrste obrazovanja za svoju djecu (čl. 26.),
pravo na pristup kulturi i znanosti (čl. 27.),
pravo na zaštitu moralnih i materijalnih interesa koji proizlaze iz kulturnog i znanstvenog stvaralaštva (čl. 27.)
pravo na društveni i međunarodni poredak u kojem se mogu ostvarivati ljudska prava (čl. 28.).
Sadržaj 30 članaka Opće deklaracije o pravima čovjeka kasnije je ugrađivan u druge međunarodne akte, uvijek uz stanovite izmjene. Najvažniji od tih akata su Međunarodni pakt o građanskim i političkim pravima i Međunarodni pakt o gospodarskim, socijalnim i kulturnim pravima - oba proglašena od Opće skupštine Ujedinjenih naroda 1966. godine; nakon dovoljnog broja ratifikacija od nacionalnih parlamenata (koji su propisali da će se prava i slobode iz tih akata poštivati u njihovim državama) oba su pakta stupila na snagu 1976.


TEXT

is(Text::Guess::Language->guess($text),'hr','is hr');

done_testing;
