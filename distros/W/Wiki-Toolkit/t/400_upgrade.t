use 5.006;
use strict;
use warnings;

use Test::More;
use Wiki::Toolkit;
use Wiki::Toolkit::TestLib;
use Wiki::Toolkit::Setup::Database;

# XXX needs to be more exhaustive
my $test_sql = {
    8 => [ qq|
INSERT INTO node VALUES (1, 'Test node 1', 1, 'Some content', 'now')|, qq|
INSERT INTO node VALUES (2, 'Test node 2', 1, 'More content', 'now')|, qq|
INSERT INTO content VALUES (1, 1, 'Some content', 'now', 'no comment')|, qq|
INSERT INTO content VALUES (2, 1, 'More content', 'now', 'no comment')|, qq|
INSERT INTO metadata VALUES (1, 1, 'foo', 'bar')|, qq|
INSERT INTO metadata VALUES (2, 1, 'baz', 'quux')| ],
    9 => [ qq|
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

my $num_mysql_only_tests = 0;
my @mysql_databases;

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
    if ( $db->{dsn} =~ /mysql/i ) {
        $num_mysql_only_tests = 2;
        push @mysql_databases, $db;
    }
}

my $num_tests = (scalar @schemas_to_test * scalar @configured_databases * 2) + $num_mysql_only_tests;
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

        # Test the data looks sane
        my $store = $class->new( %{$params} );
        my %wiki_config = ( store => $store );
        my $wiki = Wiki::Toolkit->new( %wiki_config );
        is( $wiki->retrieve_node("Test node 1"), "Some content",
            "can retrieve first test node after $schema to $current_schema" );
        is( $wiki->retrieve_node("Test node 2"), "More content",
            "can retrieve second test node after $schema to $current_schema" );
    }
}

if ( $num_mysql_only_tests ) {
    foreach my $database ( @mysql_databases ) {
        my $setup_class = $database->{setup_class};
        my $current_schema;
        {
            no strict 'refs';
            $current_schema = eval ${$setup_class . '::SCHEMA_VERSION'};
        }
        # Set up database with old schema
        my $params = $database->{params};
        $params->{wanted_schema} = 9;

        {
            no strict 'refs';
            eval &{$setup_class . '::cleardb'} ( $params );
            eval &{$setup_class . '::setup'} ( $params );
        }

        my $class = $database->{class};
        eval "require $class";

        my $dsn = $database->{dsn};

        my $dbh = DBI->connect($dsn, $params->{dbuser}, $params->{dbpass});
        
        # Manually create index that the upgrade also wants to create
        eval { $dbh->do('CREATE UNIQUE INDEX node_name ON node (name);') or die $dbh->errstr };
        is( $@, '', "Manually creating confusing index didn't die" );

        # Now upgrade
        delete $params->{wanted_schema};
        {
            no strict 'refs';
            eval &{$setup_class . '::setup'} ( $params );
            is( $@, '', "Upgrade didn't die even though node_name index had been created manually" );
        }
    }
}

