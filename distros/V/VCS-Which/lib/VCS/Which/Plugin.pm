package VCS::Which::Plugin;

# Created on: 2009-05-16 17:50:07
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
use File::chdir;

our $VERSION = version->new('0.6.6');

has [qw/_installed _base/] => (
    is => 'rw',
);

sub name {
    my ($self) = @_;
    my $package = ref $self ? ref $self : $self;

    no strict qw/refs/;          ## no critic
    return ${"$package\::name"};
}

sub exe {
    my ($self) = @_;
    my $package = ref $self ? ref $self : $self;

    no strict qw/refs/;          ## no critic
    return ${"$package\::exe"};
}

sub installed {
    my ($self) = @_;

    return die $self->name . ' does not currently implement installed!';
}

sub used {
    my ($self) = @_;

    return die $self->name . ' does not currently implement used!';
}

sub uptodate {
    my ($self) = @_;

    return die $self->name . ' does not currently implement uptodate!';
}

sub exec {
    my ($self, $dir, @args) = @_;

    die $self->name . " not installed\n" if !$self->installed();

    local $CWD = $dir;

    if ($CWD ne $dir) {
        for my $arg (@args) {
            $arg = $CWD if $arg eq $dir;
        }
    }

    my $cmd = $self->exe;
    my $run = join ' ', $cmd, @args;
    return defined wantarray ? `$run` : CORE::exec($run);
}

sub cat {
    my ($self, $file, $revision) = @_;

    my $exe = $self->exe;
    my $rev = $revision ? "-r$revision " : '';

    return `$exe cat $rev$file`;
}

sub pull {
    die '"pull" not implemented for this Version Controll System!';
}

sub push {
    die '"push" not implemented for this Version Controll System!';
}

sub versions {
    my ($self, $file, $oldest, $newest, $max) = @_;

    my %logs = %{ $self->log($file, $max ? "--limit $max" : '') };
    my @versions;

    for my $log (sort {$a <=> $b} keys %logs) {
        CORE::push @versions, $logs{$log}{rev};# if $oldest && $logs{$log}{rev} <= $oldest;
    }

    return @versions;
}

sub add {
    my ($self, $file, $revision) = @_;

    my $exe = $self->exe;
    my $rev = $revision ? "-r$revision " : '';

    return `$exe add $rev$file`;
}

1;

__END__

=head1 NAME

VCS::Which::Plugin - Base class for the various VCS plugins

=head1 VERSION

This documentation refers to VCS::Which::Plugin version 0.6.6.

=head1 SYNOPSIS

   use VCS::Which::Plugin;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

This is the base module for VCS::Which plugins. It is not used directly by
itself. Many of the methods expect package variables to be defined by the
plugin module.

This module is also usually called by L<VCS::Which> and not the plugins
directly as L<VCS::Which> is set up to do the work to determine which plugin
to use.

=head2 PLUGINS

Plugins are expected to define the following variables

=over 4

=item C<our $name>

A pretty name to describe the version control system.

=item C<our $exe>

The executable used by the vcs (eg svn, git etc)

=back

=head1 SUBROUTINES/METHODS

=head2 C<new ()>

Return: VCS::Which::Plugin - A new plugin object

Description: Simple constructor that should be inherited by plugins

=head2 C<name ()>

Return: string - The pretty name for the System

Description: Returns the pretty name for the VCS

=head2 C<exe ()>

Return: string - The name of the executable that is used to run operations
with the appropriate plugin

Description: Returns name of the executable for the appropriate version
control system.

=head2 C<installed ()>

Return: bool - True if the VCS is installed

Description: Determines if VCS is actually installed and usable

=head2 C<used ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory is versioned by this VCS

Description: Determines if the directory is under version control of this VCS

=head2 C<uptodate ($dir)>

Param: C<$dir> - string - Directory to check

Return: bool - True if the directory has no uncommitted changes

Description: Determines if the directory has no uncommitted changes

=head2 C<exec (@params)>

Param: C<@params> - array of strings - The parameters that you wish to pass
on to the vcs program.

Description: Runs a command for the appropriate vcs. In void context it
actually exec()s the command so never returns if the context is scalar or
array backticks are used to run the command and the results are returned to
the caller.

=head3 C<cat ( $file[, $revision] )>

Param: C<$file> - string - The name of the file to cat

Param: C<$revision> - string - The revision to get. If the revision is negative
it refers to the number of revisions old is desired. Any other value is
assumed to be a version control specific revision. If no revision is specified
the most recent revision is returned.

Return: The file contents of the desired revision

Description: Gets the contents of a specific revision of a file. This
implementation works for many version control systems so may not be overloaded
by specific plugins

=head3 C<versions ( [$file], [@args] )>

Description: Gets all the versions of $file

=head3 C<pull ( [$dir] )>

Description: Pulls or updates the directory $dir to the newest version

=head3 C<push ( [$dir] )>

Description: push updates to parent repository must be implemented by plugin

=head3 C<add ( [$file] )>

Add C<$file> to VCS

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
