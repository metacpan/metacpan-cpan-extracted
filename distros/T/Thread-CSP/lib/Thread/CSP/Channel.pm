package Thread::CSP::Channel;
$Thread::CSP::Channel::VERSION = '0.015';
use strict;
use warnings;

use 5.008001;

use Thread::CSP;

1;

#ABSTRACT: Channels for Communicating sequential processes

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::CSP::Channel - Channels for Communicating sequential processes

=head1 VERSION

version 0.015

=head1 SYNOPSIS

 my $c = Thread::CSP::Channel->new;
 
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

=head2 receive_ready_fh()

This will return a filehandle that one byte will be written to when a value has been send to the channel.

=head2 send_ready_fh()

This will return a filehandle that one byte will be written to when a value is being received.

=head2 close()

This will close the queue. Any C<receive> will now return undef, and any write is ignored.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
