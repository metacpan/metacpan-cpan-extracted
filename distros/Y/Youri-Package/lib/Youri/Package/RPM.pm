# $Id$
package Youri::Package::RPM;

=head1 NAME

Youri::Package::RPM - Base class for all RPM-based package implementation

=head1 DESCRIPTION

This bases class factorize code between various RPM-based package
implementation.

=cut

use strict;
use warnings;
use base 'Youri::Package';
use version; our $VERSION = qv('0.2.1');
use Carp;
use UNIVERSAL::require;

=head2 get_wrapper_class

Returns the name of a class corresponding to currently available perl RPM
bindings:

=over

=item C<Youri::Package::RPM::RPM4> if RPM4 is available

=item C<Youri::Package::RPM::RPM> if RPM is available

=item C<Youri::Package::RPM::URPM> if URPM is available

=back

This allow to write binding-independant code, by using
methods of this class instead of using bindings-specific
functions.

=over

=item set_verbosity

=item install_srpm

=item add_macro

=item expand_macro

=item new_header

=item new_spec

=item new_transaction

=back

=head2 set_verbosity

This method calls underlying binding corresponding function.

=head2 install_srpm

This method calls underlying binding corresponding function.

=head2 add_macro

This method calls underlying binding corresponding function.

=head2 expand_macro

This method calls underlying binding corresponding function.

=head2 new_header

This method calls the constructor of the underlying binding Header class.

=head2 new_spec

This method calls the constructor of the underlying binding Spec class.

=head2 new_transaction

This method calls the constructor of the underlying binding Transaction class.

=cut

sub get_wrapper_class {
    if (RPM4->require()) {
        Youri::Package::RPM::RPM4->require();
        return 'Youri::Package::RPM::RPM4';
    }

    if (RPM->require()) {
        Youri::Package::RPM::RPM->require();
        return 'Youri::Package::RPM::RPM';
    }

    if (URPM->require()) {
        Youri::Package::RPM::URPM->require();
        return 'Youri::Package::RPM::URPM';
    }

    croak "No RPM bindings available";
}

sub get_pattern {
    my ($class, $name, $version, $release, $arch) = @_;

    return $class->get_unquoted_pattern(
        $name ? quotemeta($name) : undef,
        $version ? quotemeta($version) : undef,
        $release ? quotemeta($release) : undef,
        $arch ? quotemeta($arch) : undef
    );
}

sub get_unquoted_pattern {
    my ($class, $name, $version, $release, $arch) = @_;

    return 
        ($name ? $name : '[\w-]+' ).
        '-' .
        ($version ? $version : '[^-]+' ).
        '-' .
        ($release ? $release : '[^-]+' ). 
        '\.' .
        ($arch ? $arch : '\w+' ).
        '\.rpm';
}

sub as_file {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_file};
}

sub is_debug {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $name = $self->get_name();
    my $group = $self->get_tag('group');

    # debug packages names must end in -debug or -debuginfo or -debugsource
    return 
        $group eq 'Development/Debug' &&
        ($name =~ /-debug$/ || $name =~ /-debuginfo$/ || $name =~ /-debugsource$/);
}

1;
