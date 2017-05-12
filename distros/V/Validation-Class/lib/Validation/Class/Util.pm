# Utility Functions for Validation Classes

package Validation::Class::Util;

use strict;
use warnings;

our $VERSION = '7.900057'; # VERSION

use Module::Runtime 'use_module';
use Scalar::Util 'blessed';
use Carp 'confess';
use Exporter ();

our @ISA    = qw(Exporter);
our @EXPORT = qw(

    build_args
    build_args_collection
    has
    hold
    isa_arrayref
    isa_classref
    isa_coderef
    isa_hashref
    isa_listing
    isa_mapping
    isa_prototype
    isa_regexp
    prototype_registry

);

sub build_args {

    my $self = shift;

    my $class = ref $self || $self;

    if ( scalar @_ == 1 ) {
        confess
            "The new() method for $class expects single arguments to " .
            "take the form of a hash reference"
            unless defined $_[0] && ref $_[0] eq 'HASH'
        ;
        return {%{$_[0]}};
    }

    elsif ( @_ % 2 ) {
        confess
            "The new() method for $class expects a hash reference or a " .
            "key/value list. You passed an odd number of arguments"
        ;
    }

    else {
        return {@_};
    }

}

sub build_args_collection {

    my $class = shift;

    # Validation::Class::Mapping should already be loaded
    return Validation::Class::Mapping->new($class->build_args(@_));

}

sub has {

    my ( $attrs, $default ) = @_;

    return unless $attrs;

    confess "Error creating accessor, default must be a coderef or constant"
        if ref $default && ref $default ne 'CODE';

    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';

    for my $attr (@$attrs) {

        confess "Error creating accessor '$attr', name has invalid characters"
            unless $attr =~ /^[a-zA-Z_]\w*$/;

        my $code;

        if ( defined $default ) {

            $code = sub {

                if ( @_ == 1 ) {
                    return $_[0]->{$attr} if exists $_[0]->{$attr};
                    return $_[0]->{$attr}
                        = ref $default eq 'CODE'
                        ? $default->( $_[0] )
                        : $default;
                }
                $_[0]->{$attr} = $_[1];
                $_[0];

            };

        }

        else {

            $code = sub {

                return $_[0]->{$attr} if @_ == 1;
                $_[0]->{$attr} = $_[1];
                $_[0];

            };

        }

        no strict 'refs';
        no warnings 'redefine';

        my $class = caller(0);

        *{"$class\::$attr"} = $code;

    }

    return;

}

sub hold {

    my ( $attrs, $default ) = @_;

    return unless $attrs;

    confess "Error creating accessor, default is required and must be a coderef"
        if ref $default ne 'CODE';

    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';

    for my $attr (@$attrs) {

        confess "Error creating accessor '$attr', name has invalid characters"
            unless $attr =~ /^[a-zA-Z_]\w*$/;

        my $code;

        $code = sub {

            if ( @_ == 1 ) {
                return $_[0]->{$attr} if exists $_[0]->{$attr};
                return $_[0]->{$attr} = $default->( $_[0] );
            }

            # values are read-only cannot be changed
            confess "Error attempting to modify the read-only attribute ($attr)";

        };

        no strict 'refs';
        no warnings 'redefine';

        my $class = caller(0);

        *{"$class\::$attr"} = $code;

    }

    return;

}

sub import {

    strict->import;
    warnings->import;

    __PACKAGE__->export_to_level(1, @_);

    return;

}

sub isa_arrayref {

    return "ARRAY" eq ref(shift) ? 1 : 0;

}

sub isa_classref {

    my ($object) = @_;

    return blessed(shift) ? 1 : 0;

}

sub isa_coderef {

    return "CODE" eq ref(shift) ? 1 : 0;

}

sub isa_hashref {

    return "HASH" eq ref(shift) ? 1 : 0;

}

sub isa_listing {

    return "Validation::Class::Listing" eq ref(shift) ? 1 : 0;

}

sub isa_mapping {

    return "Validation::Class::Mapping" eq ref(shift) ? 1 : 0;

}

sub isa_prototype {

    return prototype_registry->has(shift) ? 1 : 0;

}

sub isa_regexp {

    return "REGEXP" eq uc(ref(shift)) ? 1 : 0;

}

sub prototype_registry {

    # Validation::Class::Prototype should be already loaded
    return Validation::Class::Prototype->registry;

}

1;
