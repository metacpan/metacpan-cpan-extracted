#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Ollama' ) || print "Bail out!\n";
}

diag( "Testing WebService::Ollama $WebService::Ollama::VERSION, Perl $], $^X" );
