#!/usr/bin/env perl

use Test::More tests => 9;

BEGIN
{
	use_ok( 'nextgen' ) or exit;
	nextgen->import();
}


eval 'say "# say() should be available";';
is( $@, '', 'say() should be available' );

{
eval '$x = 1;';
	like(
		$@
		, qr/Global symbol "\$x" requires explicit/
		, 'strict should be enabled'
	);
}

my $warnings;
local $SIG{__WARN__} = sub { $warnings = shift };
my $y =~ s/hi//;
like( $warnings, qr/Use of uninitialized value/, 'warnings should be enabled' );

{
	eval { main->new };
	like (
		$@
		, qr/Can't locate object method "new" via package "main"/
		, 'did not install new in main implicit :procedural'
	);
}

## Can't test this which seems to generate parser error
## eval { new D };
## like ( $@, qr/Indirect call of method "new"/, 'indirect' )

package Class;
use nextgen mode => [qw(:procedural)];

{
	eval { Class->new };
	Test::More::like( $@, qr/Can't locate object method "new" via package "Class"/, ':procedural did not turn this into a Class' );
}

{
	eval "use NEXT;";
	Test::More::like( $@, qr/nextgen::blacklist/, 'use on NEXT resulted in black-list exception' );
}

{
	eval "require 'NEXT.pm';";
	Test::More::like( $@, qr/nextgen::blacklist/, 'require on "NEXT.pm" resulted in black-list exception' );
}

{
	eval "require NEXT;";
	Test::More::like( $@, qr/nextgen::blacklist/, 'require on "NEXT" module resulted in black-list exception' );
}
