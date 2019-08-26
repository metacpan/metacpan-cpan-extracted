package XT::Files::Plugin::Dirs;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.002';

use parent 'XT::Files::Plugin';

sub run {
    my ( $self, $args ) = @_;

    my @dirs;

  ARG:
    for my $arg ( @{$args} ) {
        my ( $key, $value ) = @{$arg};

        if ( ( $key eq 'bin' ) || ( $key eq 'module' ) || ( $key eq 'test' ) ) {
            push @dirs, $arg;
            next ARG;
        }

        $self->log_fatal("Invalid configuration option '$key = $value' for plugin 'Dirs'");
    }

    my $xtf = $self->xtf;

    # We sort the dirs because e.g. bin/lib must be scanned before bin
    # because bin_dir() would add every file found.
    #
    # By reverse sorting we guarantee that we always scan the most
    # significant directory first.
  DIR:
    for my $dir ( reverse sort { $a->[1] cmp $b->[1] } @dirs ) {
        my ( $type, $name ) = @{$dir};

        if ( $type eq 'bin' ) {
            $xtf->bin_dir($name);
            next DIR;
        }

        if ( $type eq 'module' ) {
            $xtf->module_dir($name);
            next DIR;
        }

        if ( $type eq 'test' ) {
            $xtf->test_dir($name);
            next DIR;
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files::Plugin::Dirs - plugin to add directories to be tested

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

In the L<XT::Files> config file:

    [Dirs]
    bin = bin
    bin = script
    module = lib
    test = t
    test = xt

=head1 DESCRIPTION

Adds some directories to L<XT::Files> to be tested by author tests. Every
file found in the directory that matches the directory types criteria,
is added, as the specified type.

The files are searched recursive. Symlinks are skipped.

The directories are sorted and processed in reverse order. This allows you to
e.g. add

    bin = maint
    module = maint/lib

and F<maint/lib> will be searched first. Then, when F<maint> is searched all
the files found from F<maint/lib> won't be overwritten, effectively blocking
them from being found as bin.

The following options are supported:

=over 4

=item * bin

Adds all files contained in these directories as Perl scripts to the list of
files to be tested.

=item * module

Adds all files with the C<.pm> extension, contained in these directories, as
module files to the list of files to be tested. Files with the C<.pod>
extension are added as Pod files.

=item * test

Adds all files contained in these directories with the C<.t> extension as
test files.

=back

=head1 USAGE

=head2 new

Inherited from L<XT::Files::Plugin>.

=head2 run

The C<run> method should not be run directly. Use the C<plugin> call from
L<XT::Files>

=head1 SEE ALSO

L<XT::Files>, L<XT::Files::Plugin>, L<XT::Files::Plugin::Default>

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
