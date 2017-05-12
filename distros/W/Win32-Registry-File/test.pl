# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32::Registry::File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use POSIX qw(tmpnam);
do { $tmpfile = tmpnam() } until open TMPFILE, ">$tmpfile";
print TMPFILE <<EOT;
[Setup]
MasterProduct=UnrealTournament
Group=UnrealTournament
Group=DE Mutators			; Digital Extreme mutators
Group=Pinata
Group=NIUT				; random weapons

[DE Mutators]
File=System\\de.u
File=System\\de.int
File=Help\\demutators-readme.txt
File=System\\de-logo.bmp
Caption=DE Mutators
Version=100
Requires=UnrealTournament

[Pinata]
File=System\\Pinata.int
File=System\\Pinata.u
File=Help\\Pinata_readme.txt
Caption=Pinata
Version=200
Requires=UnrealTournament

[NIUT]
File=Help\\niut.txt
File=System\\NIUT.u
File=System\\Niut.int
File=System\\Niut.ini
Caption=NIUT
Version=121
Requires=UnrealTournament

[Engine.GameEngine]
MasterServerAddress=unreal.epicgames.com MasterServerPort=\\
	27900
ServerActors = \\
IpServer.UdpServerUplinkMasterServerAddress=master0.gamespy.com \\
MasterServerPort=27900
ServerActors	=	IpServer.UdpServerUplinkMaster\\
	ServerAddress=master.mplayer.com MasterServerPort = 27900
EOT
close TMPFILE;

# constructor
$ini = new Win32::Registry::File($tmpfile);
if (defined $ini) { print "ok 2\n"; }
else { print "not ok 2\n"; }

# existence test
if ($ini->exists(['Setup']) and $ini->exists(['Setup', 'Group'])
	and $ini->exists(['Setup', 'MasterProduct'])
	and $ini->exists(['Setup', 'Group', 'NIUT'])
	and $ini->exists(['Setup', 'MasterProduct', 'UnrealTournament'])
	and $ini->exists(['DE Mutators', 'File', 'System\\de.int'])) {
	print "ok 3\n";
} else { print "not ok 3\n"; }

# nonexistence test
if (!$ini->exists(['NONEXISTENT']) and !$ini->exists(['Setup', 'NONEXISTENT'])
	and !$ini->exists(['Setup', 'Group', 'NONEXISTENT'])
	and !$ini->exists(['Setup', 'MasterProduct', 'NONEXISTENT'])
	and !$ini->exists(['DE Mutators', 'File', 'NONEXISTENT'])) {
	print "ok 4\n";
} else { print "not ok 4\n"; }

# get single value
if ($ini->get(['Setup', 'MasterProduct']) eq 'UnrealTournament'
	and $ini->get(['Engine.GameEngine', 'MasterServerAddress']) eq
	    'unreal.epicgames.com MasterServerPort=27900') {
	print "ok 5\n";
} else { print "not ok 5\n"; }

# get multiple values
@setupgroup = $ini->get(['Setup', 'Group']);
if ($setupgroup[0] eq 'UnrealTournament'
	and $setupgroup[1] eq 'DE Mutators'
	and $setupgroup[2] eq 'Pinata'
	and $setupgroup[3] eq 'NIUT') {
	print "ok 6\n";
} else { print "not ok 6\n" };

# force get single value
if ($ini->get(['Setup', 'Group'], -mapping => 'single') eq 'UnrealTournament') {
	print "ok 7\n";
} else { print "not ok 7\n"; }

# force get multiple value
@masterproducts = $ini->get(['Setup', 'MasterProduct'], -mapping => 'multiple');
if ($#masterproducts == 0 and $masterproducts[0] eq 'UnrealTournament') {
	print "ok 8\n";
} else { print "not ok 8\n"; }

# get entire section
%setup = %{ $ini->get(['Setup']) };
if ($setup{MasterProduct}[0] eq 'UnrealTournament'
	and $setup{Group}[0] eq 'UnrealTournament'
	and $setup{Group}[1] eq 'DE Mutators'
	and $setup{Group}[2] eq 'Pinata'
	and $setup{Group}[3] eq 'NIUT') {
	print "ok 9\n";
} else { print "not ok 9\n"; }

# get a non-existent key
if (!defined $ini->get(['Setup', 'NONEXISTENT'])) {
	print "ok 10\n";
} else { print "not ok 10\n"; }

# erroneous get calls
if (!defined $ini->get(['', 'MasterProduct'])
	and !defined $ini->get([undef, '', 'NIUT'])
	and !defined $ini->get(['', undef, 'NIUT'])
	and !defined $ini->get([''])) {
	print "ok 11\n";
} else { print "not ok 11\n"; }

# change value
if (($oldver = $ini->put(['DE Mutators', 'Version', '200'])) == 100
	and $ini->get(['DE Mutators', 'Version']) == 200) {
	print "ok 12\n";
} else { print "not ok 12\n"; }

# add value to existing key
$ini->put(['Setup', 'Group', 'NewMutator'], -add => 1);
# add new key
$ini->put(['DE Mutators', 'Old Version', $oldver]);
# add new group and key
$ini->put(['NewMutator', 'Caption', 'The Great New Mutator']);
if ($ini->exists(['Setup', 'Group', 'NewMutator'])
	and $ini->get(['DE Mutators', 'Old Version']) == 100
	and $ini->exists(['NewMutator', 'Caption', 'The Great New Mutator'])) {
	print "ok 13\n";
} else { print "not ok 13\n"; }

# delete one value from a key
$ini->delete(['Setup', 'Group', 'Pinata']);
# delete whole key
$ini->delete(['DE Mutators', 'File']);
# delete whole section
$ini->delete(['Pinata']);
# delete whole section content but keep section
$ini->delete(['NIUT'], -keep => 1);
if (!$ini->exists(['Setup', 'Group', 'Pinata'])
	and !defined $ini->get(['DE Mutators', 'File'])
	and !defined $ini->get(['Pinata'])
	and !%{ $ini->get(['NIUT']) }) {
	print "ok 14\n";
} else { print "not ok 14\n"; }

# save function
$ini->save;
open TMPFILE, "<$tmpfile";
undef $/;
$wholefile = <TMPFILE>;
$/ = "\n";
close TMPFILE;
$shouldbe = <<EOT;
[Setup]
MasterProduct=UnrealTournament
Group=UnrealTournament
Group=DE Mutators
Group=NIUT
Group=NewMutator

[DE Mutators]
Caption=DE Mutators
Version=200
Requires=UnrealTournament
Old Version=100

[NIUT]

[Engine.GameEngine]
MasterServerAddress=unreal.epicgames.com MasterServerPort=27900
ServerActors=IpServer.UdpServerUplinkMasterServerAddress=master0.gamespy.com MasterServerPort=27900
ServerActors=IpServer.UdpServerUplinkMasterServerAddress=master.mplayer.com MasterServerPort = 27900

[NewMutator]
Caption=The Great New Mutator

EOT

if ($wholefile eq $shouldbe) {
	print "ok 15\n";
} else { print "not ok 15\n"; }

unlink $tmpfile;

# test encoder
$ini = new Win32::Registry::File();
$ini->registry(1);
$ini->put(['USERS_RIGHTS', 'SzValue', '"MyString"'], -add => 1);
$ini->put(['USERS_RIGHTS', 'Number', 123], -add => 1);
$ini->put(['USERS_RIGHTS', 'BigNumber', 0xffffffff], -add => 1);
$ini->put(['USERS_RIGHTS', 'NotSoBigNumber', 0x80000000], -add => 1);
$ini->put(['USERS_RIGHTS', 'ListOfNum', (1..9)], -add => 1);
$ini->put(['USERS_RIGHTS', 'ListOfStr', ('"str1"', '"str2"', '"str3"')],
	-add => 1);
$ini->put(['SecondSection', 'Number', 123], -add => 1);

if ($ini->exists(['USERS_RIGHTS', 'SzValue', '"MyString"'])
	and $ini->exists(['USERS_RIGHTS', 'Number', 'dword:0000007b'])
	and $ini->exists(['USERS_RIGHTS', 'BigNumber', 'dword:ffffffff'])
	and $ini->exists(['USERS_RIGHTS', 'NotSoBigNumber', 'dword:80000000'])
	and $ini->exists(['USERS_RIGHTS', 'ListOfNum',
		'hex:01,02,03,04,05,06,07,08,09'])
	and $ini->exists(['USERS_RIGHTS', 'ListOfStr',
		'hex(7):73,74,72,31,00,73,74,72,32,00,73,74,72,33,00,00'])
	and $ini->exists(['SecondSection', 'Number', 'dword:0000007b'])) {
	print "ok 16\n";
} else { print "not ok 16\n"; }

# test get/put
if ($ini->put(['USERS_RIGHTS', 'Number', 9999]) == 123
	and $ini->get(['USERS_RIGHTS', 'Number']) == 9999) {
	print "ok 17\n";
} else { print "not ok 17\n"; }

do { $tmpfile = tmpnam() } until open TMPFILE, ">$tmpfile";
$ini->save($tmpfile);

# test decoder
undef $ini;
$ini = new Win32::Registry::File($tmpfile);

if ($ini->get(['USERS_RIGHTS', 'SzValue']) eq "MyString"
	and $ini->get(['USERS_RIGHTS', 'Number']) == 9999
	and $ini->get(['USERS_RIGHTS', 'BigNumber']) == 4294967295
	and $ini->get(['USERS_RIGHTS', 'NotSoBigNumber']) == 2147483648
	and join(',', $ini->get(['USERS_RIGHTS', 'ListOfNum']))
		eq "1,2,3,4,5,6,7,8,9"
	and join(',', $ini->get(['USERS_RIGHTS', 'ListOfStr']))
		eq "str1,str2,str3"
	and $ini->get(['SecondSection', 'Number']) == 123) {
	print "ok 18\n";
} else { print "not ok 18\n"; }

unlink $tmpfile;

# test comment delimiter
do { $tmpfile = tmpnam() } until open TMPFILE, ">$tmpfile";
print TMPFILE <<EOT;
[Options]
Configured=1
GSversion=550
Version=2.7
Language=en
GhostscriptDLL=C:\\PROGRAM FILES\\GSTOOLS\\gs5.50\\gsdll32.dll
GhostscriptInclude=C:\\PROGRAM FILES\\GSTOOLS\\gs5.50;C:\\PROGRAM FILES\\GSTOOLS\\gs5.50\\fonts

[Measure]
XX=1		# new comment delimiter
XY=0		; old
YX=0		; again

[DEQData]
Winlist=t123;218 praivi;215 ptsk;209
EOT
close TMPFILE;
undef $ini;
$ini = new Win32::Registry::File($tmpfile, -commentdelim => '#');

if ($ini->get(['Options', 'GhostscriptInclude']) eq 'C:\\PROGRAM FILES\\GSTOOLS\\gs5.50;C:\\PROGRAM FILES\\GSTOOLS\\gs5.50\\fonts'
	and $ini->get(['Measure', 'XX']) eq '1'
	and $ini->get(['Measure', 'XY']) eq "0\t\t; old"
	and $ini->get(['DEQData', 'Winlist']) eq 't123;218 praivi;215 ptsk;209'
	) {
	print "ok 19\n";
} else { print "not ok 19\n"; }

# test regex comment delimiter
undef $ini;
$ini = new Win32::Registry::File;
$ini->commentdelim('[;#]');
$ini->open($tmpfile);
if ($ini->get(['Measure', 'XX']) eq '1'
	and $ini->get(['Measure', 'XY']) eq '0') {
	print "ok 20\n";
} else { print "not ok 20\n"; }

# test empty comment delimiter
undef $ini;
$ini = new Win32::Registry::File($tmpfile, -commentdelim => '');
if ($ini->get(['Measure', 'XY']) eq "0\t\t; old"
	and $ini->get(['Measure', 'YX']) eq "0\t\t; again") {
	print "ok 21\n";
} else { print "not ok 21\n"; }

unlink $tmpfile;
