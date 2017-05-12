# $Id: /mirror/youri/soft/Media/trunk/lib/Youri/Media.pm 2367 2007-04-22T18:47:34.552172Z guillomovitch  $
package Youri::Media;

=head1 NAME

Youri::Media - Abstract media class

=head1 DESCRIPTION

This abstract class defines Youri::Media interface.

=cut

use Carp;
use strict;
use warnings;
use version; our $VERSION = qv('0.2.1');

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Media object.

Generic parameters:

=over

=item id $id

Media id.

=item name $name

Media name.

=item type $type (source/binary)

Media type.

=item test true/false

Test mode (default: false).

=item verbose true/false

Verbose mode (default: false).

=item options $options

Hash of test-specific options.

=item skip_tests $tests

List of tests to skip.

=item skip_archs $arches

List of arches to skip.

=back

Subclass may define additional parameters.

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        name           => '',    # media name
        canonical_name => '',    # media canonical name
        type           => '',    # media type
        test           => 0,     # test mode
        verbose        => 0,     # verbose mode
        options        => undef,
        @_
    );


    croak "No type given" unless $options{type};
    croak "Wrong value for type: $options{type}"
        unless $options{type} =~ /^(?:binary|source)$/;

    # some options need to be arrays. Check it and convert to hashes
    foreach my $option (qw(skip_archs skip_tests)) {
        next unless defined $options{$option};
        croak "$option should be an arrayref"
            unless ref $options{$option} eq 'ARRAY';
        $options{$option}  = {
            map { $_ => 1 } @{$options{$option}}
        };
    }

    croak "options should be an hashref"
        if $options{options} && ref $options{options} ne 'HASH';

    my $self = bless {
        _id         => $options{id}, 
        _verbose    => $options{verbose}, 
        _name       => $options{name} || $options{id}, 
        _type       => $options{type}, 
        _options    => $options{options}, 
        _skip_archs => $options{skip_archs},
        _skip_tests => $options{skip_tests},
    }, $class;

    $self->_init(%options);

    # remove unwanted archs
    if ($options{skip_archs}->{all}) {
        $self->_remove_all_archs()
    } elsif ($options{skip_archs}) {
        $self->_remove_archs($options{skip_archs});
    }

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 get_id()

Returns media identity.

=cut

sub get_id {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_id};
}

=head2 get_name()

Returns the name of this media.

=cut

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_name};
}

=head2 get_type()

Returns the type of this media.

=cut

sub get_type {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_type};
}

=head2 get_option($test, $option)

Returns a specific option for given test.

=cut

sub get_option {
    my ($self, $test, $option) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_options}->{$test}->{$option};
}

=head2 skip_archs()

Returns the list of arch which are to be skipped for this media.

=cut

sub skip_archs {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return keys %{$self->{_skip_archs}};
}

=head2 skip_arch($arch)

Tells wether given arch is to be skipped for this media.

=cut

sub skip_arch {
    my ($self, $arch) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_skip_archs}->{all} ||
        $self->{_skip_archs}->{$arch};
}

=head2 skip_tests()

Returns the list of id of test which are to be skipped for this media.

=cut

sub skip_tests {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return keys %{$self->{_skip_tests}};
}

=head2 skip_test($test_id)

Tells wether test with given id is to be skipped for this media.

=cut

sub skip_test {
    my ($self, $test) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_skip_tests}->{all} ||
        $self->{_skip_tests}->{$test};
}

=head2 get_package_class()

Return package class for this media.

=head2 traverse_files($function)

Apply given function to all files of this media.

=head2 traverse_headers($function)

Apply given function to all headers, partially parsed, of this media.

=head2 traverse_full_headers($function)

Apply given function to all headers, fully parsed, of this media.

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item traverse_headers

=item traverse_full_headers

=item traverse_files

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
