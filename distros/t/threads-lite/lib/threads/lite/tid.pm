package threads::lite::tid;

use strict;
use warnings;
use experimental 'smartmatch';
use Scalar::Util qw/blessed/;

use overload '~~' => sub {
	my ($self, $other, $reverse) = @_;
	if (blessed($other) && $other->isa(__PACKAGE__)) {
		return $self->id == $other->id;
	}
	else {
		return $self eq $other;
	}
  },
  '""' => sub {
	my $self = shift;
	return "thread=${$self}";
  },
  'eq' => sub {
	my ($self, $other, $reverse) = @_;
	($self, $other) = ($other, $self) if $reverse;
	return "$self" ~~ $other;
  };

use threads::lite qw/self receive/;

our $VERSION = '0.034';

sub rpc {
	my ($self, @arguments) = @_;
	$self->send(self, @arguments);
	my (undef, @ret) = receiveq($self);
	return (@ret);
}

sub id {
	my $self = shift;
	return ${$self};
}

1;

__END__

=head1 NAME

threads::lite::tid - a threads::lite thread id

=head1 VERSION

Version 0.034

=head1 SYNOPSIS

This module represents a thread ID object. It provides a handle to a thread.

=head1 FUNCTIONS

=head2 send(@list)

Send a message to a thread. The message items may contain any data type that can be serialized by L<Storable> (including coderefs).

=head2 id()

Get an opaque but primitive identifier for thread.

=head2 monitor()

Monitor the thread. This will cause the calling thread to get a notification of the thread's end. In case of a natural death it returns C<('exit', 'normal', $id, @return_value)>, in case of an unnatural death it will contain C<('exit', 'error', $id, $exception)>.

=head2 rpc(@args)

This is a utility function. It send prepended by the sending process' tid, and waits for a reply prepended by the tid, and returns it without the tid.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

This is an early release, it is expected to have plenty of bugs.

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

Copyright 2009, 2010 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

