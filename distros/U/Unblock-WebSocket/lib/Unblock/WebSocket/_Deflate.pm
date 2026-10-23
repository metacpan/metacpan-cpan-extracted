package Unblock::WebSocket::_Deflate;

use strict;
use warnings;
use Carp qw(croak);
use Compress::Raw::Zlib 2.017 qw(
    Z_BUF_ERROR
    Z_HUFFMAN_ONLY
    Z_OK
    Z_SYNC_FLUSH
);

my $TAIL = "\x00\x00\xff\xff";

sub new {
    my ($class, %option) = @_;

    my $role = delete $option{role};
    croak 'new(): role must be client or server'
        unless defined($role) && ($role eq 'client' || $role eq 'server');

    my $config = delete $option{config};
    croak 'new(): config must be a hash reference'
        unless ref($config) eq 'HASH';

    my $max_message_size = delete $option{max_message_size};
    croak 'new(): max_message_size must be a positive integer'
        unless defined($max_message_size) && !ref($max_message_size)
            && $max_message_size =~ /\A[0-9]+\z/ && $max_message_size > 0;

    croak 'new(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    my $out_bits = $role eq 'client'
        ? ($config->{client_max_window_bits} || 15)
        : ($config->{server_max_window_bits} || 15);
    croak 'permessage-deflate compressor window must be between 8 and 15'
        if $out_bits < 8 || $out_bits > 15;

    my $in_bits = $role eq 'client'
        ? ($config->{server_max_window_bits} || 15)
        : ($config->{client_max_window_bits} || 15);
    croak 'permessage-deflate inflater window must be between 8 and 15'
        if $in_bits < 8 || $in_bits > 15;

    my $out_no_context = $role eq 'client'
        ? $config->{client_no_context_takeover}
        : $config->{server_no_context_takeover};
    my $in_no_context = $role eq 'client'
        ? $config->{server_no_context_takeover}
        : $config->{client_no_context_takeover};

    return bless {
        role             => $role,
        config           => { %$config },
        max_message_size => 0 + $max_message_size,
        out_bits         => 0 + $out_bits,
        in_bits          => 0 + $in_bits,
        out_no_context   => $out_no_context ? 1 : 0,
        in_no_context    => $in_no_context ? 1 : 0,
        deflater         => undef,
        inflater         => undef,
    }, $class;
}

sub _new_deflater {
    my ($self) = @_;
    my %option = (
        -WindowBits   => -$self->{out_bits},
        -AppendOutput => 1,
    );

    # zlib promotes an 8-bit deflate window to 9 internally. For an RFC 7692
    # window of 8, use a 9-bit raw stream with Huffman-only compression. That
    # emits no LZ77 distance references, so the stream is valid for a peer
    # constrained to a 256-byte window.
    if ($self->{out_bits} == 8) {
        $option{-WindowBits} = -9;
        $option{-Strategy} = Z_HUFFMAN_ONLY;
    }

    my ($z, $status) = Compress::Raw::Zlib::Deflate->new(%option);
    croak "permessage-deflate deflater initialization failed: $status"
        unless $z && $status == Z_OK;
    return $z;
}

sub _new_inflater {
    my ($self) = @_;
    my $bufsize = $self->{max_message_size} + 1;
    $bufsize = 64 * 1024 if $bufsize > 64 * 1024;

    my ($z, $status) = Compress::Raw::Zlib::Inflate->new(
        -WindowBits   => -$self->{in_bits},
        -LimitOutput  => 1,
        -Bufsize      => $bufsize,
        -AppendOutput => 0,
    );
    croak "permessage-deflate inflater initialization failed: $status"
        unless $z && $status == Z_OK;
    return $z;
}

sub compress {
    my ($self, $payload) = @_;
    croak 'compress(): payload must be a defined scalar'
        if !defined($payload) || ref($payload);
    my $bytes = "$payload";
    croak 'compress(): payload must be a byte string'
        unless utf8::downgrade($bytes, 1);

    my $z = $self->{deflater} ||= $self->_new_deflater;
    my $output = '';

    my $status = $z->deflate($bytes, $output);
    croak "permessage-deflate compression failed: $status"
        unless $status == Z_OK;

    $status = $z->flush($output, Z_SYNC_FLUSH);
    croak "permessage-deflate sync flush failed: $status"
        unless $status == Z_OK;

    croak 'permessage-deflate compressor produced an invalid sync-flush tail'
        if length($output) < 4 || substr($output, -4) ne $TAIL;
    substr($output, -4, 4, '');

    $self->{deflater} = undef if $self->{out_no_context};
    return $output;
}

sub decompress {
    my ($self, $payload) = @_;
    croak 'decompress(): payload must be a defined scalar'
        if !defined($payload) || ref($payload);
    my $input = "$payload";
    croak 'decompress(): payload must be a byte string'
        unless utf8::downgrade($input, 1);
    $input .= $TAIL;

    my $z = $self->{inflater} ||= $self->_new_inflater;
    my $output = '';

    while (1) {
        my $chunk = '';
        my $before = length($input);
        my $status = $z->inflate($input, $chunk);

        croak "permessage-deflate decompression failed: $status"
            unless $status == Z_OK || $status == Z_BUF_ERROR;

        $output .= $chunk;
        croak 'WebSocket message exceeds configured limit'
            if length($output) > $self->{max_message_size};

        last unless length $input;
        croak 'permessage-deflate decompressor made no progress'
            if length($input) == $before && !length($chunk);
    }

    $self->{inflater} = undef if $self->{in_no_context};
    return $output;
}

sub config {
    my ($self) = @_;
    return { %{ $self->{config} } };
}

1;
