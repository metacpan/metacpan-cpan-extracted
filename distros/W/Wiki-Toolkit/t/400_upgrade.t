use 5.006;
use strict;
use warnings;

use Test::More;
use Wiki::Toolkit;
use Wiki::Toolkit::TestLib;
use Wiki::Toolkit::Setup::Database;

my $test_sql = {
    10 => [ qq|
INSERT INTO node (id, name, version, text, modified) VALUES (1, 'Test node 1', 1, 'Some content', 'now')|, qq|
INSERT INTO node (id, name, version, text, modified) VALUES (2, 'Test node 2', 1, 'More content', 'now')|, qq|
INSERT INTO content (node_id, version, text, modified, comment) VALUES (1, 1, 'Some content', 'now', 'no comment')|, qq|
INSERT INTO content (node_id, version, text, modified, comment) VALUES (2, 1, 'More content', 'now', 'no comment')|, qq|
INSERT INTO metadata VALUES (1, 1, 'foo', 'bar')|, qq|
INSERT INTO metadata VALUES (2, 1, 'baz', 'quux')| ],
};

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;
my @configured_databases = $iterator->configured_databases;
my @schemas_to_test;

use Wiki::Toolkit::Setup::SQLite;

foreach my $db (@configured_databases) {
    my $setup_class = $db->{setup_class};
    eval "require $setup_class";
    my $current_schema;
    {
        no strict 'refs';
        $current_schema = eval ${$setup_class . '::SCHEMA_VERSION'};
    }
    foreach my $schema (@Wiki::Toolkit::Setup::Database::SUPPORTED_SCHEMAS) {
        push @schemas_to_test, $schema if $schema < $current_schema;
    }
}

my $num_tests = (scalar @schemas_to_test * scalar @configured_databases * 2);
if ( $num_tests == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => $num_tests;
}

foreach my $database (@configured_databases) {
    my $setup_class = $database->{setup_class};
    my $current_schema;
    {
        no strict 'refs';
        $current_schema = eval ${$setup_class . '::SCHEMA_VERSION'};
    }
    foreach my $schema (@schemas_to_test) {
        # Don’t try testing upgrades from schema 10 on MySQL because this
        # schema will just fail if MySQL has strict turned on.
        SKIP: {
            if ( $schema == 10
                 && $setup_class eq "Wiki::Toolkit::Setup::MySQL" ) {
                skip "Not testing upgrades from schema 10 on MySQL", 2;
            }

            # Set up database with old schema
            my $params = $database->{params};
            $params->{wanted_schema} = $schema;

            {
              no strict 'refs';
              eval &{$setup_class . '::cleardb'} ( $params );
              eval &{$setup_class . '::setup'} ( $params );
            }

            my $class = $database->{class};
            eval "require $class";

            my $dsn = $database->{dsn};

            my $dbh = DBI->connect($dsn, $params->{dbuser}, $params->{dbpass});

            foreach my $sql (@{$test_sql->{$schema}}) {
                $dbh->do($sql);
            }

            # Upgrade to current schema
            delete $params->{wanted_schema};
            {
              no strict 'refs';
              eval &{$setup_class . '::setup'} ( $params );
            }

            # Make sure the data looks plausible.
            my $store = $class->new( %{$params} );
            my %wiki_config = ( store => $store );
            my $wiki = Wiki::Toolkit->new( %wiki_config );
            is( $wiki->retrieve_node("Test node 1"), "Some content",
                "can retrieve 1st test node after $schema to $current_schema");
            is( $wiki->retrieve_node("Test node 2"), "More content",
                "can retrieve 2nd test node after $schema to $current_schema");
        }
    }
}
