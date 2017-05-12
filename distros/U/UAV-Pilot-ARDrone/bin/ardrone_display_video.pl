#!/usr/local/bin/perl
use v5.14;
use warnings;
use AnyEvent;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::ARDrone::Video::Mock;
use UAV::Pilot::Events;
use UAV::Pilot::SDL::Events;
use UAV::Pilot::SDL::Video;
use UAV::Pilot::SDL::Window;
use UAV::Pilot::Video::FileDump;
use UAV::Pilot::Video::H264Decoder;
use Getopt::Long ();


my $FILENO   = undef;
my $OUT_FILE = undef;
Getopt::Long::GetOptions(
    'fileno=i'   => \$FILENO,
    'out-file=s' =>  \$OUT_FILE,
);



sub get_input_fh
{
    my ($fileno) = @_;
    my $fh = undef;

    if( defined $fileno ) {
        open( $fh, '<&=', $fileno ) or die "Can't open fileno '$fileno': $!\n";
    }
    else {
        $fh = \*STDIN;
    }

    return $fh;
}

{
    my $cv = AnyEvent->condvar;
    my $events = UAV::Pilot::Events->new({
        condvar => $cv,
    });

    my $driver = UAV::Pilot::ARDrone::Driver::Mock->new({
        host => 'localhost',
    });
    $driver->connect;

    my $window = UAV::Pilot::SDL::Window->new;

    my $vid_display = UAV::Pilot::SDL::Video->new;
    my @displays = ($vid_display);
    my @h264_handlers = (UAV::Pilot::Video::H264Decoder->new({
        displays => \@displays,
    }));
    $vid_display->add_to_window( $window );

    if( defined $OUT_FILE ) {
        open( my $fh, '>', $OUT_FILE )
            or die "Can't write to file $OUT_FILE: $!\n";
        my $file_dumper = UAV::Pilot::Video::FileDump->new({
            fh => $fh,
        });
        push @h264_handlers, $file_dumper;
    }

    my $fh = get_input_fh( $FILENO );
    my $video = UAV::Pilot::ARDrone::Video::Mock->new({
        fh       => $fh,
        handlers => \@h264_handlers,
        condvar  => $cv,
        driver   => $driver,
    });

    my $sdl_events = UAV::Pilot::SDL::Events->new;

    $events->register( $_ ) for $sdl_events, $window;
    $_->init_event_loop for $video, $events;
    $cv->recv;
}
