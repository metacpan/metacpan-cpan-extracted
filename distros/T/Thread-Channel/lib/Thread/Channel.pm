package Thread::Channel;
{
  $Thread::Channel::VERSION = '0.003';
}

use strict;
use warnings;

use Sereal ();

use XSLoader;
XSLoader::load('Thread::Channel', __PACKAGE__->VERSION);

1; # End of Thread::Channel

# ABSTRACT: Fast thread queues

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::Channel - Fast thread queues

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use threads;
 use Thread::Channel;
 my $channel = Thread::Channel->new;

 my $reader = threads->create(sub {
     while (my $line = <>) {
         $channel->enqueue($line)
     };
     $channel->enqueue(undef);
 });

 while (defined(my $line = $channel->dequeue)) {
     print $line;
 }
 $reader->join;

=head1 DESCRIPTION

Thread::Channel is an alternative to L<Thread::Queue>. By using a smart serialization ladder, it can achieve high performance without compromizing on flexibility.

=head1 METHODS

=head2 new()

This constructs a new channel.

=head2 enqueue(@items)

This enqueues the message C<@items> to the channel. Note that this list is a single message.

=head2 dequeue()

Dequeues a message from queue. Note that this returns a list, not (necessarily) a scalar. If the channel is empty, it will wait until a message arrives.

=head2 dequeue_nb()

Dequeues a message from queue. Note that this returns a list, not (necessarily) a scalar. If the channel is empty, it will return an empty list.

=head1 SEE ALSO

=over 4

=item * Thread::Queue

=item * Sereal

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
