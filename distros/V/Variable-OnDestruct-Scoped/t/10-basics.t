#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;
use Test::Differences;

use Variable::OnDestruct::Scoped;
use Symbol qw/gensym/;

sub DESTROY {
	die;
}

{
	my $counter = 0;
	{
	my $self = on_destruct my @array2, sub { $counter = 1 };
	undef $self;
	}
	is $counter, 0, "Second array didn't trigger!";
}

my @success = sort qw/scalar array hash code glob/;
{
	my %got;

	{
		my $var = 'foo';
		my $sub = sub { $var };
		my $glob = gensym();

		on_destruct my %hash,      sub { $got{hash}++ };
		on_destruct $var,       sub { $got{scalar}++ };
		on_destruct &{ $sub },  sub { $got{code}++ };
		on_destruct *{ $glob }, sub { $got{glob}++ };
		on_destruct my @array,  sub { $got{array}++ };
	}
	eq_or_diff [ sort keys %got ], \@success, 'Destructors were called';
}

{
	my %got;

	{
		my $var = 'foo';
		my $sub = sub { $var };
		my $glob = gensym();

		my @throwaway;
		push @throwaway, on_destruct $var,       sub { $got{scalar}++ };
		push @throwaway, on_destruct my @array,  sub { $got{array}++ };
		push @throwaway, on_destruct my %hash,   sub { $got{hash}++ };
		push @throwaway, on_destruct &{ $sub },  sub { $got{code}++ };
		push @throwaway, on_destruct *{ $glob }, sub { $got{glob}++ };
		@throwaway = ();
	}
	eq_or_diff [ sort keys %got ], [], 'Destructors were not called again';
}

{
	my @handles;
	my %got;

	{
		my $var = 'foo';
		my $sub = sub { $var };
		my $glob = gensym();

		push @handles, on_destruct $var,       sub { $got{scalar}++ };
		push @handles, on_destruct my @array,  sub { $got{array}++ };
		push @handles, on_destruct &{ $sub },  sub { $got{code}++ };
		push @handles, on_destruct my %hash,   sub { $got{hash}++ };
		push @handles, on_destruct *{ $glob }, sub { $got{glob}++ };
	}
	eq_or_diff [ sort keys %got ], \@success, 'Destructors were called once more';
}
