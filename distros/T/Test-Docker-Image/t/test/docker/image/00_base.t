use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Mock::Guard;

use Test::Docker::Image;

my ($boot, $tag, $container_ports)
    = ('Test::Docker::Image::Boot', 'iwata/centos6-mysql51-q4m-hs', [3306, 80]);
my $container_id = '50e6798fa852e8568ca4e2be7890e40271b69bba000cd769c3d56e2a7e254efaa';

subtest "new" => sub {
    my $guard = mock_guard($boot => +{
        docker_run => sub {
            my (undef, $got_ports, $got_tag) = @_;
            my $exp_ports = [qw/-p 3306 -p 80/];
            is_deeply $got_ports => $exp_ports, 'first argument means port number options';
            is $got_tag => $tag, 'second argument means image tag option';
            return $container_id;
        },
    }, 'Test::Docker::Image' => +{
        DESTROY => 0,
    });

    lives_and {
        my $docker_image = Test::Docker::Image->new(
            tag             => $tag,
            sleep_secs      => 0.1,
            container_ports => $container_ports,
        );

        is $docker_image->tag => $tag;
        is_deeply $docker_image->container_ports => $container_ports;
        is $docker_image->container_id => $container_id;
        isa_ok $docker_image->{boot} => 'Test::Docker::Image::Boot';

    };

    is $guard->call_count($boot => 'docker_run') => 1, "docker_run call once";
    is $guard->call_count('Test::Docker::Image' => 'DESTROY') => 1, "DESTROY call once";
};

subtest "port" => sub {
    my $container_port = 3306;
    my $host_port      = 49172;

    my $guard = mock_guard($boot => +{
        docker_run => sub {
            my (undef, $got_ports, $got_tag) = @_;
            my $exp_ports = [qw/-p 3306/];
            is_deeply $got_ports => $exp_ports, 'first argument means port number options';
            is $got_tag => $tag, 'second argument means image tag option';
            return $container_id;
        },
        docker_port => sub {
            my (undef, $got_container_id, $got_container_port) = @_;
            is $got_container_id => $container_id, 'container_id';
            is $got_container_port => $container_port, 'container_port';
            return $host_port;
        },
    }, 'Test::Docker::Image' => +{
        DESTROY => 0,
    });

    lives_and {
        my $docker_image = Test::Docker::Image->new(
            tag             => $tag,
            container_ports => [ $container_port ],
            boot            => $boot,
        );

        is $docker_image->port( $container_port ) => $host_port;
    };

    for my $method ( qw(docker_run docker_port) ) {
        is $guard->call_count($boot => $method) => 1, "$method call once";
    }
    is $guard->call_count('Test::Docker::Image' => 'DESTROY') => 1, "DESTROY call once";
};

done_testing;
