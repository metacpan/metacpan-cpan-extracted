#!perl

use strict;
use warnings;
use utf8;

# Test::LocalFunctions::Fast uses Compiler::Lexer.
# It is not up to user to install Compiler::Lexer.
BEGIN {
    use Test::More;
    eval 'use Compiler::Lexer';
    plan skip_all => "Compiler::Lexer required for testing Test::LocalFunctions::Fast" if $@ || $Compiler::Lexer::VERSION < 0.13;
}

use Test::LocalFunctions::Fast;

all_local_functions_ok();

done_testing;
