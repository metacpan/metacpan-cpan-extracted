#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;
use Wiki::Toolkit::TestConfig;

my $class;
BEGIN {
    $class = "Wiki::Toolkit::Store::MySQL";
    use_ok($class);
}

eval { $class->new; };
ok( $@, "Failed creation dies" );

my %config = %{$Wiki::Toolkit::TestConfig::config{MySQL}};
my ($dbname, $dbuser, $dbpass, $dbhost) =
                                      @config{qw(dbname dbuser dbpass dbhost)};

SKIP: {
    skip "No MySQL database configured for testing", 11 unless $dbname;

    my $store = eval { $class->new( dbname => $dbname,
				    dbuser => $dbuser,
				    dbpass => $dbpass,
				    dbhost => $dbhost );
		     };
    is( $@, "", "Creation succeeds with connection parameters" );
    isa_ok( $store, $class );
    ok( $store->dbh, "...and has set up a database handle" );

    my $dsn = "dbi:mysql:$dbname";
    $dsn .= ";host=$dbhost" if $dbhost;
    my $dbh = DBI->connect( $dsn, $dbuser, $dbpass );
    my $evil_store = eval { $class->new( dbh => $dbh ); };
    is( $@, "", "Creation succeeds with dbh" );
    isa_ok( $evil_store, $class );
    ok( $evil_store->dbh, "...and we can retrieve the database handle" );

    # White box test - do internal locking functions work the way we expect?
    ok( $store->_lock_node("Home"), "Can lock a node" );
    ok( ! $evil_store->_lock_node("Home"),
        "...and now other people can't get a lock on it" );
    ok( ! $evil_store->_unlock_node("Home"),
        "...or unlock it" );
    ok( $store->_unlock_node("Home"), "...but I can unlock it" );
    ok( $evil_store->_lock_node("Home"),
	"...and now other people can lock it" );

    # Cleanup (not necessary, since this thread is about to die, but here
    # in case I forget and add some more tests at the end).
    $evil_store->_unlock_node("Home");

}
