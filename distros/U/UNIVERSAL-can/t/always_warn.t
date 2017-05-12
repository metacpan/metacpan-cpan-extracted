#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 2;
use Test::SmallWarn;

# must happen here to register warnings category
BEGIN { use_ok( 'UNIVERSAL::can', '-always_warn' ) };

{
	package Demo;

	sub new { bless {}, shift }

	sub can
	{
		my ($self, $method) = @_;
		return $self->SUPER::can( $method );
	}
}

my $demo = Demo->new( 'Demo' );
{
	no warnings;
	warning_like { UNIVERSAL::can( $demo, 'new' ) }
		qr/Called UNIVERSAL::can/,
		'-always_warn flag should make module always warn';
}
