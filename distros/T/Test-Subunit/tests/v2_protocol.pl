#!/usr/bin/perl
# Tests for Test::Subunit::V2 binary protocol support
use strict;
use warnings;
use Test::More tests => 49;

BEGIN {
    use_ok('Test::Subunit::V2', qw(
        pack_packet read_packet parse_stream
        encode_varint decode_varint
        STATUS_EXISTS STATUS_INPROGRESS STATUS_SUCCESS STATUS_FAIL
        STATUS_SKIP STATUS_XFAIL STATUS_UXSUCCESS
        FLAG_RUNNABLE FLAG_TESTID
    ));
}

# --- Varint encoding -------------------------------------------------------

is(unpack("H*", Test::Subunit::V2::encode_varint(0)),    '00',
   'varint 0 => 1 byte');
is(unpack("H*", Test::Subunit::V2::encode_varint(63)),   '3f',
   'varint 63 => 1 byte');
is(unpack("H*", Test::Subunit::V2::encode_varint(64)),   '4040',
   'varint 64 => 2 bytes');
is(unpack("H*", Test::Subunit::V2::encode_varint(12)),   '0c',
   'varint 12 matches example packet length field');

# Round trip
for my $n (0, 1, 63, 64, 16383, 16384, 4194303, 1073741823) {
    my $bytes = Test::Subunit::V2::encode_varint($n);
    my $pos = 0;
    my $got = Test::Subunit::V2::decode_varint(\$bytes, \$pos);
    is($got, $n, "varint round trip $n");
    is($pos, length $bytes, "varint $n consumed all bytes");
}

# --- Known-vector packet ---------------------------------------------------

# From the subunit v2 spec: trivial 'foo' enumeration packet.
my $expected = pack('H*', 'b329010c03666f6f08555f1b');
my $got = pack_packet(
    status   => STATUS_EXISTS,
    runnable => 1,
    testid   => 'foo',
);
is(unpack('H*', $got), unpack('H*', $expected),
   'enumeration packet matches spec example');

# --- Round-trip a variety of packets ---------------------------------------

sub roundtrip {
    my (%opts) = @_;
    my $buf = pack_packet(%opts);
    my $pos = 0;
    my ($pkt, $new_pos) = read_packet(\$buf, $pos);
    return ($pkt, $buf, $new_pos);
}

{
    my ($pkt, $buf, $new) = roundtrip(
        status => STATUS_SUCCESS, testid => 'my.test', runnable => 1);
    is($pkt->{testid}, 'my.test',     'success: testid round trip');
    is($pkt->{status}, STATUS_SUCCESS, 'success: status round trip');
    is($pkt->{runnable}, 1,           'success: runnable flag');
    is($new, length $buf,             'success: consumed entire packet');
}

{
    my ($pkt) = roundtrip(
        status    => STATUS_FAIL,
        testid    => 'broken',
        tags      => ['slow', 'network'],
        timestamp => [1234567890, 500000000],
        file_name => 'traceback',
        file_content => "line 1\nline 2\n",
        mime      => 'text/plain; charset=utf-8',
        route_code => '0/1',
        runnable  => 1,
    );
    is($pkt->{status}, STATUS_FAIL,         'fail status');
    is($pkt->{testid}, 'broken',            'fail testid');
    is_deeply($pkt->{tags}, ['slow','network'], 'tags round trip');
    is_deeply($pkt->{timestamp}, [1234567890, 500000000], 'timestamp round trip');
    is($pkt->{file_name}, 'traceback',      'file name');
    is($pkt->{file_content}, "line 1\nline 2\n", 'file content');
    is($pkt->{mime}, 'text/plain; charset=utf-8', 'mime');
    is($pkt->{route_code}, '0/1',           'route code');
}

# EOF flag is exposed.
{
    my ($pkt) = roundtrip(status => STATUS_SUCCESS, testid => 'x',
                          file_name => 'log', file_content => '', eof => 1);
    is($pkt->{eof}, 1, 'EOF flag round trip');
}

# --- CRC validation --------------------------------------------------------

{
    my $buf = pack_packet(status => STATUS_EXISTS, testid => 'foo');
    # Corrupt one byte of the body.
    substr($buf, 5, 1) = chr(ord(substr($buf, 5, 1)) ^ 0xFF);
    my $pos = 0;
    my $r = eval { read_packet(\$buf, $pos); 1 };
    ok(!$r, 'corrupted packet rejected');
    like($@, qr/CRC/, 'error mentions CRC');
}

# --- parse_stream dispatch -------------------------------------------------

package MockOps;
sub new { bless { start => [], end => [], out => '', packets => [] }, shift }
sub start_test { push @{$_[0]{start}}, $_[1] }
sub end_test   { push @{$_[0]{end}},
                 { name => $_[1], result => $_[2], unexpected => $_[3],
                   reason => $_[4] } }
sub output_msg { $_[0]{out} .= $_[1] }
sub packet     { push @{$_[0]{packets}}, $_[1] }

package main;

{
    my $stream = pack_packet(status => STATUS_INPROGRESS, testid => 't1',
                             runnable => 1)
               . pack_packet(status => STATUS_SUCCESS,    testid => 't1',
                             runnable => 1)
               . pack_packet(status => STATUS_INPROGRESS, testid => 't2',
                             runnable => 1)
               . pack_packet(status => STATUS_FAIL,       testid => 't2',
                             runnable => 1,
                             file_name => 'reason',
                             file_content => 'boom');
    open my $fh, '<', \$stream or die $!;
    my $ops = MockOps->new;
    my $stats = { TESTS_EXPECTED_OK => 0, TESTS_UNEXPECTED_FAIL => 0 };
    parse_stream($ops, $stats, $fh);

    is_deeply($ops->{start}, ['t1', 't2'], 'two tests started');
    is(scalar @{$ops->{end}}, 2,           'two tests ended');
    is($ops->{end}[0]{result}, 'success',  'first test succeeded');
    is($ops->{end}[0]{unexpected}, 0,      'first not unexpected');
    is($ops->{end}[1]{result}, 'fail',     'second test failed');
    is($ops->{end}[1]{unexpected}, 1,      'fail is unexpected');
    is($ops->{end}[1]{reason}, 'boom',     'failure reason captured');
    is($stats->{TESTS_EXPECTED_OK}, 1,     'one expected ok');
    is($stats->{TESTS_UNEXPECTED_FAIL}, 1, 'one unexpected fail');
}

# Interleaved non-subunit output is reported via output_msg.
{
    my $stream = "hello\n"
               . pack_packet(status => STATUS_INPROGRESS, testid => 'x',
                             runnable => 1)
               . pack_packet(status => STATUS_SUCCESS,    testid => 'x',
                             runnable => 1)
               . "trailing\n";
    open my $fh, '<', \$stream or die $!;
    my $ops = MockOps->new;
    parse_stream($ops, {}, $fh);
    like($ops->{out}, qr/hello/,    'interleaved stdout before packet');
    like($ops->{out}, qr/trailing/, 'interleaved stdout after packet');
}

# parse_results transparently dispatches v2 when it sees 0xB3.
{
    require Test::Subunit;
    my $stream = pack_packet(status => STATUS_INPROGRESS, testid => 'a',
                             runnable => 1)
               . pack_packet(status => STATUS_SUCCESS,    testid => 'a',
                             runnable => 1);
    open my $fh, '<', \$stream or die $!;
    my $ops = MockOps->new;
    my $stats = { TESTS_EXPECTED_OK => 0 };
    Test::Subunit::parse_results($ops, $stats, $fh);
    is($stats->{TESTS_EXPECTED_OK}, 1, 'parse_results auto-detects v2');
}
