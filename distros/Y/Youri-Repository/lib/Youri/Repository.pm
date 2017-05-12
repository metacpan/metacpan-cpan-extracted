# $Id: /mirror/youri/soft/Repository/trunk/lib/Youri/Repository.pm 2230 2007-03-05T21:32:43.256766Z guillomovitch  $
package Youri::Repository;

=head1 NAME

Youri::Repository - Abstract repository

=head1 DESCRIPTION

This abstract class defines Youri::Repository interface.

=cut

use warnings;
use strict;
use Carp;
use File::Basename;
use Youri::Package;
use version; our $VERSION = qv('0.1.0');

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Repository object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        install_root  => '', # path to top-level directory
        archive_root  => '', # path to top-level directory
        version_root  => '', # path to top-level directory
        test          => 0,  # test mode
        verbose       => 0,  # verbose mode
        @_
    );


    croak "no install root" unless $options{install_root};
    croak "invalid install root" unless -d $options{install_root};

    my $self = bless {
        _install_root  => $options{install_root},
        _archive_root  => $options{archive_root},
        _version_root  => $options{version_root},
        _test          => $options{test},
        _verbose       => $options{verbose},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 get_package_class()

Return package class for this repository.

=cut

sub get_package_class {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_package_class};
}

=head2 get_package_charset()

Return package charset for this repository.

=cut

sub get_package_charset {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_package_charset};
}

=head2 get_extra_arches()

Return the list of additional archictectures to handle when dealing with noarch
packages.

=cut

sub get_extra_arches {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return @{$self->{_extra_arches}};
}


=head2 get_older_revisions($package, $target, $user_context, $app_context)

Get all older revisions from a package found in its installation directory, as a
list of L<Youri::Package> objects.

=cut

sub get_older_revisions {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package older revisions for $target\n"
        if $self->{_verbose} > 0;

    return $self->get_revisions(
        $package,
        $target,
        $user_context,
        $app_context,
        sub { return $package->compare($_[0]) > 0 }
    );
}

=head2 get_last_older_revision($package, $target, $user_context, $app_context)

Get last older revision from a package found in its installation directory, as a
single L<Youri::Package> object.

=cut

sub get_last_older_revision {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package last older revision for $target\n"
        if $self->{_verbose} > 0;

    return (
        $self->get_older_revisions(
            $package,
            $target,
            $user_context,
            $app_context
        )
    )[0];
}

=head2 get_newer_revisions($package, $target, $user_context, $app_context)

Get all newer revisions from a package found in its installation directory, as
a list of L<Youri::Package> objects.

=cut

sub get_newer_revisions {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package newer revisions for $target\n"
        if $self->{_verbose} > 0;

    return $self->get_revisions(
        $package,
        $target,
        $user_context,
        $app_context,
        sub { return $_[0]->compare($package) > 0 }
    );
}


=head2 get_revisions($package, $target, $user_context, $app_context, $filter)

Get all revisions from a package found in its installation directory, using an
optional filter, as a list of L<Youri::Package> objects.

=cut

sub get_revisions {
    my ($self, $package, $target, $user_context, $app_context, $filter) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package revisions for $target\n"
        if $self->{_verbose} > 0;

    my @packages = 
        map { $self->get_package_class()->new(file => $_) }
        $self->get_files(
            $self->{_install_root},
            $self->get_install_path(
                $package,
                $target,
                $user_context,
                $app_context
            ),
            $self->get_package_class()->get_pattern(
                $package->get_name(),
                undef,
                undef,
                $package->get_arch(),
            )
        );

    @packages = grep { $filter->($_) } @packages if $filter;

    return
        sort { $b->compare($a) } # sort by revision order
        @packages;
}

=head2 get_obsoleted_packages($package, $target, $user_context, $app_context)

Get all packages obsoleted by given one, as a list of L<Youri::Package>
objects.

=cut

sub get_obsoleted_packages {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for packages obsoleted by $package for $target\n"
        if $self->{_verbose} > 0;

    my @packages;
    foreach my $obsolete ($package->get_obsoletes()) {
        my $pattern = $self->get_package_class()->get_pattern(
            $obsolete->get_name()
        );
        my $range = $obsolete->get_range();
        push(@packages,
            grep { $range ? $_->satisfy_range($range) : 1 } 
            map { $self->get_package_class()->new(file => $_) }
            $self->get_files(
                $self->{_install_root},
                $self->get_install_path(
                    $package, $target,
                    $user_context,
                    $app_context
                ),
                $pattern
            )
        );
    }

    return @packages;
}

=head2 get_replaced_packages($package, $target, $user_context, $app_context)

Get all packages replaced by given one, as a list of L<Youri::Package>
objects.

=cut

sub get_replaced_packages {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for packages replaced by $package for $target\n"
        if $self->{_verbose} > 0;

    my @list;

    # collect all older revisions
    push(@list, $self->get_older_revisions(
        $package,
        $target,
        $user_context,
        $app_context
    ));

    # noarch packages are potentially linked from other directories
    if ($package->get_arch() eq 'noarch') {
        foreach my $arch ($self->get_extra_arches()) {
            push(@list, $self->get_older_revisions(
                $package,
                $target,
                $user_context,
                { arch => $arch }
            ));
        }
    }

    # collect all obsoleted packages
    push(@list, $self->get_obsoleted_packages(
        $package,
        $target,
        $user_context,
        $app_context
    ));

    return @list;
}

=head2 get_files($path, $pattern)

Get all files found in a directory, using an optional filtering pattern
(applied to the whole file name), as a list of files.

=cut

sub get_files {
    my ($self, $root, $path, $pattern) = @_;
    croak "Not a class method" unless ref $self;

    my @files;
    my $dir = "$root/$path";
    $pattern = '.*' unless defined $pattern;
    my $comp_pattern = qr/^$pattern$/;

    print "Looking for files matching $pattern in $root/$path\n"
        if $self->{_verbose} > 1;

    opendir(my $dh, $dir) or die "Can't open $dir: $!";
    while (my $file = readdir($dh)) {
        next unless $file =~ $comp_pattern;
        $file = "$dir/$file";
        next unless -f $file;
        push(@files, $file);
    }
    closedir($dh);

    return @files;
}

=head2 get_install_root()

Returns installation root

=cut

sub get_install_root {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_install_root};
}

=head2 get_install_dir($package, $target, $user_context, $app_context)

Returns install destination directory for given L<Youri::Package> object
and given target.

=cut

sub get_install_dir {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;

    return $self->_get_dir(
        $self->{_install_root},
        $self->get_install_path($package, $target, $user_context, $app_context)
    );
}

=head2 get_archive_root()

Returns archiving root

=cut

sub get_archive_root {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_archive_root};
}

=head2 get_archive_dir($package, $target, $user_context, $app_context)

Returns archiving destination directory for given L<Youri::Package> object
and given target.

=cut

sub get_archive_dir {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;

    return $self->_get_dir(
        $self->{_archive_root},
        $self->get_archive_path($package, $target, $user_context, $app_context)
    );
}


=head2 get_version_root()

Returns versionning root

=cut

sub get_version_root {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_version_root};
}

=head2 get_version_dir($package, $target, $user_context, $app_context)

Returns versioning destination directory for given L<Youri::Package>
object and given target.

=cut

sub get_version_dir {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;

    return $self->_get_dir(
        $self->{_version_root},
        $self->get_version_path($package, $target, $user_context, $app_context)
    );
}

sub _get_dir {
    my ($self, $root, $path) = @_;

    return substr($path, 0, 1) eq '/' ?
        $path :
        $root . '/' . $path;
}

=head2 get_install_file($package, $target, $user_context, $app_context)

Returns install destination file for given L<Youri::Package> object and
given target.

=cut

sub get_install_file {
    my ($self, $package, $target, $user_context, $app_context) = @_;
    croak "Not a class method" unless ref $self;

    return 
        $self->get_install_dir($package, $target, $user_context, $app_context) .
        '/' .
        $package->get_file_name();
}

=head2 get_install_path($package, $target, $user_context, $app_context)

Returns installation destination path (relative to repository root) for given
L<Youri::Package> object and given target.

=head2 get_archive_path($package, $target, $user_context, $app_context)

Returns archiving destination path (relative to repository root) for given
L<Youri::Package> object and given target.

=head2 get_version_path($package, $target, $user_context, $app_context)

Returns versioning destination path (relative to repository root) for given
L<Youri::Package> object and given target.

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item get_install_path

=item get_archive_path

=item get_version_path

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
