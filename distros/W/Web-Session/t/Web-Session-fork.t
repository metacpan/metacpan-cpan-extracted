use strict;
use warnings;
use Config;
use File::Temp qw(tempdir);
use Test::More;

plan skip_all => 'fork() is needed for this test'
  if ( $^O eq 'MSWin32' or !$Config{d_fork} );
plan skip_all => 'DBD::SQLite is needed for this test'
  unless eval { require DBI; require DBD::SQLite; 1 };

# A real fork(): the parent has a session tied (so a connected store) and has
# called a class method when it forks. The child uses its copy of the session
# and calls the class method again: it must use handles of its own, and the
# parent's handles must still work after the child exits. PostgreSQL also
# checks that the child doesn't close the parent's connection on the server
# (AutoInactiveDestroy); SQLite has no server connection. Using in the child a
# session tied before the fork is not supported (see Web::Session): the
# parent commits its transaction first, only the handles are checked here

sub forkTest {
    my ( $name, $class, $args ) = @_;
    eval "require $class; 1" or die $@;
    my $id = do {
        my %s;
        tie %s, $class, undef, $args;
        $s{uid} = 'dwho';
        my $id = $s{_session_id};
        untie %s;
        $id;
    };

    my %s;
    tie %s, $class, $id, $args;
    is( $s{uid}, 'dwho', "$name: session read by the parent" );
    # Stores commit when they are freed: keep no reference to them
    my $parentDbh = tied(%s)->{object_store}->{dbh};
    ok( $parentDbh, "$name: parent store connected" );
    my $classDbh = $class->_classDbh($args);

    # Else the child wouldn't see the parent's transaction, and SQLite would
    # lock it out. The store stays connected
    $parentDbh->commit unless ( $parentDbh->{AutoCommit} );

    pipe( my $read, my $write ) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    unless ($pid) {
        close $read;
        my @res;
        eval {
            $s{uid} = 'child';
            tied(%s)->save;
            my $dbh = tied(%s)->{object_store}->{dbh};
            untie %s;
            push @res, ( $dbh and $dbh != $parentDbh ) ? 1 : 0;
            push @res, ( $dbh and $dbh->{private_ws_pid} == $$ ) ? 1 : 0;
            my $cdbh = $class->_classDbh($args);
            push @res, ( $cdbh != $classDbh ) ? 1 : 0;
            my $r = $class->searchOn( $args, 'uid', 'child' );
            push @res, ( $r->{$id} ) ? 1 : 0;
            1;
        } or push @res, "died: $@";
        print $write join( ',', @res ), "\n";
        close $write;

        # Like a worker ending: global destruction frees the handles
        exit 0;
    }
    close $write;
    my $line = <$read> // '';
    chomp $line;
    waitpid( $pid, 0 );
    is( $?, 0, "$name: child exited" );
    is( $line, '1,1,1,1', "$name: child used handles of its own" )
      or diag "child said: $line";

    ok( $parentDbh->ping, "$name: parent session handle still works" );
    ok( $classDbh->ping,  "$name: parent class handle still works" );
    is( $s{uid}, 'dwho', "$name: parent copy unchanged" );
    $s{uid} = 'parent';
    untie %s;
    my $r = $class->searchOn( $args, 'uid', 'parent' );
    ok( $r->{$id}, "$name: parent write after the fork" );
    my %t;
    tie %t, $class, $id, $args;
    is( $t{uid}, 'parent', "$name: parent write read back" );
    tied(%t)->delete;
    untie %t;
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $dsn = "dbi:SQLite:dbname=$dir/sessions.db";
    my $dbh = DBI->connect( $dsn, '', '', { RaiseError => 1 } );
    $dbh->do( 'CREATE TABLE sessions (id char(64) not null primary key,'
          . ' a_session text, uid text)' );
    $dbh->disconnect;
    forkTest( 'SQLite', 'Web::Session::SQLite',
        { DataSource => $dsn, Index => 'uid' } );
}

SKIP: {
    skip 'Set PG_DSN to run the PostgreSQL test', 1 unless $ENV{PG_DSN};
    skip 'DBD::Pg is needed', 1 unless eval { require DBD::Pg; 1 };
    my $table = 'asb_test_fork';
    my $args  = {
        DataSource => $ENV{PG_DSN},
        UserName   => $ENV{PG_USER},
        Password   => $ENV{PG_PASSWORD},
        TableName  => $table,
        Commit     => 1,
    };
    # Inherited by the child too: without AutoInactiveDestroy, the child
    # would close this connection when it exits
    my $dbh = DBI->connect( @$args{qw(DataSource UserName Password)},
        { RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1 } );
    $dbh->do("DROP TABLE IF EXISTS $table");
    $dbh->do( "CREATE TABLE $table"
          . ' (id varchar(64) not null primary key, a_session jsonb)' );
    forkTest( 'PgJSON', 'Web::Session::PgJSON', $args );
    $dbh->do("DROP TABLE $table");
    $dbh->disconnect;
}

done_testing;
