package VCS::Which::Plugin::Bazaar;

# Created on: 2009-05-16 16:58:36
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

our $VERSION = version->new('0.6.9');
our $name    = 'Bazaar';
our $exe     = 'bzr';
our $meta    = '.bzr';

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

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    my $ans = `$exe status`;

    return $ans ? 0 : 1;
}

sub pull {
    my ( $self, $dir ) = @_;

    $dir ||= $self->_base;

    croak "'$dir' is not a directory!" if !-e $dir;

    local $CWD = $dir;
    return !system "$exe pull > /dev/null 2> /dev/null";
}

sub cat {
    my ($self, $file, $revision) = @_;

    if ( $revision && $revision =~ /^-\d+$/xms ) {
        my @versions = reverse `$exe log -q $file` =~ /^ revno: \s+ (\d+)/gxms;
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
                if ( $raw eq ( '-' x 60 ) . "\n"  && $line ) {
                    CORE::push @log, $line;
                    $line = '';
                }
                elsif ( $raw ne ( '-' x 60 ) . "\n"  ) {
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
                next if $log =~ /--include-merges/;
                my ($details, $description) = $log =~ /^(.*)\nmessage:\s*(.*)$/xms;
                $description =~ s/\s+\Z//xms;
                if (!defined $details) {
                    warn "Error in reading line:\n$log\n";
                    next;
                }
                my %details = map {split /:\s+/, $_, 2} split /\n/, $details, 5;
                $log{$num--} = {
                    rev    => $details{revno},
                    Author => $details{committer},
                    Date   => $details{timestamp},
                    description => $description,
                },
            }
            return \%log;
        }
}

1;

__END__

=head1 NAME

VCS::Which::Plugin::Bazaar - The Bazaar plugin for VCS::Which

=head1 VERSION

This documentation refers to VCS::Which::Plugin::Bazaar version 0.6.9.

=head1 SYNOPSIS

   use VCS::Which::Plugin::Bazaar;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

This is the plugin for the Bazaar version control system.

=head1 SUBROUTINES/METHODS

=head2 C<name ()>

Return: string - The pretty name for the System

Description: Returns the pretty name for the Bazaar

=head2 C<installed ()>

Return: bool - True if the Bazaar is installed

Description: Determines if Bazaar is actually installed and usable

=head2 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this Bazaar

Description: Determines if the directory is under version control of this Bazaar

=head2 C<uptodate ($dir)>

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
