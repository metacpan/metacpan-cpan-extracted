package ZMQ::FFI::ZMQ4_1::Raw;
$ZMQ::FFI::ZMQ4_1::Raw::VERSION = '1.12';
use FFI::Platypus;

sub load {
    my ($soname) = @_;

    my $ffi    = FFI::Platypus->new( lib => $soname // 'libzmq.so' );
    my $target = caller;

    $ffi->attach(
        # void *zmq_ctx_new()
        ['zmq_ctx_new' => "${target}::zmq_ctx_new"]
			 => [] => 'pointer'
    );

    $ffi->attach(
        # int zmq_ctx_get(void *context, int option_name)
        ['zmq_ctx_get' => "${target}::zmq_ctx_get"]
			 => ['pointer', 'int'] => 'int'
    );

    $ffi->attach(
        # int zmq_ctx_set(void *context, int option_name, int option_value)
        ['zmq_ctx_set' => "${target}::zmq_ctx_set"]
			 => ['pointer', 'int', 'int'] => 'int'
    );

    $ffi->attach(
        # void *zmq_socket(void *context, int type)
        ['zmq_socket' => "${target}::zmq_socket"]
			 => ['pointer', 'int'] => 'pointer'
    );

    $ffi->attach(
        # int zmq_proxy(const void *front, const void *back, const void *cap)
        ['zmq_proxy' => "${target}::zmq_proxy"]
			 => ['pointer', 'pointer', 'pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_ctx_term (void *context)
        ['zmq_ctx_term' => "${target}::zmq_ctx_term"]
			 => ['pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_send(void *socket, void *buf, size_t len, int flags)
        ['zmq_send' => "${target}::zmq_send"]
            => ['pointer', 'string', 'size_t', 'int'] => 'int'
    );

    $ffi->attach(
        # int zmq_msg_recv(zmq_msg_t *msg, void *socket, int flags)
        ['zmq_msg_recv' => "${target}::zmq_msg_recv"]
            => ['pointer', 'pointer', 'int'] => 'int'
    );

    $ffi->attach(
        # int zmq_unbind(void *socket, const char *endpoint)
        ['zmq_unbind' => "${target}::zmq_unbind"]
            => ['pointer', 'string'] => 'int'
    );

    $ffi->attach(
        # int zmq_disconnect(void *socket, const char *endpoint)
        ['zmq_disconnect' => "${target}::zmq_disconnect"]
            => ['pointer', 'string'] => 'int'
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

    $ffi->attach(
        # int zmq_curve_keypair (char *z85_public_key, char *z85_secret_key);
        ['zmq_curve_keypair' => "${target}::zmq_curve_keypair"]
            => ['opaque', 'opaque'] => 'int'
    );

    $ffi->attach(
        # int zmq_has (const char *capability);
        ['zmq_has' => "${target}::zmq_has"]
            => ['string'] => 'int'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQ::FFI::ZMQ4_1::Raw

=head1 VERSION

version 1.12

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
