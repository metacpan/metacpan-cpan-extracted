use strict;
use warnings;
use lib qw(t/lib);
use Test::More;
use Test::SharedFork;
use t::Util;


my $err;
open( my $fh, '>>', \$err );
*STDERR = $fh;

{
    my $server = t::Util->new_server();

    unless ( $server->docker_is_running ) {
        plan skip_all => "docker is not running.";
        exit;
    }

    my $dsn = $server->dsn;
    my $dbh = DBI->connect($server->dsn(dbname => 'template1'), '', '', {});
    ok $dbh, 'create dbh by DBI';

    my $pid = fork();
    if (!defined $pid) {
        skip "Can't fork", 3;
    }
    elsif ($pid == 0) {
        ok 1, "child";
        sleep(2);
        exit;
    }
    elsif ($pid) {
        ok 1, "parent";
        waitpid($pid, 0);
    }

}

ok !$err, $err;

done_testing;