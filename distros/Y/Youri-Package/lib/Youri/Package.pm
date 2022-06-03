# $Id$
package Youri::Package;

=head1 NAME

Youri::Package - Abstract package class

=head1 DESCRIPTION

This abstract class defines Youri::Package interface.

=cut

use strict;
use warnings;
use version; our $VERSION = qv('0.2.9');

use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package object.

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        @_
    );

    my $self = bless {
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head2 get_pattern($name, $version, $release, $arch)

Returns a pattern matching a file for a package, using available informations.
All meta characters in arguments are quoted.

=head2 get_unquoted_pattern($name, $version, $release, $arch)

Returns a pattern matching a file for a package, using available informations.
Meta characters in arguments are not quoted.

=head2 compare_revisions($revision1, $revision2)

Compares two revision tokens, and returns a numeric value:

=over

=item positive if first revision is higher

=item null if both revisions are equal

=item negative if first revision is lower

=back

=head2 check_ranges_compatibility($range1, $range2)

Returns a true value if given revision ranges are compatible.

=head1 INSTANCE METHODS

=head2 as_file()

Returns the file corresponding to this package.

=head2 as_string()

Returns a string representation of this package.

=head2 as_formated_string(I<format>)

Returns a string representation of this package, formated according to
I<format>. Format is a string, where each %{foo} token will get replaced by
equivalent tag value.

=head2 get_name()

Returns the name of this package.

=head2 get_version()

Returns the version of this package.

=head2 get_release()

Returns the release of this package.

=head2 get_revision()

Returns the revision of this package.

=head2 get_arch()

Returns the architecture of this package.

=head2 get_file_name()

Returns the file name of this package (name-version-release.arch.extension).

=head2 is_source()

Returns true if this package is a source package.

=head2 is_binary()

Returns true if this package is a binary package.

=head2 is_debug()

Returns true if this package is a debug package.

=head2 get_type()

Returns the type (binary/source) of this package.

=head2 get_age()

Returns the age of this package

=head2 get_url()

Returns the URL of this package

=head2 get_summary()

Returns the summary of this package

=head2 get_description()

Returns the description of this package

=head2 get_packager()

Returns the packager of this package.

=head2 get_source_package()

Returns the name of the source package of this package.

=head2 get_tag($tag)

Returns the value of tag $tag of this package.

=head2 get_canonical_name()

Returns the canonical name of this package, shared by its multiple components,
usually the one from the source package.

=head2 get_canonical_revision()

Returns the canonical revision of this package, shared by its multiple components,
usually the one from the source package.

=head2 get_requires()

Returns the list of dependencies required by this package, as an array of
L<Youri::Package::Relationship> objects.

=head2 get_provides()

Returns the list of dependencies provided by this package, as an array of
L<Youri::Package::Relationship> objects.

=head2 get_obsoletes()

Returns the list of other packages obsoleted by this one, as an array of
L<Youri::Package::Relationship> objects.

=head2 get_conflicts()

Returns the list of other packages conflicting with this one, as an array of
L<Youri::Package::Relationship> objects.

=head2 get_files()

Returns the list of files contained in this package, as an array of
L<Youri::Package::File> objects.

=head2 get_gpg_key()

Returns the gpg key id of package signature.

=head2 get_information()

Returns formated informations about the package.

=head2 get_changes()

Returns the list of changes for this package, as an array of
L<Youri::Package::Change> objects.

=head2 get_last_change()

Returns the last change for this package, as as structure described before.

=head2 compare($package)

Compares ordering with other package, according to their corresponding revision
tokens, and returns a numeric value:

=over

=item positive if this package is newer

=item null if both have same revision

=item negative if this package is older

=back

=head2 satisfy_range($range)

Returns a true value if this package revision satisfies given revision range.

=head2 sign($name, $path, $passphrase)

Signs the package with given name, keyring path and passphrase.

=head2 extract()

Extract package content in local directory.

=head1 SUBCLASSING

All instances methods have to be implemented.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head2 get_file()

Deprecated in favor of as_file().

=cut

sub get_file {
    my ($self) = @_;
    carp "Deprecated method, use as_file() now";

    return $self->as_file();
}

=head2 get_full_name()

Deprecated in favor of as_string().

=cut

sub get_full_name {
    my ($self) = @_;
    carp "Deprecated method, use as_string now";

    return $self->as_string();
}

=head2 compare_versions($version1, $version2)

Deprecated in favor of compare_revisions().

=cut

sub compare_versions {
    my ($self, $version1, $version2) = @_;
    carp "Deprecated method, use compare_revisions now";

    return $self->compare_revisions($version1, $version2);
}

=head2 compare_ranges($version1, $version2)

Deprecated in favor of check_ranges_compatibility().

=cut

sub compare_ranges {
    my ($self, $range1, $range2) = @_;
    carp "Deprecated method, use check_ranges_compatibility now";

    return $self->check_ranges_compatibility($range1, $range2);
}

=head2 get_revision_name()

Deprecated in favor of as_formated_string() with proper format string.

=cut

sub get_revision_name {
    my ($self) = @_;
    carp "Deprecated method, use as_formated_string('%{name}-%{version}-%{release}') now";

    return $self->as_formated_string('%{name}-%{version}-%{release}');
}

=head2 get_information()

Deprecated in favor of as_formated_string() with proper pattern.

=cut

sub get_information {
    my ($self) = @_;
    carp "Deprecated method, use as_formated_string() with proper format string now";

    return $self->as_formated_string(<<EOF);
Name        : %-27{NAME}  Relocations: %|PREFIXES?{[%{PREFIXES} ]}:{(not relocatable)}|
Version     : %-27{VERSION}       Vendor: %{VENDOR}
Release     : %-27{RELEASE}   Build Date: %{BUILDTIME:date}
Install Date: %|INSTALLTIME?{%-27{INSTALLTIME:date}}:{(not installed)         }|      Build Host: %{BUILDHOST}
Group       : %-27{GROUP}   Source RPM: %{SOURCERPM}
Size        : %-27{SIZE}%|LICENSE?{      License: %{LICENSE}}|
Signature   : %|DSAHEADER?{%{DSAHEADER:pgpsig}}:{%|RSAHEADER?{%{RSAHEADER:pgpsig}}:{%|SIGGPG?{%{SIGGPG:pgpsig}}:{%|SIGPGP?{%{SIGPGP:pgpsig}}:{(none)}|}|}|}|
%|PACKAGER?{Packager    : %{PACKAGER}\n}|%|URL?{URL         : %{URL}\n}|Summary     : %{SUMMARY}
Description :\n%{DESCRIPTION}
EOF
}


1;
