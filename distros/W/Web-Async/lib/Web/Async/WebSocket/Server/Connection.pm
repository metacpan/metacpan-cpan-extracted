package Web::Async::WebSocket::Server::Connection;
use Myriad::Class extends => 'IO::Async::Notifier';

our $VERSION = '0.002'; ## VERSION
## AUTHORITY

use Web::Async::WebSocket::Frame;

use List::Util qw(pairmap);
use Compress::Zlib;
use POSIX ();
use Time::Moment;
use Digest::SHA qw(sha1);
use MIME::Base64 qw(encode_base64);
use Unicode::UTF8 qw(valid_utf8);

# As defined in the RFC - it's used as part of the hashing for the security header in the response
use constant WEBSOCKET_GUID => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

# Opcodes have a registry here: https://www.iana.org/assignments/websocket/websocket.xhtml#opcode
our %OPCODE_BY_CODE = (
    0  => 'continuation',
    1  => 'text',
    2  => 'binary',
    8  => 'close',
    9  => 'ping',
    10 => 'pong',
);
our %OPCODE_BY_NAME = reverse %OPCODE_BY_CODE;

our %COMPRESSIBLE_OPCODE = (
    $OPCODE_BY_NAME{text}   => 1,
    $OPCODE_BY_NAME{binary} => 1,
);

field $server : reader : param = undef;

# Given the state of websockets in general, this is unlikely to change from `HTTP/1.1` anytime soon
field $http_version : reader : param = 'HTTP/1.1';
# 101 Upgrade is defined by the RFC, but if you have special requirements you can override via the constructor
field $status : reader : param = '101';
# The message is probably ignored by everything
field $msg : reader : param = 'Switching Protocols';
# There aren't a vast number of extensions, at the time of writing https://www.iana.org/assignments/websocket/websocket.xhtml#extension-name
# lists just two of 'em
field $supported_extension : reader : param {
    +{
        'permessage-deflate' => 1,
        'server_no_context_takeover' => 1,
        'client_no_context_takeover' => 1,
        'server_max_window_bits' => 1,
        'client_max_window_bits' => 1,
    }
}

# What to report in the `Server:` header
field $server_name : reader : param = 'perl';

# Restriction on number of raw (pre-decompression!) bytes,
# advised to set this to a nonzero value to avoid clients
# burning up all your memory...
field $maximum_payload_size : reader : param = undef;

# Our current deflation (compression) state
field $deflation;
# Our current inflation (decompression) state
field $inflation;

field $ryu : param : reader;

field $on_handshake_failure : param : reader = undef;

# A Ryu::Source representing the messages received from the client
field $incoming_frame : reader : param { $self->ryu->source }
# A Ryu::Source representing the messages to be sent to the client
field $outgoing_frame : reader : param { $self->ryu->source }

field $compression_options : reader { +{ } }

# The IO::Async::Stream representing the network connection
# to the client
field $stream;

field $closed : reader : param = undef;

method configure (%args) {
    $http_version = delete $args{http_version} if exists $args{http_version};
    $status = delete $args{status} if exists $args{status};
    $msg = delete $args{msg} if exists $args{msg};
    $ryu = delete $args{ryu} if exists $args{ryu};
    $stream = delete $args{stream} if exists $args{stream};
    $server_name = delete $args{server_name} if exists $args{server_name};
    $maximum_payload_size = delete $args{maximum_payload_size} if exists $args{maximum_payload_size};
    $on_handshake_failure = delete $args{on_handshake_failure} if exists $args{on_handshake_failure};
    return $self->next::method(%args);
}

method _add_to_loop ($loop) {
    $on_handshake_failure //= async method ($stream, $error, @) {
        await $stream->write("$http_version 400 $error\x0D\x0A\x0D\x0A");
    };
    $closed //= $self->loop->new_future;
    $stream->configure(
        on_closed => $self->$curry::weak(async method (@) {
            $closed->done unless $closed->is_ready;
            $server->on_client_disconnect($self);
        }),
    );
}

=head2 send_text_frame

Send a text frame.

Expects a Unicode Perl text string as the first parameter - this will be
encoded to UTF-8 and sent to the client.

=cut

async method send_text_frame ($text, %args) {
    return await $self->write_frame(
        payload => $text,
        type => 'text',
        %args
    );
}

=head2 send_binary_frame

Send a binary data frame.

Expects the raw binary data bytes as the first parameter.

=cut

async method send_data_frame ($data, %args) {
    return await $self->write_frame(
        payload => $data,
        type    => 'binary',
        %args
    );
}

=head2 write_frame

Sends one or more frames to the client.

=cut

async method write_frame (%args) {
    die 'already closed' if $closed->is_ready;
    for my $frame ($self->prepare_frames(%args)) {
        await $stream->write($frame);
    }
    return;
}

async method prepare_frames (%args) {
    my @frames;
    $log->tracef('Write frame with %s', \%args);
    my $opcode = $OPCODE_BY_NAME{$args{type}} // die 'invalid frame type';
    my $compressed = ($args{compress} // 1) && $compression_options->{compress} && $COMPRESSIBLE_OPCODE{$opcode};
    my $payload = $args{payload};
    $payload = encode_utf8($payload) if $opcode == $OPCODE_BY_NAME{text};

    $opcode |= 0x80;
    if($compressed) {
        $opcode |= 0x40;
        my $original = length $payload;
        $payload = $self->deflate($payload);
        # Strip terminator if we have one
        $payload =~ s{\x00\x00\xFF\xFF$}{};
        $log->tracef(
            'Size after deflation is %d/%d, ratio of %4.1f%%',
            length($payload),
            $original,
            100.0 * (length($payload) / ($original || 1)),
        );
    }
    my $len = length $payload;
    my $msg = pack('C1', $opcode);
    if($len < 126) {
        $msg .= pack('C1', $len);
    } elsif($len <= 0xFFFF) {
        $msg .= pack('C1n1', 126, $len);
    } else {
        $msg .= pack('C1Q>1', 127, $len);
    }
    $msg .= $payload;
    push @frames, $msg;
    return @frames;
}

method deflate ($data) {
    undef $deflation unless $compression_options->{server_context};
    $deflation //= deflateInit(
        -WindowBits => -($compression_options->{server_bits} || 15)
    ) or die "Cannot create a deflation stream\n" ;

    my ($output, $status) = $deflation->deflate($data);
    die "deflation failed\n" unless $status == Z_OK;
    (my $block, $status) = $deflation->flush(Z_SYNC_FLUSH);
    die "deflation failed at flush stage\n" unless $status == Z_OK;

    return $output . $block;
}

method inflate ($data) {
    undef $inflation unless $compression_options->{cilent_context};
    $inflation //= inflateInit(
        -WindowBits => -($compression_options->{client_bits} || 15)
    ) or die "Cannot create a deflation stream\n" ;

    my ($block, $status) = $inflation->inflate($data);
    die "deflation failed\n" unless $status == Z_STREAM_END or $status == Z_OK;
    return $block;
}

async method read_headers () {
    my %hdr;
    while(1) {
        my $line = decode_utf8('' . await $stream->read_until("\x0D\x0A"));
        $line =~ s/\x0D\x0A$//;
        last unless length $line;

        my ($k, $v) = $line =~ /^([^:]+):\s+(.*)$/;
        $k = lc($k =~ tr{-}{_}r);
        $hdr{$k} = $v;
    }
    return \%hdr;
}

method generate_response_key ($key) {
    die "No websocket key provided\n" unless defined $key and length $key;
    return encode_base64(sha1($key . WEBSOCKET_GUID), '');
}

async method handle_connection () {
    try {
        $self->add_child($stream);
        my $first = await $stream->read_until("\x0D\x0A");
        my ($method, $url, $version) = $first =~ m{^(\S+)\s+(\S+)\s+(HTTP/\d+\.\d+)\x0D\x0A$}a;
        $log->tracef('HTTP request is [%s] for [%s] version %s', $method, $url, $version);
        my $hdr = await $self->read_headers();

        $log->tracef('url = %s, headers = %s', $url, format_json_text($hdr));

        unless($hdr->{sec_websocket_version} >= 13) {
            die sprintf "Invalid websocket version %s\n", $hdr->{sec_websocket_version};
        }

        my %output = (
            'Upgrade'    => 'websocket',
            'Connection' => 'upgrade',
            'Server'     => $server_name,
            'Date'       => Time::Moment->now_utc->strftime("%a, %d %b %Y %H:%M:%S GMT"),
        );
        $output{'Sec-WebSocket-Accept'} = $self->generate_response_key($hdr->{sec_websocket_key});

        if(exists $hdr->{sec_websocket_extensions}) {
            my $extensions;
            VALID: {
                SELECTION:
                for my $selection (split /\s*,\s*/, $hdr->{sec_websocket_extensions} // '') {
                    my @options = map {; /^(\S+)(?:\s*=\s*(.*)\s*)?$/ ? ($1, $2) : () } split /\s*;\s*/, $selection;
                    my @order = pairmap { $a } @options;
                    my %options = @options;
                    my @invalid = grep { !$supported_extension->{$_} } sort keys %options;
                    if(@invalid) {
                        $log->infof('Rejecting invalid option combination %s', \@invalid);
                        next SELECTION;
                    }

                    $log->infof('Acceptable options: %s', \%options);
                    $options{client_max_window_bits} //= 15 if exists $options{client_max_window_bits};
                    $compression_options->{client_bits} = $options{client_max_window_bits};
                    $compression_options->{server_bits} = $options{server_max_window_bits} || 15;
                    $extensions = join '; ', map { defined($options{$_}) ? "$_=$options{$_}" : $_ } @order;
                    $compression_options->{server_context} = (exists $options{server_no_context_takeover}) ? 0 : 1;
                    $compression_options->{client_context} = (exists $options{client_no_context_takeover}) ? 0 : 1;
                    $compression_options->{compress} = 1 if exists $options{'permessage-deflate'};
                    last VALID;
                }
                $log->infof('No acceptable extension options, giving up: %s', $hdr->{sec_websocket_extensions});
                await $stream->write(
                    join(
                        "\x0D\x0A",
                        "$http_version 400 No acceptable extensions",
                        (pairmap {
                            encode_utf8("$a: $b")
                        } %output),
                        # Blank line at the end of the headers
                        '', ''
                    )
                );
                die 'no acceptable extensions';
            }
            $output{'Sec-Websocket-Extensions'} = $extensions;
        }

        # Send the entire header block in a single write
        await $stream->write(
            join(
                "\x0D\x0A",
                "$http_version $status $msg",
                (pairmap {
                    encode_utf8("$a: $b")
                } %output),
                # Blank line at the end of the headers
                '', ''
            )
        );
    } catch ($e) {
        $log->errorf('Failed - %s', $e);
        await $self->$on_handshake_failure($stream, $e);
        return;
    }

    # Once the handshake is complete, we don't need the handler any more,
    # and keeping it around could lead to unwanted refcount cycles
    undef $on_handshake_failure;

    # Body processing
    try {
        $log->tracef('Start reading frames');
        while(1) {
            await $incoming_frame->unblocked;
            my $frame = await $self->read_frame();
            $log->tracef('Had frame: %s', $frame);
            $incoming_frame->emit($frame);
        }
    } catch ($e) {
        $log->errorf('Problem, %s', $e) unless $e =~ /^EOF/;
        await $self->close(
            code   => 1011, # internal error
            reason => 'Internal error'
        );
    }
}

async method read_frame () {
    $log->tracef('Reading frames from %s', "$stream");
    my $fin;
    my $data = '';
    my $compressed;
    my $type;
    do {
        my ($chunk, $eof);
        ($chunk, $eof) = await $stream->read_exactly(2);
        die "EOF\n" if $eof;
        my ($opcode, $len) = unpack 'C1C1', $chunk;
        my $masked = $len & 0x80;
        die "unmasked frame\n" unless $masked;
        $len &= ~0x80;
        $fin = ($opcode & 0x80) ? 1 : 0;
        my @rsv = map { ($opcode & $_) ? 1 : 0 } 0x40, 0x20, 0x10;
        $compressed //= $compression_options->{compress} && $rsv[0];
        return await $self->close(
            code => 1002,
            reason => 'Reserved bit 0 set with compression disabled',
        ) if $rsv[0] and not $compression_options->{compress};
        return await $self->close(
            code => 1002,
            reason => 'Unexpected reserved bit set',
        ) if any { $_ } @rsv;
        $type //= $opcode & 0x0F;
        return await $self->close(
            code   => 1002,
            reason => 'Unknown opcode',
        ) unless $OPCODE_BY_CODE{$type};
        if($len == 126) {
            ($chunk, $eof) = await $stream->read_exactly(2);
            die "EOF\n" if $eof;
            ($len) = unpack 'n1', $chunk;
            die 'invalid length' if $len < 126;
        } elsif($len == 127) {
            ($chunk, $eof) = await $stream->read_exactly(8);
            die "EOF\n" if $eof;
            ($len) = unpack 'Q>1', $chunk;
            die 'invalid length' if $len < 0xFFFF or $len & 0x80000000;
        }
        my $mask = '';
        if($masked) {
            ($mask, $eof) = await $stream->read_exactly(4);
            die "EOF\n" if $eof;
        }
        $log->tracef(
            'Frame opcode %d, length %d, fin = %s, rsv = %s %s %s, mask key %v0x',
            $opcode,
            $len,
            $fin,
            @rsv,
            $mask
        );
        die "excessive length\n" if defined($maximum_payload_size) and $len + length($data) > $maximum_payload_size;
        (my $payload, $eof) = await $stream->read_exactly($len);
        die "EOF\n" if $eof;
        if($masked) {
            $log->tracef('Masked payload = %v0x', $payload);
            my ($frac, $int) = POSIX::modf(length($payload) / 4);
            $payload ^.= ($mask x $int) . substr($mask, 0, 4 * $frac);
        }
        $log->tracef('Payload = %v0x', $payload);
        $data .= $payload;
    } until $fin;
    $data = $self->inflate($data . "\x00\x00\xFF\xFF") if $compressed;
    $log->tracef('Frame opcode is %s', $OPCODE_BY_CODE{$type});
    if($type == $OPCODE_BY_NAME{text}) {
        return await $self->close(
            code   => 1002,
            reason => 'Invalid UTF-8 data in text frame',
        ) unless valid_utf8($data);
        $data = decode_utf8($data);
    }
    $log->tracef('Finished, data is now %s', $data);
    my $frame = Web::Async::WebSocket::Frame->new(
        payload => $data,
        opcode => $type
    );
    if($OPCODE_BY_CODE{$type} equ 'close') {
        my ($code, $reason) = unpack 'na*', $frame->payload;
        return await $self->close(
            code   => 1002,
            reason => 'Invalid UTF-8 reason in close frame',
        ) unless valid_utf8($reason);
        await $self->close(
            code   => ($code || 0),
            reason => decode_utf8($reason // ''),
        );
    }
    return $frame;
}

async method close (%args) {
    # Can only close once
    return if $closed->is_ready;

    # No point trying to write anything if the remote has closed the connection
    if($stream->is_read_eof) {
        $closed->done(%args);
        $stream->close;
        return;
    }

    my $f = $self->write_frame(
        type    => 'close',
        payload => pack(
            'na*' => ($args{code} // 0), encode_utf8($args{reason} // '')
        ),
    );
    if($server) {
        $server->on_client_close($self, %args);
    }
    $closed->done(%args);
    await $f;
    $stream->close;
}

1;
