package Unblock::HTTP2::_Headers;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);

use Uniform::HTTP::FastPath 0.06 ();
use Uniform::HTTP::Request 0.06;
use Uniform::HTTP::Response 0.06;

our $VERSION = '0.11';

my %FORBIDDEN = map { $_ => 1 } qw(
    connection
    keep-alive
    proxy-connection
    transfer-encoding
    upgrade
);

my $TOKEN_RE = qr/\A[!\#\$%&'*+\-.\^_`|~0-9A-Za-z]+\z/;

sub native_message {
    my ($class, $message) = @_;
    return unless Uniform::HTTP::FastPath::can_view($message);
    return $message;
}

sub _received_flags {
    my ($kind, $end_stream) = @_;

    my $flags =
          Uniform::HTTP::FastPath::FLAG_HEADERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TRAILERS_LOSSLESS();

    $flags |= Uniform::HTTP::FastPath::FLAG_TARGET_EXACT()
        if $kind == Uniform::HTTP::FastPath::KIND_REQUEST();

    if ($end_stream) {
        $flags |= Uniform::HTTP::FastPath::FLAG_COMPLETE();
    }
    else {
        $flags |= Uniform::HTTP::FastPath::FLAG_MUTABLE()
            | Uniform::HTTP::FastPath::FLAG_BODY_MUTABLE()
            | Uniform::HTTP::FastPath::FLAG_TRAILERS_MUTABLE();
    }

    return $flags;
}

sub _validate_request_value {
    my ($operation, $name, $value) = @_;

    if ($name eq 'method' || $name eq 'protocol') {
        croak "$operation: $name must be an HTTP token"
            unless defined($value) && !ref($value) && $value =~ $TOKEN_RE;
        return;
    }

    if ($name eq 'target') {
        croak "$operation: target must not be empty"
            unless defined($value) && !ref($value) && length($value);
        croak "$operation: target contains spaces or control bytes"
            if $value =~ /[\x00-\x20\x7f]/;
        return;
    }

    if ($name eq 'scheme') {
        croak "$operation: scheme must be a valid URI scheme"
            unless defined($value) && !ref($value)
                && $value =~ /\A[A-Za-z][A-Za-z0-9+.-]*\z/;
        return;
    }

    if ($name eq 'authority') {
        croak "$operation: authority must not be empty"
            unless defined($value) && !ref($value) && length($value);
        croak "$operation: authority contains a prohibited delimiter or control byte"
            if $value =~ /[\x00-\x20\x7f\/?#]/;
        return;
    }

    croak "$operation: unknown request value '$name'";
}

sub _pairs {
    my ($operation, $pairs) = @_;

    croak "$operation: header block must be an array reference"
        unless ref($pairs) eq 'ARRAY';

    for my $pair (@$pairs) {
        croak "$operation: each field must be a [name, value] pair"
            unless ref($pair) eq 'ARRAY' && @$pair == 2;
        croak "$operation: field name and value must be defined scalars"
            if !defined($pair->[0]) || ref($pair->[0])
            || !defined($pair->[1]) || ref($pair->[1]);
    }

    return $pairs;
}

sub _check_normal_field {
    my ($operation, $name, $value) = @_;

    croak "$operation: HTTP/2 field names must be lowercase"
        unless $name eq lc $name;
    croak "$operation: field name must be an HTTP token"
        unless $name =~ $TOKEN_RE;
    croak "$operation: field value contains a prohibited control byte"
        if $value =~ /[\x00-\x08\x0a-\x1f\x7f]/;

    croak "$operation: HTTP/2 forbids connection-specific field '$name'"
        if $FORBIDDEN{$name};

    croak "$operation: HTTP/2 TE is limited to trailers"
        if $name eq 'te' && lc($value) ne 'trailers';

    return;
}

sub _normal_field {
    my ($operation, $name, $value) = @_;
    _check_normal_field($operation, $name, $value);
    return [ $name, $value ];
}

sub _split_header_block {
    my ($operation, $pairs, $allowed) = @_;
    _pairs($operation, $pairs);

    my %pseudo;
    my @normal;
    my $saw_normal = 0;

    for my $pair (@$pairs) {
        my ($name, $value) = @$pair;

        if (substr($name, 0, 1) eq ':') {
            croak "$operation: pseudo-header follows a regular field"
                if $saw_normal;
            croak "$operation: unsupported pseudo-header '$name'"
                unless $allowed->{$name};
            croak "$operation: duplicate pseudo-header '$name'"
                if exists $pseudo{$name};
            $pseudo{$name} = $value;
            next;
        }

        $saw_normal = 1;
        _check_normal_field($operation, $name, $value);
        push @normal, $pair;
    }

    return (\%pseudo, \@normal);
}

sub request_from_headers {
    my ($class, $pairs, %option) = @_;

    my $end_stream = delete($option{end_stream}) ? 1 : 0;
    croak 'request_from_headers(): unknown options: '
        . join(', ', sort keys %option)
        if %option;

    my ($pseudo, $normal) = _split_header_block(
        'request_from_headers()',
        $pairs,
        {
            ':method'    => 1,
            ':scheme'    => 1,
            ':authority' => 1,
            ':path'      => 1,
            ':protocol'  => 1,
        },
    );

    my $method = $pseudo->{':method'};
    croak 'request_from_headers(): missing :method'
        unless defined($method) && length($method);

    my ($target, $scheme, $authority, $protocol);

    if (uc($method) eq 'CONNECT') {
        croak 'request_from_headers(): CONNECT requires :authority'
            unless defined($pseudo->{':authority'})
                && length($pseudo->{':authority'});

        $authority = $pseudo->{':authority'};

        if (exists $pseudo->{':protocol'}) {
            $protocol = $pseudo->{':protocol'};
            croak 'request_from_headers(): extended CONNECT requires nonempty :protocol'
                unless defined($protocol) && length($protocol);
            croak 'request_from_headers(): extended CONNECT requires :scheme'
                unless defined($pseudo->{':scheme'})
                    && length($pseudo->{':scheme'});
            croak 'request_from_headers(): extended CONNECT requires :path'
                unless defined($pseudo->{':path'})
                    && length($pseudo->{':path'});

            $scheme = $pseudo->{':scheme'};
            $target = $pseudo->{':path'};
        }
        else {
            croak 'request_from_headers(): ordinary CONNECT must omit :scheme and :path'
                if exists($pseudo->{':scheme'}) || exists($pseudo->{':path'});
            $target = $authority;
        }
    }
    else {
        croak 'request_from_headers(): :protocol requires CONNECT'
            if exists $pseudo->{':protocol'};
        croak 'request_from_headers(): missing :scheme'
            unless defined($pseudo->{':scheme'})
                && length($pseudo->{':scheme'});
        croak 'request_from_headers(): missing :path'
            unless defined($pseudo->{':path'})
                && length($pseudo->{':path'});
        croak 'request_from_headers(): missing :authority'
            unless defined($pseudo->{':authority'})
                && length($pseudo->{':authority'});

        $scheme = $pseudo->{':scheme'};
        $authority = $pseudo->{':authority'};
        $target = $pseudo->{':path'};
    }

    _validate_request_value('request_from_headers()', 'method', $method);
    _validate_request_value('request_from_headers()', 'target', $target);
    _validate_request_value('request_from_headers()', 'authority', $authority);
    _validate_request_value('request_from_headers()', 'scheme', $scheme)
        if defined $scheme;
    _validate_request_value('request_from_headers()', 'protocol', $protocol)
        if defined $protocol;

    my $view = [
        Uniform::HTTP::FastPath::ABI_VERSION(),
        Uniform::HTTP::FastPath::KIND_REQUEST(),
        _received_flags(
            Uniform::HTTP::FastPath::KIND_REQUEST(),
            $end_stream,
        ),
        '2',
        $method,
        $target,
        $scheme,
        $authority,
        $protocol,
        undef,
        undef,
        $normal,
        [],
        undef,
    ];

    return Uniform::HTTP::FastPath::request_from_validated($view);
}

sub response_from_headers {
    my ($class, $pairs, %option) = @_;

    my $end_stream = delete($option{end_stream}) ? 1 : 0;
    croak 'response_from_headers(): unknown options: '
        . join(', ', sort keys %option)
        if %option;

    my ($pseudo, $normal) = _split_header_block(
        'response_from_headers()',
        $pairs,
        { ':status' => 1 },
    );

    my $status = $pseudo->{':status'};
    croak 'response_from_headers(): missing :status'
        unless defined($status) && length($status);

    croak 'response_from_headers(): status must be an integer from 100 through 599'
        unless $status =~ /\A[0-9]+\z/
            && $status >= 100
            && $status <= 599;

    my $view = [
        Uniform::HTTP::FastPath::ABI_VERSION(),
        Uniform::HTTP::FastPath::KIND_RESPONSE(),
        _received_flags(
            Uniform::HTTP::FastPath::KIND_RESPONSE(),
            $end_stream,
        ),
        '2',
        undef,
        undef,
        undef,
        undef,
        undef,
        0 + $status,
        undef,
        $normal,
        [],
        undef,
    ];

    return Uniform::HTTP::FastPath::response_from_validated($view);
}

sub apply_trailers {
    my ($class, $message, $pairs) = @_;

    croak 'apply_trailers(): requires a canonical Uniform HTTP message'
        unless blessed($message)
            && $message->can('add_trailer')
            && $message->can('freeze_trailers');

    my ($pseudo, $normal) = _split_header_block(
        'apply_trailers()',
        $pairs,
        {},
    );

    for my $field (@$normal) {
        $message->add_trailer(@$field);
    }

    $message->freeze_trailers;
    return $message;
}

sub _request_contract {
    my ($request) = @_;
    return unless blessed($request);

    for my $method (qw(
        method target scheme authority protocol version
        header_count header_name header_value
        trailer_count trailer_name trailer_value
        has_buffered_body body
    )) {
        return unless $request->can($method);
    }

    return 1;
}

sub _response_contract {
    my ($response) = @_;
    return unless blessed($response);

    for my $method (qw(
        status version
        header_count header_name header_value
        trailer_count trailer_name trailer_value
        has_buffered_body body
    )) {
        return unless $response->can($method);
    }

    return 1;
}

sub _check_version {
    my ($operation, $message) = @_;
    my $version = $message->version;
    croak "$operation: explicit HTTP version must be 2"
        if defined($version) && $version ne '2';
    return;
}

sub normal_fields {
    my ($class, $operation, $message) = @_;

    my @fields;
    for my $index (0 .. $message->header_count - 1) {
        my $name = lc $message->header_name($index);
        my $value = $message->header_value($index);
        push @fields, _normal_field($operation, $name, $value);
    }

    return \@fields;
}

sub trailer_fields {
    my ($class, $operation, $message) = @_;

    my $count = $message->trailer_count;
    croak "$operation: trailer section is unavailable"
        unless defined $count;

    my @fields;
    for my $index (0 .. $count - 1) {
        my $name = lc $message->trailer_name($index);
        my $value = $message->trailer_value($index);
        push @fields, _normal_field($operation, $name, $value);
    }

    return \@fields;
}

sub request_headers {
    my ($class, $request) = @_;

    croak 'request_headers(): requires the Uniform HTTP request contract'
        unless _request_contract($request);
    _check_version('request_headers()', $request);

    my $method = $request->method;
    my $protocol = $request->protocol;
    my @block = ([ ':method', $method ]);

    if (uc($method) eq 'CONNECT') {
        my $authority = $request->authority;
        croak 'request_headers(): CONNECT requires authority'
            unless defined($authority) && length($authority);

        if (defined $protocol) {
            croak 'request_headers(): extended CONNECT requires nonempty protocol'
                unless length($protocol);

            my $scheme = $request->scheme;
            croak 'request_headers(): extended CONNECT requires scheme'
                unless defined($scheme) && length($scheme);
            croak 'request_headers(): extended CONNECT requires a path target'
                unless defined($request->target) && length($request->target);

            push @block,
                [ ':protocol', $protocol ],
                [ ':scheme', $scheme ],
                [ ':authority', $authority ],
                [ ':path', $request->target ];
        }
        else {
            croak 'request_headers(): ordinary CONNECT target must equal authority'
                unless $request->target eq $authority;
            croak 'request_headers(): ordinary CONNECT must not have scheme'
                if defined $request->scheme;
            push @block, [ ':authority', $authority ];
        }
    }
    else {
        croak 'request_headers(): protocol metadata requires CONNECT'
            if defined $protocol;

        my $scheme = $request->scheme;
        my $authority = $request->authority;
        my $target = $request->target;

        croak 'request_headers(): HTTP/2 Request requires nonempty path target'
            unless defined($target) && length($target);
        croak 'request_headers(): HTTP/2 Request requires scheme'
            unless defined($scheme) && length($scheme);
        croak 'request_headers(): HTTP/2 Request requires authority'
            unless defined($authority) && length($authority);

        push @block,
            [ ':scheme', $scheme ],
            [ ':authority', $authority ],
            [ ':path', $target ];
    }

    push @block, @{ $class->normal_fields('request_headers()', $request) };
    return \@block;
}

sub response_headers {
    my ($class, $response) = @_;

    croak 'response_headers(): requires the Uniform HTTP response contract'
        unless _response_contract($response);
    _check_version('response_headers()', $response);

    my @block = ([ ':status', '' . $response->status ]);
    push @block, @{ $class->normal_fields('response_headers()', $response) };
    return \@block;
}

1;
