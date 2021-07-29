# NAME

UV - Perl interface to libuv

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use UV;
    use UV::Loop;

    # hi-resolution time
    my $hi_res_time = UV::hrtime();

    # A new loop
    my $loop = UV::Loop->new();

    # default loop
    my $loop = UV::Loop->default_loop(); # convenience singleton constructor
    my $loop = UV::Loop->default(); # convenience singleton constructor

    # run a loop with one of three options:
    # UV_RUN_DEFAULT, UV_RUN_ONCE, UV_RUN_NOWAIT
    $loop->run(); # runs with UV_RUN_DEFAULT
    $loop->run(UV::Loop::UV_RUN_DEFAULT); # explicitly state UV_RUN_DEFAULT
    $loop->run(UV::Loop::UV_RUN_ONCE);
    $loop->run(UV::Loop::UV_RUN_NOWAIT);

# DESCRIPTION

This module provides an interface to [libuv](http://libuv.org). We will try to
document things here as best as we can, but we also suggest you look at the
[libuv docs](http://docs.libuv.org) directly for more details on how things
work.

Event loops that work properly on all platforms. YAY!

# FUNCTIONS

The following functions are available:

## check

    my $handle = UV::check(); # uses the default loop
    my $handle = UV::check(loop => $some_other_loop); # non-default loop

Returns a new [UV::Check](https://metacpan.org/pod/UV%3A%3ACheck) Handle object.

## default\_loop

    my $loop = UV::default_loop();
    # You can also get it with the UV::Loop methods below:
    my $loop = UV::Loop->default_loop();
    my $loop = UV::Loop->default();
    # Passing a true value as the first arg to the UV::Loop constructor
    # will also return the default loop
    my $loop = UV::Loop->new(1);

Returns the default loop (which is a singleton object). This module already
creates the default loop and you get access to it with this method.

## err\_name

    my $error_name = UV::err_name(UV::UV_EAI_BADFLAGS);
    say $error_name; # EAI_BADFLAGS

The [err\_name](http://docs.libuv.org/en/v1.x/errors.html#c.uv_err_name)
function returns the error name for the given error code. Leaks a few bytes of
memory when you call it with an unknown error code.

In libuv errors are negative numbered constants. As a rule of thumb, whenever
there is a status parameter, or an API functions returns an integer, a negative
number will imply an error.

When a function which takes a callback returns an error, the callback will
never be called.

## hrtime

    my $uint64_t = UV::hrtime();

Get the current Hi-Res time; a value given in nanoseconds since some arbitrary
point in the past. On 64bit-capable perls this will be represented by an
integer with full precision. On perls unable to represent a 64bit integer this
will be given as a floating-point value so may lose some precision if the
value is large enough.

## idle

    my $handle = UV::idle(); # uses the default loop
    my $handle = UV::idle(loop => $some_other_loop); # non-default loop

Returns a new [UV::Idle](https://metacpan.org/pod/UV%3A%3AIdle) Handle object.

## loop

    my $loop = UV::loop();
    # You can also get it with the UV::Loop methods below:
    my $loop = UV::Loop->default_loop();
    my $loop = UV::Loop->default();

Returns the default loop (which is a singleton object). This module already
creates the default loop and you get access to it with this method.

## poll

    my $handle = UV::poll(); # uses the default loop
    my $handle = UV::poll(loop => $some_other_loop); # non-default loop

Returns a new [UV::Poll](https://metacpan.org/pod/UV%3A%3APoll) Handle object.

## prepare

    my $handle = UV::prepare(); # uses the default loop
    my $handle = UV::prepare(loop => $some_other_loop); # non-default loop

Returns a new [UV::Prepare](https://metacpan.org/pod/UV%3A%3APrepare) Handle object.

## signal

    my $handle = UV::signal(POSIX::SIGHUP); # uses the default loop

    my $handle = UV::signal(loop => $some_other_loop, signal => POSIX::SIGHUP);
        # non-default loop

Returns a new [UV::Signal](https://metacpan.org/pod/UV%3A%3ASignal) Handle object.

## strerror

    my $error = UV::strerror(UV::UV_EAI_BADFLAGS);
    say $error; # bad ai_flags value

The [strerror](http://docs.libuv.org/en/v1.x/errors.html#c.uv_strerror)
function returns the error message for the given error code. Leaks a few bytes
of memory when you call it with an unknown error code.

In libuv errors are negative numbered constants. As a rule of thumb, whenever
there is a status parameter, or an API functions returns an integer, a negative
number will imply an error.

When a function which takes a callback returns an error, the callback will
never be called.

## tcp

    my $tcp = UV::tcp();

Returns a new [UV::TCP](https://metacpan.org/pod/UV%3A%3ATCP) object.

## timer

    my $timer = UV::timer(); # uses the default loop
    my $timer = UV::timer(loop => $some_other_loop); # non-default loop

Returns a new [UV::Timer](https://metacpan.org/pod/UV%3A%3ATimer) object.

## tty

    my $tty = UV::tty(fd => 0);

Returns a new [UV::TTY](https://metacpan.org/pod/UV%3A%3ATTY) object.

## udp

    my $udp = UV::udp();

Returns a new [UV::UDP](https://metacpan.org/pod/UV%3A%3AUDP) object.

## version

    my $int = UV::version();

The [version](http://docs.libuv.org/en/v1.x/version.html#c.uv_version) function
returns `UV::UV_VERSION_HEX`, the libuv version packed into a single integer.
8 bits are used for each component, with the patch number stored in the 8 least
significant bits. E.g. for libuv 1.2.3 this would be `0x010203`.

## version\_string

    say UV::version_string();
    # 1.13.1

The [version\_string](http://docs.libuv.org/en/v1.x/version.html#c.uv_version_string)
function returns the libuv version number as a string. For non-release versions
the version suffix is included.

# EXCEPTIONS

If any call to `libuv` fails, an exception will be thrown. The exception will
be a blessed object having a `code` method which returns the numerical error
code (which can be compared to one of the `UV::UV_E*` error constants), and a
`message` method which returns a human-readable string describing the failure.

    try { ... }
    catch my $e {
        if(blessed $e and $e->isa("UV::Exception")) {
            print "The failure was ", $e->message, " of code ", $e->code;
        }
    }

The exception class provides stringify overload to call the `message` method,
so the normal Perl behaviour of just printing the exception will print the
message from it, as expected.

Exceptions are blessed into a subclass of `UV::Exception` named after the
type of the failure code. This allows type-based testing of error types.

    try { ... }
    catch my $e {
        if(blessed $e and $e->isa("UV::Exception::ECANCELED") {
            # ignore
        }
        else ...
    }

# CONSTANTS

## VERSION CONSTANTS

- UV\_VERSION\_MAJOR
- UV\_VERSION\_MINOR
- UV\_VERSION\_PATCH
- UV\_VERSION\_IS\_RELEASE
- UV\_VERSION\_SUFFIX
- UV\_VERSION\_HEX

## ERROR CONSTANTS

- UV\_E2BIG

    Argument list too long

- UV\_EACCES

    Permission denied

- UV\_EADDRINUSE

    Address already in use

- UV\_EADDRNOTAVAIL

    Address not available

- UV\_EAFNOSUPPORT

    Address family not supported

- UV\_EAGAIN

    Resource temporarily unavailable

- UV\_EAI\_ADDRFAMILY

    Address family not supported

- UV\_EAI\_AGAIN

    Temporary failure

- UV\_EAI\_BADFLAGS

    Bad ai\_flags value

- UV\_EAI\_BADHINTS

    Invalid value for hints

- UV\_EAI\_CANCELED

    Request canceled

- UV\_EAI\_FAIL

    Permanent failure

- UV\_EAI\_FAMILY

    ai\_family not supported

- UV\_EAI\_MEMORY

    Out of memory

- UV\_EAI\_NODATA

    No address

- UV\_EAI\_NONAME

    Unknown node or service

- UV\_EAI\_OVERFLOW

    Argument buffer overflow

- UV\_EAI\_PROTOCOL

    Resolved protocol is unknown

- UV\_EAI\_SERVICE

    Service not available for socket type

- UV\_EAI\_SOCKTYPE

    Socket type not supported

- UV\_EALREADY

    Connection already in progress

- UV\_EBADF

    Bad file descriptor

- UV\_EBUSY

    Resource busy or locked

- UV\_ECANCELED

    Operation canceled

- UV\_ECHARSET

    Invalid Unicode character

- UV\_ECONNABORTED

    Software caused connection abort

- UV\_ECONNREFUSED

    Connection refused

- UV\_ECONNRESET

    Connection reset by peer

- UV\_EDESTADDRREQ

    Destination address required

- UV\_EEXIST

    File already exists

- UV\_EFAULT

    Bad address in system call argument

- UV\_EFBIG

    File too large

- UV\_EHOSTUNREACH

    Host is unreachable

- UV\_EINTR

    Interrupted system call

- UV\_EINVAL

    Invalid argument

- UV\_EIO

    i/o error

- UV\_EISCONN

    Socket is already connected

- UV\_EISDIR

    Illegal operation on a directory

- UV\_ELOOP

    Too many symbolic links encountered

- UV\_EMFILE

    Too many open files

- UV\_EMLINK

    Too many links

- UV\_EMSGSIZE

    Message too long

- UV\_ENAMETOOLONG

    Name too long

- UV\_ENETDOWN

    Network is down

- UV\_ENETUNREACH

    Network is unreachable

- UV\_ENFILE

    File table overflow

- UV\_ENOBUFS

    No buffer space available

- UV\_ENODEV

    No such device

- UV\_ENOENT

    No such file or directory

- UV\_ENOMEM

    Not enough memory

- UV\_ENONET

    Machine is not on the network

- UV\_ENOPROTOOPT

    Protocol not available

- UV\_ENOSPC

    No space left on device

- UV\_ENOSYS

    Function not implemented

- UV\_ENOTCONN

    Socket is not connected

- UV\_ENOTDIR

    Not a directory

- UV\_ENOTEMPTY

    Directory not empty

- UV\_ENOTSOCK

    Socket operation on non-socket

- UV\_ENOTSUP

    Operation not supported on socket

- UV\_ENXIO

    No such device or address

- UV\_EOF

    End of file

- UV\_EPERM

    Operation not permitted

- UV\_EPIPE

    Broken pipe

- UV\_EPROTO

    Protocol error

- UV\_EPROTONOSUPPORT

    Protocol not supported

- UV\_EPROTOTYPE

    Protocol wrong type for socket

- UV\_ERANGE

    Result too large

- UV\_EROFS

    Read-only file system

- UV\_ESHUTDOWN

    Cannot send after transport endpoint shutdown

- UV\_ESPIPE

    Invalid seek

- UV\_ESRCH

    No such process

- UV\_ETIMEDOUT

    Connection timed out

- UV\_ETXTBSY

    Text file is busy

- UV\_EXDEV

    Cross-device link not permitted

- UV\_UNKNOWN

    Unknown error

# AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

# AUTHORS EMERITUS

Daisuke Murase <`typester@cpan.org`>,
Chase Whitener <`capoeirab@cpan.org`>

# COPYRIGHT AND LICENSE

Copyright 2012, Daisuke Murase.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
