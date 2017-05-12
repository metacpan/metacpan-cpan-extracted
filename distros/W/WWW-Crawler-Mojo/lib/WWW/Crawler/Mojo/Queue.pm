package WWW::Crawler::Mojo::Queue;
use strict;
use warnings;
use utf8;
use Mojo::Base -base;

sub dequeue { die 'Must be implemented by sub classes' }
sub enqueue { die 'Must be implemented by sub classes' }
sub length  { die 'Must be implemented by sub classes' }
sub next    { die 'Must be implemented by sub classes' }
sub requeue { die 'Must be implemented by sub classes' }
sub shuffle { die 'Must be implemented by sub classes' }

1;

=head1 NAME

WWW::Crawler::Mojo::Queue - Crawler queue base class

=head1 SYNOPSIS

    my $queue = WWW::Crawler::Mojo::Queue::Memory->new;
    $queue->enqueue($job1);
    $queue->enqueue($job2);
    say $queue->length          # 2
    $job3 = $queue->next();     # $job3 = $job1
    $job4 = $queue->dequeue();  # $job4 = $job1
    say $queue->length          # 1

=head1 DESCRIPTION

This class represents a FIFO queue.

=head1 METHODS

=head2 dequeue

Shifts the oldest job and returns it. 

    my $job = $queue->deuque;

=head2 enqueue

    $queue->enqueue($job);

Pushes a job unless the job has been already pushed before.

=head2 next

Returns the job which will be dequeued next. It also accept an offset to get any
future job.

    $queue->next; # meaning $queue->next(0)
    $queue->next(1);
    $queue->next(2);

=head2 length

Returns queue length

    say $queue->length

=head2 requeue

Pushes a job regardless of the job has been enqueued before or not.

    $queue->requeue($job);

=head2 shuffle

Shuffles the queue array.

    $queue->shuffle;

=head1 AUTHOR

Keita Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Keita Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
