package uni::perl::xd;

use uni::perl;
m{
use strict;
use warnings;
}x;

sub xd ($;$) {
	if( eval{ require Devel::Hexdump; 1 }) {
		no strict 'refs';
		*{ caller().'::xd' } = \&Devel::Hexdump::xd;
	} else {
		no strict 'refs';
		*{ caller().'::xd' } = sub($;$) {
			my @a = unpack '(H2)*', $_[0];
			my $s = '';
			for (0..$#a/16) {
				$s .= "@a[ $_*16 .. $_*16 + 7 ]  @a[ $_*16+8 .. $_*16 + 15 ]\n";
			}
			return $s;
		};
	}
	goto &{ caller().'::xd' };
}

sub import {
	my $me = shift;
	my $caller = shift || caller;
	$me->load($caller);
	@_ = ('uni::perl');
	goto &uni::perl::import;
}

sub load {
	my $me = shift;
	my $caller = shift;
	no strict 'refs';
	*{ $caller .'::xd' } = \&xd;
	return;
}

1;
