use v5.14;
use UAV::Pilot::Exceptions;
use UAV::Pilot::Events;
use UAV::Pilot::EasyEvent;
use UAV::Pilot::Video::FileDump;
use UAV::Pilot::WumpusRover;
use UAV::Pilot::WumpusRover::Video;

use constant VIDEO_EXTERNAL_STREAM_EXEC => 'wumpus_display_video.pl';


{
    my $dev         = undef;
    my $cv          = undef;
    my $events      = undef;
    my $easy_events = undef;
    my $sdl         = undef;

    # TODO
    # Make this into a role so ARDrone and WumpusRover can share the code
    my $init_events = sub {
        return 1 if defined $events;
        die "Can't init UAV::Pilot::Events without a condvar\n" unless defined $cv;

        $events = UAV::Pilot::Events->new({
            condvar => $cv,
        });

        $events->init_event_loop;

        # If we can load SDL, then init it here
        eval "use UAV::Pilot::SDL::Events";
        if(! $@ ) {
            my $sdl_events = UAV::Pilot::SDL::Events->new;
            $events->register( $sdl_events );
        }

        $dev->init_event_loop( $cv, $easy_events );
        return 1;
    };

    my $vid_driver = undef;
    my $init_vid_driver = sub {
        return 1 if defined $vid_driver;

        $vid_driver = UAV::Pilot::WumpusRover::Video->new({
            condvar => $cv,
            driver  => $dev->driver,
        });
        $vid_driver->init_event_loop;

        return 1;
    };

    my $fork_process_win32 = sub {
        my (@args) = @_;
        my $pid = system( 1, @args )
            or die "Could not execute " . $args[0] . ": $!\n";
        return $pid;
    };
    my $fork_process_unixy = sub {
        my (@args) = @_;

        my $pid = fork();
        if( $pid ) {
            # Parent
        }
        else {
            # Child
            exec( @args ) or die "Could not execute " . $args[0] . ": $!\n";
        }

        # Remember, child won't get here because of exec()
        return $pid;
    };

    my $init_sdl = sub {
        # TODO
    };

    my @PIDS;
    my $start_video_single_process = sub {
        $init_events->();
        $init_sdl->();
        $init_vid_driver->();
        eval "use UAV::Pilot::SDL::Video";
        die "Problem loading UAV::Pilot::SDL::Video: $@\n" if $@;
        eval "use UAV::Pilot::Video::H264Decoder";
        die "Problem loading UAV::Pilot::Video::H264Decoder: $@\n" if $@;

        my $display = UAV::Pilot::SDL::Video->new;
        my $video   = UAV::Pilot::Video::H264Decoder->new({
            displays => [ $display ],
        });
        $vid_driver->add_handler( $video );
        $display->add_to_window( $sdl, $sdl->TOP );
        $vid_driver->init_event_loop;

        say "Outputting video";
        return 1;
    };
    my $start_video_external_process = sub {
        $init_events->();

        my $pid = open( my $out_fh, '|-', VIDEO_EXTERNAL_STREAM_EXEC )
            or die "Can't execute " . VIDEO_EXTERNAL_STREAM_EXEC . ": $!\n";
        push @PIDS, $pid;

        $vid_driver = UAV::Pilot::WumpusRover::Video::Stream->new({
            condvar => $cv,
            driver  => $dev->driver,
            out_fh  => $out_fh,
        });
        $vid_driver->init_event_loop;

        say "Outputting video on external process (pipe)";
        return 1;
    };
    my $start_video_external_process_fileno = sub {
        my ($out_file) = @_;
        $init_events->();

        $vid_driver = UAV::Pilot::WumpusRover::Video::Fileno->new({
            condvar => $cv,
            driver  => $dev->driver,
        });
        my $fileno = $vid_driver->fileno;

        $SIG{CHLD} = 'IGNORE';
        my @exec = ( VIDEO_EXTERNAL_STREAM_EXEC,
            '--fileno='   . $fileno,
            (defined $out_file ? '--out-file=' . $out_file : ()),
        );
        my $pid = 'MSWin32' eq $^O
            ? $fork_process_win32->( @exec )
            : $fork_process_unixy->( @exec );
        push @PIDS, $pid;

        say "Outputting video on external process (fileno)";
        return 1;
    };

    my $cleanup_processes = sub {
        kill 'HUP', @PIDS;
    };

    sub uav_module_init
    {
        my ($class, $cmd, $args) = @_;
        $cv = $args->{condvar};

        $easy_events = UAV::Pilot::EasyEvent->new({
            condvar => $cv,
        });
        $easy_events->init_event_loop;

        $dev = $cmd->controller_callback_wumpusrover->(
            $cmd, $cv, $easy_events );
        return 1;
    }

    sub throttle ($)
    {
        my ($value) = @_;
        $dev->throttle( $value );
        return 1;
    }

    sub turn ($)
    {
        my ($value) = @_;
        $dev->turn( $value );
        return 1;
    }

    sub stop ()
    {
        $dev->throttle( 0 );
        $dev->turn( 0 );
        return 1;
    }

    # TODO
    # Make this into a role so ARDrone and WumpusRover can share the code
    sub start_joystick ()
    {
        $init_events->();
        eval "use UAV::Pilot::SDL::Joystick";
        die "Problem loading UAV::Pilot::SDL::Joystick: $@\n" if $@;

        my $joystick = UAV::Pilot::SDL::Joystick->new({
            condvar => $cv,
            events  => $easy_events,
        });
        $events->register( $joystick );

        say 'Ready for joystick input on ['
            . SDL::Joystick::name( $joystick->joystick->index )
            . ']';

        return 1;
    }

    sub dump_video_to_file ($)
    {
        my ($file) = @_;
        $init_vid_driver->();

        open( my $fh, '>', $file ) or UAV::Pilot::IOException->throw({
            error => "Can't open [$file] for reading: $!\n",
        });
        my $vid_dump = UAV::Pilot::Video::FileDump->new({
            fh => $fh,
        });

        $vid_driver->add_handler( $vid_dump );
        say "Dumping video to file '$file'";
        return 1;
    }

    sub start_video (;$$)
    {
        my ($type, $out_file) = @_;
        $type //= 0;

        return
            (0 == $type) ?$start_video_external_process_fileno->($out_file):
            (1 == $type) ? $start_video_external_process->( $out_file ) :
            $start_video_single_process->( $out_file );
    }


}

# TODO
# Implement taking picture
#sub take_picture ($)
#{
#    my ($file) = @_;
#}



# TODO
# Implement telemetry on server
#sub start_nav ()
#{
#}




1;
