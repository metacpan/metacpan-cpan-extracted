#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


#<<< notidy

subtest 'empty = 1' => sub {
    my $t = Piddle [ empty => 1 ];

    ok(  $t->check( PDL->null ), 'PDL->null' );
    ok(  $t->check( PDL->new( [] ) ), 'PDL->new( [] )' );
    ok( !$t->check( PDL->new() ), 'PDL->new()' );

};

subtest 'empty = 0' => sub {

    my $t = Piddle [ empty => 0 ];

    ok( !$t->check( PDL->null ), 'PDL->null' );
    ok( !$t->check( PDL->new( [] ) ), 'PDL->new( [] )' );
    ok(  $t->check( PDL->new() ), 'PDL->new()' );

};

#>>> tidy once more
done_testing;
