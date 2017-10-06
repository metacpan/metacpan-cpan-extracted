#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


#<<< notidy

subtest 'null = 1' => sub {
    my $t = Piddle [ null => 1 ];

    ok(  $t->check( PDL->null ), 'PDL->null' );
    ok( !$t->check( PDL->new() ), 'PDL->new()' );

};

subtest 'null = 0' => sub {

    my $t = Piddle [ null => 0 ];

    ok( !$t->check( PDL->null ), 'PDL->null' );
    ok(  $t->check( PDL->new() ), 'PDL->new()' );

};

#>>> tidy once more
done_testing;
