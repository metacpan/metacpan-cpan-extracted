package threads::lite;

use strict;
use warnings;

use experimental 'smartmatch';

our $VERSION = '0.034';

use 5.010001;

use Exporter 5.57 qw//;
use Storable 2.05 ();

use XSLoader;
XSLoader::load('threads::lite', $VERSION);

our @EXPORT_OK   = qw/spawn receive receive_nb receiveq receiveq_nb self send_to/;
our %EXPORT_TAGS = (
	receive => [qw/receive receive_nb receiveq receiveq_nb/],
	all     => \@EXPORT_OK,
);

require threads::lite::tid;
use threads::lite::queue;

sub import {
	require feature;
	feature->import('switch');
	goto &Exporter::import;
}

sub _receive;
sub _receive_nb;
sub self;

my @mailbox;

##no critic (Subroutines::RequireFinalReturn)

sub receiveq {
	my @args = @_;
	if (@args) {
		for my $index (0..$#mailbox) {
			return _return_elements(splice @mailbox, $index, 1) if $mailbox[$index] ~~ @args;
		}
		while (1) {
			my $message = _receive;
			return _return_elements($message) if $message ~~ @args;
			push @mailbox, $message;
		}
	}
	else {
		return _return_elements(@mailbox ? shift @mailbox : _receive);
	}
}

sub receiveq_nb {
	my @args = @_;
	if (@args) {
		for my $index (0..$#mailbox) {
			return _return_elements(splice @mailbox, $index, 1) if $mailbox[$index] ~~ @args;
		}
		while (my $message = _receive_nb) {
			return _return_elements($message) if $message ~~ @args;
			push @mailbox, $message;
		}
		return;
	}
	else {
		my $ret = @mailbox ? shift @mailbox : _receive_nb;
		return $ret ? _return_elements($ret) : $ret;
	}
}

## no critic (Subroutines::RequireArgUnpacking,Subroutines::ProhibitSubroutinePrototypes)

sub receive(&) {
	my $receive = shift;

	my @save;
	my $i = 0;
	MESSAGE:
	while (1) {
		my $message;
		if ($i < @mailbox) {
			$message = splice @mailbox, $i, 1, @save;
			$i += @save;
		}
		else {
			push @mailbox, @save;
			$message = _receive;
		}

		for ($message) {
			$receive->();
			@save = ($message);
			next MESSAGE;
		}
		continue {
			return _return_elements($message);
		}
	}
}

sub receive_nb(&) {
	my $receive = shift;
	my @save;

	my $i = 0;
	MESSAGE:
	while (1) {
		my $message;
		if ($i < @mailbox) {
			$message = splice @mailbox, $i, 1, @save;
			$i += @save;
		}
		else {
			push @mailbox, @save;
			$message = _receive_nb;
			return if not $message;
		}

		for ($message) {
			$receive->();
			@save = ($message);
			next MESSAGE;
		}
		continue {
			return _return_elements($message);
		}
	}
}

1;

__END__

=head1 NAME

threads::lite - Actor model threading for Perl

=head1 VERSION

Version 0.034

=head1 SYNOPSIS

 use Modern::Perl;
 use threads::lite qw/spawn self receive receive_table/;
 use SmartMatch::Sugar;

 sub child {
     my $other = threads::lite::receiveq;
     while (<>) {
         chomp;
         $other->send(line => $_);
     }
     return;
 }

 my $child = spawn({ monitor => 1 } , \&child);
 $child->send(self);

 my $continue = 1;
 while ($continue) {
     receive {
         when([ 'line', any ]) {
             my (undef, $line) = @$_;
             say "received line: $line";
         }
         when([ 'exit', any, $child->id ]) {
             say "received end of file";
             $continue = 0;
         }
         default {
             die sprintf "Got unknown message: (%s)", join ", ", @$_;
         }
     };
 };

=head1 DESCRIPTION

This module implements threads for perl. One crucial difference with C<threads.pm> threads is that the threads are disconnected, except by message queues. It thus facilitates a message passing style of multi-threading.

Please note that B<this module is a research project>. In no way is API stability guaranteed. It is released for evaluation purposes only, not for production usage.

=head1 FUNCTIONS

All these functions are exported optionally.

=head2 Utility functions

=head3 spawn($options, $sub)

Spawn new threads. It will run $sub and send all monitoring processes it's return value. $options is a hashref that can contain the following elements.

=over 2

=item * modules => [...]

Load the specified modules before running any code.

=item * pool_size => int

Create C<pool_size> identical clones.

=item * monitor => 0/1

If this is true, the calling process will monitor the newly spawned threads. Defaults to false.

=item * stack_size => int

The stack size for the newly created threads. It defaults to 64 kiB.

=back

$sub can be a function name or a subref. If it is a name, you must make sure the module it is in is loaded in the new thread. If it is a reference to a function it will be serialized before being sent to the new thread. This means that any enclosed variables will probability not work as expected. Any locally imported functions will not be defined in the new thread, so you probably want to use fully qualified names.

=head3 self()

Retreive the thread identifier object corresponding with the current thread.

=head3 send_to($id, ...)

Send a message a thread identified by its primitive identifier

=head2 Receiving functions

All these functions will try to match messages in the local thread's mailbox to a pattern. If it can find a match, the message will be removed from the mailbox.

=head3 receive { ... }

Match each message against the code in the block until a message matches it. The block is expected to contain C<when> and C<default> blocks, but may contain other code too. If no matching message is found, it will block until a suitable message is received.

=head3 receive_nb { ... }

Match in exactly the same way receive does, but do not block if no suitable message can be found. Instead it will return an empty list.

=head3 receiveq(@pattern)

Return the first message that smart-matches @pattern. If there is no such message in the queue, it blocks until a suitable message is received. An empty pattern results in the first message 

=head3 receiveq_nb(@pattern)

Return the first message that smart-matches @pattern. If there is no such message in the queue, it returns an empty list (undef in scalar context).

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

This is an early development release, and is expected to be buggy and incomplete. In particular, memory management is known to be buggy.

Please report any bugs or feature requests to C<bug-threads-lite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=threads-lite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc threads::lite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=threads-lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/threads-lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/threads-lite>

=item * Search CPAN

L<http://search.cpan.org/dist/threads-lite>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010, 2011 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
