package VCS::Rcs;

use strict;
use vars qw($VERSION $LOG_CMD %LOG_CACHE);
use VCS::Rcs::Dir;
use VCS::Rcs::File;
use VCS::Rcs::Version;
use IPC::Open2;

$VERSION = '0.06';

$LOG_CMD = "rlog";

sub _boiler_plate_info {
    my ($self, $what) = @_;
    my ($header, $log) = $self->_split_log($self->{VERSION});
    my $rev_info = $self->_parse_log_rev($log);
    $rev_info->{$what};
}

sub _split_log {
    my ($self, $version) = @_;
    my $log_text;
    my $cache_id = $self->url;
    unless (defined($log_text = $LOG_CACHE{$cache_id})) {
      my @cmd = ($LOG_CMD, (defined $version ? "-r$version" : ()), $self->path);
      open2 my $fh, undef, @cmd;
      $LOG_CACHE{$cache_id} = $log_text = join '', <$fh>;
    }
    my @sections = split /\n[=\-]+\n/, $log_text;
    @sections = ($sections[0], grep {/^revision $version(\n|\s)/} @sections) if $version;
#map { print "SEC: $_\n" } @sections;
    die "Failed to parse log info from '$log_text'\n" unless @sections;
    @sections;
}

sub _parse_log_rev {
    my ($self, $text) = @_;
    my ($rev_line, $blurb, @reason) = split /\n/, $text;
    my %info = map {
        split /:\s+/
    } split /;\s*/, $blurb;
    my ($junk, $rev) = split /\s+/, $rev_line;
    $info{'revision'} = $rev;
    $info{'reason'} = \@reason;
#print "REASON: @reason\n";
#map { print "$_ => $info{$_}\n" } keys %info;
    \%info;
}

sub _parse_log_header {
    my ($self, $text) = @_;
    $text =~ s#(description:.*)##s;
    my $desc = join "\n ", split /\n/, $1;
    $text .= $desc;
    my @parts = $text =~ /^(\S.*?)(?=^\S|\Z)/gms;
    chomp @parts;
#map { print "PART: $_\n" } @parts;
    my %info = map {
        split /:\s*/, $_, 2
    } @parts;
#map { print "$_ => $info{$_}\n" } keys %info;
    \%info;
}

1;

=head1 NAME

VCS::Rcs - notes for the rcs implementation

=head1 SYNOPSIS

    use VCS;
    $file = VCS::File->new('/source/rcsrepos/project/Makefile');

=head1 DESCRIPTION

Currently, the user needs to ensure that their environment has the
B<rcs> toolset available, including B<rlog>, B<rcsdiff>, B<co>, et al.
On Unix like environments ensure that the C<$PATH> environment variable
has the appropriate directory listed.  On Windows be sure that the C<%PATH%>
variable has the directory with B<rlog.exe> etc. in it.

=head1 AVAILABILITY

VCS::Rcs is currently part of the main VCS distribution.

=head1 COPYRIGHT

Copyright (c) 1998-2003 Leon Brocard & Greg McCarroll. All rights
reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<VCS>.

=cut
