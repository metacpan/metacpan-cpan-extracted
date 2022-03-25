package ZMQ::FFI::ZMQ2::Raw;
$ZMQ::FFI::ZMQ2::Raw::VERSION = '1.18';
use FFI::Platypus;

sub load {
    my ($soname) = @_;

    my $ffi    = FFI::Platypus->new( lib => $soname // 'libzmq.so' );
    my $target = caller;

    $ffi->attach(
        # void *zmq_init(int io_threads)
        ['zmq_init' => "${target}::zmq_init"]
			 => ['int'] => 'pointer'
    );

    $ffi->attach(
        # void *zmq_socket(void *context, int type)
        ['zmq_socket' => "${target}::zmq_socket"]
			 => ['pointer', 'int'] => 'pointer'
    );

    $ffi->attach(
        # int zmq_device(int device, const void *front, const void *back)
        ['zmq_device' => "${target}::zmq_device"]
			 => ['int', 'pointer', 'pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_term(void *context)
        ['zmq_term' => "${target}::zmq_term"]
			 => ['pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_send(void *socket, zmq_msg_t *msg, int flags)
        ['zmq_send' => "${target}::zmq_send"]
            => ['pointer', 'pointer', 'int'] => 'int'
    );

    $ffi->attach(
        # int zmq_recv(void *socket, zmq_msg_t *msg, int flags)
        ['zmq_recv' => "${target}::zmq_recv"]
            => ['pointer', 'pointer', 'int'] => 'int'
    );

    $ffi->attach(
        # int zmq_connect(void *socket, const char *endpoint)
        ['zmq_connect' => "${target}::zmq_connect"]
            => ['pointer', 'string'] => 'int'
    );

    $ffi->attach(
        # int zmq_bind(void *socket, const char *endpoint)
        ['zmq_bind' => "${target}::zmq_bind"]
            => ['pointer', 'string'] => 'int'
    );

    $ffi->attach(
        # int zmq_msg_init(zmq_msg_t *msg)
        ['zmq_msg_init' => "${target}::zmq_msg_init"]
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_msg_init_size(zmq_msg_t *msg, size_t size)
        ['zmq_msg_init_size' => "${target}::zmq_msg_init_size"]
            => ['pointer', 'int'] => 'int'
    );

    $ffi->attach(
        # size_t zmq_msg_size(zmq_msg_t *msg)
        ['zmq_msg_size' => "${target}::zmq_msg_size"]
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        # void *zmq_msg_data(zmq_msg_t *msg)
        ['zmq_msg_data' => "${target}::zmq_msg_data"]
            => ['pointer'] => 'pointer'
    );

    $ffi->attach(
        # int zmq_msg_close(zmq_msg_t *msg)
        ['zmq_msg_close' => "${target}::zmq_msg_close"]
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_close(void *socket)
        ['zmq_close' => "${target}::zmq_close"]
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        # const char *zmq_strerror(int errnum)
        ['zmq_strerror' => "${target}::zmq_strerror"]
            => ['int'] => 'string'
    );

    $ffi->attach(
        # int zmq_errno(void)
        ['zmq_errno' => "${target}::zmq_errno"]
            => [] => 'int'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQ::FFI::ZMQ2::Raw

=head1 VERSION

version 1.18

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
