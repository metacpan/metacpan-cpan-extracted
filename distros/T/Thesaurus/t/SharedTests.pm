package SharedTests;

use strict;

use Test::More;

my $tests = 14;
sub run_tests
{
    my %p = @_;

    if ( $p{require} )
    {
        eval "require $p{require}";
        if ( $@ =~ /locate/ )
        {
            plan skip_all => "These tests require $p{require}";
            exit;
        }
    }

    $tests += $p{extra_tests} || 0;

    plan tests => $tests;

    use_ok( $p{class} );

    my $p = $p{p} || {};

    {
        my $th = $p{class}->new(%$p);

        $th->add( [ qw( a b c d E f ) ],
                  [ qw( 1 2 3 HELLO hello ) ] );

        my @words = sort $th->find('a');
        is( scalar @words, 6,
            "six matches should be returned" );

        my $x = 0;
        foreach ( qw( E a b c d f ) )
        {
            is( $words[$x++], $_,
                "\$words[$x] should be $_" );
        }

        my @find_A = $th->find('A');
        is( scalar @find_A, 0,
            "the object should be case sensitive for searches" );

        $th->delete('E');

        is( scalar $th->find('a'), 0,
            "delete should remove all items in a list" );
    }

    {
        my $th = $p{class}->new( %$p, ignore_case => 1 );

        $th->add( [ qw{ a b c d E f } ],
                  [ qw{ 1 2 3 HELLO hello } ] );

        is( scalar $th->find('e'), 6,
            "object should be case insensitive" );

        is( scalar $th->find('E'), 6,
            "object should be case insensitive (second test)" );

        $th->add( ['e', 'q'], [7, 8] );

        is( scalar $th->find('q'), 8,
            "adding multiple lists at once" );

        is( scalar $th->find('7'), 2,
            "adding multiple lists at once (second test)" );
    }
}

1;
