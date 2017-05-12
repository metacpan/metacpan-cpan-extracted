package Video::Xine::Event::Queue;
{
  $Video::Xine::Event::Queue::VERSION = '0.26';
}

use strict;
use warnings;

use Video::Xine::Event;

sub new {
  my $type = shift;
  my ($stream) = @_;

  my $self = {};
  $self->{'stream'} = $stream;
  $self->{'queue'} = xine_event_new_queue($stream->{'stream'});
  bless $self, $type;
}

sub get_event {
  my $self = shift;
  my $event = xine_event_get($self->{'queue'})
    or return;
  bless $event, 'Video::Xine::Event';
}

sub wait_event {
    my $self = shift;

    my $event = xine_event_wait($self->{'queue'});

    bless $event, 'Video::Xine::Event';
}

1;

__END__

=head1 NAME

Video::Xine::Event::Queue -- Event queue for Xine streams

=head1 SYNOPSIS

  use Video::Xine;
  use Video::Xine::Event::Queue;

  my $queue = Video::Xine::Event::Queue->new($stream);

  my $event = $queue->get_event();

=head1 METHODS

=head3 new()

  Video::Xine::Event::Queue->new($stream)

Returns an event queue object.

=head3 get_event()

  my $event = $queue->get_event();

Gets an event from the event queue. If there are no events waiting,
returns undef.

=head3 wait_event()

 my $event = $queue->wait_event();

Waits for an event from the event queue, then returns it. Blocks if no
events are waiting.

=cut
