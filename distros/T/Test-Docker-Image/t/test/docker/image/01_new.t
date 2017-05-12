use strict;
use warnings;

use Test::More;
use Test::Exception;

use Test::Docker::Image;

my ($boot, $tag, $container_ports)
    = ('Test::Docker::Image::Boot', 'iwata/centos6-mysql51-q4m-hs', [3306]);

subtest "construstor's options" => sub {
    subtest "unusual boot module" => sub {
        throws_ok {
            Test::Docker::Image->new(
                boot            => 'Test::Docker::Image::Boot::Hoge',
                tag             => $tag,
                container_ports => $container_ports,
            );
        } qr/failed to load/, 'throw exception';
    };

    subtest "unset tag" => sub {
        throws_ok {
            Test::Docker::Image->new(
                boot => $boot,
                container_ports => $container_ports,
            );
        } qr/tag argument is required/, 'throw exception';
    };

    subtest "unset container_ports" => sub {
        throws_ok {
            Test::Docker::Image->new(
                boot => $boot,
                tag  => $tag,
            );
        } qr/container_ports argument must be ArrayRef/, 'throw exception';
    };

    subtest "container_ports is not ArrayRef" => sub {
        throws_ok {
            Test::Docker::Image->new(
                boot            => $boot,
                tag             => $tag,
                container_ports => 3306,
            );
        } qr/container_ports argument must be ArrayRef/, 'throw exception';
    };

};


done_testing;
