package VCS::CMSynergy::ObjectTieHash;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

use base 'VCS::CMSynergy::Object';

use Carp;

my %builtin = map { $_ => 1 } qw( objectname name version cvtype instance );

# TIEHASH(class, { ccm => ..., objectname => ..., ...})
sub TIEHASH
{
    my ($class, $href) = @_;
    return bless $href, $class;
}

sub FETCH
{
    my ($self, $key) = @_;
    return $builtin{$key} ? $self->$key : $self->get_attribute($key);
}

sub STORE
{
    my ($self, $key, $value) = @_;
    carp(__PACKAGE__ . qq[::STORE: pseudo attribute "$key" is read-only]) if $builtin{$key};
    return $self->set_attribute($key, $value);
}

sub EXISTS
{
    my ($self, $key) = @_;
    return $builtin{$key} || defined $self->get_attribute($key);
}

sub FIRSTKEY
{
    my ($self) = @_;
    my $attrs = $self->list_attributes;
    # FIXME are %builtin pseudo attrs shown by "ccm attr -la"? esp. objectname
    $self->_private->{_attrs} = [ keys %$attrs ];
    return pop @{ $self->_private->{_attrs} };
}

sub NEXTKEY
{
    my ($self, $lastkey) = @_;
    return pop @{ $self->_private->{_attrs} };
}


# redefine getter methods and access to private data
{
    package VCS::CMSynergy::Object;

    no warnings 'redefine';

    # access private parts and the only "real" fields via the tied object
    # NOTE why the || below? because in FETCH etc we are NOT tied
    # but otherwise we ARE
    sub ccm        { my $self = shift; (tied %$self || $self)->{ccm}; };
    sub objectname { my $self = shift; (tied %$self || $self)->{objectname}; };
    sub _private   { my $self = shift; tied %$self || $self; }
}


1;
