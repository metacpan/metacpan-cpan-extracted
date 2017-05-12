package Test::Docker::Image::Boot;

use strict;
use warnings;

use Test::Docker::Image::Utility qw(docker);
use URI::Split 'uri_split';

sub new {
    my $class = shift;
    return bless{}, $class;
}

sub host {
    my (undef, $auth) = uri_split $ENV{DOCKER_HOST};
    my ($host, $port) = split ':', $auth;
    return $host;
}

sub docker_run {
    my ($self, $ports, $image_tag) = @_;
    my $container_id = docker(qw/run -d -t/, @$ports, $image_tag);
    return $container_id;
}

sub docker_port {
    my ($self, $container_id, $container_port) = @_;
    my $port_info = docker('port', $container_id, $container_port);
    my (undef, $port) = split ':', $port_info;
    return $port;
}

1;
