package Test::XTFiles;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Class::Tiny 1;

use XT::Files;

#
# CLASS METHODS
#

sub BUILD {
    my ( $self, $args ) = @_;

    @{ $self->{_files} } = XT::Files->instance->files;

    return;
}

#
# OBJECT METHODS
#

sub all_executable_files {
    my ($self) = @_;

    my @files = map { $_->name } grep { $_->is_script } $self->files;
    return @files;
}

sub all_files {
    my ($self) = @_;

    my @files = map { $_->name } $self->files;
    return @files;
}

sub all_module_files {
    my ($self) = @_;

    my @files = map { $_->name } grep { $_->is_module } $self->files;
    return @files;
}

sub all_perl_files {
    my ($self) = @_;

    my @files = map { $_->name } grep { $_->is_script || $_->is_module || $_->is_test } $self->files;
    return @files;
}

sub all_pod_files {
    my ($self) = @_;

    my @files = map { $_->name } grep { $_->is_pod } $self->files;
    return @files;
}

sub all_test_files {
    my ($self) = @_;

    my @files = map { $_->name } grep { $_->is_test } $self->files;
    return @files;
}

sub files {
    my ($self) = @_;

    my @files = sort @{ $self->{_files} };
    return @files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::XTFiles - standard interface for author tests to find files to check

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    use Test::XTFiles;

    my @files = Test::XTFiles->new->all_module_files;

=head1 DESCRIPTION

Author tests often iterate over the files of a distribution to check them.
L<XT::Files> is a standard interface that allows the author test to ask the
distribution for all the files of a type, instead of guessing which files
to check.

=head1 USAGE

=head2 all_executable_files

Returns a list of all the Perl scripts that should be tested. This includes
tests, if the distribution added them. You should test them as you test Perl
scripts.

This list can be useful for tests that test things like execute permission or
the shebang line.

=head2 all_files

Returns all files that should be tested. A typical use case would be to test
all files that contain Pod documentation as Pod can be, but doesn't have to
be, included in scripts, modules, tests and, of course, pod files.

    # all files with Pod in it
    use Pod::Simple::Search;
    my @files = grep { Pod::Simple::Search->new->contains_pod($_) }
        Test::XTFiles->new->all_files;

=head2 all_module_files

Returns a list of all Perl modules that should be tested.

Before using this method make sure that you really want to test only modules.
Most tests should run against modules and scripts. It's often better to use
the C<all_perl_files> method instead.

=head2 all_perl_files

Returns a list of all Perl files that should be tested. That includes
modules, scripts and, if the distribution added them, tests. Most author
tests should probably iterate over this list.

=head2 all_pod_files

Returns a list of all Pod files. These are the files that end in C<.pod>.
This list does not contain script or modules that include a Pod documentation.

It's probably better to use the C<all_files> method and check which files
contain Pod.

=head2 all_test_files

Returns a list of all C<.t> files to be tested, if added by the distribution.

=head2 files

Returns a list of all files to be tested as L<XT::Files::File> objects.

=head1 SEE ALSO

L<XT::Files>, L<XT::Files::File>

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
