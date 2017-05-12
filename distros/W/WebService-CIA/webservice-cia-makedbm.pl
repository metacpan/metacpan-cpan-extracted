#!/usr/bin/perl -w

use strict;
use WebService::CIA::Source::Web;
use WebService::CIA::Source::DBM;

my $dbm = WebService::CIA::Source::DBM->new({ DBM  => 'factbook.dbm', Mode => 'readwrite' });
my $web = WebService::CIA::Source::Web->new();

chomp (my @data = <DATA>);
for (my $i = 0; $i < scalar @data; $i++) {
    next unless $data[$i];
    my ($cc, $name) = split /:/, $data[$i];
    printf "%3d/%3d %s (%s) ... ", $i + 1, scalar @data, $name, $cc;
    my $vals = $web->all($cc);
    if (scalar keys %$vals > 0) {
        $dbm->set($cc, $vals);
        print "done\n";
    } else {
        print "no data found\n";
    }
}

__DATA__
af:Afghanistan
al:Albania
ag:Algeria
aq:American Samoa
an:Andorra
ao:Angola
av:Anguilla
ay:Antarctica
ac:Antigua and Barbuda
xq:Arctic Ocean
ar:Argentina
am:Armenia
aa:Aruba
at:Ashmore and Cartier Islands
zh:Atlantic Ocean
as:Australia
au:Austria
aj:Azerbaijan
bf:Bahamas, The
ba:Bahrain
fq:Baker Island
bg:Bangladesh
bb:Barbados
bs:Bassas da India
bo:Belarus
be:Belgium
bh:Belize
bn:Benin
bd:Bermuda
bt:Bhutan
bl:Bolivia
bk:Bosnia and Herzegovina
bc:Botswana
bv:Bouvet Island
br:Brazil
io:British Indian Ocean Territory
vi:British Virgin Islands
bx:Brunei
bu:Bulgaria
uv:Burkina Faso
bm:Burma
by:Burundi
cb:Cambodia
cm:Cameroon
ca:Canada
cv:Cape Verde
cj:Cayman Islands
ct:Central African Republic
cd:Chad
ci:Chile
ch:China
kt:Christmas Island
ip:Clipperton Island
ck:Cocos (Keeling) Islands
co:Colombia
cn:Comoros
cg:Congo, Democratic Republic of the
cf:Congo, Republic of the
cw:Cook Islands
cr:Coral Sea Islands
cs:Costa Rica
iv:Cote d'Ivoire
hr:Croatia
cu:Cuba
cy:Cyprus
ez:Czech Republic
da:Denmark
dj:Djibouti
do:Dominica
dr:Dominican Republic
tt:East Timor
ec:Ecuador
eg:Egypt
es:El Salvador
ek:Equatorial Guinea
er:Eritrea
en:Estonia
et:Ethiopia
eu:Europa Island
fk:Falkland Islands (Islas Malvinas)
fo:Faroe Islands
fj:Fiji
fi:Finland
fr:France
fg:French Guiana
fp:French Polynesia
fs:French Southern and Antarctic Lands
gb:Gabon
ga:Gambia, The
gz:Gaza Strip
gg:Georgia
gm:Germany
gh:Ghana
gi:Gibraltar
go:Glorioso Islands
gr:Greece
gl:Greenland
gj:Grenada
gp:Guadeloupe
gq:Guam
gt:Guatemala
gk:Guernsey
gv:Guinea
pu:Guinea-Bissau
gy:Guyana
ha:Haiti
hm:Heard Island and McDonald Islands
vt:Holy See (Vatican City)
ho:Honduras
hk:Hong Kong
hq:Howland Island
hu:Hungary
ic:Iceland
in:India
xo:Indian Ocean
id:Indonesia
ir:Iran
iz:Iraq
ei:Ireland
is:Israel
it:Italy
jm:Jamaica
jn:Jan Mayen
ja:Japan
dq:Jarvis Island
je:Jersey
jq:Johnston Atoll
jo:Jordan
ju:Juan de Nova Island
kz:Kazakhstan
ke:Kenya
kq:Kingman Reef
kr:Kiribati
kn:Korea, North
ks:Korea, South
ku:Kuwait
kg:Kyrgyzstan
la:Laos
lg:Latvia
le:Lebanon
lt:Lesotho
li:Liberia
ly:Libya
ls:Liechtenstein
lh:Lithuania
lu:Luxembourg
mc:Macau
mk:Macedonia, The Former Yugoslav Republic of
ma:Madagascar
mi:Malawi
my:Malaysia
mv:Maldives
ml:Mali
mt:Malta
im:Man, Isle of
rm:Marshall Islands
mb:Martinique
mr:Mauritania
mp:Mauritius
mf:Mayotte
mx:Mexico
fm:Micronesia, Federated States of
mq:Midway Islands
md:Moldova
mn:Monaco
mg:Mongolia
mh:Montserrat
mo:Morocco
mz:Mozambique
wa:Namibia
nr:Nauru
bq:Navassa Island
np:Nepal
nl:Netherlands
nt:Netherlands Antilles
nc:New Caledonia
nz:New Zealand
nu:Nicaragua
ng:Niger
ni:Nigeria
ne:Niue
nf:Norfolk Island
cq:Northern Mariana Islands
no:Norway
mu:Oman
zn:Pacific Ocean
pk:Pakistan
ps:Palau
lq:Palmyra Atoll
pm:Panama
pp:Papua New Guinea
pf:Paracel Islands
pa:Paraguay
pe:Peru
rp:Philippines
pc:Pitcairn Islands
pl:Poland
po:Portugal
rq:Puerto Rico
qa:Qatar
re:Reunion
ro:Romania
rs:Russia
rw:Rwanda
sh:Saint Helena
sc:Saint Kitts and Nevis
st:Saint Lucia
sb:Saint Pierre and Miquelon
vc:Saint Vincent and the Grenadines
ws:Samoa
sm:San Marino
tp:Sao Tome and Principe
sa:Saudi Arabia
sg:Senegal
yi:Serbia and Montenegro
se:Seychelles
sl:Sierra Leone
sn:Singapore
lo:Slovakia
si:Slovenia
bp:Solomon Islands
so:Somalia
sf:South Africa
sx:South Georgia and the South Sandwich Islands
oo:Southern Ocean
sp:Spain
pg:Spratly Islands
ce:Sri Lanka
su:Sudan
ns:Suriname
sv:Svalbard
wz:Swaziland
sw:Sweden
sz:Switzerland
sy:Syria
ti:Tajikistan
tz:Tanzania
th:Thailand
to:Togo
tl:Tokelau
tn:Tonga
td:Trinidad and Tobago
te:Tromelin Island
ts:Tunisia
tu:Turkey
tx:Turkmenistan
tk:Turks and Caicos Islands
tv:Tuvalu
ug:Uganda
up:Ukraine
tc:United Arab Emirates
uk:United Kingdom
us:United States
uy:Uruguay
uz:Uzbekistan
nh:Vanuatu
ve:Venezuela
vm:Vietnam
vq:Virgin Islands
wq:Wake Island
wf:Wallis and Futuna
we:West Bank
wi:Western Sahara
xx:World
ym:Yemen
za:Zambia
zi:Zimbabwe
tw:Taiwan
