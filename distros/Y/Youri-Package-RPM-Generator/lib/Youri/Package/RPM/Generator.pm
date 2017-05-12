# $Id: Generator.pm 2386 2013-01-03 20:41:58Z guillomovitch $
package Youri::Package::RPM::Generator;

=head1 NAME

Youri::Package::RPM::Generator - Template-based rpm generator

=head1 DESCRIPTION

This is a rpm package generator, intended to quickly generate real rpm packages
for testing purposes.

=cut

use strict;
use warnings;
use version; our $VERSION = qv('0.1.3');

use Carp;
use English qw/-no_match_vars/;
use File::Temp qw/tempdir/;
use Text::Template;

my %defaults = (
    name    => 'test',
    version => 1,
    release => 1,
    arch    => 'noarch',
    summary => 'test package',
    license => 'free',
    group   => 'testing'
);

my $template = Text::Template->new(TYPE => 'STRING', SOURCE => <<'EOF');
Name:		[% $name %]
Version:	[% $version  %]
Release:	[% $release %]
Summary:	[% $summary %]
License:	[% $license %]
Group:		[% $group %]
[% $url     ? "Url:   $url" : '' %]
[% $buildarch     ? "BuildArch:   $buildarch" : '' %]
BuildRoot:	%{_tmppath}/%{name}-%{version}

%description
[% $description %]

%prep
rm -rf %{buildroot}
%setup -T -c

%build

%install
install -d -m 755 %{buildroot}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)

%changelog
[% $changelog %]
EOF

=head1 CLASS METHODS

=head2 new(%options)

Creates and returns a new Youri::Package::Generator object.

Available parameters:

=over

=item tags $tags

Hashref of tags for created packages.

=back

Default tags values:

=over

=item name    test

=item version 1

=item release 1

=item arch    noarch

=item summary test package

=item license free

=item group   testing

=back

=cut

sub new {
    my ($class, %options) = @_;

    foreach my $tag (qw/name version release summary group license/) {
        $options{tags}->{$tag} ||= $defaults{$tag};
    }

    my $topdir = tempdir(CLEANUP => 0);
    mkdir "$topdir/$_" foreach qw/SPECS BUILD RPMS SRPMS SOURCES tmp/;

    my $spec = "$topdir/SPECS/$options{tags}->{name}.spec";
    open my $fh, '>', $spec  or die "Can't open $spec: $!";

    $template->fill_in(
        DELIMITERS => [ '[% ', ' %]' ],
        HASH       => $options{tags},
        OUTPUT     => $fh
    );
    close $fh;

    my $self = bless {
        _topdir  => $topdir,
        _tags    => $options{tags},
    }, $class;

    return $self;
}

=head1 INSTANCE METHODS

=head2 get_source

Generate the source package, and return the corresponding file.

=cut

sub get_source {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $command = sprintf(
        'rpmbuild -bs --define "_topdir %s" %s/SPECS/%s.spec >/dev/null 2>&1',
        $self->{_topdir},
        $self->{_topdir},
        $self->{_tags}->{name}
    );
    my $status = system $command;
    die "Can't execute $command: $ERRNO" if $status;

    my $dir = $self->{_topdir} . '/SRPMS';
    return <$dir/*.rpm>;
}

=head2 get_binaries

Generate the binary packages, and return the corresponding files.

=cut

sub get_binaries {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $dir = $self->{_topdir} . '/RPMS/';
    if ($self->{_tags}->{buildarch}) {
        $dir .= $self->{_tags}->{buildarch};
    } else {
        my $target_cpu = `rpm --eval %_target_cpu`;
        chomp $target_cpu;
        $dir .= $target_cpu;
    }

    mkdir $dir;

    my $command = sprintf(
        'rpmbuild -bb --define "_topdir %s" %s/SPECS/%s.spec >/dev/null 2>&1',
        $self->{_topdir},
        $self->{_topdir},
        $self->{_tags}->{name}
    );
    my $status = system $command;
    die "Can't execute $command: $ERRNO" if $status;

    return <$dir/*.rpm>;
}

1;
