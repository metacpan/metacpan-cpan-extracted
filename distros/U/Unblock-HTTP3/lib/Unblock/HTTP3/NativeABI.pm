package Unblock::HTTP3::NativeABI;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec ();

use Unblock::HTTP3 ();
use Unblock::HTTP3::_Native ();

our $VERSION = '0.03';

use constant ABI_VERSION   => 1;
use constant TX_ACTIVE     => 0;
use constant TX_COMPLETE   => 1;
use constant TX_CANCELLED  => 2;
use constant TX_ERROR      => 3;

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
        'unblock_http3_consumer.h',
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
        provider => \&Unblock::HTTP3::_Native::_consumer_operations_address,
        abi_version => ABI_VERSION,
        struct_size =>
            Unblock::HTTP3::_Native::_consumer_operations_size(),
        operations_address =>
            Unblock::HTTP3::_Native::_consumer_operations_address(),
    };
}

1;

__END__

=head1 NAME

Unblock::HTTP3::NativeABI - Native consumer ABI for Unblock::HTTP3

=head1 DESCRIPTION

This module exposes the optional native consumer ABI for XS event frameworks
and HTTP libraries.

The normal Perl API remains the portable interface. Native consumers may keep
one persistent ABI context for a C<Unblock::HTTP3::Connection> and use C
function pointers for the common connection and transaction path.

The ABI does not expose libnghttp3 structures or private Unblock::HTTP3
storage. QUIC transport ownership remains with Net::QUIC.

=head1 DISCOVERY

    my $definition = Unblock::HTTP3::NativeABI::definition();

The returned hash contains:

    provider
    abi_version
    struct_size
    operations_address

C<provider> keeps the XS provider loaded and may be called again to obtain the
current operations address.

Consumers must check both C<abi_version> and C<struct_size> before
dereferencing operations.

ABI version 1 accepts exact C<Unblock::HTTP3::Connection> and
C<Unblock::HTTP3::Transaction> objects. Subclasses should use the portable
Perl API.

=head1 HEADER

The installed header is:

    Unblock/HTTP3/NativeABI/unblock_http3_consumer.h

Its include directory is available through:

    Unblock::HTTP3::NativeABI::native_include_dir()

C<c_header()> returns the same header text for build systems that prefer to
generate a private copy.

=head1 ABI VERSION 1

ABI version 1 provides operations to:

    create and destroy a persistent Connection context
    service a Connection
    submit a normal client request
    poll ready Transactions
    poll informational response events
    access canonical Request and Response objects
    access Transaction stream ID and state
    send normal and informational server responses
    inspect Connection failure state

C<request()> uses the normal request defaults. Advanced Perl-only request
options such as streaming body configuration remain available through the
portable API.

=head1 OWNERSHIP

C<request()>, C<next_transaction()>, C<next_informational()>, and
C<transaction_next_informational()> return owned SV pointers with one caller
reference. The consumer must mortalize or decrement them.

C<transaction_request()>, C<transaction_response()>, and C<error()> return
borrowed SV pointers. They remain valid only while the owning object remains
alive and unchanged.

C<request()> returns NULL when the ordinary request path returns undef,
including temporary QUIC stream-credit backpressure. Poll operations return
NULL when no item is ready. C<transaction_response()> returns NULL until a
response exists.

Canonical Request and Response objects may be inspected with the
Uniform::HTTP 0.06 native FastPath.

=head1 THREADS

Create one ABI context per Perl interpreter. Do not share a context across
ithreads. Create a fresh context after an interpreter clone.

=head1 FALLBACK

The native ABI is an optimization. Consumers that cannot use ABI version 1
should continue to use the ordinary Perl API.

=cut
