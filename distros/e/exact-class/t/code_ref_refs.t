use Test::Most;

my $counter = 0;

package Thing {
    use exact 'class';

    has alpha => \ sub {
        return ++$counter;
    };

    has beta => \ sub {
        return ++$counter;
    };
}

my $thing = Thing->new;

is( $thing->alpha->(), 1, 'code ref ref call 1' );
is( $thing->beta ->(), 2, 'code ref ref call 2' );
is( $thing->alpha->(), 3, 'code ref ref call 3' );
is( $thing->beta ->(), 4, 'code ref ref call 4' );

done_testing();
