package Unblock::HTTP1::NativeABI;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec ();

use Unblock::HTTP1 ();
use Unblock::HTTP1::_Native ();

our $VERSION = $Unblock::HTTP1::VERSION;

use constant ABI_VERSION   => 1;
use constant INPUT_OK      => 0;
use constant INPUT_MORE    => 1;
use constant INPUT_CLOSED  => 3;
use constant INPUT_SWITCH  => 4;

my $include_dir = File::Spec->catdir(
    dirname(__FILE__),
    'NativeABI',
);

sub native_include_dir {
    return $include_dir;
}

sub header_path {
    return File::Spec->catfile(
        $include_dir,
        'unblock_http1_native_abi.h',
    );
}

sub c_header {
    my $path = header_path();

    open my $fh, '<', $path
        or die "could not read $path: $!";

    local $/;
    my $header = <$fh>;

    close $fh
        or die "could not close $path: $!";

    return $header;
}

sub definition {
    return {
        provider => \&Unblock::HTTP1::_Native::_borrowed_input_operations_address,
        abi_version => ABI_VERSION,
        struct_size =>
            Unblock::HTTP1::_Native::_borrowed_input_operations_size(),
        operations_address =>
            Unblock::HTTP1::_Native::_borrowed_input_operations_address(),
    };
}

1;

__END__

=head1 NAME

Unblock::HTTP1::NativeABI - Native transport ABI for Unblock::HTTP1

=head1 DESCRIPTION

This module exposes the optional native transport ABI used by XS-backed
transports and event frameworks.

The ordinary C<input()> method remains the portable interface. A native
integration can instead feed borrowed input buffers directly to the HTTP/1
engine.

The ABI works with both C<Unblock::HTTP1::Client> and
C<Unblock::HTTP1::Server>.

=head1 DISCOVERY

    my $definition = Unblock::HTTP1::NativeABI::definition();

The returned hash contains:

    provider
    abi_version
    struct_size
    operations_address

C<provider> keeps the XS provider loaded and can be called again to obtain the
current operations address.

Consumers must check both C<abi_version> and C<struct_size> before
dereferencing operations.

=head1 HEADER

The installed header is:

    Unblock/HTTP1/NativeABI/unblock_http1_native_abi.h

Its include directory is available through:

    Unblock::HTTP1::NativeABI::native_include_dir()

The complete installed path is available through:

    Unblock::HTTP1::NativeABI::header_path()

C<c_header()> returns the same header text for build systems that prefer to
generate a private copy.

=head1 C ABI

ABI version 1 contains C<create>, C<input>, C<eof>, and C<destroy>.

C<create> receives one Unblock::HTTP1 Client or Server object and returns a
connection-local native context. Keep that context for the lifetime of the
HTTP/1 connection.

=head1 BORROWED INPUT

The native input operation receives:

    const char *data
    size_t length
    size_t *consumed

C<data> remains owned by the caller. Unblock::HTTP1 may inspect it only during
the input call and never retains the pointer after the call returns.

ABI version 1 uses these input result codes:

    INPUT_OK       0
    INPUT_MORE     1
    INPUT_CLOSED   3
    INPUT_SWITCH   4

C<INPUT_MORE> means the unconsumed tail must be retained by the host and
presented again with more contiguous bytes.

C<INPUT_SWITCH> means HTTP parsing has ended. The unconsumed tail belongs to
the protocol that takes ownership after HTTP.

=head1 FALLBACK

The native ABI is an optimization. A framework that does not use XS, cannot
consume ABI version 1, or chooses not to use the fast path should continue to
use C<input()>.

=cut
