package Timed::Logger;

use 5.16.0;
use strict;
use warnings;

use Moose;
use Time::HiRes;
use Carp;
use List::Util;
use Timed::Logger::Entry;

=head1 NAME

Timed::Logger - store events for later analysis.

=head1 VERSION

Version 0.0.6

=cut

our $VERSION = '0.0.6';

=head1 SYNOPSIS

    use Timed::Logger;

    my $logger = Timed::Logger->new;

    my $log_entry = $logger->start;
    #...
    #some lengthly operation
    #...
    $logger->finish($entry, { description => 'long operation' });

    #...

    foreach my $entry ($logger->log->{default}) {
        printf("Operation %s took $.4f s", $entry->data->{description}, $entry->elapsed);
    }

    printf("Total time: $.4f s", $logger->elapsed_total);
    printf("Total time in default bucket: $.4f s", $logger->elapsed_total('default'));

=head1 DESCRIPTION

Timed::Logger allows one to log events along with amount if time that event took.
This can be useful for debugging and profiling purposes.  See L<Plack::Middleware::Debug::Timed::Logger>
for usage example.

=head1 BUCKETS

Sometimes you want to break your events into different types and anaylze them separately.
This can be achieved using buckets:

    my $log_entry = $logger->start('DB');
    #...
    #some DB operation
    #...
    $logger->finish($entry, { description => 'long operation' });

    my $log_entry = $logger->start('some');
    #...
    #some other type of operation
    #...
    $logger->finish($entry, { description => 'long operation' });

By default bucket named 'default' is used.

=head1 ATTRIBUTES

=head2 log

This attribute contains a log gathered so far.  It is organized as an hashref of arrayref of entries.
Keys in a hash represent buckets. Each entry has a Timed::Logger::Entry type.

=head1 METHODS

=head2 new

Create a new Timed::Logger.

=head2 start([$bucket])

Start a new event.  Returns new Timed::Logger::Entry.  One can specify bucket to use, otherwise 'default' is used.

=head2 finish($entry[, $data])

Save current into log.  If optional $data is set it is stored in Timed::Logger::Entry data attribute.

=head2 elapsed_total([$bucket])

Calculates total time for all events (by default) or for given bucket if one is provided.

=cut

has log => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { {} },
  init_arg => undef
 );

sub start {
  my ($self, $bucket) = @_;
  $bucket ||= 'default';
  return Timed::Logger::Entry->new(bucket => $bucket, started => Time::HiRes::time);
}

sub finish {
  my ($self, $entry, $data) = @_;
  croak('Provide an entry to finish') unless($entry);
  $entry->finished(Time::HiRes::time);
  $entry->data($data) if(defined($data));
  push(@{$self->log->{$entry->bucket}}, $entry);
}

sub elapsed_total {
  my ($self, $bucket) = @_;
  if($bucket) {
    return List::Util::sum(map { $_->elapsed } @{$self->log->{$bucket} || []}) || 0
  }
  else {
    return List::Util::sum(map { $_->elapsed } map { @$_ } values(%{$self->log})) || 0;
  }
}

=head1 SEE ALSO

L<Plack::Middleware::Timed::Logger>, L<Plack::Middleware::Debug::Timed::Logger>,
L<Timed::Logger::Dancer::AdoptPlack>

=head1 AUTHOR

Nikolay Martynov, C<< <kolya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-timed-logger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Timed-Logger>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Timed::Logger


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
