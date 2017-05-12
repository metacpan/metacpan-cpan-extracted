package Test::SmallWarn;

use strict;
use warnings;

use Test::More;

sub import
{
	my $caller = caller();

	no strict 'refs';
	*{ $caller . '::warning_like' } = \&warning_like;
	*{ $caller . '::warnings_are' } = \&warnings_are;
}

sub warning_like (&$;$)
{
	my ($code, $regex, $description) = @_;

	my $warning          = '' ;
	local $SIG{__WARN__} = sub { $warning .= shift };

	$code->();
	like( $warning, $regex, $description );
}

sub warnings_are (&$;$)
{
	my ($code, $expected, $description) = @_;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, shift };

	$code->();
	is( "@warnings", "@$expected", $description );
}

1;
