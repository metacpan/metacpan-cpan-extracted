package Test::Smoke::App::HandleQueue;
use warnings;
use strict;
use Carp;

our $VERSION = '0.001';

use base 'Test::Smoke::App::Base';

use Test::Smoke::Poster;
use Test::Smoke::PostQueue;

=head1 NAME

Test::Smoke::App::HadleQueue - Queue handler for reports that failed to POST to CoreSmokeDB

=head1 SYNOPSIS

    use Test::Smoke::App::Options;
    use Test::Smoke::App::HandleQueue;

    my $app = Test::Smoke::App::HandleQueue->new(
        Test::Smoke::App::Options->handlequeue_config
    );
    $app->run();

=head1 DESCRIPTION

This applet reads the current queue and tries to send every report in it. On
success the item is removed, on failure it stiks around. After all items in the
queue have been looked at, the ones that do not exist in the archive directory
will also be removed from the queue.

=head2 Test::Smoke::App::HandleQueue->new(%arguments)

Create an instance of the app.

=head3 Arguments

Named, list:

=over

=item B<qfile>

The file where the queue is kept.

=item B<adir>

The directory where the archive is.

=item B<smokedb_url>

Where to send the reports.

=item B<poster>

The type of HTTP client to use for sending the report to C<smokedb_url>

=item B<poster-options>

Each of the HTTP clients has its own set of options, See
L<Test::Smoke::Poster::Curl>, L<Test::Smoke::Poster::HTTP_Tiny> and
L<Test::Smoke::Poster::LWP_UserAgent>.

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_poster} = Test::Smoke::Poster->new(
        $self->option('poster') => $self->options,

        # We will need to fake 'ddir' in order to get the reports from the
        # archive
        ddir => $self->option('adir'),
        v    => $self->option('verbose'),
    );
    $self->{_queue} = Test::Smoke::PostQueue->new(
        adir   => $self->option('adir'),
        qfile  => $self->option('qfile'),
        v      => $self->option('verbose'),
        poster => $self->poster,
    );

    return $self;
}

=head2 $handle_queue->run()

Try to send all items in the queue and remove items that are no longer in the archive.

=cut

sub run {
    my $self = shift;

    $self->queue->handle();
    $self->queue->purge();
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
