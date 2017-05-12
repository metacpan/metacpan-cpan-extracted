package VCS::Cvs;

use strict;
use vars qw($VERSION);
use Cwd qw(cwd);
use File::Spec::Functions qw(splitpath);
use VCS::Cvs::Dir;
use VCS::Cvs::File;
use VCS::Cvs::Version;

$VERSION = '0.06';

my $LOG_CMD = "cvs log";

my %LOG_CACHE;

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

        my $cwd = cwd();
        my($volume, $path, $file) = splitpath($self->path);
        chdir $path;

        my $cmd =
            $LOG_CMD .
            " " . $file . " 2>/dev/null |";
#warn "cmd: $cmd\n";
        $LOG_CACHE{$cache_id} = $log_text = $self->_read_pipe($cmd);

        chdir $cwd;
    }
    my @sections = split /\n[=\-]+\n/, $log_text;
    @sections = ($sections[0], grep { /^revision $version(?:\s+locked by.*?)?\n/ } @sections)
        if $version;
#map { print "SEC: $_\n" } @sections;
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

sub _read_pipe {
    my ($self, $cmd) = @_;
    local *PIPE;
    open PIPE, $cmd;
    local $/ = undef;
    my $contents = <PIPE>;
    close PIPE;
    $contents = '' unless defined $contents;
    return $contents;
}

1;


__END__

=head1 NAME

VCS::Cvs - notes for the CVS implementation

=head1 SYNOPSIS

    $ENV{CVSROOT} = '/cvsroot';
    use VCS;
    $file = VCS::File->new('vcs://localhost/VCS::Cvs/source/project/Makefile');

=head1 DESCRIPTION

Currently, the user needs to ensure that the environmental requirements
for CVS command line tools are satisfied.

=head1 AVAILABILITY

VCS::Cvs is currently part of the main VCS distribution.

=head1 COPYRIGHT

Copyright (c) 1998-2003 Leon Brocard & Greg McCarroll. All rights
reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<VCS>.

=cut
