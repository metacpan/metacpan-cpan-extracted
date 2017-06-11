#!perl

use Test::Lib;
use Test2::Bundle::Extended;

{
    package C1;

    use base qw[ Parent ];

    # do everything
    use overload::reify;
}

subtest "method" => sub {

    my $c1 = C1->new;
    $c1 += 2;
    is( $c1->logs, [ [ "Parent::+=" => 2 ], ], "operator" );

    $c1->operator_add_assign( 3 );
    is( $c1->logs, [ [ "Parent::+=" => 2 ],
                    [ "Parent::+=" => 3 ],
        ], "method" );

};

subtest "coderef" => sub {

    my $c1 = C1->new;
    $c1 -= 2;
    is( $c1->logs, [ [ "Parent::-=" => 2 ], ], "operator" );

    $c1->operator_subtract_assign( 3 );
    is( $c1->logs, [ [ "Parent::-=" => 2 ],
                    [ "Parent::-=" => 3 ],
        ], "method" );

};

done_testing;
