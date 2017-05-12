use Test::Simple tests => 6;
use Test::Pockito;

use Test::Pockito::DefaultMatcher qw(is_defined is_array);

use strict;
use warnings;

{
    my @params_called   = ( 1, 2, 3 );
    my @params_expected = ( 1, 2, 3 );

    my ($found) =
      Test::Pockito::DefaultMatcher::default_call_match( "some package",
        "some method", \@params_called, \@params_expected );

    ok( $found == 1, "Comparing same size things is fine" );
}

{
    my @params_called   = (1);
    my @params_expected = ( 1, undef, undef );
    my @call_result     = ( 4, 5, 6 );

    my ($found) =
      Test::Pockito::DefaultMatcher::default_call_match( "some package",
        "some method", \@params_called, \@params_expected );
    ok( $found == 1, "Comparing different size things w/ undefs in one match" );
}

{
    my @params_called   = (1);
    my @params_expected = ();

    my ($found) =
      Test::Pockito::DefaultMatcher::default_call_match( "some package",
        "some method", \@params_called, \@params_expected );
    ok( $found == 0,
        "Comparing different size things w/ right side has nothing" );
}

{
    my @params_called   = ();
    my @params_expected = (1);

    my ($found) =
      Test::Pockito::DefaultMatcher::default_call_match( "some package",
        "some method", \@params_called, \@params_expected );
    ok( $found == 0,
        "Comparing different size things w/ left side has nothing" );
}

{
    my @params_called = ( 1, 2, [3] );
    my @params_expected = ( is_defined, 2, is_array );

    my $found =
      Test::Pockito::DefaultMatcher::default_call_match( "some package",
        "some method", \@params_called, \@params_expected );

    ok( $found == 1, "Matcher methods work" );

}

{
    my @params_called = ( 1, [2], 3 );
    my @params_expected = ( is_defined, 2, is_array );

    my $found =
      Test::Pockito::DefaultMatcher::default_call_match( "some package",
        "some method", \@params_called, \@params_expected );

    ok( $found == 0,
        "Matcher methods work in not matching things it shouldn't" );

}
