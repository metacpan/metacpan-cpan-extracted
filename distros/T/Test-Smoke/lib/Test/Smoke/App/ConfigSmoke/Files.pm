package Test::Smoke::App::ConfigSmoke::Files;
use warnings;
use strict;

our $VERSION = '0.002';

use Exporter 'import';
our @EXPORT = qw/ config_files /;

use Cwd;
use File::Spec;
use Test::Smoke::App::Options;

=head1 NAME

Test::Smoke::App::ConfigSmoke::Files - Mixin for L<Test::Smoke::App::ConfigSmoke>

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_files

Configure options C<outfile>, C<rptfile>, C<jsnfile>, C<lfile>, C<adir> and C<qfile>.

=cut

sub config_files {
    my $self = shift;

    print "\n-- Various files/directories section --\n";

    # just set defaults
    for my $option (qw/ outfile rptfile jsnfile /) {
        my $opt = Test::Smoke::App::Options->$option;
        $self->current_values->{$option} = $opt->default;
    }
    $self->current_values->{lfile} = File::Spec->rel2abs($self->prefix . ".log", getcwd());

    $self->handle_option(Test::Smoke::App::Options->adir);

    if ($self->current_values->{adir} && $self->current_values->{smokedb_url}) {
        print "\nI see you post your reports to the Perl5 CoreSmokeDB\n";
        print "and archive previous reports...\n";
        my $qfile_option = Test::Smoke::App::Options->qfile;
        my $qdft = $self->default_for_option($qfile_option);
        if (!$qdft && !length($qdft)) {
            $qfile_option->configdft(sub { $self->prefix . ".qfile" });
        }
        $self->handle_option($qfile_option);
    }

    $self->current_values->{delay_report} = $^O eq 'VMS' ? 1 : 0;
}

1;

=head1 COPYRIGHT

(c) 2020, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

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

