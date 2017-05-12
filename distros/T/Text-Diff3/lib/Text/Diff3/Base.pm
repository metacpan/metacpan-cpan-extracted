package Text::Diff3::Base;
use 5.006;
use strict;
use warnings;

use version; our $VERSION = '0.08';

__PACKAGE__->mk_attr_accessor('factory');

sub new {
    my($class, @arg) = @_;
    my $self = bless {}, $class;
    $self->initialize(@arg);
    return $self;
}

sub initialize {
    my($self, $f) = @_;
    $self->factory($f);
    return $self;
}

sub mk_attr_accessor {
    my($class, @fields) = @_;
    $class = ref $class ? ref $class : $class;
    for my $field (@fields) {
        my $accessor = $class->_accessor($field);
        no strict 'refs';
        *{"${class}::${field}"} = $accessor;
    }
    return;
}

sub _accessor {
    my($class, $field) = @_;
    return sub{
        my($self, @arg) = @_;
        if (@arg) {
            $self->{$field} = $arg[0];
        }
        return $self->{$field};
    };
}

1;

__END__

=pod

=head1 NAME

Text::Diff3::Base - Text::Diff3 component's base class

=head1 VERSION

0.08

=head1 SYNOPSIS

    package Text::Diff3::COMPONENT;
    use base qw(Text::Diff3::Base);
    
    __PACKAGE__->mk_attr_accessor(qw(attr1_name attr2_name));

=head1 DESCRIPTION

This module is the base class for all Text::Diff3 components.

=head1 METHODS

=over

=item C<< $factory_name->new($factory_name => @arg) >>

creates an instance of COMPONENT with the initialize method.

=item C<< $component->factory >>

is an attribute to hold factory class name.

=item C<< $component->initialize($factory_name => @arg) >>

is the default initializer for components.
This sets passed name into the factory attribute.

=item C<< $component->mk_attr_accessor(qw(attr1_name attr2_name)) >>

declares attribute accessors in package.

=back

=head1 COMPATIBILITY

Use new function style interfaces introduced from version 0.08.
This module remained for backward compatibility before version 0.07.
This module is no longer maintenance after version 0.08.

=head1 AUTHOR

MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 MIZUTANI Tociyuki

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

=cut

