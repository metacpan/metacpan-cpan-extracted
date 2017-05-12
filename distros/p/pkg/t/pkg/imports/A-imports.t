#!perl

use Test::Lib;
use Test::More;

{
    package test_a;
    use pkg 'A' => -import => 'tattle_ok';

    ::is( tattle_ok(), 'ok: A', 'A imports ok' );

}

{
    package test_b;

    use pkg 'A::C' => -import => 'tattle_ok';

    ::is( tattle_ok(), 'ok: A::C', 'A::C imports ok' );
}

done_testing;

