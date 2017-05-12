#!/usr/bin/perl
use v5.14;
use warnings;
use AnyEvent;
use Glib qw( TRUE FALSE );
use Glib::EV;
use EV;
use GStreamer;
use Digest::Adler32::XS;

use constant {
    VIDEO_MAGIC_NUMBER => 0xFB42,
    VIDEO_VERSION      => 0x0000,
    VIDEO_ENCODING     => 0x0001,
};
my $INPUT_FILE  = shift || die "Need input file\n";


sub bus_callback
{
    my ($bus, $msg, $loop) = @_;

    if( $msg->type & "error" ) {
        warn $msg->error;
        $loop->quit;
    }
    elsif( $msg->type & "eos" ) {
        warn "End of stream, quitting\n";
        $loop->quit;
    }

    return TRUE;
}

sub dump_file_callback
{
    my ($fakesink, $buf, $pad, $user_data) = @_;
    my $frame_data = $buf->data;
    my $frame_size = $buf->size;
    state $called = 0;

    my $digest = Digest::Adler32::XS->new;
    $digest->add( $frame_data );
    my $checksum = $digest->hexdigest;

    warn "Frame $called, Buffer size: $frame_size, Checksum: $checksum\n";
    output_video_frame( $frame_data, $frame_size, 640, 360 );

    $called++;
    return 1;
}

sub output_video_frame
{
    my ($frame_data, $frame_size, $width, $height) = @_;

    my $digest = Digest::Adler32::XS->new;
    $digest->add( $frame_data );
    my $checksum = $digest->digest;

    my $flags = 0x00000001; # Turn on heartbeat flag (test purposes)

    my $out_headers = pack 'nnnNNnnC*'
        ,VIDEO_MAGIC_NUMBER
        ,VIDEO_VERSION
        ,VIDEO_ENCODING
        ,$flags
        ,$frame_size
        ,$width
        ,$height
        ,unpack( 'C*', $checksum )
        ,( (0x00) x 10 ) # 10 bytes reserved
        ;

    print $out_headers;
    print $frame_data;
    return 1;
}


{
    GStreamer->init();
    my $loop = Glib::MainLoop->new( undef, FALSE );

    my $pipeline = GStreamer::Pipeline->new( 'pipeline' );
    my ($filesrc, $h264, $capsfilter, $fakesink)
        = GStreamer::ElementFactory->make(
            filesrc    => 'and_who_are_you',
            h264parse  => 'the_proud_lord_said',
            capsfilter => 'that_i_should_bow_so_low',
            fakesink   => 'only_a_cat_of_a_different_coat',
        );

    my $caps = GStreamer::Caps::Simple->new( 'video/x-h264',
        alignment       => 'Glib::String' => 'au',
        'stream-format' => 'Glib::String' => 'byte-stream',
    );
    $capsfilter->set( caps => $caps );

    $filesrc->set(
        location => $INPUT_FILE,
    );

    $fakesink->set(
        'signal-handoffs' => TRUE,
    );
    $fakesink->signal_connect(
        'handoff' => \&dump_file_callback,
    );

    $pipeline->add( $filesrc, $h264, $capsfilter, $fakesink );
    $filesrc->link( $h264, $capsfilter, $fakesink );

    $pipeline->get_bus->add_watch( \&bus_callback, $loop );

    $pipeline->set_state( 'playing' );
    $loop->run;

    # Cleanup
    $pipeline->set_state( 'null' );
}
