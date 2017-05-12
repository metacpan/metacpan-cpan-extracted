#!/usr/bin/env perl

use Test::More tests => 11
	+do { eval { require Test::NoWarnings;Test::NoWarnings->import; 1 } || 0 };
use uni::perl 0.9;

my $char = "а";
ok(utf8::is_utf8($char), 'utf8 works');
eval q{ $zzz; };
like($@, qr/Global symbol "\$zzz" requires explicit package/, 'strict works');

eval q{ say "# say() should be available"; };
is( $@, '', 'say() should be available' );

eval q{ state $x };
is( $@, '', 'state should be available' );

eval q{ given($_) { default {} } };
is( $@, '', 'switch should be available' );

eval<<'END_CLASSES';
package A; $A::VERSION = 1;
package B; @B::ISA = 'A';
package C; @C::ISA = 'A';
package D;
use uni::perl;
@D::ISA = qw( B C );
END_CLASSES
;
package main;

is_deeply( mro::get_linear_isa( 'D' ), [qw( D B C A )], 'mro should use C3' );

{
	no uni::perl;
	
	my $char = "а";
	ok(!utf8::is_utf8($char), 'utf8 disabled');
	eval q{ $zzz; };
	is($@, '', 'strict disabled');

	eval q{ say "# say() should be available"; };
	isnt( $@, '', 'say() shouldnt be available' );

	eval q{ state $x };
	isnt( $@, '', 'state shouldnt be available' );

	eval q{ given($_) { default {} } };
	isnt( $@, '', 'switch shouldnt be available' );
}
