package VCS::Which::Plugin::Subversion;

# Created on: 2009-05-16 16:58:03
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

our $VERSION = version->new('0.6.6');
our $name    = 'Subversion';
our $exe     = 'svn';
our $meta    = '.svn';

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

    return -d "$dir/$meta";
}

sub uptodate {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    my @lines = `$exe status`;
    pop @lines;

    return !@lines;
}

sub pull {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    return !system "$exe update > /dev/null 2> /dev/null";
}

sub cat {
    my ($self, $file, $revision) = @_;

    if ( $revision && $revision =~ /^-\d+$/xms ) {
        my @versions = reverse `$exe log -q $file` =~ /^ r(\d+) \s/gxms;
        $revision = $versions[$revision];
    }
    elsif ( !defined $revision ) {
        $revision = '';
    }

    $revision &&= "-r$revision";

    return `$exe cat $revision $file`;
}

sub log {
    my ($self, @args) = @_;

    my $args = join ' ', map {"'$_'"} @args;

    return
        SCALAR   { scalar `$exe log $args` }
        ARRAYREF {
            my @raw_log = `$exe log $args`;
            my @log;
            my $line = '';
            for my $raw (@raw_log) {
                if ( $raw eq ( '-' x 72 ) . "\n"  && $line ) {
                    CORE::push @log, $line;
                    $line = '';
                }
                elsif ( $raw ne ( '-' x 72 ) . "\n"  ) {
                    $line .= $raw;
                }

            }
            return \@log;
        }
        HASHREF  {
            my $logs = `$exe log $args`;
            my @logs = split /^-+\n/xms, $logs;
            shift @logs;
            my $num = @logs;
            my %log;
            for my $log (@logs) {
                my ($details, $description) = split /\n\n?/, $log, 2;
                $description =~ s/\s+\Z//xms;
                $details =~ s/^\s*(.*?)\s*/$1/;
                my @details = split /\s+\|\s+/, $details;
                $details[0] =~ s/^r//;
                $log{$num--} = {
                    rev    => $details[0],
                    Author => $details[1],
                    Date   => $details[2],
                    description => $description,
                },
            }
            return \%log;
        }
}

sub versions {
    my ($self, $file, $oldest, $newest, $max) = @_;

    $file = path($file);
    local $CWD = -d $file ? $file : $file->parent;
    my %logs = %{ $self->log(-d $file ? '.' : $file->basename, $max ? "--limit $max" : '') };
    my @versions;

    for my $log (sort {$a <=> $b} keys %logs) {
        push @versions, $logs{$log}{rev};# if $oldest && $logs{$log}{rev} <= $oldest;
    }

    return @versions;
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Subversion - The Subversion plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Subversion version 0.6.6.

=head1 SYNOPSIS

   use VCS::Which::Plugin::Subversion;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

Plugin to provide access to the Subversion version control system

=head1 SUBROUTINES/METHODS

=head3 C<installed ()>

Return: bool - True if the Subversion is installed

Description: Determines if Subversion is actually installed and usable

=head3 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this Subversion

Description: Determines if the directory is under version control of this Subversion

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
