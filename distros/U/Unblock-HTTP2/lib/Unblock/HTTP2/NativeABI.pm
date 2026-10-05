package Unblock::HTTP2::NativeABI;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec ();

use Unblock::HTTP2 ();
use Unblock::HTTP2::_nghttp2 ();

our $VERSION = $Unblock::HTTP2::VERSION;

use constant ABI_VERSION      => 1;
use constant INPUT_OK         => 0;
use constant INPUT_MORE       => 1;
use constant INPUT_CLOSED     => 3;
use constant OUTPUT_OK        => 0;
use constant OUTPUT_CLOSED    => 3;
use constant OUTPUT_CONTINUE  => 0;
use constant OUTPUT_PAUSE     => 1;
use constant OUTPUT_ERROR     => -1;

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
        'unblock_http2_native_abi.h',
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
        provider => \&Unblock::HTTP2::_nghttp2::_native_transport_operations_address,
        abi_version => ABI_VERSION,
        struct_size =>
            Unblock::HTTP2::_nghttp2::_native_transport_operations_size(),
        operations_address =>
            Unblock::HTTP2::_nghttp2::_native_transport_operations_address(),
    };
}

1;

__END__

=head1 NAME

Unblock::HTTP2::NativeABI - Native transport ABI for Unblock::HTTP2

=head1 DESCRIPTION

This module exposes the optional native transport ABI used by XS-backed
transports and event frameworks.

The ordinary C<input()> and C<output()> methods remain the portable interface.
A native integration can instead feed borrowed input buffers directly and drain
outbound nghttp2 buffers through a native sink callback.

The ABI works with both C<Unblock::HTTP2::Client> and
C<Unblock::HTTP2::Server>.

=head1 DISCOVERY

    my $definition = Unblock::HTTP2::NativeABI::definition();

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

    Unblock/HTTP2/NativeABI/unblock_http2_native_abi.h

Its include directory is available through:

    Unblock::HTTP2::NativeABI::native_include_dir()

The complete installed path is available through:

    Unblock::HTTP2::NativeABI::header_path()

C<c_header()> returns the same header text for build systems that prefer to
generate a private copy.

=head1 C ABI

ABI version 1 begins with C<create>, C<input>, C<eof>, and C<destroy>.
HTTP/2 then appends native output and readiness operations.

C<create> receives one Unblock::HTTP2 Client or Server object and returns a
connection-local native context. Keep that context for the lifetime of the
HTTP/2 connection.

=head1 BORROWED INPUT

The native input operation receives:

    const char *data
    size_t length
    size_t *consumed

C<data> remains owned by the caller. Unblock::HTTP2 may inspect it only during
the input call and never retains the pointer after the call returns.

libnghttp2 incrementally retains protocol parsing state, so fragmented HTTP/2
frames do not require the caller to preserve an incomplete prefix. A successful
call normally reports the complete input window as consumed.

ABI version 1 uses these input result codes:

    INPUT_OK       0
    INPUT_MORE     1
    INPUT_CLOSED   3

C<INPUT_MORE> is reserved for compatibility with the common Unblock borrowed
input pattern. The current HTTP/2 implementation does not normally return it.

=head1 NATIVE OUTPUT

C<output> drains generated HTTP/2 bytes directly from libnghttp2 into a native
sink callback.

The sink receives a borrowed buffer:

    const char *data
    size_t length

That pointer is valid only for the duration of the sink call. The sink must
write or copy the bytes before returning.

The sink return value controls draining:

    OUTPUT_CONTINUE   keep draining
    OUTPUT_PAUSE      current chunk was accepted; stop after it
    OUTPUT_ERROR      fatal sink failure

C<OUTPUT_PAUSE> provides transport backpressure without losing the chunk that
was just accepted. Call C<output> again when the transport can accept more.

C<produced> reports the number of bytes accepted by the sink during the call.

=head1 EOF

HTTP/2 has no message framing based on transport EOF. C<eof> therefore closes
the connection and returns C<INPUT_CLOSED>.

=head1 FALLBACK

The native ABI is an optimization. A framework that does not use XS, cannot
consume ABI version 1, or chooses not to use the fast path should continue to
use C<input()>, C<output()>, C<want_read()>, and C<want_write()>.

=cut
