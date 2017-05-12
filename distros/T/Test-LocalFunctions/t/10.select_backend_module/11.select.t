#!perl

use strict;
use warnings;

use Test::More;

use Test::LocalFunctions;

subtest 'Should select rightly' => sub {
    eval {require Compiler::Lexer};
    my $should_inc     = 'Test/LocalFunctions/Fast.pm';
    my $should_not_inc = 'Test/LocalFunctions/PPI.pm';
    my $expect_backend = 'Test::LocalFunctions::Fast';
    if ( $@ || $Compiler::Lexer::VERSION < 0.13 ) {
        $should_inc     = 'Test/LocalFunctions/PPI.pm';
        $should_not_inc = 'Test/LocalFunctions/Fast.pm';
        $expect_backend = 'Test::LocalFunctions::PPI';
    }
    ok $INC{$should_inc};
    ok not $INC{$should_not_inc};
    is Test::LocalFunctions::which_backend_is_used(), $expect_backend;
};
done_testing;
