package VCS::Hms;

use strict;
use vars qw($VERSION);
use VCS::Hms::Dir;
use VCS::Hms::File;
use VCS::Hms::Version;

$VERSION = '0.04';

my $LOG_CMD = "fhist";

my %LOG_CACHE;

sub _boiler_plate_info {
    my ($self, $what) = @_;
    my ($header, $log) = $self->_split_log($self->version);
    my $rev_info = $self->_parse_log_rev($log);
    $rev_info->{$what};
}

sub _split_log {
    my ($self, $version) = @_;
    my $log_text;

    my $cache_id = $self->path . '/' . defined $version ? $version : 'all';
    unless (defined($log_text = $LOG_CACHE{$cache_id})) {
        my $cmd =
            $LOG_CMD .
            (defined $version ? " -r$version" : '') .
            " " . $self->path . " |";
        $LOG_CACHE{$cache_id} = $log_text = $self->_read_pipe($cmd);
    }
    my @sections = split /\n[=\-]+\n/, $log_text;
    #map { print "SEC: $_\n" } @sections;
    @sections;
}

sub _parse_log_rev {
    my ($self, $text) = @_;
    my ($rev_line, $blurb, $blurb2, @reason) = split /\n/, $text;
    my %info = map {
        split /:\s+/,2
    } split /;\s*/, $blurb.$blurb2,;
    my ($junk, $rev) = split /\s+/, $rev_line;
    $info{'revision'} = $rev;
    $info{'reason'} = \@reason;
    #print "REASON: @reason\n";
    #map { print "$_ => $info{$_}\n" } keys %info;
    \%info;
}

sub _parse_log_header {
    my ($self, $text) = @_;
    my @parts = $text =~ /^(\S.*?)(?=^\S|\Z)/gms;
    chomp @parts;
    #map { print "PART: $_\n" } @parts;
    my %info = map {
        split /:\s*/, $_, 2
    } @parts;
    #map { print "$_ => $info{$_}\n" } keys %info;
    \%info;
}

sub _read_pipe {
    my ($self, $cmd) = @_;
    local *PIPE;
    #print "Pipe : $cmd\n";
    open PIPE, $cmd;
    local $/ = undef;
    my $contents = <PIPE>;
    close PIPE;
    return $contents;
}

1;

=head1 NAME

VCS::Hms - notes for the HMS implementation

=head1 IMPORTANT NOTE

I have no way to test this module and so I have removed it out of
the main VCS distribution. If you have access to Hms and would like
to maintain this module please contact me - greg@mccarroll.org.uk.


=head1 SYNOPSIS

    use VCS;
    $file = VCS::File->new('Makefile');

=head1 DESCRIPTION

Currently, the user needs to ensure that their environment has the
HMS toolset available, including B<fhist>, B<fdiff>, B<fco>, et al.
On Unix like environments ensure that the C<$PATH> environment variable
has the appropriate directory listed.

=head1 COPYRIGHT

    Copyright (c) 2003-2008 Greg McCarroll.
    Copyright (c) 1998-2001 Leon Brocard.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<VCS>.

=cut
