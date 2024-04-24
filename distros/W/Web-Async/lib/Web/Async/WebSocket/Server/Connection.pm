package Web::Async::WebSocket::Server::Connection;
use Myriad::Class extends => 'IO::Async::Notifier';

our $VERSION = '0.001'; ## VERSION
## AUTHORITY

use Web::Async::WebSocket::Frame;

use List::Util qw(pairmap);
use Compress::Zlib;
use POSIX ();
use Time::Moment;
use Digest::SHA qw(sha1);
use MIME::Base64 qw(encode_base64);

# As defined in the RFC - it's used as part of the hashing for the security header in the response
use constant WEBSOCKET_GUID => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

# Opcodes have a registry here: https://www.iana.org/assignments/websocket/websocket.xhtml#opcode
my %OPCODE_BY_CODE = (
    0 => 'continuation',
    1 => 'text',
    2 => 'binary',
    8 => 'close',
    9 => 'ping',
    10 => 'pong',
);
my %OPCODE_BY_NAME = reverse %OPCODE_BY_CODE;

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
        'permessage-deflate' => 1
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
# A Future which will resolve with an error if the handshake failed
field $handshake_failure : reader = undef;

# The IO::Async::Stream representing the network connection
# to the client
field $stream;

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
}

method deflate ($data) {
    $deflation //= deflateInit(
        -WindowBits => -MAX_WBITS
    ) or die "Cannot create a deflation stream\n" ;

    my ($output, $status) = $deflation->deflate($data);
    die "deflation failed\n" unless $status == Z_OK;
    (my $block, $status) = $deflation->flush(Z_SYNC_FLUSH);
    die "deflation failed at flush stage\n" unless $status == Z_OK;

    return $output . $block;
}

method inflate ($data) {
    $inflation //= inflateInit(
        -WindowBits => -MAX_WBITS
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

        my @extensions = grep { $supported_extension->{$_} } map { /([^=]+)/ } split /\s*;\s*/, $hdr->{sec_websocket_extensions};
        $output{'Sec-Websocket-Extensions'} = join ';', sort @extensions;

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

    # Body processing
    try {
        $log->tracef('Start reading frames');
        while(1) {
            await $incoming_frame->unblocked;
            my $frame = await $self->read_frame();
            $log->tracef('Had frame: %s', $frame);
            $incoming_frame->emit($frame);
#            await $self->write_frame(
#                type    => 'text',
#                payload => $payload
#            );
        }
    } catch ($e) {
        $log->errorf('Problem, %s', $e);
        $stream->close;
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
        $compressed //= $rsv[0];
        $type //= $opcode & 0x0F;
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
    $data = decode_utf8($data) if $type == $OPCODE_BY_NAME{text};
    $log->tracef('Finished, data is now %s', $data);
    return Web::Async::WebSocket::Frame->new(
        payload => $data,
        opcode => $type
    );
}

async method write_frame (%args) {
    my $compressed = $args{compress} // 1;
    $log->tracef('Write frame with %s', \%args);
    # FIN
    my $opcode = $OPCODE_BY_NAME{$args{type}};
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
            100.0 * (length($payload) / $original),
        );
    }
    my $len = length $payload;
    my $msg = pack('C1', $opcode);
    if($len < 126) {
        $msg .= pack('C1', $len);
    } elsif($len < 0xFFFF) {
        $msg .= pack('C1n1', 126, $len);
    } else {
        $msg .= pack('C1Q>1', 127, $len);
    }
    $msg .= $payload;
    await $stream->write($msg);
    return;
}

1;
