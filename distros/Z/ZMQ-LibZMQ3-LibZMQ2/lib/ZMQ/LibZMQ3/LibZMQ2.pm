package ZMQ::LibZMQ3::LibZMQ2;

use 5.006;
use strict;
use warnings FATAL => 'all';
use ZMQ::LibZMQ3;

=head1 NAME

ZMQ::LibZMQ3::LibZMQ2 - Seamlessly Run LibZMQ Progs against LibZMQ3

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This provides an interface compatible with ZMQ::LibZMQ2, but runs against
ZMQ::LibZMQ3.  For more information and documentation, see ZMQ::LibZMQ2

To port, assuming no fully qualified namespace calls, change

 #use ZMQ::LibZMQ2;

to

 use ZMQ::LibZMQ3::LibZMQ2;

=head2 Porting Implementation and Caveats

There are a few specific issues that come up when porting LibZMQ2 applications
to LibZMQ3.   This module attempts to provide a basic wrapper, preventing those
most common issues from surfacing.  This is not intended for new development,
but for cases where existing code uses ZMQ::LibZMQ2 and you need to deploy
against LibZMQ3.

The primary cases covered are:

=over

=item renamed methods

For example, zmq_recv becomes zmq_recvmsg.

=item different return value semantics

For example, zmq_sendmsg returning positive ints on success on 3.x while
zmq_send returns 0 on success in libzmq2

=item poll argument semantics

The argument is now in miliseconds rather than microseconds, so without wrapping
this, applications poll for 1000 times as long.

=back

There are, however, a very few specific cases not covered by the porting layer.
For the most part these are internal details that programs hopefully avoid
caring about but they were found during the test cases copied from ZMQ::LibZMQ2.

These include:

=over

=item object class names

Objects are blessed in the LibZMQ3 namespace instead of the LibZMQ2 namespace.
For example, a socket is blessed as ZMQ::LibZMQ3::Socket rather than
ZMQ::LibZMQ2::Socket.

=item object internals

Object reference semantics are not guaranteed to be useful across
implementations.  For example, sockets were blessed scalar references in
LibZMQ2, but they are not in LibZMQ3.

=back

The above caveats are fairly minor, and are expected not to affect most
applications.

=head1 EXPORT

=over

=item zmq_errno

=item zmq_strerror

=item zmq_init

=item zmq_socket

=item zmq_bind

=item zmq_connect

=item zmq_close

=item zmq_getsockopt

=item zmq_setsockopt

=item zmq_send

=item zmq_recv

=item zmq_msg_init

=item zmq_msg_init_data

=item zmq_msg_init_size

=item zmq_msg_copy

=item zmq_msg_move

=item zmq_msg_close

=item zmq_msg_poll

=item zmq_version

=item zmq_device

=item zmq_getsockopt_int

=item zmq_getsockopt_int64

=item zmq_getsockopt_string

=item zmq_getsockopt_uint64

=item zmq_setsockopt_int

=item zmq_setsockopt_int64

=item zmq_setsockopt_string

=item zmq_setsockopt_uint64

=back

=cut

use base qw(Exporter);
## no critic (ProhibitAutomaticExportation)
our @EXPORT = qw(
    zmq_errno zmq_strerror
    zmq_init zmq_term zmq_socket zmq_bind zmq_connect zmq_close
    zmq_getsockopt zmq_setsockopt
    zmq_send zmq_recv
    zmq_msg_init zmq_msg_init_data zmq_msg_init_size
    zmq_msg_data zmq_msg_size
    zmq_msg_copy zmq_msg_move zmq_msg_close
    zmq_poll zmq_version zmq_device
    zmq_setsockopt_int zmq_setsockopt_int64 zmq_setsockopt_string
    zmq_setsockopt_uint64 zmq_getsockopt_int zmq_getsockopt_int64
    zmq_getsockopt_string zmq_getsockopt_uintint64
);

# Function override map:
# libzmq2 => libzmq3
#
# if you need to skip, you can do
#
# libzmq2 => 0
#
# and then define your own function
my %fmap = (
    zmq_send => 0,
    zmq_recv => 'zmq_recvmsg',
    zmq_poll => 0,
);

{
    no strict 'refs';      ## no critic (ProhibitNoStrict)
    no warnings 'once';    ## no critic (ProhibitNoWarnings)
    my $pkg = __PACKAGE__;
    *{"${pkg}::$_->{export}"} = *{"ZMQ::LibZMQ3::$_->{import}"} for map {
        my $target = $_;
        $target = $fmap{$_} if exists $fmap{$_};
        $target
            ? {
            import => $target,
            export => $_
            }
            : ();
    } @EXPORT;
};

no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

sub zmq_poll {
    my $timeout = pop @_;
    push @_, $timeout / 1000;
    return ZMQ::LibZMQ3::zmq_poll(@_);
}

sub zmq_send {
    my $rv = ZMQ::LibZMQ3::zmq_sendmsg(@_) || 0;
    return $rv == -1 ? -1 : 0;
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zmq-libzmq2-libzmq3 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZMQ-LibZMQ2-LibZMQ3>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZMQ::LibZMQ2::LibZMQ3


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZMQ-LibZMQ2-LibZMQ3>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZMQ-LibZMQ2-LibZMQ3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZMQ-LibZMQ2-LibZMQ3>

=item * Search CPAN

L<http://search.cpan.org/dist/ZMQ-LibZMQ2-LibZMQ3/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Binary.com.

This code is released under the Apache License version 2.  Please see the
included LICENSE file.

=head2 TEST SUITE COPYRIGHT AND LICENSE

The Test Suite is copied from ZMQ::LibZMQ, is copyright Daisuke Maki
<daisuke@endeworks.jp> and Steffen Mueller, <smueller@cpan.org>.

It is released uner the same terms as Perl itself.


=cut

1;    # End of ZMQ::LibZMQ2::LibZMQ3
