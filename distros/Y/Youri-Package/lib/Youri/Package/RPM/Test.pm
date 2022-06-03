# $Id$
package Youri::Package::RPM::Test;

=head1 NAME

Youri::Package::RPM::Test - Fake rpm package implementation

=head1 DESCRIPTION

This is a fake L<Youri::Package> implementation for rpm, intended for testing
purposes.

=cut

use strict;
use warnings;
use base 'Youri::Package::RPM';
use feature qw(switch);
use overload
    '""'     => 'as_string',
    '0+'     => '_to_number',
    fallback => 1;

use Carp;
use File::Basename;
use URPM;

our $AUTOLOAD;

my @tags = qw/
    name
    version
    release
    filename
    arch
    url
    summary
    description
    packager
    buildtime
    sourcerpm
    gpg_key
/;

my %tags = map { $_ => 1 } @tags;

sub check_ranges_compatibility {
    my ($class, $range1, $range2) = @_;

    return URPM::ranges_overlap($range1, $range2);
}

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Package::RPM::Test object.

Specific parameters:

=over

=item file $file

Path of file to use for creating this package.

=item tags $tags

Hahref of tag values

=item requires $requires

Arraryef of package relationships.

=item provides $provides

Arraryef of package relationships.

=item obsoletes $obsoletes

Arraryef of package relationships.

=item conflicts $conflicts

Arraryef of package relationships.

=item files $files

Arraryef of package files.

=item changes $changes

Arraryef of package changes.

=back

=cut

sub _init {
    my ($self, %options) = @_;

    if (exists $options{tags}) {
        $self->{_tags}->{$_} = $options{tags}->{$_}
            foreach keys %{$options{tags}};
    }

    if (exists $options{file}) {
        croak "undefined file"
            unless $options{file};
        croak "non-existing file $options{file}"
            unless -f $options{file};
        croak "non-readable file $options{file}"
            unless -r $options{file};
        my $filename = basename($options{file});
        given ($filename) {
            when (/^([\w-]+)-([^-]+)-([^-]+)\.(\w+)\.rpm$/) {
                # rpm4 style package, with combined dist suffix and release
                $self->{_tags}->{name} = $1;
                $self->{_tags}->{version} = $2;
                $self->{_tags}->{release} = $3;
                $self->{_tags}->{arch} = $4;
                $self->{_file} = $options{file};
            }
            when (/^([\w-]+)-([^-]+)-([^-]+)-([^-]+)\.(\w+)\.rpm$/) {
                # rpm5 style package, with distinct dist suffix and release
                $self->{_tags}->{name} = $1;
                $self->{_tags}->{version} = $2;
                $self->{_tags}->{release} = $3;
                $self->{_tags}->{arch} = $5;
                $self->{_file} = $options{file};
            }
            default {
                croak "non-compliant filename $filename";
            }
        }
    }

    $self->{_requires}  = $options{requires};
    $self->{_provides}  = $options{provides};
    $self->{_obsoletes} = $options{obsoletes};
    $self->{_conflicts} = $options{conflicts};
    $self->{_files}     = $options{files};
    $self->{_changes}   = $options{changes};

    # default values
    $self->{_tags}->{name}    ||= 'test';
    $self->{_tags}->{arch}    ||= 'noarch';
    $self->{_tags}->{version} ||= 1;
    $self->{_tags}->{release} ||= 1;
    $self->{_tags}->{filename} = sprintf(
        '%s-%s-%s.%s.rpm',
        $self->{_tags}->{name},
        $self->{_tags}->{version},
        $self->{_tags}->{release},
        $self->{_tags}->{arch}
    );
}

sub get_revision {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $revision = 
        ($self->{_tags}->{version} || '') . 
        '-' .
        ($self->{_tags}->{release} || '');

    return $self->{_tags}->{epoch} ?
        ($self->{_tags}->{epoch} || '') . ':' . $revision : $revision;
}

sub get_tag {
    my ($self, $tag) = @_;
    croak "Not a class method" unless ref $self;
    croak "invalid tag $tag" unless $tags{$tag};
    return $self->{_tags}->{$tag};
}

sub is_source {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_tags}->{arch} eq 'src';
}

sub is_binary {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_tags}->{arch} ne 'src';
}

sub get_type {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_tags}->{arch} eq 'src' ?
        "source" :
        "binary";
}

sub get_canonical_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    # return name if arch is not defined
    return $self->{_tags}->{name}
        if ! $self->{_tags}->{arch};

    # otherwise return name if arch is source
    return $self->{_tags}->{name}
        if $self->{_tags}->{arch} eq 'src';

    # otherwise return name if sourcerpm is not defined
    return $self->{_tags}->{name}
       if ! $self->{_tags}->{sourcerpm};

    # otherwise source package name
    $self->{_tags}->{sourcerpm} =~ /^(\S+)-[^-]+-[^-]+\.src\.rpm$/;
    return $1;
}

sub get_file_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return 
        $self->as_string() . '.rpm';
}

sub as_string {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return 
        ($self->{_tags}->{name} || '') .
        '-' .
        ($self->{_tags}->{version} || '') . 
        '-' .
        ($self->{_tags}->{release} || '') .
        '.' .
        ($self->{_tags}->{arch} || '');
}

sub as_formated_string {
    my ($self, $format) = @_;
    croak "Not a class method" unless ref $self;

    $format =~ s/%\{([^}]+)\}/$self->{_tags}->{$1}/eg;
    return $format;
}

sub _to_number {
    return refaddr($_[0]);
}

sub get_requires {
    my ($self, $format) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_requires} ? @{$self->{_requires}} : ();
}

sub get_provides {
    my ($self, $format) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_provides} ? @{$self->{_provides}} : ();
}

sub get_obsoletes {
    my ($self, $format) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_obsoletes} ? @{$self->{_obsoletes}} : ();
}

sub get_conflicts {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_conflicts} ? @{$self->{_conflicts}} : ();
}

sub get_files {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_files} ? @{$self->{_files}} : ();
}

sub get_changes {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_changes} ?
        map {
            Youri::Package::Change->new($_->[0], $_->[1], $_->[2])
        } @{$self->{_changes}} :
        ();
}

sub get_last_change {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_changes} ?
        Youri::Package::Change->new(
            $self->{_changes}->[0]->[0],
            $self->{_changes}->[0]->[1],
            $self->{_changes}->[0]->[2]
        ) :
        undef;
}

sub compare {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    return URPM::rpmvercmp($self->get_revision(), $package->get_revision());
}

sub satisfy_range {
    my ($self, $range) = @_;
    croak "Not a class method" unless ref $self;

    return $self->check_ranges_compatibility(
        '== ' . $self->get_revision(),
        $range
    );
}

sub AUTOLOAD {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    croak "invalid method" unless $method =~ /^get_(\w+)$/;

    my $tag = $1;
    return $self->get_tag($1);
}

1;
