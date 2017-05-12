package Text::Echelon;

=head1 NAME

Text::Echelon - get random Echelon related words.

=head1 SYNOPSIS

  use Text::Echelon;
  my $te = Text::Echelon->new();
  print $te->get();
  print $te->getmany($num); #or $te->getmany($num, $delimiter);
  print $te->makeheader();
  print $te->makecustom($pre, $num, $post, $delim);

=head1 Using with mutt

If you want to generate an X-Echelon header on your outgoing mail, put the
following in your .muttrc:
C<my_hdr `/path/to/echelon.pl`>

F<echelon.pl> is supplied in this distribution.

=head1 DESCRIPTION

Text::Echelon is a small program that will return Echelon 
'I<spook words>', as per

F<http://www.attrition.org/attrition/keywords.html>

If you don't know why you might want this, look at:

F<http://www.echelon.wiretapped.net/>

F<http://www.echelonwatch.org/>

=head1 METHODS

=cut

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.02';
my @Wordlist = <DATA>;
chomp @Wordlist;

=head2 new

Creates a new instance of Text::Echelon

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}#new

=head2 get

Returns one random spook word or phrase as a scalar

=cut

sub get {
    my $self = shift;
	return $Wordlist[rand($#Wordlist)];
}#get

=head2 getmany

Takes a number of spook words or phrases to be returned and the delimiter 
between words as parameters. Returns a scalar string of spookwords.

=cut

sub getmany {
    my $self = shift;
    my ($num, $delim) = @_;
    $num   ||= '3';
    $delim ||= ', ';
    #join $delim, map $self->get (1 .. $num);
    my $str = '';
    for(my $currnum = 1; $currnum <= $num; $currnum++)
    {
        $str .= $self->get();
        $str .= $delim unless ($currnum == $num);
    }
    return $str;
}#getmany

=head2 makecustom

Takes four parameters - the prefix to use, the number of words or
phrases to include, the postfix to use and the delimiter between words.
Returns a scalar string.

=cut

sub makecustom {
    my $self = shift;
    my ($pre, $num, $post, $delim) = @_;
    $pre ||= '';
    $num ||= '3';
    $post ||= '';
    $delim ||= ', ';
    return $pre . $self->getmany($num, $delim) . $post;
}#makecustom

=head2 makeheader

Creates a header suitable for putting in your outgoing email.
The scalar returned is in the format:

C<X-Echelon: smuggle, CIA, indigo>

=cut

sub makeheader {
    my $self = shift;
    return $self->makecustom('X-Echelon: ');
}#makeheader

=head1 AVAILABILITY

It should be available for download from
F<http://russell.matbouli.org/code/text-echelon/>
or from CPAN

=head1 AUTHOR

Russell Matbouli E<lt>text-echelon-spam@russell.matbouli.orgE<gt>

F<http://russell.matbouli.org/>

=head1 TODO

Create something more plausable - generate natural language.
Ideally, a sentence generated randomly that contains spook words.

=head1 LICENSE

Distributed under GPL v2. See COPYING included with this distibution.

=head1 SEE ALSO

perl(1).

=cut

#End, return true
1;
__DATA__
Waihopai
INFOSEC
Information Security
Information Warfare
IW
IS
Priavacy
Information Terrorism
Terrorism Defensive Information
Defense Information Warfare
Offensive Information
Offensive Information Warfare
National Information Infrastructure
InfoSec
Reno
Compsec
Computer Terrorism
Firewalls
Secure Internet Connections
ISS
Passwords
DefCon V
Hackers
Encryption
Espionage
USDOJ
NSA
CIA
S/Key
SSL
FBI
Secert Service
USSS
Defcon
Military
White House
Undercover
NCCS
Mayfly
PGP
PEM
RSA
Perl-RSA
MSNBC
bet
AOL
AOL TOS
CIS
CBOT
AIMSX
STARLAN
3B2
BITNET
COSMOS
DATTA
E911
FCIC
HTCIA
IACIS
UT/RUS
JANET
JICC
ReMOB
LEETAC
UTU
VNET
BRLO
BZ
CANSLO
CBNRC
CIDA
JAVA
Active X
Compsec 97
LLC
DERA
Mavricks
Meta-hackers
^?
Steve Case
Tools
Telex
Military Intelligence
Scully
Flame
Infowar
Bubba
Freeh
Archives
Sundevil
jack
Investigation
ISACA
NCSA
spook words
Verisign
Secure
ASIO
Lebed
ICENRO
Lexis-Nexis
NSCT
SCIF
FLiR
Lacrosse
Flashbangs
HRT
DIA
USCOI
CID
BOP
FINCEN
FLETC
NIJ
ACC
AFSPC
BMDO
NAVWAN
NRL
RL
NAVWCWPNS
NSWC
USAFA
AHPCRC
ARPA
LABLINK
USACIL
USCG
NRC
~
CDC
DOE
FMS
HPCC
NTIS
SEL
USCODE
CISE
SIRC
CIM
ISN
DJC
SGC
UNCPCJ
CFC
DREO
CDA
DRA
SHAPE
SACLANT
BECCA
DCJFTF
HALO
HAHO
FKS
868
GCHQ
DITSA
SORT
AMEMB
NSG
HIC
EDI
SAS
SBS
UDT
GOE
DOE
GEO
Masuda
Forte
AT
GIGN
Exon Shell
CQB
CONUS
CTU
RCMP
GRU
SASR
GSG-9
22nd SAS
GEOS
EADA
BBE
STEP
Echelon
Dictionary
MD2
MD4
MDA
MYK
747,777
767
MI5
737
MI6
757
Kh-11
Shayet-13
SADMS
Spetznaz
Recce
707
CIO
NOCS
Halcon
Duress
RAID
Psyops
grom
D-11
SERT
VIP
ARC
S.E.T. Team
MP5k
DREC
DEVGRP
DF
DSD
FDM
GRU
LRTS
SIGDEV
NACSI
PSAC
PTT
RFI
SIGDASYS
TDM. SUKLO
SUSLO
TELINT
TEXTA. ELF
LF
MF
VHF
UHF
SHF
SASP
WANK
Colonel
domestic disruption
smuggle
15kg
nitrate
Pretoria
M-14
enigma
Bletchley Park
Clandestine
nkvd
argus
afsatcom
CQB
NVD
Counter Terrorism Security
Rapid Reaction
Corporate Security
Police
sniper
PPS
ASIS
ASLET
TSCM
Security Consulting
High Security
Security Evaluation
Electronic Surveillance
MI-17
Counterterrorism
spies
eavesdropping
debugging
interception
COCOT
rhost
rhosts
SETA
Amherst
Broadside
Capricorn
Gamma
Gorizont
Guppy
Ionosphere
Mole
Keyhole
Kilderkin
Artichoke
Badger
Cornflower
Daisy
Egret
Iris
Hollyhock
Jasmine
Juile
Vinnell
B.D.M.,Sphinx
Stephanie
Reflection
Spoke
Talent
Trump
FX
FXR
IMF
POCSAG
Covert Video
Intiso
r00t
lock picking
Beyond Hope
csystems
passwd
2600 Magazine
Competitor
EO
Chan
Alouette,executive
Event Security
Mace
Cap-Stun
stakeout
ninja
ASIS
ISA
EOD
Oscor
Merlin
NTT
SL-1
Rolm
TIE
Tie-fighter
PBX
SLI
NTT
MSCJ
MIT
69
RIT
Time
MSEE
Cable & Wireless
CSE
Embassy
ETA
Porno
Fax
finks
Fax encryption
white noise
pink noise
CRA
M.P.R.I.
top secret
Mossberg
50BMG
Macintosh Security
Macintosh Internet Security
Macintosh Firewalls
Unix Security
VIP Protection
SIG
sweep
Medco
TRD
TDR
sweeping
TELINT
Audiotel
Harvard
1080H
SWS
Asset
Satellite imagery
force
Cypherpunks
Coderpunks
TRW
remailers
replay
redheads
RX-7
explicit
FLAME
Pornstars
AVN
Playboy
Anonymous
Sex
chaining
codes
Nuclear
20
subversives
SLIP
toad
fish
data havens
unix
c
a
b
d
the
Elvis
quiche
DES
1*
NATIA
NATOA
sneakers
counterintelligence
industrial espionage
PI
TSCI
industrial intelligence
H.N.P.
Juiliett Class Submarine
Locks
loch
Ingram Mac-10
sigvoice
ssa
E.O.D.
SEMTEX
penrep
racal
OTP
OSS
Blowpipe
CCS
GSA
Kilo Class
squib
primacord
RSP
Becker
Nerd
fangs
Austin
Comirex
GPMG
Speakeasy
humint
GEODSS
SORO
M5
ANC
zone
SBI
DSS
S.A.I.C.
Minox
Keyhole
SAR
Rand Corporation
Wackenhutt
EO
Wackendude
mol
Hillal
GGL
CTU
botux
Virii
CCC
Blacklisted 411
Internet Underground
XS4ALL
Retinal Fetish
Fetish
Yobie
CTP
CATO
Phon-e
Chicago Posse
l0ck
spook keywords
PLA
TDYC
W3
CUD
CdC
Weekly World News
Zen
World Domination
Dead
GRU
M72750
Salsa
7
Blowfish
Gorelick
Glock
Ft. Meade
press-release
Indigo
wire transfer
e-cash
Bubba the Love Sponge
Digicash
zip
SWAT
Ortega
PPP
crypto-anarchy
AT&T
SGI
SUN
MCI
Blacknet
Middleman
KLM
Blackbird
plutonium
Texas
jihad
SDI
Uzi
Fort Meade
supercomputer
bullion
3
Blackmednet
Propaganda
ABC
Satellite phones
Planet-1
cryptanalysis
nuclear
FBI
Panama
fissionable
Sears Tower
NORAD
Delta Force
SEAL
virtual
Dolch
secure shell
screws
Black-Ops
Area51
SABC
basement
data-haven
black-bag
TEMPSET
Goodwin
rebels
ID
MD5
IDEA
garbage
market
beef
Stego
unclassified
utopia
orthodox
Alica
SHA
Global
gorilla
Bob
Pseudonyms
MITM
Gray Data
VLSI
mega
Leitrim
Yakima
Sugar Grove
Cowboy
Gist
8182
Gatt
Platform
1911
Geraldton
UKUSA
veggie
3848
Morwenstow
Consul
Oratory
Pine Gap
Menwith
Mantis
DSD
BVD
1984
Flintlock
cybercash
government
hate
speedbump
illuminati
president
freedom
cocaine
$
Roswell
ESN
COS
E.T.
credit card
b9
fraud
assasinate
virus
anarchy
rogue
mailbomb
888
Chelsea
1997
Whitewater
MOD
York
plutonium
William Gates
clone
BATF
SGDN
Nike
Atlas
Delta
TWA
Kiwi
PGP 2.6.2.
PGP 5.0i
PGP 5.1
siliconpimp
Lynch
414
Face
Pixar
IRIDF
eternity server
Skytel
Yukon
Templeton
LUK
Cohiba
Soros
Standford
niche
51
H&K
USP
^
sardine
bank
EUB
USP
PCS
NRO
Red Cell
Glock 26
snuffle
Patel
package
ISI
INR
INS
IRS
GRU
RUOP
GSS
NSP
SRI
Ronco
Armani
BOSS
Chobetsu
FBIS
BND
SISDE
FSB
BfV
IB
froglegs
JITEM
SADF
advise
TUSA
HoHoCon
SISMI
FIS
MSW
Spyderco
UOP
SSCI
NIMA
MOIS
SVR
SIN
advisors
SAP
OAU
PFS
Aladdin
chameleon man
Hutsul
CESID
Bess
rail gun
Peering
17
312
NB
CBM
CTP
Sardine
SBIRS
SGDN
ADIU
DEADBEEF
IDP
IDF
Halibut
SONANGOL
Flu
&
Loin
PGP 5.53
EG&G
AIEWS
AMW
WORM
MP5K-SD
1071
WINGS
cdi
DynCorp
UXO
Ti
THAAD
package
chosen
PRIME
SURVIAC
