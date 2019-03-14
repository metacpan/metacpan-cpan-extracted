package ZMQ::FFI::Custom::Raw;
$ZMQ::FFI::Custom::Raw::VERSION = '1.17';
sub load {
    my ($soname) = @_;

    my $ffi    = FFI::Platypus->new( lib => $soname // 'libzmq.so' );
    my $target = caller;

    #
    # for get/set sockopt create ffi functions for each possible opt type
    #

    # int zmq_getsockopt(void *sock, int opt, void *val, size_t *len)

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_binary"]
            => ['pointer', 'int', 'pointer', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_int"]
            => ['pointer', 'int', 'int*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_int64"]
            => ['pointer', 'int', 'sint64*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_uint64"]
            => ['pointer', 'int', 'uint64*', 'size_t*'] => 'int'
    );

    # int zmq_setsockopt(void *sock, int opt, const void *val, size_t len)

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_binary"]
            => ['pointer', 'int', 'pointer', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_int"]
            => ['pointer', 'int', 'int*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_int64"]
            => ['pointer', 'int', 'sint64*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_uint64"]
            => ['pointer', 'int', 'uint64*', 'size_t'] => 'int'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQ::FFI::Custom::Raw

=head1 VERSION

version 1.17

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
