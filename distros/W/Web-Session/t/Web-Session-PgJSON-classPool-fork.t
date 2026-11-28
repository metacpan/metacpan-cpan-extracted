use strict;
use warnings;
use Test::More;

# Class methods of Web::Session::PgJSON after a real fork(): the child must
# not use the idle pooled connection of its parent, and its exit must not
# close it. Needs a PostgreSQL server (PG_DSN, PG_USER, PG_PASSWORD)
plan skip_all => 'Set PG_DSN to run this test' unless $ENV{PG_DSN};
plan skip_all => 'fork() is needed for this test' if ( $^O eq 'MSWin32' );

my $class = 'Web::Session::PgJSON';
use_ok($class);

my $table = 'asb_test_classpool_fork';
my $args  = {
    DataSource => $ENV{PG_DSN},
    UserName   => $ENV{PG_USER},
    Password   => $ENV{PG_PASSWORD},
    TableName  => $table,
};
my $dbh = DBI->connect( @$args{qw(DataSource UserName Password)},
    {
        RaiseError          => 1,
        AutoCommit          => 1,
        PrintError          => 0,
        AutoInactiveDestroy => 1,
    }
);
$dbh->do("DROP TABLE IF EXISTS $table");
$dbh->do("CREATE TABLE $table (id varchar(64) primary key, a_session jsonb)");

my %session;
tie %session, $class, undef, $args;
$session{uid} = 'dwho';
my $id = $session{_session_id};
untie %session;

my $backendPid = sub {
    my $loan = Web::Session::Store::Postgres->_lend($args);
    return $loan->{dbh}->selectrow_array('SELECT pg_backend_pid()');
};

# The pool now holds one idle connection of this process
is_deeply( [ keys %{ $class->searchOn( $args, 'uid', 'dwho' ) } ],
    [$id], 'parent: searchOn' );
my $parentBackend = $backendPid->();

pipe( my $r, my $w ) or die $!;
my $pid = fork;
die "fork: $!" unless defined $pid;
unless ($pid) {
    close $r;
    my $ok = eval {
        my $found = $class->searchOn( $args, 'uid', 'dwho' );
        print {$w} $backendPid->(), "\n";
        exists $found->{$id};
    };
    close $w;
    exit( $ok ? 0 : 1 );
}
close $w;
my $childBackend = <$r>;
close $r;
waitpid( $pid, 0 );
is( $? >> 8, 0, 'child: searchOn' );
chomp $childBackend if ( defined $childBackend );
ok( defined $childBackend, 'child: got a connection' );
isnt( $childBackend, $parentBackend,
    'child: not the parent pooled connection' );

is( $backendPid->(), $parentBackend,
    'parent: pooled connection kept after the child exited' );
is_deeply( [ keys %{ $class->searchOn( $args, 'uid', 'dwho' ) } ],
    [$id], 'parent: searchOn after the child exited' );

$dbh->do("DROP TABLE $table");
done_testing();
