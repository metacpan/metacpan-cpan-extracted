[![Build Status](https://travis-ci.org/fujiwara/Test-UNIXSock.svg?branch=master)](https://travis-ci.org/fujiwara/Test-UNIXSock)
# NAME

Test::UNIXSock - testing UNIX domain socket program

# SYNOPSIS

    use Test::UNIXSock;

    my $server = Test::UNIXSock->new(
        code => sub {
            my $path = shift;
            ...
        },
    );
    my $client = MyClient->new( sock => $server->path );
    undef $server; # kill child process on DESTROY

Using memcached:

    use Test::UNIXSock;

    my $memcached = Test::UNIXSock->new(
        code => sub {
            my $path = shift;

            exec $bin, '-s' => $path;
            die "cannot execute $bin: $!";
        },
    );
    my $memd = Cache::Memcached->new({servers => [$memcached->path]});
    ...

And functional interface is available:

    use Test::UNIXSock;
    test_unix_sock(
        client => sub {
            my ($path, $server_pid) = @_;
            # send request to the server
        },
        server => sub {
            my $path = shift;
            # run server
        },
    );

# DESCRIPTION

Test::UNIXSock is a test utility to test UNIX domain socket server programs.

This is based on [Test::TCP](https://metacpan.org/pod/Test::TCP).

# METHODS

- test\_unixsock

    Functional interface.

        test_unixsock(
            client => sub {
                my $path = shift;
                # send request to the server
            },
            server => sub {
                my $path = shift;
                # run server
            },
            # optional
            path => "/tmp/mytest.sock", # if not specified, create a sock in tmpdir
            max_wait => 3, # seconds
        );

- wait\_unix\_sock

        wait_unix_sock({ path => $path });

    Waits for a particular path is available for connect.

# Object Oriented interface interface

- my $server = Test::UNIXSock->new(%args);

    Create new instance of Test::UNIXSock.

    Arguments are following:

    - $args{auto\_start}: Boolean

        Call `$server->start()` after create instance.

        Default: true

    - $args{code}: CodeRef

        The callback function. Argument for callback function is: `$code->($pid)`.

        This parameter is required.

    - $args{max\_wait} : Number

        Will wait for at most `$max_wait` seconds before checking port.

        See also [Net::EmptyPort](https://metacpan.org/pod/Net::EmptyPort).

        _Default: 10_

- $server->start()

    Start the server process. Normally, you don't need to call this method.

- $server->stop()

    Stop the server process.

- my $pid = $server->pid();

    Get the pid of child process.

- my $port = $server->port();

    Get the port number of child process.

# FAQ

See also [Test::TCP](https://metacpan.org/pod/Test::TCP) FAQ section.

# AUTHOR

Fujiwara Shunichiro <fujiwara.shunichiro@gmail.com>

# SEE ALSO

[Test::TCP](https://metacpan.org/pod/Test::TCP)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module is based on [Test::TCP](https://metacpan.org/pod/Test::TCP). copyright (c) 2013 by Tokuhiro Matsuno <tokuhirom@gmail.com>.
