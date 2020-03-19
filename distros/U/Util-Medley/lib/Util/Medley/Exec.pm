package Util::Medley::Exec;
$Util::Medley::Exec::VERSION = '0.026';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Util::Medley::Crypt;
use Util::Medley::Number;

=head1 NAME

Util::Medley::Exec - proxy for cmdline to libs

=head1 VERSION

version 0.026

=cut

method commify (Num :$val!) {

	my $num = Util::Medley::Number->new;
	say $num->commify($val);
}

method decommify (Str :$val!) {

	my $num = Util::Medley::Number->new;
	say $num->decommify( $val );
}

method encryptStr (Str :$str!,
				   Str :$key) {

	my %a;
	$a{str} = $str;
	$a{key} = $key if $key;

	my $crypt = Util::Medley::Crypt->new;
	say $crypt->encryptStr(%a);
}

method decryptStr (Str :$str!,
				   Str :$key) {

	my %a;
	$a{str} = $str;
	$a{key} = $key if $key;

	my $crypt = Util::Medley::Crypt->new;
	say $crypt->decryptStr(%a);
}

1;
