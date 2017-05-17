package Test::Smoke::App::SendReport;
use warnings;
use strict;

our $VERSION = '0.001';

use base 'Test::Smoke::App::Base';

use File::Spec::Functions;
use Test::Smoke::Mailer;
use Test::Smoke::Poster;
use Test::Smoke::Reporter;

=head1 NAME

Test::Smoke::App::SendReport - Implementation for tssendrpt.pl

=head1 DESCRIPTIN

=head2 $sendrpt->run()

=over

=item * Send e-mail if C<< $self->option('mail') >>

=item * Post to CoreSmokeDB if C<< $self->option('smokedb_url') >>

=back

=cut

sub run {
    my $self = shift;

    $self->check_for_report_and_json;

    if ($self->option('mail')) {
        $self->{_mailer} = Test::Smoke::Mailer->new(
            $self->option('mail_type'),
            $self->options,
            v => $self->option('verbose'),
        );
        $self->log_info("==> Starting mailer");
        $self->mailer->mail();
    }
    else {
        $self->log_warn("==> Skipping mailer");
    }

    if ($self->option('smokedb_url')) {
        $self->{_poster} = Test::Smoke::Poster->new(
            $self->option('poster'),
            $self->options,
            v => $self->option('verbose'),
        );
        $self->log_info("==> Starting poster");
        my $id = $self->poster->post();
        $self->log_warn("%s/%s", $self->option('smokedb_url'), $id);
        return $id;
    }
    else {
        $self->log_warn("==> Skipping poster");
    }
}

=head2 $sendrpt->check_for_report_and_json()

Check for the '.rpt' and the '.jsn' file, return true if both exist.

=cut

sub check_for_report_and_json {
    my $self = shift;

    my $rptfile = catfile($self->option('ddir'), $self->option('rptfile'));
    my $jsnfile = catfile($self->option('ddir'), $self->option('jsnfile'));
    my $missing = 0;
    if (!-f $rptfile) {
        $self->log_warn("RPTfile ($rptfile) not found");
        $missing = 1;
    }
    else {
        $self->log_debug("RPTfile (%s) found.", $rptfile);
    }
    if (!-f $jsnfile) {
        $self->log_warn("JSNfile ($jsnfile) not found");
        $missing = 1;
    }
    else {
        $self->log_debug("JSNfile (%s) found.", $jsnfile);
    }
    if ($missing || $self->option('report')) {
        $self->log_info("Regenerate report and json.");
        $self->regen_report_and_json();
    }
    return 1;
}

=head2 $sendrpt->regen_report_and_json()

Create a reporter object and generate the '.rpt' and '.jsn' files.

=cut

sub regen_report_and_json {
    my $self = shift;

    my $outfile = catfile($self->option('ddir'), $self->option('outfile'));
    if (!-f $outfile) {
        die "No smoke results found ($outfile)\n";
    }
    my $reporter = Test::Smoke::Reporter->new(
        $self->options,
        v => $self->option('verbose'),
    );
    $self->log_debug("[Reporter] write_to_file()");
    $reporter->write_to_file();
    $self->log_debug("[Reporter] smokedb_data()");
    $reporter->smokedb_data();

    return 1;
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
