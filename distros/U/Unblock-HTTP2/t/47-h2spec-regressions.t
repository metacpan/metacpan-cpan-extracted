use strict;
use warnings;
use Test::More;
use Unblock::HTTP2::Server;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::_nghttp2;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use lib 't/lib';
use Test::UnblockHTTP2 qw(pump_until_idle);

sub frame {
    my ($type, $flags, $id, $payload) = @_;
    $payload = '' unless defined $payload;
    my $n = length $payload;
    return pack('C3CCN', $n >> 16, ($n >> 8) & 255, $n & 255,
                $type, $flags, $id) . $payload;
}

# HPACK static :method GET, :scheme http, :path /; literal :authority.
my $headers = "\x82\x86\x84\x01\x0cexample.test";
sub request { return frame(1, $_[1] ? 5 : 4, $_[0], $headers) }

sub feed {
    my ($ctx, $bytes) = @_;
    my $chunk = $ctx->{chunk} || length($bytes);
    while (length $bytes) {
        my $part = substr($bytes, 0, $chunk, '');
        my $consumed;
        if ($ctx->{driver}) {
            (undef, $consumed) = $ctx->{driver}->feed($part);
        } else {
            $consumed = $ctx->{server}->input($part);
        }
        die 'incomplete input consumption' unless $consumed == length $part;
    }
}

sub drain {
    my ($ctx) = @_;
    my $bytes = '';
    while ($ctx->{server}->want_write) {
        my $part;
        if ($ctx->{driver}) {
            (undef, $part) = $ctx->{driver}->drain;
        } else {
            $part = $ctx->{server}->output;
        }
        last unless length $part;
        $bytes .= $part;
    }
    my @frames;
    while (length $bytes) {
        die 'truncated frame header' if length($bytes) < 9;
        my ($a, $b, $c, $type, $flags, $id) = unpack('C3CCN', substr($bytes, 0, 9, ''));
        my $length = ($a << 16) | ($b << 8) | $c;
        die 'truncated frame payload' if length($bytes) < $length;
        push @frames, { type => $type, flags => $flags, id => $id,
                       payload => substr($bytes, 0, $length, '') };
    }
    return @frames;
}

sub context {
    my ($native, $chunk, %options) = @_;
    my $ctx = { chunk => $chunk, requests => [] };
    my $requests = $ctx->{requests};
    $ctx->{server} = Unblock::HTTP2::Server->new(
        on_request => sub {
            my ($tx) = @_;
            push @$requests, $tx->stream_id;
            $options{headers}->($tx) if $options{headers};
        },
        on_request_end => sub {
            $_[0]->respond(Uniform::HTTP::Response->new(status => 200, body => 'ok'))
                unless $options{defer};
        },
    );
    $ctx->{driver} = Unblock::HTTP2::_nghttp2::NativeDriver->new($ctx->{server}) if $native;
    feed($ctx, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
        . frame(4, 0, 0, $options{modern} ? pack('nN', 9, 1) : ''));
    drain($ctx);
    feed($ctx, frame(4, 1, 0));
    return $ctx;
}

sub goaway_code {
    my ($ctx) = @_;
    my @goaway = grep { $_->{type} == 7 } drain($ctx);
    return unless @goaway;
    return unpack('N', substr($goaway[-1]{payload}, 4, 4));
}

for my $native (0, 1) {
    for my $chunk (0, 1, 7, 13) {
        subtest "input native=$native fragment=$chunk" => sub {
            for my $type (0, 1) {
                for my $peer_reset (0, 1) {
                    my $ctx = context($native, $chunk);
                    feed($ctx, request(1, !$peer_reset));
                    if ($peer_reset) {
                        # Coalesced RST_STREAM + late frame must see the close.
                        feed($ctx, frame(3, 0, 1, pack('N', 8))
                            . frame($type, $type ? 5 : 1, 1, $type ? $headers : 'late'));
                    } else {
                        drain($ctx); # Serialize response END_STREAM, retiring the stream.
                        feed($ctx, frame($type, $type ? 5 : 1, 1, $type ? $headers : 'late'));
                    }
                    is goaway_code($ctx), 5, "closed type=$type peer_reset=$peer_reset sends STREAM_CLOSED";
                    ok !$ctx->{server}->want_read, 'GOAWAY ends read interest after output drains';
                }
            }
            {
                my $ctx = context($native, $chunk);
                feed($ctx, request(5, 1) . request(3, 1));
                is goaway_code($ctx), 1, 'decreasing skipped ID sends PROTOCOL_ERROR';
                is_deeply $ctx->{requests}, [5], 'invalid request never reaches application';
            }
            for my $id (0, 1) {
                my $ctx = context($native, $chunk);
                feed($ctx, frame(2, 0, $id, pack('NC', $id, 15)));
                is goaway_code($ctx), 1, "legacy invalid PRIORITY id=$id sends PROTOCOL_ERROR";
            }
            {
                my $ctx = context($native, $chunk);
                feed($ctx, request(1, 0)
                    . frame(8, 0, 1, pack('N', 0x7fffffff))
                    . frame(8, 0, 1, pack('N', 0x7fffffff)));
                my @out = drain($ctx);
                my @rst = grep { $_->{type} == 3 && $_->{id} == 1 } @out;
                ok @rst, 'stream window overflow sends RST_STREAM';
                is @rst ? unpack('N', $rst[0]{payload}) : undef, 3, 'reset carries FLOW_CONTROL_ERROR';
                ok !grep($_->{type} == 7, @out), 'stream window overflow does not kill connection';
                feed($ctx, request(3, 1));
                is_deeply $ctx->{requests}, [1, 3], 'unrelated request still succeeds after overflow';
                ok !defined goaway_code($ctx), 'connection remains usable';
            }
            {
                my $ctx = context($native, $chunk, modern => 1);
                feed($ctx, frame(2, 0, 1, pack('NC', 1, 15)) . frame(6, 0, 0, '12345678'));
                my @out = drain($ctx);
                ok !grep($_->{type} == 7, @out), 'negotiated modern priorities ignore legacy dependency';
                ok grep($_->{type} == 6 && $_->{flags} == 1, @out), 'PING still works after ignored priority';
            }
            {
                my $ctx = context($native, $chunk, headers => sub { $_[0]->cancel });
                feed($ctx, request(1, 0));
                my @out = drain($ctx); # The local reset is now serialized.
                ok grep($_->{type} == 3, @out), 'local reset reached the wire';
                # Insert x-race: yes in HPACK's dynamic table on the ignored stream.
                my $trailer = "\x40\x06x-race\x03yes";
                feed($ctx, frame(0, 0, 1, 'already in flight')
                    . frame(1, 5, 1, $trailer) . frame(1, 4, 3, $headers . "\xbe"));
                is_deeply $ctx->{requests}, [1, 3], 'late DATA and trailers after local reset preserve connection';
                ok !defined goaway_code($ctx), 'local reset race does not send GOAWAY';
            }
            {
                my $ctx = context($native, $chunk, headers => sub { $_[0]->cancel });
                feed($ctx, request(1, 0) . request(3, 0) . request(5, 0));
                drain($ctx);
                feed($ctx, frame(3, 0, 3, pack('N', 8)));
                feed($ctx, frame(0, 0, 1, 'late') . frame(0, 0, 5, 'late'));
                ok !defined goaway_code($ctx), 'splitting reset history preserves neighbor races';
                feed($ctx, frame(0, 0, 3, 'after peer reset'));
                is goaway_code($ctx), 5, 'peer reset ends the local-reset race exception';
            }
            {
                my $ctx = context($native, $chunk, defer => 1);
                feed($ctx, request(1, 1) . request(3, 1));
                is_deeply $ctx->{requests}, [1, 3], 'concurrent streams remain independent';
                ok !defined goaway_code($ctx), 'active lower stream is not classified as skipped';
            }
            {
                my $ctx = context($native, $chunk);
                feed($ctx, request(1, 0) . request(5, 0)
                    . frame(1, 5, 1, "\x00\x05x-end\x03yes"));
                ok !defined goaway_code($ctx), 'valid trailers on older active stream survive a skipped ID';
                feed($ctx, frame(0, 1, 5, 'body'));
                ok !defined goaway_code($ctx), 'newer concurrent stream completes normally';
                feed($ctx, request(3, 1));
                is goaway_code($ctx), 1, 'the skipped gap remains invalid after neighbors complete';
            }
            {
                my $ctx = context($native, $chunk);
                feed($ctx, request(1, 1));
                drain($ctx);
                # Oversized DATA must preserve nghttp2's FRAME_SIZE_ERROR,
                # rather than being replaced by our retired-stream error.
                feed($ctx, frame(0, 0, 1, 'x' x 16385));
                is goaway_code($ctx), 6, 'frame size validation takes precedence';
            }
            {
                my $ctx = context($native, $chunk);
                feed($ctx, request(1, 1));
                drain($ctx);
                feed($ctx, frame(1, 0, 3, $headers) . frame(0, 0, 1, 'late'));
                is goaway_code($ctx), 1, 'interleaved header block keeps PROTOCOL_ERROR precedence';
            }
            {
                my $client = Unblock::HTTP2::Client->new;
                my $server = Unblock::HTTP2::Server->new(on_request_end => sub {
                    $_[0]->respond(Uniform::HTTP::Response->new(status => 200, body => 'ok'));
                });
                pump_until_idle($client, $server);
                my $tx = $client->request(Uniform::HTTP::Request->new(
                    method => 'GET', scheme => 'http', target => '/', authority => 'example.test'));
                pump_until_idle($client, $server);
                ok $tx->is_complete, 'client response completed';
                my $ctx = { server => $client, chunk => $chunk };
                $ctx->{driver} = Unblock::HTTP2::_nghttp2::NativeDriver->new($client) if $native;
                feed($ctx, frame(0, 1, $tx->stream_id, 'late response'));
                is goaway_code($ctx), 5, 'client also rejects DATA on a retired response stream';
            }
        };
    }
}

subtest 'long connection coalesces retired stream history' => sub {
    my $ctx = context(0, 0);
    for my $n (0 .. 4999) {
        feed($ctx, request(2 * $n + 1, 1));
        my @out = drain($ctx);
        die 'normal history exhausted' if grep { $_->{type} == 7 } @out;
    }
    is scalar(@{ $ctx->{requests} }), 5000, '5000 ordinary requests need no history limit close';
    feed($ctx, frame(0, 1, 1, 'late old DATA'));
    is goaway_code($ctx), 5, 'old peer-closed stream is still validated';
};

subtest 'pathological stream history is bounded' => sub {
    my $ctx = context(0, 0);
    my $code;
    for my $n (0 .. 1100) {
        feed($ctx, request(4 * $n + 1, 1));
        $code = goaway_code($ctx);
        last if defined $code;
    }
    is $code, 11, 'fragmented history ends with ENHANCE_YOUR_CALM';
};

subtest 'out-of-order completion coalesces history' => sub {
    my %tx;
    my $ctx = context(1, 7, defer => 1, headers => sub { $tx{$_[0]->stream_id} = $_[0] });
    for my $batch (0 .. 19) {
        my $first = $batch * 160 + 1;
        feed($ctx, join '', map { request($first + $_ * 2, 1) } 0 .. 79);
        # This permutation repeatedly closes interior streams before neighbors.
        for my $n (0 .. 79) {
            my $id = $first + (($n * 37) % 80) * 2;
            delete($tx{$id})->respond(Uniform::HTTP::Response->new(status => 200, body => 'ok'));
            die 'out-of-order history did not coalesce' if defined goaway_code($ctx);
        }
    }
    is scalar(@{ $ctx->{requests} }), 1600, '1600 out-of-order exchanges stay within the history bound';
    feed($ctx, frame(0, 1, 1, 'late'));
    is goaway_code($ctx), 5, 'oldest completed stream remains protected';
};

done_testing;
