use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

plan skip_all => "DBD::SQLite is needed for this test"
  unless eval { require DBI; require DBD::SQLite; 1 };

# The connections of the stores are shared through DBI->connect_cached(): they
# must be fork safe like the handles of the class methods (see
# Web-Session-classDbh-fork.t). connect_cached() is wrapped to record the
# attributes; SQLite is only used to get a real handle, whatever the store

my $dir = tempdir( CLEANUP => 1 );
my $dsn = "dbi:SQLite:dbname=$dir/sessions.db";

my @calls;
{
    no warnings 'redefine';
    my $orig = \&DBI::connect_cached;
    *DBI::connect_cached = sub {
        push @calls, { %{ $_[4] } };
        goto &$orig;
    };
}

my %stores = (
    MySQL       => {},
    SQLite      => {},
    MariaDBJSON => {},
    Patroni     => { KeepConnections => 0 },
    Cassandra   => {},
    Postgres    => { KeepConnections => 0 },
    Postgres2   => { Commit          => 0 },    # no pool without Commit
);

foreach my $name ( sort keys %stores ) {
    ( my $mod = $name ) =~ s/\d+$//;
    my $store = "Web::Session::Store::$mod";
  SKIP: {
        skip "$store not loadable", 10 unless eval "require $store; 1";
        @calls = ();
        my $session = sub {
            return {
                args =>
                  { DataSource => $dsn, Commit => 1, %{ $stores{$name} } },
                data => { _session_id => 'x' },
            };
        };
        foreach ( 1, 2 ) {
            my $s = $store->new;
            eval { $s->connection( $session->() ) };
            is( $@, '', "$name: connection $_" );
        }
        ok( scalar @calls >= 2, "$name: connect_cached used" );
        is( $calls[0]->{private_ws_pid}, $$, "$name: pid in attributes" );
        ok( $calls[0]->{AutoInactiveDestroy}, "$name: AutoInactiveDestroy" );
        is_deeply( $calls[0], $calls[1], "$name: same process, same key" );

        # A store connected before a fork(), used in the child: the handle
        # (opened by another process) is replaced. A real fork() is tested
        # in Web-Session-fork.t
        my $s = $store->new;
        $s->connection( $session->() );
        my $dbh = $s->{dbh};
        $dbh->{private_ws_pid} = $$ + 1;
        $s->{materialize_sth} = 'parent statement';
        @calls = ();
        eval { $s->connection( $session->() ) };
        is( $@,                    '', "$name: connection in the child" );
        is( scalar @calls,         1,  "$name: inherited handle replaced" );
        is( $s->{materialize_sth}, undef, "$name: statements forgotten" );

        # Freed in the child: no commit on the parent's handle
        $dbh = $s->{dbh};
        $dbh->{private_ws_pid} = $$ + 1;
        my $commits = 0;
        {
            no warnings 'redefine';
            local *DBI::db::commit = sub { $commits++; 1 };
            undef $s;
        }
        is( $commits, 0, "$name: no commit in the child" );
        $dbh->{private_ws_pid} = $$;
    }
}
done_testing;
