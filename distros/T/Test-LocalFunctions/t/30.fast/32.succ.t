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

foreach my $lib (map{"t/resource/lib/Test/LocalFunctions/Succ$_.pm"} 1..1) {
    if ($lib =~ /Succ\d*.pm/) {
        require "Test/LocalFunctions/$&";
    }
    local_functions_ok($lib);
}

done_testing;
