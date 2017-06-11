#!perl

use Test::Lib;
use Test2::Bundle::Extended;

use Parent;

subtest 'parent ok' => sub {

    my $p1 = Parent->new( value => 22 );

    is ( $p1, 22, 'initial value' );

    $p1 += 2;
    is( $p1, 24, '+=' );
    is( $p1->logs, [ [ 'Parent::+=' => 2 ] ], "log(+=)" );

    $p1 -= 5;
    is ( $p1, 19, '-=' );
    is( $p1->logs, [
            [ 'Parent::+=' => 2 ],
            [ 'Parent::-=' => 5 ],
        ], "log(-=)" );

};

done_testing;
