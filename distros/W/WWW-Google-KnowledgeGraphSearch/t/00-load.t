#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok( 'WWW::Google::KnowledgeGraphSearch' )         || print "Bail out!\n";
    use_ok( 'WWW::Google::KnowledgeGraphSearch::Result' ) || print "Bail out!\n";
}

diag( "Testing WWW::Google::KnowledgeGraphSearch $WWW::Google::KnowledgeGraphSearch::VERSION, Perl $], $^X" );

done_testing();
