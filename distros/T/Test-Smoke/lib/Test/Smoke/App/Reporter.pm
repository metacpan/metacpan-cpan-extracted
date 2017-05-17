package Test::Smoke::App::Reporter;
use warnings;
use strict;

our $VERSION = '0.001';

use base 'Test::Smoke::App::Base';

use Test::Smoke::Reporter;

=head1 NAME

Test::Smoke::App::Reporter - The tsreport.pl application.

=head1 DESCRIPTION

=head2 Test::Smoke::App::Reporter->new()

Return an instance.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_reporter} = Test::Smoke::Reporter->new(
        $self->options,
        v => $self->option('verbose'),
    );

    return $self;
}

=head2 $reporter->run()

Write the rpt_file and jsn_file.

=cut

sub run {
    my $self = shift;

    $self->log_debug("[Reporter] write_to_file()");
    $self->reporter->write_to_file();

    $self->log_debug("[Reporter] smokedb_data()");
    $self->reporter->smokedb_data();

    return 1;
}

1;

=head1 COPYRIGHT

(c) 2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

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
