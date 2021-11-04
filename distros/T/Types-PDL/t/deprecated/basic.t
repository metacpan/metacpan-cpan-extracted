#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


#<<< notidy

ok(  Piddle->check( PDL->new ), 'piddle' );
ok( !Piddle->check( 0 ),        'scalar number' );
ok( !Piddle->check( '0' ),      'scalar string' );
ok( !Piddle->check( \my $foo ), 'reference' );

#>>> tidy once more
done_testing;
