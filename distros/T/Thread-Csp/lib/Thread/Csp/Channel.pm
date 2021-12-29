package Thread::Csp::Channel;
$Thread::Csp::Channel::VERSION = '0.001';
use strict;
use warnings;

use 5.008001;

use Thread::Csp;

1;

#ABSTRACT: Channels for Communicating sequential processes

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::Csp::Channel - Channels for Communicating sequential processes

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $c = Thread::Csp::Channel->new;
 
 $c->send("value");

 my $rec = $c->receive;

=head1 DESCRIPTION

This class represents a channel between two or more CSP threads, allowing any cloneable value (unblessed values, channels and potentially others) to be passed around between threads.

=head1 METHODS

=head2 new()

This creates a new channel.

=head2 send($value)

This sends a value over the channel. It will block until another thread is prepared to receive the value.

=head2 receive()

This receives a value from the channel. It will block until another thread is prepared to send the value.

=head2 set_notify($handle, $value)

This will cause C<$value> to be written to C<$handle> whenever a new value becomes available, unless it's already being read. B<THIS METHOD IS PARTICULARLY EXPERIMENTAL>.

=head2 close()

This will close the queue. Any C<receive> will now return undef, and any write is ignored.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
