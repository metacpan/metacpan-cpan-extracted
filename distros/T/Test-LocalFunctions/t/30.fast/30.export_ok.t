#!perl

use strict;
use warnings;

# Test::LocalFunctions::Fast uses Compiler::Lexer.
# It is not up to user to install Compiler::Lexer.
BEGIN {
    use Test::More;
    eval 'use Compiler::Lexer';
    plan skip_all => "Compiler::Lexer required for testing Test::LocalFunctions::Fast" if $@ || $Compiler::Lexer::VERSION  < 0.13;
}

use Test::LocalFunctions::Fast;

no strict 'subs';
can_ok( Test::LocalFunctions::Fast, qw/all_local_functions_ok local_functions_ok/ );
use strict;

done_testing;
