#!perl -w

# to resolve RT 41639

use strict;

use Test::More tests => 5;
use Test::Warn;
use overload (); # pre-load for debugging

use warnings;
use warnings::unused;
{
	my $orig = \&Test::Warn::_cmp_like;
	no warnings 'redefine';
	*Test::Warn::_cmp_like = sub{
		my($got, $expected) = @_;
		@_ = ([sort { $a->{warn} cmp $b->{warn} } @$got],
			  [sort { $a->{warn} cmp $b->{warn} } @$expected]);
		goto &$orig;
	};
}

warning_like { eval q{
#line 27 06_multiscope.t(eval)

	my $x;
	{
		my $x;
		# $x is not used
	}

	{
		my $x;
		$x++;
	}
	1;
} or die $@;
} [qr/^Unused .* line 28/, qr/^Unused .* line 30/];



warning_like { eval q{
#line 45 06_multiscope.t(eval)

	my $x;
	do{
		my $x;
		# $x is not used
	};

	do{
		my $x;
		$x++;
	};
	1;
} or die $@;
} [qr/^Unused .* line 46/, qr/^Unused .* line 48/];

warning_like { eval q{
#line 62 06_multiscope.t(eval)

	my $x;
	do{
		my $x;
	};
	do{
		my $x;
	};
	$x++;
	1;
} or die $@;
} [qr/^Unused .* line 65/, qr/^Unused .* line 68/];



warning_like { eval q{
#line 79 06_multiscope.t(eval)

	my $x;
	do{
		no warnings 'once';
		my $x;
	};
	do{
		my $x;
	};
	1;
} or die $@;
} [qr/^Unused .* line 80/, qr/^Unused .* line 86/];

warning_like { eval q{
#line 94 06_multiscope.t(eval)

	my $x;
	do{
		my $x;
	};
	do{
		no warnings 'once';
		my $x;
	};
	1;
} or die $@;
} [qr/^Unused .* line 95/, qr/^Unused .* line 97/];
