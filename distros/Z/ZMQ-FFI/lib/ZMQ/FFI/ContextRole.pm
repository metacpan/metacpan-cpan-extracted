package ZMQ::FFI::ContextRole;
$ZMQ::FFI::ContextRole::VERSION = '1.18';
use Moo::Role;

use ZMQ::FFI::Util qw(current_tid);

# real underlying zmq context pointer
has context_ptr => (
    is      => 'rw',
    default => -1,
);

# used to make sure we handle fork situations correctly
has _pid => (
    is      => 'ro',
    default => sub { $$ },
);

# used to make sure we handle thread situations correctly
has _tid => (
    is      => 'ro',
    default => sub { current_tid() },
);

has soname => (
    is       => 'ro',
    required => 1,
);

has threads => (
    is        => 'ro',
    predicate => 'has_threads',
);

has max_sockets => (
    is        => 'ro',
    predicate => 'has_max_sockets',
);

has sockets => (
    is        => 'rw',
    lazy      => 1,
    default   => sub { {} },
);

requires qw(
    init
    get
    set
    socket
    proxy
    device
    destroy
    curve_keypair
    z85_encode
    z85_decode
    has_capability
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQ::FFI::ContextRole

=head1 VERSION

version 1.18

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
