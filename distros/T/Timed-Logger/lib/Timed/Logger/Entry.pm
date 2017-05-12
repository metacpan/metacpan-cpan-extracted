package Timed::Logger::Entry;

use 5.16.0;
use strict;
use warnings;

use Moose;

=head1 NAME

Timed::Logger::Entry - a log entry for L<Timed::Logger>.

=head1 SYNOPSIS

Timed::Logger::Entry represents one log entry for L<Timed::Logger>.

    use Timed::Logger;

    my $logger = Timed::Logger->new;

    #... log-log-log ...

    foreach my $entry ($logger->log->{default}) {
        printf("Operation %s took $.4f s", $entry->data->{description}, $entry->elapsed);
    }

See L<Timed::Logger> for details.

=head1 ATTRIBUTES

=head2 bucket

Bucket this entry belongs to

=head2 started

Timestamp (floating point) this operation was started. See L<Time::HiRes>.

=head2 finished

Timestamp (floating point) this operation was sinished. See L<Time::HiRes>.

=head2 data

Application specific data for this event.

=head1 METHODS

=head2 elapsed

Returns amount of time this application took, floating point seconds.

=cut

has bucket => (is => 'rw', required => 1);
has started => (is => 'rw', required => 1);
has finished => (is => 'rw');
has data => (is => 'rw');

sub elapsed {
  return $_[0]->finished - $_[0]->started;
}

=head1 AUTHOR

Nikolay Martynov, C<< <kolya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-timed-logger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Timed-Logger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Timed::Logger::Entry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Timed-Logger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Timed-Logger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Timed-Logger>

=item * Search CPAN

L<http://search.cpan.org/dist/Timed-Logger/>

=back


=head1 ACKNOWLEDGEMENTS

Logan Bell and Belden Lyman.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nikolay Martynov and Shutterstock Inc (http://shutterstock.com). All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Timed::Logger
