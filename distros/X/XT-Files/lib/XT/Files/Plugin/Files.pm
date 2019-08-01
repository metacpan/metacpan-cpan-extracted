package XT::Files::Plugin::Files;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'XT::Files::Plugin';

sub run {
    my ( $self, $args ) = @_;

    my @files;

  ARG:
    for my $arg ( @{$args} ) {
        my ( $key, $value ) = @{$arg};

        if ( ( $key eq 'bin' ) || ( $key eq 'module' ) || ( $key eq 'pod' ) || ( $key eq 'test' ) ) {
            push @files, $arg;
            next ARG;
        }

        $self->log_fatal("Invalid configuration option '$key = $value' for plugin 'Files'");
    }

    my $xtf = $self->xtf;

  FILE:
    for my $file (@files) {
        my ( $type, $name ) = @{$file};

        next FILE if -l $name || -d _ || !-e _;

        if ( $type eq 'bin' ) {
            $xtf->bin_file($name);
            next FILE;
        }

        if ( $type eq 'module' ) {
            $xtf->module_file($name);
            next FILE;
        }

        if ( $type eq 'pod' ) {
            $xtf->pod_file($name);
            next FILE;
        }

        if ( $type eq 'test' ) {
            $xtf->test_file($name);
            next FILE;
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files::Plugin::Files - plugin to add files to be tested

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

In the L<XT::Files> config file:

    [Files]
    bin = maint/cleanup.pl
    module = maint/cleanup_helper.pm
    pod = contributing.pod
    test = maint/hello.t

=head1 DESCRIPTION

Adds some files to L<XT::Files> to be tested by author tests. use this to add
single files. To recursively add while directories, the
L<XT::Files::Plugin::Dirs> plugin is better suited.

The following options are supported:

=over 4

=item * bin

Adds the files as Perl scripts to the list of files to be tested.

=item * module

Adds the file as Perl module to the list of files to be tested.

=item * pod

Adds the file as Pod file to the list of files to be tested.

=item * test

Adds the file as Perl script and as Perl test to the list of files to be
tested.

=back

Note: The file extension for all files is ignored. This differs from the
L<XT::Files::Plugin::Dirs> plugin.

=head1 USAGE

=head2 new

Inherited from L<XT::Files::Plugin>.

=head2 run

The C<run> method should not be run directly. Use the C<plugin> call from
L<XT::Files>

=head1 SEE ALSO

L<XT::Files>, L<XT::Files::Plugin>, L<XT::Files::Plugin::Dirs>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/XT-Files/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/XT-Files>

  git clone https://github.com/skirmess/XT-Files.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
