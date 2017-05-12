#!perl

use strict;
use warnings;
use Test::More;
select(($|=1,select(STDERR),$|=1)[1]);


plan skip_all => 'Example file for when we do want spell checking';

my (@testfiles, @perlfiles, @textfiles, @commentfiles, $fh);

if (!eval { require Text::SpellChecker; 1 }) {
	plan skip_all => 'Could not find Text::SpellChecker';
}
else {
	opendir my $dir, 't' or die qq{Could not open directory 't': $!\n};
	@testfiles = map { "t/$_" } grep { /^.+\.(t|pl)$/ } readdir $dir;
	closedir $dir or die qq{Could not closedir "$dir": $!\n};

	open my $fh, '<', 'MANIFEST' or die qq{Could not open the MANIFEST file: $!\n};
	while (<$fh>) {
		next unless /(.*\.pm)/;
		push @perlfiles, $1;
	}
	close $fh or die qq{Could not close the MANIFEST file: $!\n};

	@textfiles = qw/README Changes LICENSE ToDo/;

	@commentfiles = (@testfiles, 'Makefile.PL', @perlfiles);

	plan tests => @textfiles + @perlfiles + @commentfiles;
}

my %okword;
my $file = 'Common';
while (<DATA>) {
	if (/^## (.+):/) {
		$file = $1;
		next;
	}
	next if /^#/ or ! /\w/;
	for (split) {
		$okword{$file}{$_}++;
	}
}

sub spellcheck {
	my ($desc, $text, $file) = @_;
	my $check = Text::SpellChecker->new(text => $text);
	my %badword;
	my $class = $file =~ /\.pm$/ ? 'Perl' : $file =~ /\.t$/ ? 'Test' : '';
	while (my $word = $check->next_word) {
		next if $okword{Common}{$word} or $okword{$file}{$word} or $okword{$class}{$word};
		$badword{$word}++;
	}
	my $count = keys %badword;
	if (! $count) {
		pass ("Spell check passed for $desc");
		return;
	}
	fail ("Spell check failed for $desc. Bad words: $count");
	for (sort keys %badword) {
		diag "$_\n";
	}
	return;
}


## General spellchecking
for my $file (@textfiles) {
	if (!open $fh, '<', $file) {
		fail (qq{Could not find the file "$file"!});
	}
	else {
		{ local $/; $_ = <$fh>; }
		close $fh or warn qq{Could not close "$file": $!\n};
		spellcheck ($file => $_, $file);
	}
}

## Now the embedded POD
SKIP: {
	if (!eval { require Pod::Spell; 1 }) {
		my $files = @perlfiles;
		skip ('Need Pod::Spell to test the spelling of embedded POD', $files);
	}

	for my $file (@perlfiles) {
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = qx{podspell $file};
		spellcheck ("POD from $file" => $string, $file);
	}
}

## Now the comments
SKIP: {
	if (!eval { require File::Comments; 1 }) {
		my $files = @commentfiles;
		skip ('Need File::Comments to test the spelling inside comments', $files);
	}

	my $fc = File::Comments->new();

	for my $file (@commentfiles) {
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = $fc->comments($file);
		if (! $string) {
			fail (qq{Could not get comments from file $file});
			next;
		}
		$string = join "\n" => @$string;
		$string =~ s/=head1.+//sm;
		spellcheck ("comments from $file" => $string, $file);
	}

}


__DATA__
## These words are okay

## Common:

afterwards
altblue
API
arcfour
arg
autarch
auth
Auth
AUTH
authfile
Authfile
AuthMgr
AUTOLOAD
Bas
BatchMode
Beatson
bigint
bigints
BindAddress
bitmask
bitwise
blackmans
blowfish
Blowfish
boolean
Bramley
btrott
BubbleBabble
Callis
cbc
CFB
ChallengeResponse
ChallengeResponseAuthentication
ChannelMgr
checksum
cmd
CMSG
CompressionLevel
config
Config
cpan
CPAN
CPANPLUS
crc
CRC
ctrl
dan
dans
datatype
dbrobins
DBROBINS
de
des
dev
dgehl
Diffie
dir
Dorrah
DSA
dss
eg
env
ENV
eof
EOF
et
eval
everyone's
executables
filehandle
filehandles
FILENO
fujitsu
getpwuid
getservbyname
GMP
GPL
hmac
HMAC
hostfile
HostKeyAlgorithms
html
http
IdentityFile
ie
init
IP
ipmq
iqmp
issh
istate
Jurado
katipo
Kex
KeyboardInt
keyfiles
keygen
Kineticode
Koneru
len
Ley
licensor
linearize
login
Login
lookup
manpage
Makefile
matt
MCPAN
md
MERCHANTIBILITY
mixup
mpe
msg
Mullane
namespace
NetScreen
nz
ol
OO
openssh
OpenSSH
OpenSSL
Paetznick
param
params
parens
Pari
passphrase
passphrases
PasswordPromptHost
PasswordPromptLogin
pch
PEM
perl
plugins
prereq
prereqs
programatically
pscp
pssh
pty
Pubkey
publickey
PublicKey
rcable
rcp
ReadKey
README
reblessed
redistributors
remoteinteract
Rhosts
Rolsky
rsa
RSA
Sabino
sackheads
Sagar
Scheid
Schwern
scp
sdk
SFTP
sha
SHA
shosts
Silverstein
Sisseren
SMSG
Spellcheck
sshd
stderr
STDERR
stdin
STDIN
stdout
STDOUT
str
StringThing
sublicense
substr
subsystems
sudo
syswrite
textfiles
TIS
ToDo
Tolsma
Trostler
Trott
turnstep
TURNSTEP
Tyrrell
uk
untainting
username
usr
Util
uu
versa
Vopata
wildcard
www
xray
xs
YAML
YAMLiciousness
yml
zlib
Zlib

## Test

spellchecking
