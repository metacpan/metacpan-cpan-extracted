use strict;
use Test::More;

# Every SQL backend must reference existing serialize/unserialize subs
foreach my $backend (
    qw(MariaDB MariaDBJSON MySQL MySQLJSON Patroni PgJSON Postgres SQLite)
  )
{
    my $class = "Web::Session::$backend";
  SKIP: {
        skip "$class can't be loaded", 2 unless ( eval "require $class" );
        my $self = do { no strict 'refs'; &{"${class}::populate"}() };
        ok( defined &{ $self->{serialize} }, "$backend serialize sub exists" );
        ok(
            defined &{ $self->{unserialize} },
            "$backend unserialize sub exists"
        );
    }
}

done_testing();
