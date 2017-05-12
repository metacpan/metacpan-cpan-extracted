#!/usr/bin/perl
use v5.14;
use warnings;
use AnyEvent;
use Glib qw( TRUE FALSE );
use Glib::EV;
use EV;
use GStreamer;

my $INPUT_FILE  = shift || die "Need input file\n";
my $OUTPUT_FILE = shift || die "Need output file\n";


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
    my $handler = $user_data->{handler};
    state $called = 0;

    warn "Calling dump_file_callback, call count: $called\n";
    $called++;

    warn "Buffer size: " . $buf->size . "\n";
    $handler->process_h264_frame( $buf->data,
        640, 360, 640, 360,
        # TODO fill in width/height params that we get from GStreamer
        #$display_width, $display_height, $encoded_width, $encoded_height
    );

    return 1;
}


{
    GStreamer->init();
    my $loop = Glib::MainLoop->new( undef, FALSE );

    my $pipeline = GStreamer::Pipeline->new( 'pipeline' );
    my ($filesrc, $gdpdepay, $h264parse, $fakesink) =
        GStreamer::ElementFactory->make(
            filesrc   => 'and_who_are_you',
            gdpdepay  => 'the_proud_lord_said',
            h264parse => 'that_i_should_bow_so_low',
            fakesink  => 'only_a_cat_of_a_different_coat',
        );

    $filesrc->set(
        location => $INPUT_FILE,
    );

    $fakesink->set(
        'signal-handoffs' => TRUE,
    );
    $fakesink->signal_connect(
        'handoff' => \&dump_file_callback,
    );

    $pipeline->add( $filesrc, $gdpdepay, $h264parse, $fakesink );
    $filesrc->link( $gdpdepay, $h264parse, $fakesink );

    $pipeline->get_bus->add_watch( \&bus_callback, $loop );

    $pipeline->set_state( 'playing' );
    $loop->run;

    # Cleanup
    $pipeline->set_state( 'null' );
}
