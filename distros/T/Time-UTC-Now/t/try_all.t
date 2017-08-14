use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Time::UTC::Now"; }

sub initial_digit_count($) {
	$_[0] =~ /\A([0-9]*)/;
	return length($1);
}

sub pad_tod($) { ("0" x (5 - initial_digit_count($_[0]))).$_[0] }

my $mechs = Time::UTC::Now::_try_all();
my($namesz, $daysz, $todsz, $boundsz) = (0, 0, 0, 0);
foreach(@$mechs) {
	my $n = length($_->{name});
	$namesz = $n if $n > $namesz;
	if(exists $_->{dayno}) {
		my $d = length($_->{dayno});
		$daysz = $d if $d > $daysz;
		my $t = length(pad_tod($_->{tod}));
		$todsz = $t if $t > $todsz;
	}
	if(exists $_->{bound}) {
		my $b = initial_digit_count($_->{bound});
		$boundsz = $b if $b > $boundsz;
	}
}
diag "mechanisms:";
foreach(@$mechs) {
	my $line = sprintf("%*s [%d] %d", $namesz, $_->{name},
			$_->{max_got}, $_->{got});
	$line .= sprintf(" %*s:%-*s", $daysz, $_->{dayno},
			$todsz, pad_tod($_->{tod}))
		if exists $_->{dayno};
	$line .= (" " x (1 + $boundsz - initial_digit_count($_->{bound}))).
			$_->{bound}
		if exists $_->{bound};
	$line =~ s/ +\z//;
	diag $line;
}
ok 1;

1;
