use strict;
use warnings;
use Test::More;

# Module integration tests requiring Docker
# Set TESTCONTAINERS_LIVE=1 to run these tests

unless ($ENV{TESTCONTAINERS_LIVE}) {
    plan skip_all => 'Set TESTCONTAINERS_LIVE=1 to run integration tests (requires Docker)';
}

subtest 'PostgreSQL module' => sub {
    use Testcontainers::Module::PostgreSQL qw( postgres_container );

    my $pg = postgres_container(
        username => 'pguser',
        password => 'pgpass',
        database => 'pgtest',
    );

    ok($pg, 'postgres container created');
    ok($pg->is_running, 'postgres is running');

    my $host = $pg->host;
    my $port = $pg->mapped_port('5432/tcp');
    ok($port, "postgres port mapped: $port");

    my $conn = $pg->connection_string;
    like($conn, qr{^postgresql://pguser:pgpass\@localhost:\d+/pgtest$}, 'connection string format');

    my $dsn = $pg->dsn;
    like($dsn, qr{^dbi:Pg:dbname=pgtest;host=localhost;port=\d+$}, 'DSN format');

    # Test actual DB connectivity if DBD::Pg is available
    if (eval { require DBI; require DBD::Pg; 1 }) {
        my $dbh = DBI->connect($dsn, 'pguser', 'pgpass', { RaiseError => 1 });
        ok($dbh, 'connected to postgres');
        my $row = $dbh->selectrow_arrayref("SELECT 1");
        is($row->[0], 1, 'query works');
        $dbh->disconnect;
    } else {
        diag "Skipping DB connectivity test (DBD::Pg not available)";
    }

    $pg->terminate;
};

subtest 'Redis module' => sub {
    use Testcontainers::Module::Redis qw( redis_container );

    my $redis = redis_container();

    ok($redis, 'redis container created');
    ok($redis->is_running, 'redis is running');

    my $url = $redis->connection_string;
    like($url, qr{^redis://localhost:\d+$}, 'connection string format');

    $redis->terminate;
};

subtest 'Nginx module' => sub {
    use Testcontainers::Module::Nginx qw( nginx_container );

    my $nginx = nginx_container();

    ok($nginx, 'nginx container created');
    ok($nginx->is_running, 'nginx is running');

    my $url = $nginx->base_url;
    like($url, qr{^http://localhost:\d+$}, 'base_url format');

    # Test HTTP connectivity
    if (eval { require HTTP::Tiny; 1 }) {
        my $http = HTTP::Tiny->new(timeout => 5);
        my $response = $http->get("$url/");
        is($response->{status}, 200, 'nginx returns 200');
    }

    $nginx->terminate;
};

done_testing;
