package UV;

our $VERSION = '1.000009';
our $XS_VERSION = $VERSION;

use strict;
use warnings;
use Carp ();
use Exporter qw(import);
use Math::Int64 ();
use XS::Object::Magic ();
require XSLoader;
XSLoader::load('UV', $XS_VERSION);

our @EXPORT_OK = (
    @UV::EXPORT_XS,
    qw(default_loop loop err_name hrtime strerr translate_sys_error),
    qw(check timer),
);

# _parse_args (static, private)
sub _parse_args {
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
        Carp::croak("Argument to method could not be dereferenced as a hash") if $@;
        $args = \%copy;
    }
    elsif (@_==1 && !ref($_[0])) {
        $args = {single_arg => $_[0]};
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("Method got an odd number of elements");
    }
    return $args;
}

sub check {
    require UV::Check;
    return UV::Check->new(@_);
}

sub default_loop {
    require UV::Loop;
    return UV::Loop->default();
}

sub idle {
    require UV::Idle;
    return UV::Idle->new(@_);
}

sub loop {
    require UV::Loop;
    return UV::Loop->default();
}

sub poll {
    require UV::Poll;
    return UV::Poll->new(@_);
}

sub prepare {
    require UV::Prepare;
    return UV::Prepare->new(@_);
}

sub timer {
    require UV::Timer;
    return UV::Timer->new(@_);
}

1;

__END__

=encoding utf8

=head1 NAME

UV - Perl interface to libuv

=head1 SYNOPSIS

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


=head1 DESCRIPTION

This module provides an interface to L<libuv|http://libuv.org>. We will try to
document things here as best as we can, but we also suggest you look at the
L<libuv docs|http://docs.libuv.org> directly for more details on how things
work.

Event loops that work properly on all platforms. YAY!

=head1 CONSTANTS

=head2 VERSION CONSTANTS

=head3 UV_VERSION_MAJOR

=head3 UV_VERSION_MINOR

=head3 UV_VERSION_PATCH

=head3 UV_VERSION_IS_RELEASE

=head3 UV_VERSION_SUFFIX

=head3 UV_VERSION_HEX

=head2 ERROR CONSTANTS

=head3 UV_E2BIG

Argument list too long

=head3 UV_EACCES

Permission denied

=head3 UV_EADDRINUSE

Address already in use

=head3 UV_EADDRNOTAVAIL

Address not available

=head3 UV_EAFNOSUPPORT

Address family not supported

=head3 UV_EAGAIN

Resource temporarily unavailable

=head3 UV_EAI_ADDRFAMILY

Address family not supported

=head3 UV_EAI_AGAIN

Temporary failure

=head3 UV_EAI_BADFLAGS

Bad ai_flags value

=head3 UV_EAI_BADHINTS

Invalid value for hints

=head3 UV_EAI_CANCELED

Request canceled

=head3 UV_EAI_FAIL

Permanent failure

=head3 UV_EAI_FAMILY

ai_family not supported

=head3 UV_EAI_MEMORY

Out of memory

=head3 UV_EAI_NODATA

No address

=head3 UV_EAI_NONAME

Unknown node or service

=head3 UV_EAI_OVERFLOW

Argument buffer overflow

=head3 UV_EAI_PROTOCOL

Resolved protocol is unknown

=head3 UV_EAI_SERVICE

Service not available for socket type

=head3 UV_EAI_SOCKTYPE

Socket type not supported

=head3 UV_EALREADY

Connection already in progress

=head3 UV_EBADF

Bad file descriptor

=head3 UV_EBUSY

Resource busy or locked

=head3 UV_ECANCELED

Operation canceled

=head3 UV_ECHARSET

Invalid Unicode character

=head3 UV_ECONNABORTED

Software caused connection abort

=head3 UV_ECONNREFUSED

Connection refused

=head3 UV_ECONNRESET

Connection reset by peer

=head3 UV_EDESTADDRREQ

Destination address required

=head3 UV_EEXIST

File already exists

=head3 UV_EFAULT

Bad address in system call argument

=head3 UV_EFBIG

File too large

=head3 UV_EHOSTUNREACH

Host is unreachable

=head3 UV_EINTR

Interrupted system call

=head3 UV_EINVAL

Invalid argument

=head3 UV_EIO

i/o error

=head3 UV_EISCONN

Socket is already connected

=head3 UV_EISDIR

Illegal operation on a directory

=head3 UV_ELOOP

Too many symbolic links encountered

=head3 UV_EMFILE

Too many open files

=head3 UV_EMLINK

Too many links

=head3 UV_EMSGSIZE

Message too long

=head3 UV_ENAMETOOLONG

Name too long

=head3 UV_ENETDOWN

Network is down

=head3 UV_ENETUNREACH

Network is unreachable

=head3 UV_ENFILE

File table overflow

=head3 UV_ENOBUFS

No buffer space available

=head3 UV_ENODEV

No such device

=head3 UV_ENOENT

No such file or directory

=head3 UV_ENOMEM

Not enough memory

=head3 UV_ENONET

Machine is not on the network

=head3 UV_ENOPROTOOPT

Protocol not available

=head3 UV_ENOSPC

No space left on device

=head3 UV_ENOSYS

Function not implemented

=head3 UV_ENOTCONN

Socket is not connected

=head3 UV_ENOTDIR

Not a directory

=head3 UV_ENOTEMPTY

Directory not empty

=head3 UV_ENOTSOCK

Socket operation on non-socket

=head3 UV_ENOTSUP

Operation not supported on socket

=head3 UV_ENXIO

No such device or address

=head3 UV_EOF

End of file

=head3 UV_EPERM

Operation not permitted

=head3 UV_EPIPE

Broken pipe

=head3 UV_EPROTO

Protocol error

=head3 UV_EPROTONOSUPPORT

Protocol not supported

=head3 UV_EPROTOTYPE

Protocol wrong type for socket

=head3 UV_ERANGE

Result too large

=head3 UV_EROFS

Read-only file system

=head3 UV_ESHUTDOWN

Cannot send after transport endpoint shutdown

=head3 UV_ESPIPE

Invalid seek

=head3 UV_ESRCH

No such process

=head3 UV_ETIMEDOUT

Connection timed out

=head3 UV_ETXTBSY

Text file is busy

=head3 UV_EXDEV

Cross-device link not permitted

=head3 UV_UNKNOWN

Unknown error


=head1 FUNCTIONS

The following functions are available:

=head2 check

    my $handle = UV::check(); # uses the default loop
    my $handle = UV::check(loop => $some_other_loop); # non-default loop

Returns a new L<UV::Check> Handle object.

=head2 default_loop

    my $loop = UV::default_loop();
    # You can also get it with the UV::Loop methods below:
    my $loop = UV::Loop->default_loop();
    my $loop = UV::Loop->default();
    # Passing a true value as the first arg to the UV::Loop constructor
    # will also return the default loop
    my $loop = UV::Loop->new(1);

Returns the default loop (which is a singleton object). This module already
creates the default loop and you get access to it with this method.

=head2 err_name

    my $error_name = UV::err_name(UV::UV_EAI_BADFLAGS);
    say $error_name; # EAI_BADFLAGS

The L<err_name|http://docs.libuv.org/en/v1.x/errors.html#c.uv_err_name>
function returns the error name for the given error code. Leaks a few bytes of
memory when you call it with an unknown error code.

In libuv errors are negative numbered constants. As a rule of thumb, whenever
there is a status parameter, or an API functions returns an integer, a negative
number will imply an error.

When a function which takes a callback returns an error, the callback will
never be called.

=head2 hrtime

    my $uint64_t = UV::hrtime();

Get the current Hi-Res time (C<uint64_t>).

=head2 idle

    my $handle = UV::idle(); # uses the default loop
    my $handle = UV::idle(loop => $some_other_loop); # non-default loop

Returns a new L<UV::Idle> Handle object.

=head2 loop

    my $loop = UV::loop();
    # You can also get it with the UV::Loop methods below:
    my $loop = UV::Loop->default_loop();
    my $loop = UV::Loop->default();

Returns the default loop (which is a singleton object). This module already
creates the default loop and you get access to it with this method.

=head2 poll

    my $handle = UV::poll(); # uses the default loop
    my $handle = UV::poll(loop => $some_other_loop); # non-default loop

Returns a new L<UV::Poll> Handle object.

=head2 prepare

    my $handle = UV::prepare(); # uses the default loop
    my $handle = UV::prepare(loop => $some_other_loop); # non-default loop

Returns a new L<UV::Prepare> Handle object.

=head2 strerror

    my $error = UV::strerror(UV::UV_EAI_BADFLAGS);
    say $error; # bad ai_flags value

The L<strerror|http://docs.libuv.org/en/v1.x/errors.html#c.uv_strerror>
function returns the error message for the given error code. Leaks a few bytes
of memory when you call it with an unknown error code.

In libuv errors are negative numbered constants. As a rule of thumb, whenever
there is a status parameter, or an API functions returns an integer, a negative
number will imply an error.

When a function which takes a callback returns an error, the callback will
never be called.

=head2 timer

    my $timer = UV::timer(); # uses the default loop
    my $timer = UV::timer(loop => $some_other_loop); # non-default loop

Returns a new L<UV::Timer> object.

=head2 version

    my $int = UV::version();

The L<version|http://docs.libuv.org/en/v1.x/version.html#c.uv_version> function
returns C<UV::UV_VERSION_HEX>, the libuv version packed into a single integer.
8 bits are used for each component, with the patch number stored in the 8 least
significant bits. E.g. for libuv 1.2.3 this would be C<0x010203>.

=head2 version_string

    say UV::version_string();
    # 1.13.1

The L<version_string|http://docs.libuv.org/en/v1.x/version.html#c.uv_version_string>
function returns the libuv version number as a string. For non-release versions
the version suffix is included.

=head1 AUTHOR

Chase Whitener <F<capoeirab@cpan.org>>

=head1 AUTHOR EMERITUS

Daisuke Murase <F<typester@cpan.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2012, Daisuke Murase.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
