[![Build Status](https://travis-ci.org/iwata/p5-Test-Docker-Image.png?branch=master)](https://travis-ci.org/iwata/p5-Test-Docker-Image) [![Coverage Status](https://coveralls.io/repos/iwata/p5-Test-Docker-Image/badge.png?branch=master)](https://coveralls.io/r/iwata/p5-Test-Docker-Image?branch=master)
# NAME

Test::Docker::Image - It's new $module, this can handle a Docker image for tests.

# SYNOPSIS

    use Test::Docker::Image;

    my $mysql_image_guard = Test::Docker::Image->new(
        container_ports => [3306],
        tag             => 'iwata/centos6-mysql51-q4m-hs',
    );

    my $port = $mysql_image_guard->port(3306);
    my $host = $mysql_image_guard->host;

    `mysql -uroot -h$host -P$port -e 'show plugins'`;
    undef $mysql_image_guard; # destroy a guard object and execute docker kill and rm the container.

# DESCRIPTION

Test::Docker::Image is a module to handle a Docker image.

# METHODS

## `new`

return an instance of Test::Docker::Image, this instance is used as a guard object.

- `tag`

    This is a required parameter. This specify a tag of Docker image for docker run.

- `container_ports`

    This is a required parameter. This specify some port numbers that publish a container's port to the host.

- `boot`

    This is an optional parameter. You set a boot module name.
    `Boot` module must extend Test::Docker::Image::Boot.

- `sleep_sec`

    This is a optional parameter. Wait seconds after docker run, because you can't access container immediately.

## `port`

Return a port number, this Docker image use number for port forwarding.

## `host`

Return an IP address of Docker host.

# LICENSE

Copyright (C) iwata-motonori.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Motonori Iwata <gootonroi+github@gmail.com>
