package WWW::Crawler::Mojo::Queue::Memory;
use strict;
use warnings;
use utf8;
use Mojo::Base 'WWW::Crawler::Mojo::Queue';
use List::Util;

has 'cap';
has jobs               => sub { [] };
has redundancy_storage => sub { {} };

sub dequeue {
  return shift(@{shift->jobs});
}

sub enqueue {
  return shift->_enqueue(@_);
}

sub length {
  return scalar(@{shift->jobs});
}

sub next {
  return shift->jobs->[shift || 0];
}

sub requeue {
  shift->_enqueue(@_, 1);
}

sub shuffle {
  my $self = shift;
  @{$self->jobs} = List::Util::shuffle @{$self->jobs};
}

sub _enqueue {
  my ($self, $job, $requeue) = @_;
  my $digest = $job->digest;
  my $redund = $self->redundancy_storage;
  return if !$requeue  && $redund->{$digest};
  return if $self->cap && $self->cap < $self->length;
  push(@{$self->jobs}, $job);
  $redund->{$digest} = 1;
  return $job;
}

1;

=head1 NAME

WWW::Crawler::Mojo::Queue::Memory - Crawler queue with memory

=head1 SYNOPSIS

=head1 DESCRIPTION

Crawler queue with memory.

=head1 ATTRIBUTES

This class inherits all methods from L<WWW::Crawler::Mojo::Queue> and implements
following new ones.

=head2 cap

Capacity of queue, indecating how many jobs can be kept in queue at a time.
If you enqueue over capacity, the oldest job will be automatically disposed.

=head2 jobs

jobs.

=head2 redundancy_storage

A hash ref in which the class keeps DONE flags for each jobs
in order to avoid to perform resembling jobs multiple times.

    # Mark a job as DONE
    $queue->redundancy_storage->{$job->digest} = 1;
    
    # Delete the mark
    delete($queue->redundancy_storage->{$job->digest});

=head1 METHODS

This class inherits all methods from L<WWW::Crawler::Mojo::Queue> class and
implements following new ones.

=head2 dequeue

Implementation for L<WWW::Crawler::Mojo::Queue> interface.

=head2 enqueue

Implementation for L<WWW::Crawler::Mojo::Queue> interface.

=head2 length

Implementation for L<WWW::Crawler::Mojo::Queue> interface.

=head2 next

Implementation for L<WWW::Crawler::Mojo::Queue> interface.

=head2 requeue

Implementation for L<WWW::Crawler::Mojo::Queue> interface.

=head2 shuffle

Implementation for L<WWW::Crawler::Mojo::Queue> interface.

=head1 AUTHOR

Keita Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Keita Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
