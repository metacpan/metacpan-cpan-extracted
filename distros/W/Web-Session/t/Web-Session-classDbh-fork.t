use strict;
use warnings;
use Test::More;

plan skip_all => "Optional modules (DBI) not installed"
  unless eval { require DBI; 1 };

# Class methods get their handle from _classDbh() through connect_cached().
# It must be fork safe: the attributes (part of the cache key) contain the
# process id, so a forked child never reuses the parent's handle, and
# AutoInactiveDestroy keeps a child from closing the parent's connection.
# DBI->connect_cached() is mocked: no database needed.

my @calls;
{
    no warnings 'redefine';
    *DBI::connect_cached = sub {
        my ( $class, $dsn, $user, $pass, $attr ) = @_;
        push @calls, { dsn => $dsn, attr => {%$attr} };

        # Plain hash standing for the handle (Driver is read by MySQLJSON)
        return { Driver => { Name => 'mysql' } };
    };
}

my @backends = (
    [ 'Web::Session::DBI',         'dbi:SQLite:dbname=x' ],
    [ 'Web::Session::SQLite',      'dbi:SQLite:dbname=x' ],
    [ 'Web::Session::PgJSON',      'dbi:Pg:dbname=x' ],
    [ 'Web::Session::Patroni',     'dbi:Pg:dbname=x' ],
    [ 'Web::Session::MySQLJSON',   'dbi:mysql:database=x' ],
    [ 'Web::Session::MariaDBJSON', 'dbi:MariaDB:database=x' ],
    [ 'Web::Session::Cassandra',   'dbi:Cassandra:keyspace=x' ],
);

foreach my $b (@backends) {
    my ( $pkg, $dsn ) = @$b;
  SKIP: {
        skip "$pkg not loadable", 4 unless eval "require $pkg; 1";
        @calls = ();
        $pkg->_classDbh( { DataSource => $dsn } );
        $pkg->_classDbh( { DataSource => $dsn } );
        is( scalar @calls, 2, "$pkg: connect_cached called" );
        my $attr = $calls[0]->{attr};
        is( $attr->{private_ws_pid}, $$, "$pkg: pid in attributes" );
        ok( $attr->{AutoInactiveDestroy}, "$pkg: AutoInactiveDestroy set" );
        is_deeply( $calls[0]->{attr}, $calls[1]->{attr},
            "$pkg: same process, same cache key" );
    }
}
done_testing;
