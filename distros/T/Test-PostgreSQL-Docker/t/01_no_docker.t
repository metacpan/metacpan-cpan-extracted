use strict;
use warnings;
use lib qw(t/lib);
use Test::More;
use t::Util;
use File::Spec;

my $server = Test::PostgreSQL::Docker->new( t::Util::default_args_for_new(), docker => './ese_docker' );
is $server->docker, './ese_docker';

ok !$server->docker_daemon_is_accessible();
ok !$server->docker_is_running();

is $server->run(), $server;


done_testing;
