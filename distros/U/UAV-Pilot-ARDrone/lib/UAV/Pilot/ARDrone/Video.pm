# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::ARDrone::Video;
$UAV::Pilot::ARDrone::Video::VERSION = '1.1';
use v5.14;
use Moose;
use namespace::autoclean;
use IO::Socket::INET;
use UAV::Pilot::Video::H264Handler;
use Time::HiRes ();

use Data::Dumper 'Dumper';
$Data::Dumper::Sortkeys = 1;


use constant READ_INTERVAL            => 1 / 15;
use constant BUF_READ_SIZE            => 4096;
use constant BUF_READ_SIZE_HEADER     => 128;
use constant PAVE_HEADER_PARTIAL_PROCESS_SIZE => 8;
use constant PAVE_SIGNATURE           => 'PaVE';
use constant PAVE_SIGNATURE_LE        => 0x45566150;
use constant PAVE_SIGNATURE_BE        => 0x50615645;
use constant PAVE_SIGNATURE_BE_ARRAY  => [ 0x50, 0x61, 0x56, 0x45 ];
use constant {
    CODEC_TYPES => {
        UNKNOWN      => 0,
        VLIB         => 1,
        P264         => 2,
        MPEG4_VISUAL => 3,
        MPEG4_AVC    => 4,
        0 => 'UNKOWN',
        1 => 'VLIB',
        2 => 'P264',
        3 => 'MPEG4_VISUAL',
        4 => 'MPEG4_AVC',
    },
    FRAME_TYPES => {
        UNKNOWN   => 0,
        IDR_FRAME => 1,
        I_FRAME   => 2,
        P_FRAME   => 3,
        HEADERS   => 4,
        0 => 'UNKNOWN',
        1 => 'IDR_FRAME',
        2 => 'I_FRAME',
        3 => 'P_FRAME',
        4 => 'HEADERS',
    },
    PAVE_CTRL => {
        # This one should be interpreted as a bitfield
        FRAME_DATA           => 0,
        FRAME_ADVERTISEMENT  => (1<<0),
        LAST_FRAME_IN_STREAM => (1<<1),
    },
    STREAM_ID_SUFFIX => {
        MP4_360P  => 0,
        H264_360P => 1,
        H264_720P => 2,
        0 => 'MP4_360P',
        1 => 'H264_360P',
        2 => 'H264_720P',
    },
};

use constant {
    _MODE_PARTIAL_PAVE_HEADER   => 0,
    _MODE_REMAINING_PAVE_HEADER => 1,
    _MODE_FRAME                 => 2,
    _MODE_NEXT_PAVE             => 3,
};


with 'UAV::Pilot::Logger';
with 'UAV::Pilot::ARDrone::Video::BuildIO';


has '_io' => (
    is     => 'ro',
    isa    => 'Item',
    writer => '_set_io',
);
has 'handlers' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[UAV::Pilot::Video::H264Handler]',
    default => sub {[]},
    handles => {
        'add_handler' => 'push',
    },
);
has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has 'driver' => (
    is  => 'ro',
    isa => 'UAV::Pilot::ARDrone::Driver',
);
has 'frames_processed' => (
    traits  => ['Number'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        '_add_frames_processed' => 'add',
    },
);
has '_byte_buffer' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub {[]},
    handles => {
        '_byte_buffer_splice' => 'splice',
        '_byte_buffer_size'   => 'count',
        '_byte_buffer_push'   => 'push',
    },
);
has '_mode' => (
    is  => 'rw',
    isa => 'Int',
    default => sub {
        my ($class) = @_;
        return $class->_MODE_PARTIAL_PAVE_HEADER;
    },
);
has '_last_pave_header' => (
    is      => 'rw',
    isa     => 'HashRef[Item]',
    default => sub {{}},
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $io = $class->_build_io( $args );

    $$args{'_io'} = $io;
    delete $$args{'host'};
    delete $$args{'port'};
    return $args;
}

sub emergency_restart
{
    my ($self) = @_;
    # TODO clear buffer of available packets
    $self->_io->close;
    my $io = $self->_build_io({
        driver => $self->driver,
    });
    $self->_set_io( $io );
    return 1;
}


# We split reading the PaVE header into two parts.  The first part needs just enough bytes 
# to get us to the packet size.  From there, we know how big the header will actually be, 
# so we will know if we have enough bytes yet to build the full thing.
sub _read_partial_pave_header
{
    my ($self) = @_;
    return 1 if $self->_byte_buffer_size < $self->PAVE_HEADER_PARTIAL_PROCESS_SIZE;

    my @bytes = $self->_byte_buffer_splice( 0, $self->PAVE_HEADER_PARTIAL_PROCESS_SIZE );

    my %packet;
    $packet{'_initial_read_time'}    = [Time::HiRes::gettimeofday];
    $packet{signature}               = pack 'c4', @bytes[0..3];
    $packet{signature_int}           = UAV::Pilot->convert_32bit_LE( @bytes[0..3] );
    $packet{version}                 = $bytes[4];
    $packet{video_codec}             = $bytes[5];
    $packet{packet_size}             = UAV::Pilot->convert_16bit_LE( @bytes[6,7]);

    #warn "Bad PaVE header.  Got [$packet{signature}], expected " . $self->PAVE_SIGNATURE
    if( $packet{signature} ne $self->PAVE_SIGNATURE ) {
        $self->_logger->error( "Bad PaVE header.  Got [$packet{signature}],"
            . " expected " . $self->PAVE_SIGNATURE );
        $self->_mode( $self->_MODE_NEXT_PAVE );
        return $self->_read_to_next_pave_header;
    }

    $self->_last_pave_header( \%packet );
    $self->_mode( $self->_MODE_REMAINING_PAVE_HEADER );
    return $self->_read_remaining_pave_header;
}

sub _read_remaining_pave_header
{
    my ($self) = @_;
    my %packet = %{ $self->_last_pave_header };
    my $remaining_size = $packet{packet_size} - $self->PAVE_HEADER_PARTIAL_PROCESS_SIZE;
    return 1 if $self->_byte_buffer_size < $remaining_size;

    my @bytes = $self->_byte_buffer_splice( 0, $remaining_size );

    $packet{payload_size}            = UAV::Pilot->convert_32bit_LE( @bytes[0..3] );
    $packet{encoded_stream_width}    = UAV::Pilot->convert_16bit_LE( @bytes[4,5] );
    $packet{encoded_stream_height}   = UAV::Pilot->convert_16bit_LE( @bytes[6,7] );
    $packet{display_width}           = UAV::Pilot->convert_16bit_LE( @bytes[8,9] );
    $packet{display_height}          = UAV::Pilot->convert_16bit_LE( @bytes[10,11] );
    $packet{frame_number}            = UAV::Pilot->convert_32bit_LE( @bytes[12..15] );
    $packet{timestamp}               = UAV::Pilot->convert_32bit_LE( @bytes[16..19] );
    $packet{total_chunks}            = $bytes[20];
    $packet{chunk_index}             = $bytes[21];
    $packet{frame_type}              = pack 'C', $bytes[22];
    $packet{control}                 = $bytes[23];
    $packet{stream_byte_position_lw} = UAV::Pilot->convert_32bit_LE( @bytes[24..27] );
    $packet{stream_byte_position_uw} = UAV::Pilot->convert_32bit_LE( @bytes[28..31] );
    $packet{stream_id_suffix}        = $bytes[32];
    $packet{stream_id}               = UAV::Pilot->convert_16bit_LE( @bytes[33,34] );
    $packet{total_slices}            = $bytes[35];
    $packet{slice_index}             = $bytes[36];
    $packet{header1_size}            = $bytes[37];
    $packet{header2_size}            = $bytes[38];
    $packet{reserved2}               = pack 'C2', @bytes[39,40];
    $packet{advertised_size}         = UAV::Pilot->convert_32bit_LE( @bytes[41..44] );
    $packet{reserved3}               = pack 'C12', @bytes[45..56];

    $packet{dummy_data} = pack 'C*', @bytes[57..($remaining_size - 1)]
        if $remaining_size > 57;

    $packet{video_codec_name}      = $self->CODEC_TYPES->{$packet{video_codec}};
    $packet{frame_type_name}       = $self->FRAME_TYPES->{$packet{frame_type}};
    $packet{control_names}         = [ map {
        ($packet{control} & $self->PAVE_CTRL->{$_}) ? $_ : ()
    } keys %{ $self->PAVE_CTRL } ];
    $packet{stream_id_suffix_name} = $self->STREAM_ID_SUFFIX->{$packet{stream_id_suffix}};
    $packet{signature_int_hex}     = sprintf '0x%x', $packet{signature_int};
    #warn "Frame " . $self->frames_processed . " dump: " . Dumper( \%packet );
    $self->_logger->info( "Frame num: " . $self->frames_processed
        . ", size: $packet{payload_size}" );


    $self->_logger->info( 'VIDEO_FRAME_TIMER,START,' . $self->frames_processed
        . ','
        . join( ',', @{ +$packet{'_initial_read_time'} } ) );

    $self->_add_frames_processed( 1 );
    $self->_last_pave_header( \%packet );
    $self->_mode( $self->_MODE_FRAME );
    return $self->_read_frame;
}

sub _read_to_next_pave_header
{
    my ($self) = @_;
    my @byte_buf = @{ $self->_byte_buffer };
    my @expect_signature = @{ $self->PAVE_SIGNATURE_BE_ARRAY };

    foreach my $i (0 .. $#byte_buf) {
        if( ($expect_signature[0] == $byte_buf[$i])
            && ($expect_signature[1] == $byte_buf[$i + 1])
            && ($expect_signature[2] == $byte_buf[$i + 2])
            && ($expect_signature[3] == $byte_buf[$i + 3])
        ) {
            my @new_byte_buffer = @byte_buf[$i..$#byte_buf];
            $self->_byte_buffer( \@new_byte_buffer );
            $self->_mode( $self->_MODE_PARTIAL_PAVE_HEADER );
            return $self->_read_partial_pave_header;
        }
    }

    return 1;
}

sub _read_frame
{
    my ($self) = @_;
    my %header = %{ $self->_last_pave_header };
    my $frame_size = $header{payload_size};
    return 1 if $self->_byte_buffer_size < $frame_size;

    my @frame = $self->_byte_buffer_splice( 0, $frame_size );
    foreach my $handler (@{ $self->handlers }) {
        $handler->process_h264_frame(
            \@frame,
            @header{qw{
                display_width
                display_height
                encoded_stream_width
                encoded_stream_height
            }}
        );
    }

    $self->_mode( $self->_MODE_PARTIAL_PAVE_HEADER );
    return $self->_read_partial_pave_header;
}

sub _process_io
{
    my ($self) = @_;

    my $buf;
    my $read_count = $self->_io->read( $buf, $self->BUF_READ_SIZE );
    my @bytes = unpack 'C*', $buf;
    $self->_byte_buffer_push( @bytes );

    if( $self->_mode == $self->_MODE_PARTIAL_PAVE_HEADER ) {
        $self->_read_partial_pave_header;
    }
    elsif( $self->_mode == $self->_MODE_REMAINING_PAVE_HEADER ) {
        $self->_read_remaining_pave_header;
    }
    elsif( $self->_mode == $self->_MODE_FRAME ) {
        $self->_read_frame;
    }
    elsif( $self->_mode == $self->_MODE_NEXT_PAVE ) {
        $self->_read_to_next_pave_header;
    }

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Video

=head1 SYNOPSIS

    my $cv      = AnyEvent->condvar;
    my $handler = ...; # An object that does UAV::Pilot::Video::H264Handler
    my $ardrone = ...; # An instance of UAV::Pilot::ARDrone::Driver
    my $video = UAV::Pilot::ARDrone::Video->new({
        handlers => [ $handler ],
        condvar  => $cv,
        driver   => $ardrone,
    });
    
    $video->init_event_loop;
    $cv->recv;

=head1 DESCRIPTION

Processes the Parrot AR.Drone v2 video stream, which is an h264 stream with some 
additional header data.

Note that this I<will not> work with the AR.Drone v1.

=head1 METHODS

=head2 new

    new({
        handlers => [ $handler ],
        condvar  => $cv,
        driver   => $ardrone,
    })

Constructor.  The C<handlers> param is an array of objects that do the role 
C<UAV::Pilot::Video::H264Handler>.  Param C<condvar> is an AnyEvent::CondVar.
Param C<driver> is an instance of C<UAV::Pilot::Driver::ARDrone>.

=head2 init_event_loop

Starts the AnyEvent loop for processing video packets.

=head2 emergency_restart

The AR.Drone will close the connection when emergency mode is toggled.  Calling this will 
close the stream on our end and reintitlize.

You shouldn't have to call this directly.  Pass this object to your 
C<UAV::Pilot::Control::ARDrone> instance and it will do it for you.

=head2 add_handler

    add_handler( $handler );

Adds a C<UAV::Pilot::Video::H264Handler> object to the list of handlers.

=cut
