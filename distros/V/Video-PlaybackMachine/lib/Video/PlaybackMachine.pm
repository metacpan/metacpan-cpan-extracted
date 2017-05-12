package Video::PlaybackMachine;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use POE;
use POE::Kernel;

use Video::PlaybackMachine::Config;
use Video::PlaybackMachine::ScheduleTable::DB;
use Video::PlaybackMachine::FillSegment;
use Video::PlaybackMachine::Filler;
use Video::PlaybackMachine::Scheduler;
use Video::PlaybackMachine::FillProducer::SlideShow;
use Video::PlaybackMachine::FillProducer::StillFrame;
use Video::PlaybackMachine::FillProducer::UpNext;
use Video::PlaybackMachine::FillProducer::NextSchedule;

my $config  = Video::PlaybackMachine::Config->config();

Video::PlaybackMachine::Config->init_logging();

sub run {
    my $type = shift;
    my ($start_time, $start_at_beginning) = @_;

    defined $start_time or $start_time = time();

    my $schedule_name = $config->schedule();

    my $table =
      Video::PlaybackMachine::ScheduleTable::DB->new(
       schedule_name => $schedule_name );

    my $offset;
    
    if ($start_at_beginning) {
    		my $first = $table->get_first_entry();
    		$offset = $first->start_time() - ( time() + 10 );
    }
    else {
    	$offset = $type->get_offset($start_time, $table);
    }

    my $scheduler = Video::PlaybackMachine::Scheduler->new(
        skip_tolerance => $config->skip_tolerance(),
        schedule_table => $table,
        filler         => $config->get_fill($table),
        offset         => $offset
    );

    $scheduler->spawn();

    POE::Kernel->run();

}

sub get_offset {
    my $type = shift;
    my ($start_time, $table) = @_;

    my $offset = 0;
    my $date   = $config->start();

    if ( $config->offset() > 0 || defined($date) ) {
        $offset = $config->offset() - ( time() - $start_time );

        if ( defined($date) ) {
            if ( $date eq 'first' ) {
                $offset += $table->get_offset_to_first() + 1;
            }
            else {
                $offset += $table->get_offset($date);
            }
        }

    }

    return $offset;
}

1;
__END__

=head1 NAME

Video::PlaybackMachine - Perl extension for creating a television station

=head1 DESCRIPTION

PlaybackMachine is a television broadcast system. You can tell it to
play AVI files at specific times, and it will do so. Whenever nothing
is scheduled to be playing, it will create filler from a variety of
sources.

For example, let's say that I've scheduled "Plan Nine From Outer
Space" at 3:00 PM on Saturday, January 12th, 2008, and scheduled "The
X From Outer Space" at 5:00 PM on the same day. I start the Playback
Machine on Friday night. Until 3:00 on Saturday, it shows slides,
plays background music, tells the audience that "Plan Nine" is next,
and plays short films. On 3:00 it runs "Plan Nine". When Ed Wood's
masterpiece is finished, it fills time again until 5:00.

Potential uses include:

=over

=item *

Automating a television station

=item *

Running movies at a convention

=item *

Kiosks

=back

The Playback Machine uses L<Video::Xine> (and hence libxine) to play
movies and music. Any video format that Xine is comfortable with is
perfectly OK to Playback Machine.

=head1 METHODS

=head2 CLASS METHODS

=head3 run()

  run( $start_time )

Runs the Playback Machine according to the current
configuration. C<$start_time> should be the time when the Playback
Machine session started; it defaults to time().

=head3 get_offset()

  get_offset( $start_time, $table )

Calculates the schedule offset from the configuration. The C<$table>
parameter is a Video::PlaybackMachine::ScheduleTable::DB object, and
is used to calculate the start time when the 'start' config parameter
is set to 'first'.

=head1 SEE ALSO

playback_machine.pl(1)

xine-lib, http://www.xinehq.de

L<Video::Xine>

"How Perl Saved BayCon TV", http://perlmonks.org/?node_id=601001

=head1 AUTHOR

Stephen Nelson, E<lt>stephen@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Stephen Nelson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
