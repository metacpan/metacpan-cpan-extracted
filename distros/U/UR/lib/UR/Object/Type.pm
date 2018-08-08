package UR::Object::Type;

use warnings;
use strict;
require UR;

# Used during bootstrapping.
our @ISA = qw(UR::Object);
our $VERSION = "0.47"; # UR $VERSION;

our @CARP_NOT = qw( UR::Object UR::Context  UR::ModuleLoader Class::Autouse UR::BoolExpr );

# Most of the API for this module are legacy internals required by UR.
use UR::Object::Type::InternalAPI;

# This module implements define(), and most everything behind it.
use UR::Object::Type::Initializer;

# The methods used by the initializer to write accessors in perl.
use UR::Object::Type::AccessorWriter;

# The methods to extract/(re)create definition text in the module source file.
use UR::Object::Type::ModuleWriter;

# Present the internal definer as an external method
sub define { shift->__define__(@_) }

# For efficiency, certain hash keys inside the class cache property metadata
# These go in this array, and are cleared when property metadata is mutated
our @cache_keys;

# This is the function behind $class_meta->properties(...)
# It mimics the has-many object accessor, but handles inheritance
# Once we have "isa" and "is-parent-of" operator we can do this with regular operators.
push @cache_keys, '_properties';
sub _properties {
    my $self = shift;
    my $all = $self->{_properties} ||= do {
        # start with everything, as it's a small list
        my $map = $self->_property_name_class_map;
        my @all;
        for my $property_name (sort keys %$map) {
            my $class_names = $map->{$property_name};
            my $class_name = $class_names->[0];
            my $id = $class_name . "\t" . $property_name;
            my $property_meta = UR::Object::Property->get($id);
            unless ($property_meta) {
                Carp::confess("Failed to find property meta for $class_name $property_name?");
            }
            push @all, $property_meta; 
        }
        \@all;
    };
    if (@_) {
        my ($bx, %extra) = UR::Object::Property->define_boolexpr(@_);
        my @matches = grep { $bx->evaluate($_) } @$all; 
        if (%extra) {
            # Additional meta-properties on meta-properties are not queryable until we
            # put the UR::Object::Property into a private sub-class.
            # This will give us most of the functionality. 
            for my $key (keys %extra) {
                my ($name,$op) = ($key =~ /(\w+)\s*(.*)/);
                unless (defined $self->{attributes_have}->{$name}) {
                    die "unknown property $name used to query properties of " . $self->class_name;
                }
                if ($op and $op ne '==' and $op ne 'eq') {
                    die "operations besides equals are not supported currently for added meta-properties like $name on class " . $self->class_name;
                }
                my $value = $extra{$key};
                no warnings;
                @matches = grep { $_->can($name) and $_->$name eq $value } @matches;                
            }
        }
        return if not defined wantarray;
        return @matches if wantarray;
        die "Matched multiple meta-properties, but called in scalar context!" . Data::Dumper::Dumper(\@matches) if @matches > 1;
        return $matches[0];
    }
    else {
        @$all;
    }
}

sub property {
    if (@_ == 2) {
        # optimize for the common case
        my ($self, $property_name) = @_;
        my $class_names = $self->_property_name_class_map->{$property_name};
        return unless $class_names and @$class_names;
        my $id = $class_names->[0] . "\t" . $property_name;
        return UR::Object::Property->get($id); 
    }
    else {
        # this forces scalar context, raising an exception if
        # the params used result in more than one match
        my $one = shift->properties(@_);
        return $one;
    }
}

push @cache_keys, '_property_names';
sub property_names {
    my $self = $_[0];
    my $names = $self->{_property_names} ||= do {
        my @names = sort keys %{ shift->_property_name_class_map };
        \@names;
    };
    return @$names;
}

push @cache_keys, '_property_name_class_map';
sub _property_name_class_map {
    my $self = shift;
    my $map = $self->{_property_name_class_map} ||= do {
        my %map = ();  
        for my $class_name ($self->class_name, $self->ancestry_class_names) {
            my $class_meta = UR::Object::Type->get($class_name);
            if (my $has = $class_meta->{has}) {
                for my $key (sort keys %$has) {
                    my $classes = $map{$key} ||= [];
                    push @$classes, $class_name;
                }
            }
        }
        \%map;
    };
    return $map;
}

# The prior implementation of _properties() (behind ->properties())
# filtered out certain property meta.  This is the old version.
# The new version above will return one object per property name in
# the meta ancestry.
sub _legacy_properties {
    my $self = shift;
    if (@_) {
        my $bx = UR::Object::Property->define_boolexpr(@_);
        my @matches = grep { $bx->evaluate($_) } $self->property_metas;
        return if not defined wantarray;
        return @matches if wantarray;
        die "Matched multiple meta-properties, but called in scalar context!" . Data::Dumper::Dumper(\@matches) if @matches > 1;
        return $matches[0];
    }
    else {
        $self->property_metas;
    }
}

1;

