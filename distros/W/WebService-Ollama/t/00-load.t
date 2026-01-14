#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'WebService::Ollama' ) || print "Bail out!\n";
    use_ok( 'WebService::Ollama::Async' ) || print "Bail out!\n";
    use_ok( 'WebService::Ollama::Response' ) || print "Bail out!\n";
    use_ok( 'WebService::Ollama::UA' ) || print "Bail out!\n";
}

diag( "Testing WebService::Ollama $WebService::Ollama::VERSION, Perl $], $^X" );
