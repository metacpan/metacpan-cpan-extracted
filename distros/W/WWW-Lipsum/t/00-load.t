#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;

BEGIN {
    use_ok('Carp');
    use_ok('LWP::UserAgent');
    use_ok('Mojo::DOM');
    use_ok('Moo');
    use_ok('WWW::Lipsum') || print "Bail out!\n";
}

diag( "Testing WWW::Lipsum $WWW::Lipsum::VERSION, Perl $], $^X" );
