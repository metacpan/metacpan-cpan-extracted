package threads::lite::queue;

use strict;
use warnings;
our $VERSION = '0.034';

use threads::lite;

1;

__END__

=head1 NAME

threads::lite::queue - a threads::lite persistent queue

=head1 VERSION

Version 0.034

=head1 SYNOPSIS

This module represents a queue object/

=head1 METHODS

=head2 new()

Creates a new queue object. Note that queues have to be destroyed explicitly.

=head2 enqueue(...)

Send the list of arguments to the queue.

=head2 dequeue()

Receive the front entry from the queue. If the queue is empty then it blocks.

=head2 dequeue_nb()

Receive the front entry from the queue. If the queue is empty then it returns an empty list.

=head2 destroy

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

