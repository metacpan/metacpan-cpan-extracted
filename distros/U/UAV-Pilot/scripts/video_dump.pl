#!/usr/bin/perl
use v5.14;
use warnings;
use IO::Socket::INET;
use Data::Dumper 'Dumper';

local $Data::Dumper::Sortkeys = 1;

use constant PAVE_SIGNATURE => 'PaVE';
use constant BUF_READ_SIZE  => 4096;

my $HOST = '192.168.1.1';
my $PORT = 5555;
my $FILE = shift;


my $num_frames = 0;
sub read_frame
{
    my ($input) = @_;
    my $buf;
    my $got_input = $input->read( $buf, BUF_READ_SIZE );
    return {}, 0 if ! $got_input;

    my @bytes = unpack "C*", $buf;

    my %packet;
    $packet{signature}               = pack 'c4', @bytes[0..3];
    $packet{version}                 = $bytes[4];
    $packet{video_codec}             = $bytes[5];
    $packet{packet_size}             = convert_16bit_LE( @bytes[6,7]);
    $packet{payload_size}            = convert_32bit_LE( @bytes[8..11] );
    $packet{encoded_stream_width}    = convert_16bit_LE( @bytes[12,13] );
    $packet{encoded_stream_height}   = convert_16bit_LE( @bytes[14,15] ); # here
    $packet{display_width}           = convert_16bit_LE( @bytes[16,17] );
    $packet{display_height}          = convert_16bit_LE( @bytes[18,19] );
    $packet{frame_number}            = convert_32bit_LE( @bytes[20..23] );
    $packet{timestamp}               = convert_32bit_LE( @bytes[24..27] );
    $packet{total_chunks}            = $bytes[28];
    $packet{chunk_index}             = $bytes[29];
    $packet{frame_type}              = pack 'C', $bytes[30];
    $packet{control}                 = $bytes[31];
    $packet{stream_byte_position_lw} = convert_32bit_LE( @bytes[32..35] );
    $packet{stream_byte_position_uw} = convert_32bit_LE( @bytes[36..39] );
    $packet{stream_id}               = convert_16bit_LE( @bytes[40,41] );
    $packet{total_slices}            = $bytes[42];
    $packet{slice_index}             = $bytes[43];
    $packet{packet1_size}            = $bytes[44];
    $packet{packet2_size}            = $bytes[45];
    $packet{reserved2}               = pack 'C2', @bytes[46,47];
    $packet{advertised_size}         = convert_32bit_LE( @bytes[48..51] );
    $packet{reserved3}               = pack 'C12', @bytes[52..63];
    warn "Bad PaVE signature, got: '$packet{signature}'\n"
        if PAVE_SIGNATURE ne $packet{signature};
warn "Packet: " . Dumper \%packet;

    my ($payload, $continue_reading) = read_frame_payload(
        [@bytes[$packet{packet_size}..$#bytes]] ,
        $input,
        $packet{payload_size}
    );
    $packet{payload} = $payload;
    $num_frames++;
    return (\%packet, $continue_reading);
}

sub read_frame_payload
{
    my ($leftover_bytes, $input, $total_size) = @_;
    my @bytes = @$leftover_bytes;

    my $continue = 1;
    while( (scalar(@bytes) < $total_size) && $continue ) {
        my $buf;
        my $size_left = $total_size - scalar(@bytes);
        my $buf_size = ($size_left > BUF_READ_SIZE)
            ? BUF_READ_SIZE
            : $size_left;
        my $bytes_recv = $input->read( $buf, $buf_size );
        $continue = 0 if ! $bytes_recv;

        push @bytes, unpack( 'C*', $buf );
    }

    return (\@bytes, $continue);
}


sub convert_32bit_LE
{
    my (@bytes) = @_;
    my $val = $bytes[0]
        | ($bytes[1] << 8)
        | ($bytes[2] << 16)
        | ($bytes[3] << 24);
    return $val;
}

sub convert_16bit_LE
{
    my (@bytes) = @_;
    my $val = $bytes[0] | ($bytes[1] << 8);
    return $val;
}


{
    my $input = undef;
    if( defined $FILE) {
        open( $input, '<', $FILE ) 
            or die "Can't open file for reading: $!\n";
    }
    else {
        $input = IO::Socket::INET->new(
            PeerAddr  => $HOST,
            PeerPort  => $PORT,
        ) or die "Can't open socket to $HOST:$PORT: $!\n";
    }

    my $continue = 1;
    while( $continue ) {
        my $frame = {};
        ($frame, $continue) = read_frame( $input );
        print pack( 'C*', @{ $$frame{payload} } ) if %$frame;
    }


    $input->close;
    warn "Frames processed: $num_frames\n";
}
