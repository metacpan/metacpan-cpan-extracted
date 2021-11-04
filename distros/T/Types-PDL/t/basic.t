#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


#<<< notidy

ok(  NDArray->check( PDL->new ), 'NDArray' );
ok( !NDArray->check( 0 ),        'scalar number' );
ok( !NDArray->check( '0' ),      'scalar string' );
ok( !NDArray->check( \my $foo ), 'reference' );

#>>> tidy once more
done_testing;
