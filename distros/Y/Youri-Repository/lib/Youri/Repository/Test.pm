# $Id: /local/youri/soft/core/trunk/lib/Youri/Package/RPM/Test.pm 2502 2006-12-02T10:35:40.610312Z guillaume  $
package Youri::Repository::Test;

=head1 NAME

Youri::Repository::Test - Fake test repository implementation

=head1 DESCRIPTION

This is a fake L<Youri::Repository> implementation for, intended for testing
purposes.

=cut

use strict;
use warnings;
use Carp;
use File::Temp qw/tempdir/;
use base 'Youri::Repository';

sub new {
    my $class = shift;
    my %options = (
        cleanup => 1,
        perms   => 755,
        package_class   => 'Youri::Package::RPM::Test',
        @_
    );

    my $dir = tempdir(cleanup => $options{cleanup});
    chmod oct($options{perms}), $dir;

    my $self = $class->SUPER::new(
        install_root => $dir,
        archive_root => $dir,
        version_root => $dir,
    );

    $self->{_package_class}   = $options{package_class};

    return $self;
}

sub get_install_path {
    return '';
}

sub get_archive_path {
    return '';
}

sub get_version_path {
    return '';
}

1;
