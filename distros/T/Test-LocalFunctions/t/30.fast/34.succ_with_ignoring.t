#!perl

use strict;
use warnings;
use utf8;
use FindBin;
push @INC, "$FindBin::Bin/../resource/lib";

# Test::LocalFunctions::Fast uses Compiler::Lexer.
# It is not up to user to install Compiler::Lexer.
BEGIN {
    use Test::More;
    eval 'use Compiler::Lexer';
    plan skip_all => "Compiler::Lexer required for testing Test::LocalFunctions::Fast" if $@ || $Compiler::Lexer::VERSION < 0.13;
}

use Test::LocalFunctions::Fast;

require "Test/LocalFunctions/Succ_with_ignore.pm";
local_functions_ok( "t/resource/lib/Test/LocalFunctions/Succ_with_ignore.pm", { ignore_functions => [ '_bar', '_baz', '\A_foobar'] } );

done_testing;
