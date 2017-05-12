use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Mock::Guard;

use Test::Docker::Image::Boot;

my $boot = Test::Docker::Image::Boot->new;
my $container_id = '50e6798fa852e8568ca4e2be7890e40271b69bba000cd769c3d56e2a7e254efaa';

subtest "host" => sub {
    local $ENV{DOCKER_HOST} = 'tcp://192.168.59.103:2375';
    my $exp = '192.168.59.103';
    my $got = $boot->host;
    is $got => $exp, 'see $DOCKER_HOST';
};

subtest "docker_run" => sub {
    my $ports = [qw(-p 3306 -p 22)];
    my $tag = 'iwata/centos6-mysql51-q4m-hs';

    my $guard = mock_guard('Test::Docker::Image::Boot' => +{
        docker => sub {
            my @cmds = @_;
            my $exp = [qw/run -d -t/, @$ports, $tag];
            is_deeply \@cmds => $exp;
            $container_id;
        },
    });

    my $got_container_id = $boot->docker_run($ports, $tag);
    is $got_container_id => $container_id, 'return container ID of a Docker container';
    is $guard->call_count('Test::Docker::Image::Boot' => 'docker') => 1;
};

subtest "docker_port" => sub {
    my ($container_port, $host_port) = (3306, 49172);

    my $guard = mock_guard('Test::Docker::Image::Boot' => +{
        docker => sub {
            my @cmds = @_;
            my $exp = ['port', $container_id, $container_port];
            is_deeply \@cmds => $exp;
            "0.0.0.0:$host_port";
        },
    });

    my $got_port = $boot->docker_port($container_id, $container_port);
    is $got_port => $host_port;
    is $guard->call_count('Test::Docker::Image::Boot' => 'docker') => 1;
};

done_testing;
