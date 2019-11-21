package Util::Medley::Exec;
$Util::Medley::Exec::VERSION = '0.013';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Util::Medley::Crypt;

method encryptStr (Str :$str!,
				   Str :$key!) {

	my $crypt = Util::Medley::Crypt->new;
	my $encrypted = $crypt->encryptStr(str => $str, key => $key);
	say $encrypted;
}

method decryptStr (Str :$str!,
				   Str :$key!) {

	my $crypt = Util::Medley::Crypt->new;
	my $decrypted = $crypt->decryptStr(str => $str, key => $key);
	say $decrypted;
}

1;
