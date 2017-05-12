package Test::Smoke::App::SyncTree;
use warnings;
use strict;

use base 'Test::Smoke::App::Base';

use Test::Smoke::Syncer;

=head1 NAME

Test::Smoke::App::SyncTree - Synchronise the perl source tree from a source.

=head1 DESCRIPTION

This module synchronises the smoke destination directory with a given source in a
given way. The source depends on the synchonisation method.

=head2 Synchronisers

The primary synchronisers are:

=over

=item git

This method will use the L<git()> program to set up a main clone of the
C<gitorigi> source tree.  From this local git repository yet another clone is
made into the smoke destination directory. See L<Test::Smoke::Syncer::Git> for
details.

=item rsync

This method uses the L<rsync()> program to synchronise the smoke destination
directory with a given remote directory/archive C<source>, with C<opts>.

=item copy

This method copies all files in C<cdir>/MANIFEST to C<ddir> and removes all
files not mentioned in that MANIFEST. See L<Test::Smoke::SourceTree>.

=back

=head2 Test::Smoke::App::Syncer->new()

Add a L<Test::Smoke::Syncer> object to the instance.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_syncer} = Test::Smoke::Syncer->new(
        $self->option('syncer'),
        $self->options,
        v => $self->option('verbose'),
    );

    return $self;
}

=head2 $syncer->run()

Actually call C<< $self->syncer->sync() >>.

=cut

sub run {
    my $self = shift;

    my $patchlevel = $self->syncer->sync();
    $self->log_info(
        "%s is now up to patchlevel %s",
        $self->option('ddir'),
        $patchlevel
    );
    return $patchlevel;
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
