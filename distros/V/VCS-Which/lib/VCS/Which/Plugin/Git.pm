package VCS::Which::Plugin::Git;

# Created on: 2009-05-16 16:58:22
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;
use File::chdir;
use Contextual::Return;

extends 'VCS::Which::Plugin';

our $VERSION = version->new('0.6.8');
our $name    = 'Git';
our $exe     = 'git';
our $meta    = '.git';

sub installed {
    my ($self) = @_;

    return $self->_installed if defined $self->_installed;

    for my $path (split /[:;]/, $ENV{PATH}) {
        next if !-x "$path/$exe";

        return $self->_installed( 1 );
    }

    return $self->_installed( 0 );
}

sub used {
    my ( $self, $dir ) = @_;

    if (-f $dir) {
        $dir = path($dir)->parent;
    }

    croak "$dir is not a directory!" if !-d $dir;

    my $current_dir = path($dir)->absolute;
    my $level       = 1;

    while ($current_dir) {
        if ( -d "$current_dir/$meta" ) {
            $self->_base( $current_dir );
            return $level;
        }

        $level++;

        # check that we still have a parent directory
        last if $current_dir eq $current_dir->parent;

        $current_dir = $current_dir->parent;
    }

    return 0;
}

sub uptodate {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-d $dir;

    local $CWD = path($dir)->absolute;
    my $ans = `$exe status`;

    return $ans =~ /nothing \s to \s commit/xms ? 1 : 0;
}

sub pull {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    return !system "$exe pull > /dev/null 2> /dev/null";
}

sub push {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    return !system "$exe push origin master > /dev/null 2> /dev/null";
}

sub cat {
    my ($self, $file, $revision) = @_;

    # git expects $file to be relative to the base of the git repo not the
    # current directory so we change it to being relative to the repo if nessesary
    my $repo_dir = path($self->_base) or confess "How did I get here with out a base directory?\n";
    my $cwd      = path('.')->absolute;
    local $CWD = $CWD;

    if ( -f $file && $cwd ne $repo_dir ) {
        # get relavie directory of $cwd to $repo_dir
        my ($relative) = $cwd =~ m{^ $repo_dir / (.*) $}xms;
        my $old = $file;
        $file = path("$relative/$file");
        warn "Using repo absolute file $file from $old\n" if $ENV{VERBOSE};
        $CWD = $repo_dir;
    }

    if ( $revision && $revision =~ /^-?\d+$|[^0-9a-fA-F]/xms ) {
        eval { require Git };
        if ($EVAL_ERROR) {
            die "Git.pm is not installed only propper revision names can be used\n";
        }

        my $repo = Git->repository(Directory => $self->_base);
        my @revs = reverse $repo->command('log', '--format=format:%H', '--', $file);
        $revision = $revision =~ /^[-]?\d+$/xms && $revs[$revision] ? $revs[$revision] : $revision;
    }
    elsif ( !defined $revision ) {
        $revision = '';
    }
    warn "$exe show $revision\:$file\n" if $ENV{VERBOSE};

    return `$exe show $revision\:$file`;
}

sub log {
    my ($self, @args) = @_;
    local $CWD = $CWD;

    my $dir;
    if ( defined $args[0] && -d $args[0] && $args[0] =~ m{^/} ) {
        $dir = shift @args;
        $CWD = $dir;
    }
    my $args = join ' ', grep {defined $_} @args;

    return
        SCALAR   { scalar `$exe log $args` }
        ARRAYREF {
            my @raw_log = `$exe log $args`;
            my @log;
            my $line = '';
            for my $raw (@raw_log) {
                if ( $raw =~ /^commit / && $line ) {
                    CORE::push @log, $line;
                    $line = $raw;
                }
                else {
                    $line .= $raw;
                }

            }
            return \@log;
        }
        HASHREF  {
            my $logs = `$exe log $args`;
            my @logs = split /^commit\s*/xms, $logs;
            shift @logs;
            my $num = @logs;
            my %log;
            for my $log (@logs) {
                $log{$num--} = $self->_log_expand($log);
            }
            return \%log;
        }
}

sub _log_expand {
    my ($self, $log) = @_;

    # split the commit from the reset of the message
    my ($ver, $rest) = split /\n/, $log, 2;

    # split log details and the description
    my ($details, $description) = split /\n\n\s*/, $rest, 2;

    # remove excess whitespace at the end of the description
    $description =~ s/\s+\Z//xms;
    my ($conflicts) = $description =~ /\s+Conflicts:\s+(.*)\Z/xms;
    $description =~ s/\s+Conflicts:\s+(.*)\Z//xms;

    # split up the details
    my %log = map {split /:\s*/, $_, 2} split /\n/, $details;

    # add in the description
    $log{description} = $description;

    # add in the revision
    $log{rev} = $ver;

    # add conflicts if any
    $log{conflicts} = [ split /\n\s+/, $conflicts ] if $conflicts;

    return \%log;
}

sub versions {
    my ($self, $file, $oldest, $newest, $max) = @_;

    eval { require Git };
    if ($EVAL_ERROR) {
        die "Git.pm is not installed only propper revision names can be used\n";
    }

    my $repo = Git->repository(Directory => $self->_base);
    my @revs = reverse $repo->command('rev-list', '--all', '--', path($file)->absolute);

    return @revs;
}

sub status {
    my ($self, $dir) = @_;
    my %status;
    my $name = '';
    if ( -f $dir ) {
        $name = path($dir)->absolute->basename;
    }
    local $CWD = -f $dir ? path($dir)->absolute->parent : path($dir)->absolute;
    my $status = `$exe status $name`;
    $status =~ s/^no \s+ changes (.*?) $//xms;
    chomp $status;

    my @both = split /\n?[#]?\s+both\s+modified:\s+/, $status;
    if ( @both > 1 ) {
        shift @both;
        $both[-1] =~ s/\n.*//xms;
        $status{both} = \@both;
    }

    my @modified = split /\n?[#]?\s+modified:\s+/, $status;
    if ( @modified > 1 ) {
        shift @modified;
        $modified[-1] =~ s/\n.*//xms;
        $status{modified} = \@modified;
    }

    my @added = split /\n?[#]?\s+new\sfile:\s+/, $status;
    if ( @added > 1 ) {
        shift @added;
        $added[-1] =~ s/\n.*//xms;
        $status{added} = \@added;
    }

    my @committed = split /Changes to be committed:\n/, $status;
    if (@committed > 1) {
        my $new = pop @committed;
        $status{committed} = [ $new =~ /^\t[^:]+:\s+(.*?)\n/gxms ];
    }

    my @untracked = split /Untracked files:\n/, $status;
    if ( @untracked > 1 ) {
        my $untracked = pop @untracked;
        if ($untracked =~ s/^\s+[(]use \s+ "git \s+ add \s+ [^"]+" \s+ [^)]+\)\n\n//xms) {
            chomp $untracked;
        }
        else {
            $untracked =~ s/^[#].*?\n//gxms;
        }

        if ($untracked =~ /^[#]/xms) {
            $status{untracked} = [ grep {$_} map {chomp; $_} split /\n?[#]\s+/, $untracked ];
        }
        else {
            $status{untracked} = [ $untracked =~ /^\t(.*?)\n/gxms ];
        }
    }

    if ($status =~ /
        You \s+ have \s+ unmerged \s+ paths[.]$
        |
        All \s+ conflicts \s+ fixed \s+ but \s+ you \s+ are \s+ still \s+ merging[.]$
    /xms) {
        $status{merge} = 1;
    }

    return \%status;
}

sub checkout {
    my ($self, $dir, @extra) = @_;
    my $name = '';
    if ( -f $dir ) {
        $name = path($dir)->absolute->basename;
    }
    local $CWD = -f $dir ? path($dir)->absolute->parent : path($dir)->absolute;
    my $extra = join ' ', @extra;
    `$exe checkout $extra $name`;

    return;
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Git - The Git plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Git version 0.6.8.

=head1 SYNOPSIS

   use VCS::Which::Plugin::Git;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

The plugin for the Git version control system

=head1 SUBROUTINES/METHODS

=head3 C<installed ()>

Return: bool - True if the Git is installed

Description: Determines if Git is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this Git

Description: Determines if the directory is under version control of this Git

=head3 C<uptodate ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory has no uncommitted changes

Description: Determines if the directory has no uncommitted changes

=head3 C<cat ( $file[, $revision] )>

Param: C<$file> - string - The name of the file to cat

Param: C<$revision> - string - The revision to get. If the revision is negative
it refers to the number of revisions old is desired. Any other value is
assumed to be a version control specific revision. If no revision is specified
the most recent revision is returned.

Return: The file contents of the desired revision

Description: Gets the contents of a specific revision of a file.

=head3 C<log ( @args )>

TO DO: Body

=head3 C<versions ( [$file], [@args] )>

Description: Gets all the versions of $file

=head3 C<pull ( [$dir] )>

Description: Pulls or updates the directory $dir to the newest version

=head3 C<push ( [$dir] )>

Description: push updates to the master repository

=head3 C<status ( $dir )>

Description: push updates to the master repository

=head3 C<checkout ( [$dir] )>

Checkout clean copy of C<$file>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
