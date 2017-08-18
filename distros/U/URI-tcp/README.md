# NAME

URI::tcp - tcp connection string

# SYNOPSIS

    $uri = URI->new('tcp://host:1234');

    $sock = IO::Socket::INET->new(
        PeerAddr => $uri->host,
        PeerPort => $uri->port',
        Proto    => $uri->protocol,
    );

# DESCRIPTION

URI extension for TCP protocol

# EXTENDED METHODS

## protocol()

return _tcp_

same as `scheme` method

# history

Module `URI::tcp` was indexed by [SOAP::Lite](https://metacpan.org/pod/SOAP::Lite), but isn't possible to use it. This [pull request](https://github.com/redhotpenguin/soaplite/pull/31) change it.

# contributing

for dependency use [cpanfile](https://metacpan.org/pod/cpanfile)...

for resolve dependency use [Carton](https://metacpan.org/pod/Carton) (or carton - is more experimental) 

    carton install

for run test use `minil test`

    carton exec minil test

if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

## warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
