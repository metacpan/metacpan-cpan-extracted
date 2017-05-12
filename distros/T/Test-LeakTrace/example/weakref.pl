#!perl -w

use strict;
use Test::More tests => 1;
use Test::LeakTrace qw(:test);


{
	package X;
	use Scalar::Util qw(weaken);

	sub new{
		my($class) = @_;

		my $self = bless {}, $class;

		return $self;
	}

	sub set_other{
		my($self, $other) = @_;
		weaken($self->{other} = $other) if $other;
		return $self;
	}
}

no_leaks_ok{
	my $a = X->new;
	my $b = X->new;

	$a->set_other($b);
	$b->set_other($a);

};
