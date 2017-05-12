#!perl

use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use Test::Tester;
use Test::More;

use Test::Vars;

my %errors = (
    Warned1 => [ [ '$an_unused_var', 'foo', 6 ] ],
    Warned2 => [ [ '@an_unused_var', 'foo', 6 ] ],
    Warned3 => [ [ '%an_unused_var', 'foo', 6 ] ],
    Warned4 => [ [ '$an_unused_var', 'foo', 6 ] ],

    # For some version of Perl, we get the warning on line 6 twice, for others
    # we get 6 and 7.
    Warned5 => [
        [ '$unused_var', 'foo', 6 ],
        [ '$unused_var', 'foo', [ 6, 7 ] ],
    ],
    Warned6 => [ [ '$unused_param', 'foo', 6 ] ],

    # The diag output from Warned7 is not in a predictable order, so we have
    # to ignore it.
    Warned7 => [
        [ '$unused_var', 'foo', 6 ],
        [ '$unused_var', 'bar', 13 ],
    ],
);

foreach my $package ( sort keys %errors ) {
    my $errors = $errors{$package};
    my $path = catfile( qw( t lib ), "$package.pm" );
    my $unix_path = "t/lib/$package.pm";

    my ( $premature, @results ) = run_tests( sub { vars_ok($path) } );
    ok( !$premature, "var_ok($path) had no premature output" );
    is( scalar @results, 1, "got one result from vars_ok($path)" );
    is(
        $results[0]{fail_diag}, "\tFailed test ($0 at line 39)\n",
        'failure message comes from inside this test file'
    );

    if ( @{$errors} == 1 ) {
        like(
            $results[0]{diag},
            _error( @{ $errors->[0] }, $package, $unix_path ),
            "expected diag() from vars_ok($path)"
        );
    }
    else {
        my @errors = map { _error( @{$_}, $package, $unix_path ) } @{$errors};
        like(
            $results[0]{diag},
            qr/$errors[0]$errors[1]|$errors[1]$errors[0]/,
            "expected diag() from vars_ok($path)"
        );
    }
}

sub _error {
    my ( $var, $sub, $line, $package, $path ) = @_;

    $line
        = ref $line
        ? qr/(?:$line->[0]|$line->[1])/
        : qr/$line/;

    return qr/\Q$var is used once in &${package}::$sub at $path line \E$line\n/;
}

done_testing;
