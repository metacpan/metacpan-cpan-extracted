use strict;
use Test::More;
use Test::SharedFork;
use Test::Docker::MySQL;
use DBI;

sub get_dbh {
    my $port = shift;
    note "Connecting port: $port";
    my $dsn = "dbi:mysql:database=mysql;host=127.0.0.1;port=$port";
    DBI->connect($dsn , 'root', '', { RaiseError => 1 });
}

my @default_tables = qw/ docker_mysql mysql information_schema performance_schema /;

$ENV{DOCKER_HOST} ||= 'tcp://192.168.59.103:2375';

subtest 'get one container' => sub {
    my $dm_guard = Test::Docker::MySQL->new;

    my $port   = $dm_guard->get_port;
    my $tables = (get_dbh $port)->selectall_arrayref("SHOW DATABASES");

    is_deeply [ sort @default_tables ],
              [ sort map { @$_ } @$tables ];

};

subtest 'run multiple docker containers sequentially' => sub {
    my $dm_guard = Test::Docker::MySQL->new;

    subtest 'get one container' => sub {
        my $port   = $dm_guard->get_port;
        my $tables = (get_dbh $port)->selectall_arrayref("SHOW DATABASES");

        is_deeply [ sort @default_tables ],
                  [ sort map { @$_ } @$tables ];
    };

    subtest 'get another container' => sub {
        my $port   = $dm_guard->get_port;
        my $tables = (get_dbh $port)->selectall_arrayref("SHOW DATABASES");

        is_deeply [ sort @default_tables ],
                  [ sort map { @$_ } @$tables ];
    };
};

subtest 'run multiple docker containers in parallel' => sub {
    my $pid = fork;
    if ($pid == 0) {
        # child
        srand();
        my $dm_guard = Test::Docker::MySQL->new;
        for (1 .. 5) {
            my $port   = $dm_guard->get_port;
            my $tables = (get_dbh $port)->selectall_arrayref("SHOW DATABASES");
            is_deeply [ sort @default_tables ],
                      [ sort map { @$_ } @$tables ];
        }
        undef $dm_guard;
        exit;
    } elsif ($pid) {
        # parent
        my $dm_guard = Test::Docker::MySQL->new;
        for (1 .. 5) {
            my $port   = $dm_guard->get_port;
            my $tables = (get_dbh $port)->selectall_arrayref("SHOW DATABASES");
            is_deeply [ sort @default_tables ],
                      [ sort map { @$_ } @$tables ];
        }
        waitpid $pid, 0;
    } else {
        fail $!;
    }
};

subtest 'destroy by scope' => sub {
    my $port;
    {
        my $dm_guard = Test::Docker::MySQL->new;

        $port      = $dm_guard->get_port;
        my $tables = (get_dbh $port)->selectall_arrayref("SHOW DATABASES");
        is_deeply [ sort @default_tables ],
                  [ sort map { @$_ } @$tables ];
    };

    my $dbh = eval { get_dbh $port };
    ok not defined $dbh;
    like $@, qr/Lost connection to MySQL server/;
};

subtest 'no docker' => sub {
    local $ENV{DOCKER_HOST} = '';
    my $guard = Test::Docker::MySQL->new;
    my $port = eval { $guard->get_port };
    ok not defined $port;
    like $@, qr/no such file or directory/;
};

subtest 'no container leakage' => sub {
    plan skip_all => "should pass but `status: Exited` containers remain :(";
    my $guard = Test::Docker::MySQL->new;
    my @lines = split '\n', $guard->docker(ps => '-a');
    undef $guard;
    is scalar(@lines), 1
        or note explain \@lines;
};

done_testing;
