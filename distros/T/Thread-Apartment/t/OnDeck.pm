package OnDeck;
#
#	test POPO
#
#use Thread::Apartment::Server;

#use base qw(Thread::Apartment::Server);

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	my $obj = bless {
		_onThird => $args{ThirdBase},
		}, $class;
#	$obj->set_client(delete $args{AptTAC});
	return $obj;
}

sub onDeck {	# simplex method
	my $obj = shift;
	my $thirdBase = $obj->{_onThird};
#	print STDERR "OnDeck calling thridbase at ", time(), "\n";
	$obj->{_case} = $thirdBase->getCase();
#	print STDERR "OnDeck called thridbase got $obj->{_case} at ", time(), "\n";
	return 1;
}

sub batterUp {
	my $obj = shift;

	return $obj->{_case} ?
		(($obj->{_case} eq 'uc') ? 'BATTER UP!' : 'batter up') :
		undef;
}

sub get_simplex_methods {
#	return { onDeck => 1 };
	return {};
}

1;