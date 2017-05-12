use Test::More tests => 17;

use_ok( "Wiki::Toolkit" );
use_ok( "Wiki::Toolkit::Formatter::Default" );
use_ok( "Wiki::Toolkit::Plugin" );
use_ok( "Wiki::Toolkit::Search::Base" );

eval { require DBIx::FullTextSearch; };
SKIP: {
        skip "DBIx::FullTextSearch not installed", 1 if $@;
        use_ok( "Wiki::Toolkit::Search::DBIxFTS" );
}

eval { require Search::InvertedIndex; };
SKIP: {
        skip "Search::InvertedIndex not installed", 2 if $@;
        use_ok( "Wiki::Toolkit::Search::SII" );
        use_ok( "Wiki::Toolkit::Setup::SII" );
}

eval { require Plucene; };
SKIP: {
        skip "Plucene not installed", 1 if $@;
        use_ok( "Wiki::Toolkit::Search::Plucene" );
}

eval { require Lucy; };
SKIP: {
        skip "Lucy not installed", 1 if $@;
        use_ok( "Wiki::Toolkit::Search::Lucy" );
}

use_ok( "Wiki::Toolkit::Setup::MySQL" );
use_ok( "Wiki::Toolkit::Setup::Pg" );
use_ok( "Wiki::Toolkit::Setup::SQLite" );
use_ok( "Wiki::Toolkit::Store::Database" );
use_ok( "Wiki::Toolkit::Store::MySQL" );
use_ok( "Wiki::Toolkit::Store::Pg" );
use_ok( "Wiki::Toolkit::Store::SQLite" );

use_ok( "Wiki::Toolkit::Formatter::Multiple" );
