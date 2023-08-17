package Thread::GoChannel;
$Thread::GoChannel::VERSION = '0.003';
use strict;
use warnings;

use XSLoader;
XSLoader::load('Thread::GoChannel', __PACKAGE__->VERSION);

1; # End of Thread::GoChannel

# ABSTRACT: Fast thread queues with go-like semantics

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::GoChannel - Fast thread queues with go-like semantics

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use threads;
 use Thread::GoChannel;
 my $channel = Thread::GoChannel->new;

 my $reader = threads->create(sub {
     while (my $line = <>) {
         $channel->send($line)
     }
     $channel->close;
 });

 while (defined(my $line = $channel->receive)) {
     print $line;
 }
 $reader->join;

=head1 DESCRIPTION

Thread::GoChannel is an alternative to L<Thread::Queue>. By using a smart duplication instead of serialization it can achieve high performance without compromising on flexibility.

=head1 METHODS

=head2 new()

This constructs a new channel.

=head2 send($message)

This sends the message C<$message> to the channel. It will wait until there is a receiver.

=head2 receive()

Received a message from the channel, it will wait until a message arrives, or return undef if the channel is closed.

=head2 close()

Closes the channel for further messages.

=head1 SEE ALSO

=over 4

=item * Thread::Queue

=item * Thread::Channel

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
