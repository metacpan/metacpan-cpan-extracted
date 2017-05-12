
use v5.14;
use UAV::Pilot::Exceptions;
use UAV::Pilot::Video::FileDump;
use UAV::Pilot::ARDrone::Video;
use UAV::Pilot::ARDrone::Video::Stream;
use UAV::Pilot::ARDrone::Video::Fileno;
use UAV::Pilot::Events;

use constant VIDEO_EXTERNAL_STREAM_EXEC => 'ardrone_display_video.pl';

our $dev = undef;

{
    my @NO_ARG_STRAIGHT_COMMANDS = qw(
        takeoff
        land
        calibrate
        phi_m30
        phi_30
        theta_m30
        theta_30
        theta_20deg_yaw_200
        theta_20deg_yaw_m200
        turnaround
        turnaround_godown
        yaw_shake
        yaw_dance
        phi_dance
        theta_dance
        vz_dance
        wave
        phi_theta_mixed
        double_phi_theta_mixed
        flip_ahead
        flip_behind
        flip_left
        flip_right
        emergency
        hover
        start_userbox_nav_data
        stop_userbox_nav_data
        cancel_userbox_nav_data
    );
    foreach my $name (@NO_ARG_STRAIGHT_COMMANDS) {
        no strict 'refs';
        *$name = sub () {
            $dev->$name;
        };
    }
}

{
    my @SINGLE_ARG_STRAIGHT_COMMANDS = qw(
        pitch
        roll
        yaw
        vert_speed
    );
    foreach my $name (@SINGLE_ARG_STRAIGHT_COMMANDS) {
        no strict 'refs';
        *$name = sub ($) {
            $dev->$name( @_ );
        };
    }
}

{
    my @TWO_ARG_STRAIGHT_COMMANDS = qw(
        led_blink_green_red
        led_blink_green
        led_blink_red
        led_blink_orange
        led_snake_green_red
        led_fire
        led_standard
        led_red
        led_green
        led_red_snake
        led_blank
        led_right_missile
        led_left_missile
        led_double_missile
        led_front_left_green_others_red
        led_front_right_green_others_red
        led_rear_right_green_others_red
        led_rear_left_green_others_red
        led_left_green_right_red
        led_left_red_right_green
        led_blink_standard
    );
    foreach my $name (@TWO_ARG_STRAIGHT_COMMANDS) {
        no strict 'refs';
        *$name = sub ($$) {
            $dev->$name( @_ );
        };
    }
}

sub take_picture ($$;$)
{
    $dev->take_picture( @_ );
}

sub record_usb ()
{
    $dev->record_usb;
}

{
    my $cv          = undef;
    my $events      = undef;
    my $easy_events = undef;
    my $init_events = sub {
        return 1 if defined $events;
        die "Can't init UAV::Pilot::Events without a condvar\n" unless defined $cv;

        $events = UAV::Pilot::Events->new({
            condvar => $cv,
        });
        $easy_events = UAV::Pilot::EasyEvent->new({
            condvar => $cv,
        });
        $dev->setup_read_nav_event( $easy_events );
        $events->init_event_loop;
        $easy_events->init_event_loop;

        # If we can load SDL, then init it here
        eval "use UAV::Pilot::SDL::Events";
        if(! $@ ) {
            my $sdl_events = UAV::Pilot::SDL::Events->new;
            $events->register( $sdl_events );
        }

        $dev->init_event_loop( $cv, $easy_events );
        return 1;
    };

    my $sdl = undef;
    my $init_sdl = sub {
        return 1 if defined $sdl;
        eval "use UAV::Pilot::SDL::Window;";
        die "Can't use UAV::Pilot::SDL::Window: $@\n" if $@;

        $init_events->();
        $sdl = UAV::Pilot::SDL::Window->new;
        $events->register( $sdl );
        return 1;
    };

    my $vid_driver = undef;
    my $init_vid_driver = sub {
        return 1 if defined $vid_driver;

        $vid_driver = UAV::Pilot::ARDrone::Video->new({
            condvar => $cv,
            driver  => $dev->driver,
        });
        $vid_driver->init_event_loop;
        $dev->video( $vid_driver );

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

        $vid_driver = UAV::Pilot::ARDrone::Video::Stream->new({
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

        $vid_driver = UAV::Pilot::ARDrone::Video::Fileno->new({
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
        $cv  = $$args{condvar};

        $easy_events = UAV::Pilot::EasyEvent->new({
            condvar => $cv,
        });
        $easy_events->init_event_loop;

        $dev = $cmd->controller_callback_ardrone->(
            $cmd, $cv, $easy_events );
        return 1;
    }

    sub uav_module_quit
    {
        $cleanup_processes->();
    }


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

    sub start_nav ()
    {
        eval "use UAV::Pilot::ARDrone::SDLNavOutput";
        die "Problem loading UAV::Pilot::ARDrone::SDLNavOutput: $@\n" if $@;
        $init_sdl->();
        $init_events->();

        my $nav = UAV::Pilot::ARDrone::SDLNavOutput->new({
            feeder => $dev,
        });
        $dev->driver->add_nav_collector( $nav );
        $nav->add_to_window( $sdl, $sdl->BOTTOM );

        say "Outputting navigation data";

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

    sub dump_video_to_file ($)
    {
        my ($file) = @_;
        $init_vid_driver->();

        open( my $fh, '>', $file ) or UAV::Pilot::IOException->throw({
            error => "Can't open [$file] for writing: $!\n",
        });
        my $vid_dump = UAV::Pilot::Video::FileDump->new({
            fh => $fh,
        });

        $vid_driver->add_handler( $vid_dump );
        say "Dumping video to file '$file'";
        return 1;
    }
}


1;
