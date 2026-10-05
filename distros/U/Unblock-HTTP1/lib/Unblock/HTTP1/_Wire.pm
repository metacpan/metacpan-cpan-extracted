package Unblock::HTTP1::_Wire;

use strict;
use warnings;
use Carp qw(croak);
use Config ();
use utf8 ();
use Uniform::HTTP::FastPath ();

my $MAX_CONTENT_LENGTH = $Config::Config{uvsize} >= 8
    ? '18446744073709551615'
    : '4294967295';

sub _request_from_validated_head {
    my ($head, %metadata) = @_;

    my $flags =
        Uniform::HTTP::FastPath::FLAG_HEADERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TRAILERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TARGET_EXACT();

    if ($head->{body_mode} eq 'none') {
        $flags |= Uniform::HTTP::FastPath::FLAG_COMPLETE();
    } else {
        $flags |=
            Uniform::HTTP::FastPath::FLAG_MUTABLE()
            | Uniform::HTTP::FastPath::FLAG_BODY_MUTABLE()
            | Uniform::HTTP::FastPath::FLAG_TRAILERS_MUTABLE();
    }

    return Uniform::HTTP::FastPath::request_from_validated([
        Uniform::HTTP::FastPath::ABI_VERSION(),
        Uniform::HTTP::FastPath::KIND_REQUEST(),
        $flags,
        $head->{version},
        $head->{method},
        $head->{target},
        $metadata{scheme},
        $metadata{authority},
        $metadata{protocol},
        undef,
        undef,
        $head->{headers},
        [],
        undef,
    ]);
}

sub _response_from_validated_head {
    my ($head, $informational) = @_;

    my $flags =
        Uniform::HTTP::FastPath::FLAG_HEADERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TRAILERS_LOSSLESS();

    if ($informational) {
        $flags |= Uniform::HTTP::FastPath::FLAG_COMPLETE();
    } else {
        $flags |=
            Uniform::HTTP::FastPath::FLAG_MUTABLE()
            | Uniform::HTTP::FastPath::FLAG_BODY_MUTABLE()
            | Uniform::HTTP::FastPath::FLAG_TRAILERS_MUTABLE();
    }

    return Uniform::HTTP::FastPath::response_from_validated([
        Uniform::HTTP::FastPath::ABI_VERSION(),
        Uniform::HTTP::FastPath::KIND_RESPONSE(),
        $flags,
        $head->{version},
        undef,
        undef,
        undef,
        undef,
        undef,
        $head->{status},
        $head->{reason},
        $head->{headers},
        [],
        undef,
    ]);
}

sub _fast_request_view {
    my ($request) = @_;
    return unless ref($request) eq 'Uniform::HTTP::Request';
    return Uniform::HTTP::FastPath::view($request);
}

sub _fast_response_view {
    my ($response) = @_;
    return unless ref($response) eq 'Uniform::HTTP::Response';
    return Uniform::HTTP::FastPath::view($response);
}

my %REASON = (
    100 => 'Continue', 101 => 'Switching Protocols', 103 => 'Early Hints',
    200 => 'OK', 201 => 'Created', 202 => 'Accepted', 204 => 'No Content',
    205 => 'Reset Content', 206 => 'Partial Content',
    300 => 'Multiple Choices', 301 => 'Moved Permanently', 302 => 'Found',
    303 => 'See Other', 304 => 'Not Modified', 307 => 'Temporary Redirect',
    308 => 'Permanent Redirect', 400 => 'Bad Request', 401 => 'Unauthorized',
    403 => 'Forbidden', 404 => 'Not Found', 405 => 'Method Not Allowed',
    408 => 'Request Timeout', 409 => 'Conflict', 410 => 'Gone',
    411 => 'Length Required', 413 => 'Content Too Large', 414 => 'URI Too Long',
    415 => 'Unsupported Media Type', 417 => 'Expectation Failed',
    421 => 'Misdirected Request', 422 => 'Unprocessable Content',
    426 => 'Upgrade Required', 428 => 'Precondition Required',
    429 => 'Too Many Requests', 431 => 'Request Header Fields Too Large',
    451 => 'Unavailable For Legal Reasons', 500 => 'Internal Server Error',
    501 => 'Not Implemented', 502 => 'Bad Gateway', 503 => 'Service Unavailable',
    504 => 'Gateway Timeout', 505 => 'HTTP Version Not Supported',
);

sub _bytes {
    my ($label, $value) = @_;
    croak "$label must be a defined scalar byte string"
        if !defined($value) || ref($value);
    my $copy = "$value";
    croak "$label must be a byte string" unless utf8::downgrade($copy, 1);
    return $copy;
}

sub _method {
    my ($value) = @_;
    $value = _bytes('request method', $value);
    croak 'request method must be an HTTP token'
        unless $value =~ /\A[!#\$%&'*+\-.^_\x60|~0-9A-Za-z]+\z/;
    return $value;
}

sub _field_name {
    my ($section, $value) = @_;
    $value = _bytes("$section name", $value);
    croak "invalid $section field name"
        unless $value =~ /\A[!#\$%&'*+\-.^_\x60|~0-9A-Za-z]+\z/;
    return $value;
}

sub _field_value {
    my ($section, $value) = @_;
    $value = _bytes("$section value", $value);
    croak "invalid $section field value"
        if $value =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    return $value;
}

sub _status_code {
    my ($value) = @_;
    croak 'response status must be a three-digit integer from 100 through 599'
        if !defined($value) || ref($value)
        || "$value" !~ /\A[0-9]{3}\z/
        || $value < 100 || $value > 599;
    return 0 + $value;
}

sub _reason_phrase {
    my ($value) = @_;
    $value = _bytes('response reason', $value);
    croak 'invalid HTTP/1 response reason phrase'
        if $value =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    return $value;
}

sub _lc {
    my ($value) = @_;
    $value =~ tr/A-Z/a-z/;
    return $value;
}

sub _fields {
    my ($message, $section, $view) = @_;

    if ($view) {
        my $slot = $section eq 'trailer'
            ? Uniform::HTTP::FastPath::SLOT_TRAILERS()
            : Uniform::HTTP::FastPath::SLOT_HEADERS();
        return $view->[$slot];
    }

    my $count_method = $section eq 'trailer' ? 'trailer_count' : 'header_count';
    my $name_method  = $section eq 'trailer' ? 'trailer_name' : 'header_name';
    my $value_method = $section eq 'trailer' ? 'trailer_value' : 'header_value';
    my $count = $message->$count_method();
    croak "$section fields are unavailable" unless defined $count;
    my @fields;
    for my $i (0 .. $count - 1) {
        push @fields, [
            _field_name($section, $message->$name_method($i)),
            _field_value($section, $message->$value_method($i)),
        ];
    }
    return \@fields;
}

sub _values {
    my ($fields, $wanted) = @_;
    my $key = _lc($wanted);
    return [ map { $_->[1] } grep { _lc($_->[0]) eq $key } @$fields ];
}

sub _connection_tokens {
    my ($fields) = @_;
    my %seen;
    for my $value (@{ _values($fields, 'Connection') }) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            next unless length $member;
            croak 'invalid Connection option'
                unless $member =~ /\A[!#\$%&'*+\-.^_\x60|~0-9A-Za-z]+\z/;
            $seen{ _lc($member) } = 1;
        }
    }
    return \%seen;
}

sub _content_length {
    my ($fields) = @_;
    my @numbers;
    for my $value (@{ _values($fields, 'Content-Length') }) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            croak 'invalid Content-Length' unless $member =~ /\A[0-9]+\z/;

            # Compare decimal values, not their textual spelling. RFC 9112
            # permits repeated or comma-combined values when every member has
            # the same numeric value.
            $member =~ s/\A0+(?=[0-9])//;

            croak 'Content-Length exceeds supported framing range'
                if length($member) > length($MAX_CONTENT_LENGTH)
                || (length($member) == length($MAX_CONTENT_LENGTH)
                    && $member gt $MAX_CONTENT_LENGTH);

            push @numbers, $member;
        }
    }
    return undef unless @numbers;
    my $first = $numbers[0];
    for my $number (@numbers) {
        croak 'conflicting Content-Length fields' if $number ne $first;
    }
    return 0 + $first;
}

sub _transfer_encoding {
    my ($fields) = @_;
    my @codings;
    for my $value (@{ _values($fields, 'Transfer-Encoding') }) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            croak 'invalid Transfer-Encoding' unless length $member;
            my ($token, $tail) = $member =~ /\A([^; \t]+)(.*)\z/;
            croak 'invalid Transfer-Encoding' unless defined $token;
            push @codings, [ _lc($token), $tail ];
        }
    }
    return [] unless @codings;
    croak 'unsupported HTTP/1 transfer coding'
        if @codings != 1 || $codings[0][0] ne 'chunked' || length($codings[0][1]);
    return ['chunked'];
}


sub _transfer_coding_token_end {
    my ($value, $pos) = @_;
    my $len = length $value;
    my $start = $pos;
    while ($pos < $len) {
        my $ch = substr($value, $pos, 1);
        last unless $ch =~ /[!#\$%&'*+\-.^_\x60|~0-9A-Za-z]/;
        ++$pos;
    }
    return $pos > $start ? $pos : undef;
}

sub _parse_transfer_coding_member {
    my ($member) = @_;
    $member = _trim($member);
    croak 'invalid Transfer-Encoding' unless length $member;

    my $len = length $member;
    my $pos = 0;
    my $end = _transfer_coding_token_end($member, $pos);
    croak 'invalid Transfer-Encoding' unless defined $end;
    my $coding = _lc(substr($member, $pos, $end - $pos));
    $pos = $end;
    my $parameters = 0;

    while (1) {
        ++$pos while $pos < $len && substr($member, $pos, 1) =~ /[ \t]/;
        last if $pos == $len;

        croak 'invalid Transfer-Encoding'
            unless substr($member, $pos, 1) eq ';';
        ++$pos;
        ++$pos while $pos < $len && substr($member, $pos, 1) =~ /[ \t]/;

        $end = _transfer_coding_token_end($member, $pos);
        croak 'invalid Transfer-Encoding parameter' unless defined $end;
        $pos = $end;
        ++$pos while $pos < $len && substr($member, $pos, 1) =~ /[ \t]/;

        croak 'invalid Transfer-Encoding parameter'
            unless $pos < $len && substr($member, $pos, 1) eq '=';
        ++$pos;
        ++$pos while $pos < $len && substr($member, $pos, 1) =~ /[ \t]/;
        croak 'invalid Transfer-Encoding parameter' if $pos == $len;

        if (substr($member, $pos, 1) eq '"') {
            ++$pos;
            my $closed = 0;
            while ($pos < $len) {
                my $ch = substr($member, $pos, 1);
                if ($ch eq '"') {
                    ++$pos;
                    $closed = 1;
                    last;
                }
                if ($ch eq '\\') {
                    ++$pos;
                    croak 'invalid Transfer-Encoding quoted parameter'
                        if $pos == $len;
                    ++$pos;
                    next;
                }
                my $ord = ord($ch);
                croak 'invalid Transfer-Encoding quoted parameter'
                    if ($ord < 0x20 && $ch ne "\t") || $ord == 0x7f;
                ++$pos;
            }
            croak 'unterminated Transfer-Encoding quoted parameter'
                unless $closed;
        } else {
            $end = _transfer_coding_token_end($member, $pos);
            croak 'invalid Transfer-Encoding parameter value'
                unless defined $end;
            $pos = $end;
        }
        ++$parameters;
    }

    croak 'chunked transfer coding does not accept parameters'
        if $coding eq 'chunked' && $parameters;
    return $coding;
}

sub _split_quoted_delimiter {
    my ($value, $delimiter, $label) = @_;
    my @member;
    my $start = 0;
    my $quoted = 0;
    my $escaped = 0;
    my $len = length $value;

    for my $pos (0 .. $len - 1) {
        my $ch = substr($value, $pos, 1);
        if ($escaped) {
            $escaped = 0;
            next;
        }
        if ($quoted && $ch eq '\\') {
            $escaped = 1;
            next;
        }
        if ($ch eq '"') {
            $quoted = !$quoted;
            next;
        }
        next unless $ch eq $delimiter && !$quoted;
        push @member, substr($value, $start, $pos - $start);
        $start = $pos + 1;
    }

    croak "unterminated $label quoted parameter"
        if $quoted || $escaped;
    push @member, substr($value, $start);
    return @member;
}

sub _response_transfer_encoding {
    my ($fields) = @_;
    my @coding;

    for my $value (@{ _values($fields, 'Transfer-Encoding') }) {
        my @member = _split_quoted_delimiter(
            $value, ',', 'Transfer-Encoding',
        );
        push @coding, map { scalar _parse_transfer_coding_member($_) } @member;
    }

    my $chunked = grep { $_ eq 'chunked' } @coding;
    croak 'chunked transfer coding must not be applied more than once'
        if $chunked > 1;

    return \@coding;
}


sub _qvalue_thousandths {
    my ($value) = @_;
    $value = _trim($value);

    if ($value =~ /\A0(?:\.([0-9]{0,3}))?\z/) {
        my $fraction = defined($1) ? $1 : '';
        return 0 if $fraction eq '';
        return 0 + ($fraction . ('0' x (3 - length($fraction))));
    }
    if ($value =~ /\A1(?:\.(0{0,3}))?\z/) {
        return 1000;
    }
    croak 'invalid TE qvalue';
}

sub _request_te_preferences {
    my ($fields) = @_;
    my $values = _values($fields, 'TE');
    my %quality;
    my $trailers = 0;

    for my $value (@$values) {
        next if _trim($value) eq '';

        for my $member (_split_quoted_delimiter($value, ',', 'TE')) {
            $member = _trim($member);
            croak 'invalid TE field value' unless length $member;

            if (_lc($member) eq 'trailers') {
                $trailers = 1;
                next;
            }

            my $coding = scalar _parse_transfer_coding_member($member);
            croak 'TE must not list the chunked transfer coding'
                if $coding eq 'chunked';
            croak 'trailers TE keyword must not have parameters'
                if $coding eq 'trailers';

            my @part = _split_quoted_delimiter($member, ';', 'TE');
            shift @part;
            my $rank = 1000;
            my $seen_q = 0;

            for my $index (0 .. $#part) {
                my $parameter = _trim($part[$index]);
                my ($name, $value) = $parameter =~
                    /\A([!#\$%&'*+\-.^_\x60|~0-9A-Za-z]+)[ \t]*=[ \t]*(.+)\z/s;
                croak 'invalid TE parameter' unless defined $name;

                next unless _lc($name) eq 'q';
                croak 'TE qvalue must be the final parameter'
                    if $index != $#part;
                croak 'TE must not contain more than one qvalue'
                    if $seen_q++;
                croak 'TE qvalue must not be quoted'
                    if substr($value, 0, 1) eq '"';
                $rank = _qvalue_thousandths($value);
            }

            $quality{$coding} = $rank
                if !exists($quality{$coding}) || $rank > $quality{$coding};
        }
    }

    return {
        present  => @$values ? 1 : 0,
        trailers => $trailers,
        quality  => \%quality,
    };
}

sub _trim {
    my ($value) = @_;
    $value =~ s/\A[ \t]+//;
    $value =~ s/[ \t]+\z//;
    return $value;
}

sub _validate_host_value {
    my ($value) = @_;
    $value = _bytes('Host field', $value);
    return 1 if $value eq '';

    croak 'invalid Host field'
        if $value =~ /[\x00-\x20\x7f\/?#@]/;

    if (substr($value, 0, 1) eq '[') {
        croak 'invalid Host field'
            unless $value =~ /\A\[[^\]]+\](?::[0-9]*)?\z/;
        return 1;
    }

    croak 'invalid Host field'
        unless $value =~ /\A[^:]+(?::[0-9]*)?\z/;
    return 1;
}

sub _authority_form {
    my ($target) = @_;
    $target = _bytes('CONNECT target', $target);

    my ($host, $port);
    if ($target =~ /\A(\[[^\]\s]+\]):([0-9]+)\z/) {
        ($host, $port) = ($1, $2);
    } elsif ($target =~ /\A([^:\s\/?#@]+):([0-9]+)\z/) {
        ($host, $port) = ($1, $2);
    } else {
        croak 'CONNECT target must be an authority-form host:port';
    }

    croak 'CONNECT target port must be between 1 and 65535'
        if $port < 1 || $port > 65_535;
    return wantarray ? ($host, 0 + $port) : "$host:$port";
}

sub _connect_host {
    my ($value) = @_;
    $value = _trim(_bytes('CONNECT Host', $value));

    my ($host, $port);
    if ($value =~ /\A(\[[^\]\s]+\])(?::([0-9]*))?\z/) {
        ($host, $port) = ($1, $2);
    } elsif ($value =~ /\A([^:\s\/?#@]+)(?::([0-9]*))?\z/) {
        ($host, $port) = ($1, $2);
    } else {
        croak 'CONNECT Host must contain a valid host with an optional port';
    }

    $port = undef if defined($port) && $port eq '';
    croak 'CONNECT Host port must be between 1 and 65535'
        if defined($port) && ($port < 1 || $port > 65_535);
    return ($host, defined($port) ? 0 + $port : undef);
}

sub _validate_request_target {
    my ($method, $target) = @_;
    $method = _method($method);
    $target = _bytes('request target', $target);

    croak 'HTTP/1 request target must not contain whitespace or control bytes'
        if $target =~ /[\x00-\x20\x7f]/;
    croak 'HTTP/1 request target must not contain a fragment'
        if index($target, '#') >= 0;

    if ($target eq '*') {
        croak 'HTTP/1 asterisk request target is only valid for OPTIONS'
            unless $method eq 'OPTIONS';
        return $target;
    }

    if ($method eq 'CONNECT') {
        _authority_form($target);
        return $target;
    }

    return $target if substr($target, 0, 1) eq '/';

    # absolute-form begins with a URI scheme. URI interpretation and proxy
    # routing remain above this protocol engine; only the wire form is checked.
    return $target
        if $target =~ /\A[A-Za-z][A-Za-z0-9+.-]*:[^#]*\z/;

    croak 'HTTP/1 request target must use origin-form, absolute-form, '
        . 'CONNECT authority-form, or OPTIONS asterisk-form';
}

sub _absolute_form_host {
    my ($method, $target) = @_;
    return (0, undef) if $method eq 'CONNECT';
    return (0, undef)
        unless $target =~ /\A([A-Za-z][A-Za-z0-9+.-]*):(.*)\z/s;

    my $scheme = _lc($1);
    my $rest = $2;

    if (($scheme eq 'http' || $scheme eq 'https')
        && substr($rest, 0, 2) ne '//') {
        croak 'http(s) absolute-form request target requires an authority';
    }

    # Other absolute URI schemes can legitimately omit authority. In that
    # case HTTP/1.1 still carries an empty Host field.
    return (1, '') unless substr($rest, 0, 2) eq '//';

    my $authority = substr($rest, 2);
    $authority =~ s{[/?].*\z}{}s;

    if ($scheme eq 'http' || $scheme eq 'https') {
        croak 'http(s) absolute-form request target requires a non-empty authority'
            if $authority eq '';
        croak 'http(s) absolute-form request target requires a non-empty host'
            if substr($authority, 0, 1) eq ':';
        croak 'http(s) absolute-form request target must not contain userinfo'
            if index($authority, '@') >= 0;
    }

    # Generic URI schemes can carry userinfo. Host excludes it.
    $authority =~ s/\A.*@//s;
    return (1, $authority);
}

sub _received_request_metadata {
    my ($method, $target) = @_;
    $method = _method($method);
    $target = _bytes('request target', $target);

    if ($method eq 'CONNECT') {
        return (authority => $target);
    }

    return () if substr($target, 0, 1) eq '/' || $target eq '*';

    return () unless $target =~ /\A([A-Za-z][A-Za-z0-9+.-]*):(.*)\z/s;
    my ($scheme, $rest) = ($1, $2);
    my @metadata = (scheme => $scheme);

    if (substr($rest, 0, 2) eq '//') {
        my $authority = substr($rest, 2);
        $authority =~ s{[/?].*\z}{}s;
        push @metadata, authority => $authority if length $authority;
    }

    return @metadata;
}

sub _upgrade_tokens {
    my ($where, $fields) = @_;
    my @token;
    for my $value (@{ _values($fields, 'Upgrade') }) {
        for my $member (split /,/, $value, -1) {
            $member = _trim($member);
            croak "invalid $where Upgrade field value"
                if $member eq ''
                || $member !~ /\A[!#\$%&'*+\-.^_\x60|~0-9A-Za-z]+(?:\/[!#\$%&'*+\-.^_\x60|~0-9A-Za-z]+)?\z/;
            push @token, _lc($member);
        }
    }
    return \@token;
}

sub _validate_connect_request {
    my ($request, $fields, $version, $body, $stream_body, $trailers, $view) = @_;
    my $method = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_METHOD()]
        : $request->method;
    return unless $method eq 'CONNECT';

    croak 'CONNECT requires HTTP/1.1 semantics'
        unless _semantics_version($version) eq '1.1';
    croak 'CONNECT cannot use a streaming request body' if $stream_body;
    croak 'CONNECT request must not contain a buffered body' if defined $body;
    croak 'CONNECT request must not contain trailers' if $trailers && @$trailers;
    my $connect_cl = _content_length($fields);
    croak 'CONNECT request Content-Length must be zero when present'
        if defined($connect_cl) && $connect_cl != 0;
    croak 'CONNECT request must not contain Transfer-Encoding'
        if @{ _values($fields, 'Transfer-Encoding') };

    my $target = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_TARGET()]
        : $request->target;
    my ($target_host, $target_port) = _authority_form($target);
    my $host = _values($fields, 'Host');
    croak 'CONNECT requires exactly one Host field' unless @$host == 1;

    my ($host_name, $host_port) = _connect_host($host->[0]);
    croak 'CONNECT Host must identify the authority-form request target'
        if _lc($host_name) ne _lc($target_host)
        || (defined($host_port) && $host_port != $target_port);
    return;
}

sub _validate_upgrade_request {
    my ($request, $fields, $version, $view) = @_;
    croak 'HTTP/1 Upgrade requires HTTP/1.1 semantics'
        unless _semantics_version($version) eq '1.1';

    my $connection = _connection_tokens($fields);
    croak 'HTTP/1 Upgrade request requires Connection: Upgrade'
        unless $connection->{upgrade};
    croak 'HTTP/1 Upgrade request cannot combine Connection: close with Upgrade'
        if $connection->{close};

    my $offered = _upgrade_tokens('request', $fields);
    croak 'HTTP/1 Upgrade request requires an Upgrade field' unless @$offered;

    my $cl = _content_length($fields);
    croak 'HTTP/1 Upgrade request body must be empty'
        if defined($cl) && $cl != 0;
    croak 'HTTP/1 Upgrade request cannot use Transfer-Encoding'
        if @{ _values($fields, 'Transfer-Encoding') };

    my ($has_body, $body);
    if ($view) {
        $has_body =
            $view->[Uniform::HTTP::FastPath::SLOT_FLAGS()]
            & Uniform::HTTP::FastPath::FLAG_HAS_BUFFERED_BODY() ? 1 : 0;
        $body = $view->[Uniform::HTTP::FastPath::SLOT_BODY()] if $has_body;
    } else {
        $has_body = $request->has_buffered_body;
        $body = $request->body if $has_body;
    }
    croak 'HTTP/1 Upgrade request body must be empty'
        if $has_body && defined($body) && length($body);
    return $offered;
}

sub _validate_upgrade_response {
    my ($request, $request_fields, $response_fields, $response_version, $request_view) = @_;
    croak 'HTTP/1 Upgrade response must use HTTP/1.1 semantics'
        unless _semantics_version($response_version) eq '1.1';

    my $request_version = $request_view
        ? $request_view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $request->version;
    my $offered = _validate_upgrade_request(
        $request, $request_fields, $request_version || '1.1', $request_view,
    );

    croak 'HTTP/1 Upgrade response cannot contain Content-Length'
        if @{ _values($response_fields, 'Content-Length') };
    croak 'HTTP/1 Upgrade response cannot contain Transfer-Encoding'
        if @{ _values($response_fields, 'Transfer-Encoding') };

    my $connection = _connection_tokens($response_fields);
    croak 'HTTP/1 Upgrade response requires Connection: Upgrade'
        unless $connection->{upgrade};
    croak 'HTTP/1 Upgrade response cannot combine Connection: close with Upgrade'
        if $connection->{close};

    my $selected = _upgrade_tokens('response', $response_fields);
    croak 'HTTP/1 Upgrade response must select a protocol' unless @$selected;
    my %offered = map { $_ => 1 } @$offered;
    for my $protocol (@$selected) {
        croak "HTTP/1 Upgrade response selected protocol not offered by request: $protocol"
            unless $offered{$protocol};
    }
    return;
}

sub _replace_or_add {
    my ($fields, $name, $value) = @_;
    my $key = _lc($name);
    my @out;
    my $inserted = 0;
    for my $field (@$fields) {
        if (_lc($field->[0]) eq $key) {
            if (!$inserted) {
                push @out, [ $name, "$value" ];
                $inserted = 1;
            }
            next;
        }
        push @out, [ @$field ];
    }
    push @out, [ $name, "$value" ] unless $inserted;
    return \@out;
}

sub _append_transfer_coding {
    my ($fields, $coding) = @_;
    my @out = map { [ @$_ ] } @$fields;

    for (my $i = $#out; $i >= 0; --$i) {
        next unless _lc($out[$i][0]) eq 'transfer-encoding';
        $out[$i][1] .= ', ' . $coding;
        return \@out;
    }

    push @out, [ 'Transfer-Encoding', $coding ];
    return \@out;
}

sub _ensure_trailer_header {
    my ($fields, $trailers) = @_;
    return $fields unless $trailers && @$trailers;

    my @out = map { [ @$_ ] } @$fields;
    my %announced;
    my $last_trailer_field;

    for my $index (0 .. $#out) {
        next unless _lc($out[$index][0]) eq 'trailer';
        $last_trailer_field = $index;

        for my $name (split /,/, $out[$index][1], -1) {
            $name = _trim($name);
            next unless length $name;
            $name = _field_name('Trailer', $name);
            $announced{ _lc($name) } = 1;
        }
    }

    my @missing;
    for my $field (@$trailers) {
        my $name = _field_name('trailer', $field->[0]);
        my $key = _lc($name);
        next if $announced{$key}++;
        push @missing, $name;
    }

    return \@out unless @missing;

    if (defined $last_trailer_field) {
        my $value = _trim($out[$last_trailer_field][1]);
        $out[$last_trailer_field][1] =
            length($value)
                ? $value . ', ' . join(', ', @missing)
                : join(', ', @missing);
    } else {
        push @out, [ 'Trailer', join(', ', @missing) ];
    }

    return \@out;
}

sub _append_connection_token {
    my ($fields, $token) = @_;
    my @out = map { [ @$_ ] } @$fields;

    for (my $i = $#out; $i >= 0; --$i) {
        next unless _lc($out[$i][0]) eq 'connection';
        if (length _trim($out[$i][1])) {
            $out[$i][1] .= ', ' . $token;
        } else {
            $out[$i][1] = $token;
        }
        return \@out;
    }

    push @out, [ 'Connection', $token ];
    return \@out;
}

sub _serialize_fields {
    my ($fields) = @_;
    my $wire = '';
    for my $field (@$fields) {
        $wire .= $field->[0] . ': ' . $field->[1] . "\r\n";
    }
    return $wire;
}

sub _semantics_version {
    my ($version) = @_;
    return '1.0' if $version eq '1.0';
    return '1.1' if $version =~ /\A1\.[1-9]\z/;
    croak 'unsupported HTTP/1 version';
}

sub _version {
    my ($message, $default) = @_;
    my $version = $message->version;
    $version = $default unless defined $version;
    croak 'HTTP/1 version must be 1.0 or 1.1'
        unless $version eq '1.0' || $version eq '1.1';
    return $version;
}

sub _simple_request_plan {
    my ($request, $stream_body, $view) = @_;
    return if $stream_body;

    my $version = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $request->version;
    $version = '1.1' unless defined $version;
    return unless $version eq '1.1';

    my $method = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_METHOD()]
        : _method($request->method);
    return if $method eq 'CONNECT';

    if ($view) {
        return if defined $view->[Uniform::HTTP::FastPath::SLOT_PROTOCOL()];
    } elsif ($request->can('protocol')) {
        return if defined $request->protocol;
    }

    my $body;
    if ($view) {
        if ($view->[Uniform::HTTP::FastPath::SLOT_FLAGS()]
            & Uniform::HTTP::FastPath::FLAG_HAS_BUFFERED_BODY()) {
            $body = $view->[Uniform::HTTP::FastPath::SLOT_BODY()];
        }
    } else {
        $body = $request->has_buffered_body
            ? _bytes('request body', $request->body)
            : undef;
    }

    my $trailer_count = $view
        ? scalar @{ $view->[Uniform::HTTP::FastPath::SLOT_TRAILERS()] }
        : $request->trailer_count;
    return unless defined($trailer_count) && $trailer_count == 0;

    my $target = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_TARGET()]
        : _bytes('request target', $request->target);
    _validate_request_target($method, $target);
    my ($absolute_form) = _absolute_form_host($method, $target);
    return if $absolute_form;

    my $wire = $method . ' ' . $target . " HTTP/1.1\r\n";
    my $host_count = 0;

    if ($view) {
        for my $field (@{ $view->[Uniform::HTTP::FastPath::SLOT_HEADERS()] }) {
            my ($name, $value) = @$field;
            my $key = _lc($name);

            if ($key eq 'host') {
                ++$host_count;
                _validate_host_value($value);
            }

            return if $key eq 'content-length'
                || $key eq 'transfer-encoding'
                || $key eq 'connection'
                || $key eq 'upgrade'
                || $key eq 'expect'
                || $key eq 'te';

            $wire .= $name . ': ' . $value . "\r\n";
        }
    } else {
        my $count = $request->header_count;
        return unless defined $count;
        for my $index (0 .. $count - 1) {
            my $name = _field_name('header', $request->header_name($index));
            my $value = _field_value('header', $request->header_value($index));
            my $key = _lc($name);

            if ($key eq 'host') {
                ++$host_count;
                _validate_host_value($value);
            }

            return if $key eq 'content-length'
                || $key eq 'transfer-encoding'
                || $key eq 'connection'
                || $key eq 'upgrade'
                || $key eq 'expect'
                || $key eq 'te';

            $wire .= $name . ': ' . $value . "\r\n";
        }
    }

    return if $host_count > 1;

    if (!$host_count) {
        my $authority;
        if ($view) {
            $authority = $view->[Uniform::HTTP::FastPath::SLOT_AUTHORITY()];
        } else {
            return unless $request->can('authority');
            $authority = $request->authority;
        }
        return unless defined $authority;
        $authority = _bytes('request authority', $authority) unless $view;
        _validate_host_value($authority);
        $wire .= 'Host: ' . $authority . "\r\n";
    }

    my $mode = 'none';
    my $remaining;
    if (defined $body) {
        my $length = length($body);
        $wire .= 'Content-Length: ' . $length . "\r\n";
        $mode = 'content-length';
        $remaining = 0;
    }

    $wire .= "\r\n";
    $wire .= $body if defined $body;

    return {
        wire           => $wire,
        version        => '1.1',
        mode           => $mode,
        remaining      => $remaining,
        stream_body    => 0,
        trailers       => [],
        keep_alive     => 1,
        body_finalized => 1,
    };
}

sub _simple_response_plan_portable {
    my ($request, $response, $stream_body) = @_;
    return if $stream_body;

    my $request_version = $request->version;
    $request_version = '1.1' unless defined $request_version;
    return unless $request_version eq '1.1';

    my $method = _method($request->method);
    return if $method eq 'HEAD' || $method eq 'CONNECT';

    my $request_connection = $request->header_values('Connection');
    return unless defined($request_connection) && !@$request_connection;

    my $response_version = $response->version;
    return if defined($response_version) && $response_version ne '1.1';

    my $status = _status_code($response->status);
    return if $status < 200 || $status > 599
        || $status == 204 || $status == 205 || $status == 304;

    my $trailer_count = $response->trailer_count;
    return unless defined($trailer_count) && $trailer_count == 0;

    my $body;
    if ($response->has_buffered_body) {
        $body = _bytes('response body', $response->body);
    } else {
        $body = '';
    }

    my $reason_value = $response->reason;
    my $reason = defined($reason_value)
        ? _reason_phrase($reason_value)
        : ($REASON{$status} || '');

    my $count = $response->header_count;
    return unless defined $count;

    my $wire = 'HTTP/1.1 ' . sprintf('%03d', $status)
        . ' ' . $reason . "\r\n";

    for my $index (0 .. $count - 1) {
        my $name = _field_name('header', $response->header_name($index));
        my $value = _field_value('header', $response->header_value($index));
        my $key = _lc($name);

        return if $key eq 'content-length'
            || $key eq 'transfer-encoding'
            || $key eq 'connection';

        $wire .= $name . ': ' . $value . "\r\n";
    }

    my $length = length($body);
    $wire .= 'Content-Length: ' . $length . "\r\n\r\n" . $body;

    return {
        wire           => $wire,
        version        => '1.1',
        mode           => 'content-length',
        remaining      => 0,
        stream_body    => 0,
        trailers       => [],
        keep_alive     => 1,
        close_after    => 0,
        switch         => 0,
        body_finalized => 1,
    };
}

sub _simple_response_plan {
    my ($request, $response, $stream_body, $request_view, $response_view) = @_;
    return _simple_response_plan_portable($request, $response, $stream_body)
        unless $request_view || $response_view;
    return if $stream_body;

    my $request_version = $request_view
        ? $request_view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $request->version;
    $request_version = '1.1' unless defined $request_version;
    return unless $request_version eq '1.1';

    my $method = $request_view
        ? $request_view->[Uniform::HTTP::FastPath::SLOT_METHOD()]
        : _method($request->method);
    return if $method eq 'HEAD' || $method eq 'CONNECT';

    my $request_connection = $request_view
        ? _values($request_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()], 'Connection')
        : $request->header_values('Connection');
    return unless defined($request_connection) && !@$request_connection;

    my $response_version = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $response->version;
    return if defined($response_version) && $response_version ne '1.1';

    my $status = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_STATUS()]
        : _status_code($response->status);
    return if $status < 200 || $status > 599
        || $status == 204 || $status == 205 || $status == 304;

    my $trailer_count = $response_view
        ? scalar @{ $response_view->[Uniform::HTTP::FastPath::SLOT_TRAILERS()] }
        : $response->trailer_count;
    return unless defined($trailer_count) && $trailer_count == 0;

    my $body;
    if ($response_view) {
        if ($response_view->[Uniform::HTTP::FastPath::SLOT_FLAGS()]
            & Uniform::HTTP::FastPath::FLAG_HAS_BUFFERED_BODY()) {
            $body = $response_view->[Uniform::HTTP::FastPath::SLOT_BODY()];
        } else {
            $body = '';
        }
    } elsif ($response->has_buffered_body) {
        $body = _bytes('response body', $response->body);
    } else {
        $body = '';
    }

    my $reason_value = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_REASON()]
        : $response->reason;
    my $reason = defined($reason_value)
        ? ($response_view ? $reason_value : _reason_phrase($reason_value))
        : ($REASON{$status} || '');

    my $wire = 'HTTP/1.1 ' . sprintf('%03d', $status)
        . ' ' . $reason . "\r\n";

    if ($response_view) {
        for my $field (@{ $response_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()] }) {
            my ($name, $value) = @$field;
            my $key = _lc($name);

            return if $key eq 'content-length'
                || $key eq 'transfer-encoding'
                || $key eq 'connection';

            $wire .= $name . ': ' . $value . "\r\n";
        }
    } else {
        my $count = $response->header_count;
        return unless defined $count;
        for my $index (0 .. $count - 1) {
            my $name = _field_name('header', $response->header_name($index));
            my $value = _field_value('header', $response->header_value($index));
            my $key = _lc($name);

            return if $key eq 'content-length'
                || $key eq 'transfer-encoding'
                || $key eq 'connection';

            $wire .= $name . ': ' . $value . "\r\n";
        }
    }

    my $length = length($body);
    $wire .= 'Content-Length: ' . $length . "\r\n\r\n" . $body;

    return {
        wire           => $wire,
        version        => '1.1',
        mode           => 'content-length',
        remaining      => 0,
        stream_body    => 0,
        trailers       => [],
        keep_alive     => 1,
        close_after    => 0,
        switch         => 0,
        body_finalized => 1,
    };
}

sub request_plan {
    my ($request, %option) = @_;
    my $view = _fast_request_view($request);
    croak 'request does not implement the Uniform HTTP request contract'
        unless $view
            || (ref($request) && $request->can('method') && $request->can('target')
                && $request->can('header_count') && $request->can('has_buffered_body'));

    my $protocol = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_PROTOCOL()]
        : ($request->can('protocol') ? $request->protocol : undef);
    croak 'HTTP/1 cannot directly encode Uniform Extended CONNECT protocol metadata'
        if defined $protocol;

    my $stream_body = $option{stream_body} ? 1 : 0;
    if (my $simple = _simple_request_plan($request, $stream_body, $view)) {
        return $simple;
    }

    my $version = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $request->version;
    $version = '1.1' unless defined $version;
    croak 'HTTP/1 version must be 1.0 or 1.1'
        unless $version eq '1.0' || $version eq '1.1';

    my $method = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_METHOD()]
        : _method($request->method);
    my $target = $view
        ? $view->[Uniform::HTTP::FastPath::SLOT_TARGET()]
        : _bytes('request target', $request->target);
    _validate_request_target($method, $target);

    my $fields = _fields($request, 'header', $view);
    my $body;
    if ($view) {
        if ($view->[Uniform::HTTP::FastPath::SLOT_FLAGS()]
            & Uniform::HTTP::FastPath::FLAG_HAS_BUFFERED_BODY()) {
            $body = $view->[Uniform::HTTP::FastPath::SLOT_BODY()];
        }
    } else {
        $body = $request->has_buffered_body
            ? _bytes('request body', $request->body)
            : undef;
    }
    croak 'stream_body cannot be combined with a buffered request body'
        if $stream_body && defined $body;

    my $host = _values($fields, 'Host');
    croak 'HTTP/1 request must not contain multiple Host fields' if @$host > 1;

    my ($absolute_form, $absolute_host) = _absolute_form_host($method, $target);
    if ($version eq '1.1' && $absolute_form) {
        if (@$host) {
            croak 'HTTP/1.1 absolute-form Host must match request-target authority'
                if $host->[0] ne $absolute_host;
        } else {
            $fields = [ @$fields, [ 'Host', $absolute_host ] ];
            $host = [ $absolute_host ];
        }
    } elsif (!@$host && $version eq '1.1') {
        my $authority = $view
            ? $view->[Uniform::HTTP::FastPath::SLOT_AUTHORITY()]
            : ($request->can('authority') ? $request->authority : undef);
        croak 'HTTP/1.1 request requires Host or Uniform authority metadata'
            unless defined $authority;
        $fields = [ @$fields, [
            'Host',
            $view ? $authority : _bytes('request authority', $authority),
        ] ];
    }

    _validate_host_value($_) for @{ _values($fields, 'Host') };

    my $te_preferences = _request_te_preferences($fields);
    if ($te_preferences->{present}) {
        croak 'HTTP/1.0 request cannot send TE'
            if $version eq '1.0';
        my $connection = _connection_tokens($fields);
        $fields = _append_connection_token($fields, 'TE')
            unless $connection->{te};
    }

    my $cl = _content_length($fields);
    my $te = _transfer_encoding($fields);
    croak 'request cannot contain both Transfer-Encoding and Content-Length'
        if @$te && defined $cl;

    my $trailers = _fields($request, 'trailer', $view);
    my $has_trailers = @$trailers ? 1 : 0;
    $fields = _ensure_trailer_header($fields, $trailers)
        if $has_trailers;

    _validate_connect_request(
        $request, $fields, $version, $body, $stream_body, $trailers, $view,
    );

    my ($mode, $remaining);

    if ($has_trailers) {
        croak 'HTTP/1.0 cannot send trailer fields' if $version eq '1.0';
        croak 'trailers cannot be combined with Content-Length' if defined $cl;
        $fields = _replace_or_add($fields, 'Transfer-Encoding', 'chunked');
        $mode = 'chunked';
    } elsif (@$te) {
        croak 'HTTP/1.0 does not support chunked transfer coding' if $version eq '1.0';
        $mode = 'chunked';
    } elsif (defined $cl) {
        $mode = 'content-length';
        $remaining = $cl;
        croak 'request Content-Length does not match buffered body length'
            if defined($body) && length($body) != $cl;
    } elsif ($stream_body) {
        croak 'streaming HTTP/1.0 request body requires Content-Length'
            if $version eq '1.0';
        $fields = [ @$fields, [ 'Transfer-Encoding', 'chunked' ] ];
        $mode = 'chunked';
    } elsif (defined $body) {
        $fields = [ @$fields, [ 'Content-Length', length($body) ] ];
        $mode = 'content-length';
        $remaining = length($body);
    } else {
        $mode = 'none';
    }

    my $wire = $method . ' ' . $target . ' HTTP/' . $version . "\r\n"
        . _serialize_fields($fields) . "\r\n";

    if (defined $body) {
        $wire .= $mode eq 'chunked'
            ? chunk($body) . final_chunk($trailers)
            : $body;
        $remaining = 0 if defined $remaining;
    } elsif (!$stream_body && $mode eq 'chunked') {
        $wire .= final_chunk($trailers);
    }

    my $tokens = _connection_tokens($fields);
    my $keep_alive = $tokens->{close} ? 0
        : $version eq '1.1' ? 1
        : $tokens->{'keep-alive'} ? 1 : 0;

    return {
        wire           => $wire,
        version        => $version,
        mode           => $mode,
        remaining      => $remaining,
        stream_body    => $stream_body,
        trailers       => $trailers,
        keep_alive     => $keep_alive,
        body_finalized => $stream_body ? 0 : 1,
    };
}

sub response_receive_plan {
    my ($request, $head, $response) = @_;
    my $request_view = _fast_request_view($request);
    my $response_view = $response ? _fast_response_view($response) : undef;
    my $fields = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()]
        : $head->{headers};
    my $status = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_STATUS()]
        : $head->{status};
    my $version = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $head->{version};
    my $method = $request_view
        ? $request_view->[Uniform::HTTP::FastPath::SLOT_METHOD()]
        : $request->method;

    if ($method eq 'CONNECT' && $status >= 200 && $status < 300) {
        croak 'HTTP/1 CONNECT successful response must use HTTP/1.1 semantics'
            unless _semantics_version($version) eq '1.1';
        return {
            mode       => 'none',
            remaining  => undef,
            switch     => 1,
            keep_alive => 0,
        };
    }

    if ($status == 101) {
        _validate_upgrade_response(
            $request,
            _fields($request, 'header', $request_view),
            $fields,
            $version,
            $request_view,
        );
        return {
            mode       => 'none',
            remaining  => undef,
            switch     => 1,
            keep_alive => 0,
        };
    }

    my $response_semantics = _semantics_version($version);
    my $tokens = _connection_tokens($fields);
    my $keep_alive = $tokens->{close} ? 0
        : $response_semantics eq '1.1' ? 1
        : $tokens->{'keep-alive'} ? 1 : 0;

    my $raw_te = _values($fields, 'Transfer-Encoding');
    croak 'HTTP/1.0 response must not contain Transfer-Encoding'
        if $response_semantics eq '1.0' && @$raw_te;

    if ($method eq 'HEAD' || $status == 304) {
        return {
            mode       => 'none',
            remaining  => undef,
            switch     => 0,
            keep_alive => $keep_alive,
        };
    }

    my $cl = _content_length($fields);
    my $te = _response_transfer_encoding($fields);
    croak 'response contains both Transfer-Encoding and Content-Length'
        if @$te && defined $cl;

    my $body_forbidden = ($status >= 100 && $status < 200)
        || $status == 204;

    croak '1xx and 204 responses must not contain Content-Length'
        if (($status >= 100 && $status < 200) || $status == 204) && defined $cl;
    croak '205 response Content-Length must be zero'
        if $status == 205 && defined($cl) && $cl != 0;
    croak 'bodyless response must not contain Transfer-Encoding'
        if $body_forbidden && @$te;

    my $mode = 'none';
    my $remaining;
    if (!$body_forbidden) {
        if (@$te) {
            $mode = $te->[-1] eq 'chunked' ? 'chunked' : 'close';
        } elsif (defined $cl) {
            $mode = 'content-length';
            $remaining = $cl;
        } else {
            $mode = 'close';
        }
    }

    $keep_alive = 0 if $mode eq 'close';

    return {
        mode           => $mode,
        remaining      => $remaining,
        switch         => 0,
        keep_alive     => $keep_alive,
        forbid_content => $status == 205 ? 1 : 0,
    };
}

sub response_plan {
    my ($request, $response, %option) = @_;
    my $request_view = _fast_request_view($request);
    my $response_view = _fast_response_view($response);

    croak 'response does not implement the Uniform HTTP response contract'
        unless $response_view
            || (ref($response) && $response->can('status')
                && $response->can('header_count')
                && $response->can('has_buffered_body'));

    my $stream_body = $option{stream_body} ? 1 : 0;
    if (my $simple = _simple_response_plan(
        $request, $response, $stream_body, $request_view, $response_view,
    )) {
        return $simple;
    }

    my $received_request_version = $request_view
        ? $request_view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $request->version;
    $received_request_version ||= '1.1';
    my $request_version = _semantics_version($received_request_version);

    my $response_version = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_VERSION()]
        : $response->version;
    if (defined $response_version && $response_version ne $request_version) {
        croak 'response version conflicts with supported HTTP/1 response semantics';
    }

    my $status = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_STATUS()]
        : _status_code($response->status);
    my $reason_value = $response_view
        ? $response_view->[Uniform::HTTP::FastPath::SLOT_REASON()]
        : $response->reason;
    my $reason = defined($reason_value)
        ? ($response_view ? $reason_value : _reason_phrase($reason_value))
        : ($REASON{$status} || '');

    my $fields = _fields($response, 'header', $response_view);
    my $trailers = _fields($response, 'trailer', $response_view);
    $fields = _ensure_trailer_header($fields, $trailers)
        if @$trailers;

    my $body;
    if ($response_view) {
        if ($response_view->[Uniform::HTTP::FastPath::SLOT_FLAGS()]
            & Uniform::HTTP::FastPath::FLAG_HAS_BUFFERED_BODY()) {
            $body = $response_view->[Uniform::HTTP::FastPath::SLOT_BODY()];
        }
    } else {
        $body = $response->has_buffered_body
            ? _bytes('response body', $response->body)
            : undef;
    }
    croak 'stream_body cannot be combined with a buffered response body'
        if $stream_body && defined $body;

    my $method = $request_view
        ? $request_view->[Uniform::HTTP::FastPath::SLOT_METHOD()]
        : $request->method;
    my $connect_switch = $method eq 'CONNECT'
        && $status >= 200 && $status < 300 ? 1 : 0;
    my $upgrade_switch = $status == 101 ? 1 : 0;
    my $switch = $connect_switch || $upgrade_switch ? 1 : 0;
    my $body_forbidden = $switch || ($status >= 100 && $status < 200)
        || $status == 204 || $status == 304;
    my $head_only = $method eq 'HEAD' ? 1 : 0;

    if ($connect_switch) {
        _validate_connect_request(
            $request,
            _fields($request, 'header', $request_view),
            $request_version,
            undef,
            0,
            [],
            $request_view,
        );
        croak 'successful CONNECT response must not contain a buffered body'
            if defined $body;
        croak 'successful CONNECT response cannot stream a body' if $stream_body;
        croak 'successful CONNECT response must not contain trailers' if @$trailers;
    }

    croak 'protocol-switch responses cannot carry a body or trailers'
        if $upgrade_switch && (defined($body) || $stream_body || @$trailers);
    croak 'this response status cannot carry a body or trailers'
        if $body_forbidden && !$switch
            && ((defined($body) && length($body)) || $stream_body || @$trailers);

    croak '205 response must not contain content'
        if $status == 205 && defined($body) && length($body);
    croak '205 response cannot use a streaming content producer'
        if $status == 205 && $stream_body;

    my $cl = _content_length($fields);
    croak '205 response Content-Length must be zero'
        if $status == 205 && defined($cl) && $cl != 0;

    my $metadata_only_framing = $head_only || $status == 304 ? 1 : 0;
    my $te = _response_transfer_encoding($fields);
    croak 'response cannot contain both Transfer-Encoding and Content-Length'
        if !$connect_switch && @$te && defined $cl;

    if (grep { $_ ne 'chunked' } @$te) {
        my $request_fields = _fields($request, 'header', $request_view);
        my $request_connection = _connection_tokens($request_fields);
        my $preferences = _request_te_preferences($request_fields);

        for my $coding (grep { $_ ne 'chunked' } @$te) {
            my $quality = $preferences->{quality}{$coding} || 0;
            croak "response transfer coding was not accepted by request TE: $coding"
                unless $preferences->{present}
                    && $request_connection->{te}
                    && $quality > 0;
        }
    }

    if ($connect_switch) {
        croak 'successful CONNECT response must not contain Content-Length'
            if defined $cl;
        croak 'successful CONNECT response must not contain Transfer-Encoding'
            if @$te;
        my $connection = _connection_tokens($fields);
        croak 'successful CONNECT response cannot request Connection: close'
            if $connection->{close};
    }

    if ($upgrade_switch) {
        my $response_connection = _connection_tokens($fields);
        if (!$response_connection->{upgrade}
            && !@{ _values($fields, 'Connection') }) {
            $fields = [ @$fields, [ 'Connection', 'Upgrade' ] ];
        }
        _validate_upgrade_response(
            $request,
            _fields($request, 'header', $request_view),
            $fields,
            $request_version,
            $request_view,
        );
    }

    my ($mode, $remaining, $close_after) = ('none', undef, 0);
    if ($body_forbidden) {
        croak '1xx and 204 responses must not contain Content-Length'
            if (($status >= 100 && $status < 200) || $status == 204) && defined $cl;
        croak '205 response Content-Length must be zero'
            if $status == 205 && defined($cl) && $cl != 0;
        croak 'bodyless response must not contain Transfer-Encoding'
            if $status != 304 && @$te;
        croak 'HTTP/1.0 cannot send Transfer-Encoding metadata'
            if $status == 304 && @$te && $request_version eq '1.0';
    } elsif ($head_only) {
        croak 'HEAD response cannot stream a body' if $stream_body;
        croak 'HEAD response cannot carry trailer fields' if @$trailers;
        croak 'HTTP/1.0 cannot send Transfer-Encoding metadata'
            if @$te && $request_version eq '1.0';
        if (!defined $cl && !@$te && defined $body) {
            $fields = [ @$fields, [ 'Content-Length', length($body) ] ];
        }
    } elsif (@$trailers) {
        croak 'HTTP/1.0 cannot send trailer fields' if $request_version eq '1.0';
        croak 'trailers cannot be combined with Content-Length' if defined $cl;

        if (@$te) {
            my $has_chunked = grep { $_ eq 'chunked' } @$te;
            croak 'cannot add final chunked framing after an earlier chunked transfer coding'
                if $has_chunked && $te->[-1] ne 'chunked';
            if ($te->[-1] ne 'chunked') {
                $fields = _append_transfer_coding($fields, 'chunked');
            }
        } else {
            $fields = [ @$fields, [ 'Transfer-Encoding', 'chunked' ] ];
        }
        $mode = 'chunked';
    } elsif (@$te) {
        croak 'HTTP/1.0 does not support Transfer-Encoding'
            if $request_version eq '1.0';
        if ($te->[-1] eq 'chunked') {
            $mode = 'chunked';
        } else {
            $mode = 'close';
            $close_after = 1;
        }
    } elsif (defined $cl) {
        $mode = 'content-length';
        $remaining = $cl;
        croak 'response Content-Length does not match buffered body length'
            if defined($body) && length($body) != $cl;
    } elsif ($stream_body) {
        if ($request_version eq '1.1') {
            $fields = [ @$fields, [ 'Transfer-Encoding', 'chunked' ] ];
            $mode = 'chunked';
        } else {
            $mode = 'close';
            $close_after = 1;
        }
    } else {
        my $length = defined($body) ? length($body) : 0;
        $fields = [ @$fields, [ 'Content-Length', $length ] ];
        $mode = 'content-length';
        $remaining = $length;
    }

    my $request_tokens =
        _connection_tokens(_fields($request, 'header', $request_view));
    my $response_tokens = _connection_tokens($fields);
    my $request_keep = $request_tokens->{close} ? 0
        : $request_version eq '1.1' ? 1
        : $request_tokens->{'keep-alive'} ? 1 : 0;
    my $keep_alive =
        $request_keep && !$response_tokens->{close} && !$close_after && !$switch;
    if (!$keep_alive && !$switch && $request_version eq '1.1'
        && !$response_tokens->{close}) {
        $fields = [ @$fields, [ 'Connection', 'close' ] ];
    } elsif ($keep_alive && $request_version eq '1.0'
        && !$response_tokens->{'keep-alive'}) {
        $fields = [ @$fields, [ 'Connection', 'keep-alive' ] ];
    }

    my $wire = 'HTTP/' . $request_version . ' ' . sprintf('%03d', $status)
        . ' ' . $reason . "\r\n" . _serialize_fields($fields) . "\r\n";

    if (!$head_only && !$body_forbidden && defined $body) {
        $wire .= $mode eq 'chunked'
            ? chunk($body) . final_chunk($trailers)
            : $body;
        $remaining = 0 if defined $remaining;
    } elsif (!$head_only && !$body_forbidden && !$stream_body
        && $mode eq 'chunked') {
        $wire .= final_chunk($trailers);
    }

    return {
        wire           => $wire,
        version        => $request_version,
        mode           => $mode,
        remaining      => $remaining,
        stream_body    => $stream_body,
        trailers       => $trailers,
        keep_alive     => $keep_alive,
        close_after    => $close_after,
        switch         => $switch,
        body_finalized => $stream_body ? 0 : 1,
    };
}

sub chunk {
    my ($bytes) = @_;
    $bytes = _bytes('body chunk', $bytes);
    return '' unless length $bytes;
    return sprintf('%X', length($bytes)) . "\r\n" . $bytes . "\r\n";
}

sub final_chunk {
    my ($trailers) = @_;
    $trailers ||= [];
    my $wire = "0\r\n";
    for my $field (@$trailers) {
        my $key = _lc($field->[0]);
        croak 'framing fields are forbidden in HTTP/1 trailers'
            if $key eq 'content-length' || $key eq 'transfer-encoding'
                || $key eq 'host' || $key eq 'connection' || $key eq 'trailer';
        $wire .= $field->[0] . ': ' . $field->[1] . "\r\n";
    }
    return $wire . "\r\n";
}

1;
