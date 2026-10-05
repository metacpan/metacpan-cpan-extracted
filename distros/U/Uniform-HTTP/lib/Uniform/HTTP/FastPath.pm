package Uniform::HTTP::FastPath;

use strict;
use warnings;
use Carp qw(croak);

use Uniform::HTTP::Message ();
use Uniform::HTTP::Request ();
use Uniform::HTTP::Response ();

our $VERSION = '0.06';

use constant ABI_VERSION => 1;

# The native header is compiled by consumers, never by this distribution.
use constant NATIVE_ABI_VERSION => 1;
use constant _NATIVE_LAYOUT_VERSION => 1;

sub native_compatible {
    return 0 unless @_ == 2;
    my ($abi, $layout) = @_;
    return 0 unless defined($abi) && !ref($abi) && $abi =~ /\A[0-9]+\z/
        && defined($layout) && !ref($layout) && $layout =~ /\A[0-9]+\z/;
    return $abi == NATIVE_ABI_VERSION && $layout == _NATIVE_LAYOUT_VERSION
        ? 1 : 0;
}

my $native_include_dir = do {
    require File::Basename;
    require File::Spec;
    File::Spec->rel2abs(File::Spec->catdir(
        File::Basename::dirname(__FILE__), 'FastPath',
    ));
};

sub native_include_dir { return $native_include_dir }

use constant KIND_MESSAGE  => 0;
use constant KIND_REQUEST  => 1;
use constant KIND_RESPONSE => 2;

use constant FLAG_HAS_BUFFERED_BODY => 0x001;
use constant FLAG_COMPLETE          => 0x002;
use constant FLAG_MUTABLE           => 0x004;
use constant FLAG_INITIAL_MUTABLE   => 0x008;
use constant FLAG_BODY_MUTABLE      => 0x010;
use constant FLAG_TRAILERS_MUTABLE  => 0x020;
use constant FLAG_HEADERS_LOSSLESS  => 0x040;
use constant FLAG_TRAILERS_LOSSLESS => 0x080;
use constant FLAG_TARGET_EXACT      => 0x100;

use constant SLOT_ABI       => 0;
use constant SLOT_KIND      => 1;
use constant SLOT_FLAGS     => 2;
use constant SLOT_VERSION   => 3;
use constant SLOT_METHOD    => 4;
use constant SLOT_TARGET    => 5;
use constant SLOT_SCHEME    => 6;
use constant SLOT_AUTHORITY => 7;
use constant SLOT_PROTOCOL  => 8;
use constant SLOT_STATUS    => 9;
use constant SLOT_REASON    => 10;
use constant SLOT_HEADERS   => 11;
use constant SLOT_TRAILERS  => 12;
use constant SLOT_BODY      => 13;
use constant SLOT_COUNT     => 14;

use constant _ALL_FLAGS => 0x1ff;

sub can_view {
    croak 'can_view() requires exactly one message' unless @_ == 1;
    my ($message) = @_;
    my $class = ref($message) || '';
    return 1 if $class eq 'Uniform::HTTP::Message';
    return 1 if $class eq 'Uniform::HTTP::Request';
    return 1 if $class eq 'Uniform::HTTP::Response';
    return 0;
}

sub view {
    croak 'view() requires a message and optional ABI version'
        unless @_ == 1 || @_ == 2;
    my ($message, $abi) = @_;
    $abi = ABI_VERSION unless defined $abi;

    croak 'unsupported Uniform::HTTP fast-path ABI'
        unless !ref($abi) && $abi =~ /\A[0-9]+\z/ && $abi == ABI_VERSION;
    croak 'fast path requires an exact canonical Uniform::HTTP message class'
        unless can_view($message);

    my $class = ref $message;
    my $kind = $class eq 'Uniform::HTTP::Request'  ? KIND_REQUEST
             : $class eq 'Uniform::HTTP::Response' ? KIND_RESPONSE
             : KIND_MESSAGE;

    my $flags = FLAG_HEADERS_LOSSLESS | FLAG_TRAILERS_LOSSLESS;
    $flags |= FLAG_HAS_BUFFERED_BODY if $message->{has_buffered_body};
    $flags |= FLAG_COMPLETE          if $message->{complete};
    $flags |= FLAG_MUTABLE           if $message->{mutable};
    $flags |= FLAG_INITIAL_MUTABLE
        if $message->{mutable} && !$message->{initial_frozen};
    $flags |= FLAG_BODY_MUTABLE if $message->{mutable};
    $flags |= FLAG_TRAILERS_MUTABLE
        if $message->{mutable} && !$message->{trailers_frozen};
    $flags |= FLAG_TARGET_EXACT if $kind == KIND_REQUEST;

    return [
        ABI_VERSION,
        $kind,
        $flags,
        $message->{version},
        $kind == KIND_REQUEST ? $message->{method}    : undef,
        $kind == KIND_REQUEST ? $message->{target}    : undef,
        $kind == KIND_REQUEST ? $message->{scheme}    : undef,
        $kind == KIND_REQUEST ? $message->{authority} : undef,
        $kind == KIND_REQUEST ? $message->{protocol}  : undef,
        $kind == KIND_RESPONSE ? $message->{status} : undef,
        $kind == KIND_RESPONSE ? $message->{reason} : undef,
        $message->{headers},
        $message->{trailers},
        $message->{has_buffered_body} ? $message->{body} : undef,
    ];
}

sub request_from_validated {
    croak 'request_from_validated() requires exactly one fast-path view'
        unless @_ == 1;
    my ($view) = @_;
    _validate_view($view, KIND_REQUEST);

    my $self = _common_from_view($view);
    $self->{method}    = $view->[SLOT_METHOD];
    $self->{target}    = $view->[SLOT_TARGET];
    $self->{scheme}    = $view->[SLOT_SCHEME];
    $self->{authority} = $view->[SLOT_AUTHORITY];
    $self->{protocol}  = $view->[SLOT_PROTOCOL];

    return bless $self, 'Uniform::HTTP::Request';
}

sub response_from_validated {
    croak 'response_from_validated() requires exactly one fast-path view'
        unless @_ == 1;
    my ($view) = @_;
    _validate_view($view, KIND_RESPONSE);

    my $self = _common_from_view($view);
    $self->{status} = $view->[SLOT_STATUS];
    $self->{reason} = $view->[SLOT_REASON];

    return bless $self, 'Uniform::HTTP::Response';
}

sub _common_from_view {
    my ($view) = @_;
    my $flags = $view->[SLOT_FLAGS];

    return {
        version           => $view->[SLOT_VERSION],
        headers           => $view->[SLOT_HEADERS],
        trailers          => $view->[SLOT_TRAILERS],
        initial_frozen    => $flags & FLAG_INITIAL_MUTABLE ? 0 : 1,
        trailers_frozen   => $flags & FLAG_TRAILERS_MUTABLE ? 0 : 1,
        body              => $flags & FLAG_HAS_BUFFERED_BODY
            ? $view->[SLOT_BODY] : undef,
        has_buffered_body => $flags & FLAG_HAS_BUFFERED_BODY ? 1 : 0,
        complete          => $flags & FLAG_COMPLETE ? 1 : 0,
        mutable           => $flags & FLAG_MUTABLE ? 1 : 0,
    };
}

sub _validate_view {
    my ($view, $kind) = @_;

    croak 'fast-path view must be an array reference'
        unless ref($view) eq 'ARRAY';
    croak 'fast-path view has the wrong number of slots'
        unless @$view == SLOT_COUNT;
    croak 'unsupported Uniform::HTTP fast-path ABI'
        unless defined($view->[SLOT_ABI])
            && !ref($view->[SLOT_ABI])
            && $view->[SLOT_ABI] =~ /\A[0-9]+\z/
            && $view->[SLOT_ABI] == ABI_VERSION;
    croak 'fast-path view has the wrong message kind'
        unless defined($view->[SLOT_KIND])
            && !ref($view->[SLOT_KIND])
            && $view->[SLOT_KIND] =~ /\A[0-9]+\z/
            && $view->[SLOT_KIND] == $kind;

    my $flags = $view->[SLOT_FLAGS];
    croak 'fast-path flags must be a non-negative integer'
        unless defined($flags) && !ref($flags) && $flags =~ /\A[0-9]+\z/;
    croak 'fast-path view contains unknown flags'
        if $flags & ~_ALL_FLAGS;

    croak 'fast-path headers must be an array reference'
        unless ref($view->[SLOT_HEADERS]) eq 'ARRAY';
    croak 'fast-path trailers must be an array reference'
        unless ref($view->[SLOT_TRAILERS]) eq 'ARRAY';

    croak 'trusted canonical construction requires lossless headers'
        unless $flags & FLAG_HEADERS_LOSSLESS;
    croak 'trusted canonical construction requires lossless trailers'
        unless $flags & FLAG_TRAILERS_LOSSLESS;

    if ($flags & FLAG_HAS_BUFFERED_BODY) {
        croak 'buffered fast-path body must be a defined plain scalar'
            unless defined($view->[SLOT_BODY]) && !ref($view->[SLOT_BODY]);
    }
    else {
        croak 'fast-path body slot must be undef when no buffered body is present'
            if defined $view->[SLOT_BODY];
    }

    my $mutable = $flags & FLAG_MUTABLE ? 1 : 0;
    my $body_mutable = $flags & FLAG_BODY_MUTABLE ? 1 : 0;
    croak 'fast-path body mutability is not canonical'
        unless $mutable == $body_mutable;
    if (!$mutable) {
        croak 'immutable fast-path view advertises a mutable section'
            if $flags & (FLAG_INITIAL_MUTABLE
                | FLAG_BODY_MUTABLE | FLAG_TRAILERS_MUTABLE);
    }

    if ($kind == KIND_REQUEST) {
        croak 'trusted request requires exact target fidelity'
            unless $flags & FLAG_TARGET_EXACT;
        croak 'trusted request method must be a defined plain scalar'
            unless defined($view->[SLOT_METHOD]) && !ref($view->[SLOT_METHOD]);
        croak 'trusted request target must be a defined plain scalar'
            unless defined($view->[SLOT_TARGET]) && !ref($view->[SLOT_TARGET]);
    }
    else {
        croak 'response fast-path view must not set request target fidelity'
            if $flags & FLAG_TARGET_EXACT;
        croak 'trusted response status must be a defined plain scalar'
            unless defined($view->[SLOT_STATUS]) && !ref($view->[SLOT_STATUS]);
    }

    return;
}

1;

__END__

=head1 NAME

Uniform::HTTP::FastPath - Optional fast path for native HTTP engines

=head1 SYNOPSIS

    use Uniform::HTTP::FastPath;

    if (Uniform::HTTP::FastPath::can_view($request)) {
        my $view = Uniform::HTTP::FastPath::view($request);
        $native_engine->send_uniform_fast($view);
    }

=head1 DESCRIPTION

Uniform::HTTP::FastPath is an optional interface for native-backed HTTP
implementations.

It lets an engine inspect a canonical Uniform message in one operation instead
of making many Perl method calls. It can also build a canonical Request or
Response from values that the engine has already validated.

Normal application code should use L<Uniform::HTTP::Request> and
L<Uniform::HTTP::Response>. Adapters and subclasses use the normal portable
Uniform API.

FastPath does not parse HTTP, serialize HTTP, perform I/O, or choose an HTTP
version.

=head1 ABI

The current fast-path ABI is version 1:

    Uniform::HTTP::FastPath::ABI_VERSION()   # 1

A native consumer must check the ABI version before interpreting a view.
Incompatible layouts will use a new ABI version.

=head2 can_view

    my $ok = Uniform::HTTP::FastPath::can_view($message);

Returns true only for exact canonical objects:

    Uniform::HTTP::Message
    Uniform::HTTP::Request
    Uniform::HTTP::Response

Subclasses and adapters return false because their storage or behavior may be
different.

=head2 view

    my $view = Uniform::HTTP::FastPath::view($message);

Returns an array reference with this ABI 1 layout:

    0   ABI version
    1   message kind
    2   flags
    3   HTTP version
    4   request method
    5   request target
    6   request scheme
    7   request authority
    8   request protocol
    9   response status
    10  response reason
    11  headers
    12  trailers
    13  buffered body

Use the C<SLOT_*> constants instead of hardcoded indexes when writing Perl
code.

Message kinds are:

    KIND_MESSAGE
    KIND_REQUEST
    KIND_RESPONSE

Request-only slots are C<undef> for responses. Response-only slots are C<undef>
for requests.

=head1 FLAGS

C<SLOT_FLAGS> can contain:

    FLAG_HAS_BUFFERED_BODY
    FLAG_COMPLETE
    FLAG_MUTABLE
    FLAG_INITIAL_MUTABLE
    FLAG_BODY_MUTABLE
    FLAG_TRAILERS_MUTABLE
    FLAG_HEADERS_LOSSLESS
    FLAG_TRAILERS_LOSSLESS
    FLAG_TARGET_EXACT

These describe the canonical object at the time C<view()> is called.

=head1 HEADERS AND TRAILERS

The header and trailer slots contain the canonical ordered arrays of
C<[ name, value ]> pairs.

These arrays are borrowed, not copied. A consumer must not modify them, and the
source message must not be changed while native code is using the view.

Take a new view after changing a message.

=head1 TRUSTED CONSTRUCTION

=head2 request_from_validated

    my $request =
        Uniform::HTTP::FastPath::request_from_validated($view);

=head2 response_from_validated

    my $response =
        Uniform::HTTP::FastPath::response_from_validated($view);

These functions are for protocol engines that have already validated the
message values.

They skip the normal per-field HTTP validation and adopt the header and trailer
arrays from the view. This avoids repeating work already done by a trusted
parser.

The caller must guarantee that all supplied values satisfy the normal
Uniform::HTTP rules. After successful construction, the caller must not modify
the adopted header or trailer arrays.

Use the normal Request or Response constructor for application input, wire data
that has not been fully validated, or data from an untrusted adapter.

=head1 NATIVE HEADER

Uniform::HTTP is pure Perl. No compiler is required to install it.

XS consumers can compile F<uniform_http_fastpath.h> as part of their own
distribution. The header constructs exact canonical Message, Request, and
Response objects from validated native byte spans. It can also inspect a
canonical object without allocating a Perl view or making per-field Perl calls.

Find the installed header directory with:

    my $include = Uniform::HTTP::FastPath::native_include_dir();

The native contract has its own version:

    Uniform::HTTP::FastPath::NATIVE_ABI_VERSION()   # 1

Consumers must initialize a per-interpreter handle with C<uhttp_native_init>.
It checks the compiled header against the installed runtime. The Perl helper
C<native_compatible(abi, layout)> supports that handshake; consumers do not
choose or override the header's private storage revision.

Construction copies native input bytes and requires explicit trusted opt-in.
It does not validate HTTP syntax. Inspection borrows existing values only while
the source is alive and unchanged. Adapters and subclasses use the portable
API. No native setter or alternate message class is introduced.

The Perl FastPath ABI, including its array-adoption rules, is unchanged.
See F<docs/NATIVE-FASTPATH.md> for the C API, ownership rules, examples, and
author-only conformance tests. Normal applications do not need this interface.

=head1 FALLBACK

FastPath is never required.

A native implementation should use C<can_view()> and fall back to the normal
Uniform methods when it returns false. This keeps adapters, subclasses, and
pure-Perl implementations fully portable.

=head1 SECURITY

Trusted construction deliberately bypasses normal semantic validation.

Do not use C<request_from_validated()> or C<response_from_validated()> as
general-purpose constructors. They are an interface between Uniform and a
component that has already enforced the same invariants.

The ordinary public constructors remain fully validated.

=head1 VERSION

Module version 0.06. Perl and native FastPath ABI versions are both 1.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
