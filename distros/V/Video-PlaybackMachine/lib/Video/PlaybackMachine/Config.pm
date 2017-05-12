package Video::PlaybackMachine::Config;

our $VERSION = '0.09'; # VERSION

use strict;
use warnings;

use AppConfig qw(:expand :argcount);
our @ISA = qw(AppConfig);

use FindBin '$Bin';

use Log::Log4perl;

our @Config_Files = (
    "$Bin/../conf/playback_machine.conf",
    "$Bin/../Video-PlaybackMachine/conf/playback_machine.conf",
    "$Bin/../../Video-PlaybackMachine/conf/playback_machine.conf",
    "/etc/playback_machine/playback_machine.conf"
);

BEGIN {

    my $config;

    sub config {
        my $type = shift;
        defined $config and return $config;

        $config = $type->new(
            {
                CREATE => 1,
                GLOBAL => { EXPAND => EXPAND_ALL }
            }
        );

        $config->define(
            'database',
            {
                DEFAULT => 'playback_machine',
                ARGS    => '=s'
            }
        );

        $config->define( 'schedule', { ARGS => '=s' } );

        $config->define( 'stills', { ARGS => '=s' } );

        $config->define( 'music', { ARGS => '=s' } );
        
        $config->define( 'movies', { ARGS => '=s' } );

        $config->define( 'font_dir', { ARGS => '=s' } );

        $config->define( 'fill', { ARGS => '=s@' } );

        $config->define( 'restart_interval',
            { ARGS => '=i', DEFAULT => 3 * 60 * 60 } );

        $config->define('logo=s');

        $config->define( 'disclaimer', { ARGS => '=s' } );

        $config->define('start=s');

        $config->define(
            'offset',
            {
                ARGS    => '=i',
                DEFAULT => 0
            }
        );

        $config->define(
            'skip_tolerance',
            {
                ARGS    => '=i',
                DEFAULT => 15
            }
        );

        $config->define( 'max_slides=i', { DEFAULT => 5 } );

        $config->define( 'player_verbose=i', { DEFAULT => 0 } );

        $config->define('stderr_log=s');

        $config->define('log_config=s');

        foreach my $config_file (@Config_Files) {
            -e $config_file or next;
            $config->file($config_file)
              or die "Couldn't load config file '$config_file': $!; stopped";
        }

        $config->define( 'x_display=s', { DEFAULT => ':0.0' } );

        $config->define( 'time_tick=i', { DEFAULT => 5 } );

        $config->define( 'daemonize!', { DEFAULT => 0 } );
        
        $config->define( 'time_zone', { DEFAULT => 'America/Los_Angeles' } );

        $config->getopt();

        return $config;
    }

}

sub init_logging {
    my $type = shift;

    my $config = $type->config();

    Log::Log4perl::init_once( \( $config->log_config() ) );

}

sub _producer_table {
    my $self = shift;
    my ($table) = @_;

    my $prod_table = {
        station_id => Video::PlaybackMachine::FillProducer::StillFrame->new(
            image => $self->logo(),
            time  => 6
        ),

        slideshow => Video::PlaybackMachine::FillProducer::SlideShow->new(
            directory       => $self->get('stills'),
            music_directory => $self->get('music'),
            time            => 10,
        ),

        up_next => Video::PlaybackMachine::FillProducer::UpNext->new(
            time      => 6,
            font_path => [ $self->get('font_dir') ],
        ),

        # Next 5 programs
        next_sched => Video::PlaybackMachine::FillProducer::NextSchedule->new(
            time      => 8,
            font_size => 30,
            font_path => [ $self->get('font_dir') ],
        ),


    };

    if ( $self->get('disclaimer') ) {
        $prod_table->{'disclaimer'} =
          Video::PlaybackMachine::FillProducer::StillFrame->new(
            image => $self->get('disclaimer'),
            time  => 6
          );
    }

    return $prod_table;
}

sub get_fill {
    my $self = shift;
    my ($table) = @_;

    my $pt = $self->_producer_table($table);

    my @fill_segs = ();
    my $order_idx = 1;
    foreach ( @{ $self->fill() } ) {
        my ( $name, $priority ) = split( /\t+/, $_, 2 );
        my $producer = $pt->{$name};
        unless ( defined $producer ) {
            my $logger =
              Log::Log4perl->get_logger('Video.PlaybackMachine.Config');
            $logger->warn("No fill producer found named '$name'");
            next;
        }
        my $segment = Video::PlaybackMachine::FillSegment->new(
            name           => $name,
            sequence_order => $order_idx++,
            priority_order => $priority,
            producer       => $producer
        );
        push( @fill_segs, $segment );

    }

    my $filler = Video::PlaybackMachine::Filler->new( segments => \@fill_segs );

    return $filler;
}

1;

__END__

=head1 NAME

Video::PlaybackMachine::Config -- Configuration for Video::PlaybackMachine

=head1 DESCRIPTION

Provides configuration values for Video::PlaybackMachine. Inherits
from AppConfig.

=head1 METHODS

=head2 CLASS METHODS

=head3 config()

Puts together a config object from the configuration file and
command-line parameters and returns it.

=head2 OBJECT METHODS

=head3 init_logging()

Initializes Log::Log4perl based on the 'log_config' parameter.

=head3 get_fill()

Creates the Video::PlaybackMachine::Filler object based on the
configuration and returns it.


=head1 CONFIGURATION PARAMETERS

=head3 database

Name of the database. Defaults to 'playback_machine'

=head3 schedule

String.

Name of the schedule this instance is running.

=head3 stills

String.

=head3 music

String.

=head3 fill

List of strings.

=head3 restart_interval

Integer. 

Number of seconds between automated restarts.

=head3 logo

String. 

Filename of logo.

=head3 start

String.

=head3 offset

Integer.

Number of seconds to offset from current time.

Default: 0

=head3 skip_tolerance

Maximum number of seconds to allow skipping of a movie without
considering it unplayable and going to idle.

Default: 15

=head3 max_slides

Integer.

Maximum number of slides to play in a row.

Default: 5

=head3 player_verbose

Integer.

Default: 0

=head3 stderr_log

String.

Filename to which we'll redirect stderr in daemon mode.

=head3 log_config

String.

Configuration text block for Log::Log4perl.

=head3 x_display

String.

The value of the X display to be used by X11::FullScreen.

Default: :0.0

=head3 time_tick

Integer.

The scheduler will update the 'clock' in the process name (visible in
ps display) every C<time_tick> seconds.

Default: 5

=cut

