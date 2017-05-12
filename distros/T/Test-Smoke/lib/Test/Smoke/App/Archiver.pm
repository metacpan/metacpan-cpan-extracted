package Test::Smoke::App::Archiver;
use warnings;
use strict;

use base 'Test::Smoke::App::Base';

use Test::Smoke::Archiver;

=head1 NAME

Test::Smoke::App::Archiver - The tsarchive.pl application.

=head1 DESCRIPTION

=head2 Test::Smoke::App::Archiver->new()

Creates a new attribute C<archiver> of class L<Test::Smoke::Archiver>.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_archiver} = Test::Smoke::Archiver->new(
        $self->options,
        v => $self->option('verbose'),
    );

    return $self;
}

=head2 $archiver->run()

Calls C<< $self->archiver->archive_files() >>.

=cut

sub run {
    my $self = shift;

    $self->archiver->archive_files();
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
