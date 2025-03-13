package Test::Smoke::Archiver;
use warnings;
use strict;

our $VERSION = '0.001';

use base 'Test::Smoke::ObjectBase';
use Test::Smoke::LogMixin;

use File::Copy;
use File::Path;
use File::Spec::Functions;
use Test::Smoke::Util qw/get_patch/;

=head1 NAME

Test::Smoke::Archiver - Archive the smoke files.

=head1 DESCRIPTION

=head2 Test::Smoke::Archiver->new(%arguments)

=head3 Arguments

=over

=item archive => [0|1]

=item ddir => $smoke_destination_directory

=item adir => $archive_destination_directory

=item outfile => 'mktest.out'

=item rptfile => 'mktest.rpt'

=item jsnfile => 'mktest.jsn'

=item lfile => $logfile_name

=item v => [0|1|2]

=back

=head3 Returns

The instance...

=cut

my %CONFIG = (
    df_archive => 1,
    df_ddir    => '.',
    df_adir    => undef,

    df_outfile => 'mktest.out',
    df_rptfile => 'mktest.rpt',
    df_jsnfile => 'mktest.jsn',
    df_lfile   => undef,

    df_v => 0,
);

sub new {
    my $class = shift;
    my %args = @_;

    my %struct;
    for my $dfkey (keys %CONFIG) {
        (my $key = $dfkey) =~ s/^df_//;
        $struct{"_$key"} = exists $args{$key} ? $args{$key} : $CONFIG{$dfkey};
    }

    my $self = bless \%struct, $class;

    return $self;
}

=head2 $archiver->archive_files()

Copy files.

=cut

sub archive_files {
    my $self = shift;
    if (!$self->archive) {
        return $self->log_info("Skipping archive: --noarchive.");
    }
    if (!$self->adir) {
        return $self->log_info("Skipping archive: No archive directory set.");
    }

    if (!-d $self->adir) {
        open my $ch, '>', \my $output;
        my $stdout = select $ch;
        mkpath($self->adir, 1, 0775)
            or die "Cannot mkpath(@{[$self->adir]}): $!";
        select $stdout;
        $self->log_debug($_) for split /\n/, $output;
    }

    (my $patch_level = get_patch($self->ddir)->[0]) =~ tr/ //sd;
    $self->{_patchlevel} = $patch_level;

    my @archived;
    for my $filetype (qw/rpt out jsn/) {
        my $to_archive = "archive_$filetype";
        my $filename = "${filetype}file";
        push @archived, $self->$filename if $self->$to_archive;
    }
    return \@archived;
}

=head2 $archiver->archive_rpt

=cut

sub archive_rpt {
    my $self = shift;
    my $src = catfile($self->ddir, $self->rptfile);
    if (! -f $src) {
        return $self->log_info("%s not found: skip archive rpt", $src);
    }
    my $dst = catfile($self->adir, sprintf("rpt%s.rpt", $self->patchlevel));
    if (-f $dst) {
        return $self->log_info("%s exists, skip archive rpt", $dst);
    }

    my $success = copy($src, $dst);
    if (!$success) {
        $self->log_warn("Failed to cp(%s,%s): %s", $src, $dst, $!);
    }
    else {
        $self->log_info("Copy(%s, %s): ok", $src, $dst);
    }
    return $success;
}

=head2 $archiver->archive_out

=cut

sub archive_out {
    my $self = shift;
    my $src = catfile($self->ddir, $self->outfile);
    if (! -f $src) {
        return $self->log_info("%s not found: skip archive out", $src);
    }
    my $dst = catfile($self->adir, sprintf("out%s.out", $self->patchlevel));
    if (-f $dst) {
        return $self->log_info("%s exists, skip archive out", $dst);
    }

    my $success = copy($src, $dst);
    if (!$success) {
        $self->log_warn("Failed to cp(%s,%s): %s", $src, $dst, $!);
    }
    else {
        $self->log_info("Copy(%s, %s): ok", $src, $dst);
    }
    return $success;
}

=head2 $archiver->archive_jsn

=cut

sub archive_jsn {
    my $self = shift;
    my $src = catfile($self->ddir, $self->jsnfile);
    if (! -f $src) {
        return $self->log_info("%s not found: skip archive jsn", $src);
    }
    my $dst = catfile($self->adir, sprintf("jsn%s.jsn", $self->patchlevel));
    if (-f $dst) {
        return $self->log_info("%s exists, skip archive jsn", $dst);
    }

    my $success = copy($src, $dst);
    if (!$success) {
        $self->log_warn("Failed to cp(%s,%s): %s", $src, $dst, $!);
    }
    else {
        $self->log_info("Copy(%s, %s): ok", $src, $dst);
    }
    return $success;
}

=head2 $archiver->archive_log

=cut

sub archive_log {
    my $self = shift;
    my $src = $self->lfile;
    if (! -f $src) {
        return $self->log_info("%s not found: skip archive log", $src);
    }
    my $dst = catfile($self->adir, sprintf("log%s.log", $self->patchlevel));
    if (-f $dst) {
        return $self->log_info("%s exists, skip archive log", $dst);
    }

    my $success = copy($src, $dst);
    if (!$success) {
        $self->log_warn("Failed to cp(%s,%s): %s", $src, $dst, $!);
    }
    else {
        $self->log_info("Copy(%s, %s): ok", $src, $dst);
    }
    return $success;
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
