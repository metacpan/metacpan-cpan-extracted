
package UR::Singleton;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Singleton',
    is => ['UR::Object'],
    is_abstract => 1,
);

sub id {
    my $self = shift;
    return (ref $self ? $self->SUPER::id(@_) : $self);
}

sub _init_subclass {
    my $class_name = shift;
    my $class_meta_object = $class_name->__meta__;

    # Write into the class's namespace the correct singleton overrides
    # to standard UR::Object methods.
 
    my $src;
    if ($class_meta_object->is_abstract) {
        $src =  qq|sub ${class_name}::_singleton_object { Carp::confess("${class_name} is an abstract singleton!  Select a concrete sub-class.") }|
            .   "\n"
            .   qq|sub ${class_name}::_singleton_class_name { Carp::confess("${class_name} is an abstract singleton!  Select a concrete sub-class.") }|
            .   "\n"
            .   qq|sub ${class_name}::_load { shift->_abstract_load(\@_) }|
    }
    else {
        $src =  qq|sub ${class_name}::_singleton_object { \$${class_name}::singleton or shift->_concrete_load() }|
            .   "\n"
            .   qq|sub ${class_name}::_singleton_class_name { '${class_name}' }|
            .   "\n"
            .   qq|sub ${class_name}::_load { shift->_concrete_load(\@_) }|
            .   "\n"            
            .   qq|sub ${class_name}::get { shift->_concrete_get(\@_) }|
            .   "\n"
            .   qq|sub ${class_name}::is_loaded { shift->_concrete_is_loaded(\@_) }|
        ;
    }
    
    eval $src;
    Carp::confess($@) if $@;

    return 1;
}

# Abstract singletons havd a different load() method than concrete ones.
# We could do this with forking logic, but since many of the concrete methods
# get non-default handling, it's more efficient to do it this way.

sub _abstract_load {
    my $class = shift;
    my $bx = $class->define_boolexpr(@_);
    my $id = $bx->value_for_id;
    unless (defined $id) {
        use Data::Dumper;
        my $params = { $bx->params_list };
        Carp::confess("Cannot load a singleton ($class) except by specific identity. " . Dumper($params));
    }
    my $subclass_name = $class->_resolve_subclass_name_for_id($id);
    eval "use $subclass_name";    
    if ($@) {
        undef $@;
        return;
    }
    return $subclass_name->get();
}

# Concrete singletons have overrides to the most basic acccessors to
# accomplish class/object duality smoothly.

sub _concrete_get {
    if (@_ == 1 or (@_ == 2 and $_[0] eq $_[1])) {
        my $self = $_[0]->_singleton_object;
        return $self if $self;
    }
    return shift->_concrete_load(@_);
}

sub _concrete_is_loaded {
    if (@_ == 1 or (@_ == 2 and $_[0] eq $_[1])) {
        
        my $self = $_[0]->_singleton_object;
        return $self if $self;
    }
    return shift->SUPER::is_loaded(@_);
}

sub _concrete_load {
    my $class = shift;

    $class = ref($class) || $class;
    no strict 'refs';
    my $varref = \${ $class . "::singleton" };
    unless ($$varref) {
        my $id = $class->_resolve_id_for_subclass_name($class);        

        my $class_object = $class->__meta__;
        my @prop_names = $class_object->all_property_names;
        my %default_values;
        foreach my $prop_name ( @prop_names ) {
            my $prop = $class_object->property_meta_for_name($prop_name);
            next unless $prop;
            my $val = $prop->{'default_value'};
            next unless defined $val;
            $default_values{$prop_name} = $val;
        }
   
        $$varref = $UR::Context::current->_construct_object($class,%default_values, id => $id);    
        $$varref->{db_committed} = { %$$varref };
        $$varref->__signal_change__("load");
        Scalar::Util::weaken($$varref);
    }
    my $self = $class->_concrete_is_loaded(@_);
    return unless $self;
    unless ($self->init) {
        Carp::confess("Failed to initialize singleton $class!");
    }
    return $self;
}

# This is implemented in the singleton to do any post-load processing.

sub init {
    return 1;
}

# All singletons require special deletion logic since they keep a 
#weakened reference to the singleton.

sub delete {
    my $self = shift;
    my $class = $self->class;
    $self->SUPER::delete();
    no strict 'refs';
    ${ $class . "::singleton" } = undef if ${ $class . "::singleton" } eq $self;
    return $self;
}

# In most cases, the id is the class name itself, but this is not necessary.

sub _resolve_subclass_name_for_id {
    my $class = shift;
    my $id = shift;
    return $id;
}

sub _resolve_id_for_subclass_name {
    my $class = shift;
    my $subclass_name = shift;
    return $subclass_name;
}

sub create {
    my $class = shift;
    my $bx = $class->define_boolexpr(@_);
    my $id = $bx->value_for_id;
    unless (defined $id) {
        Carp::confess("No singleton ID class specified for constructor?");
    }
    my $subclass = $class->_resolve_subclass_name_for_id($id);
    eval "use $subclass";
    unless ($subclass->isa(__PACKAGE__)) {
        eval '@' . $subclass . "::ISA = ('" . __PACKAGE__ . "')";
    }
        
    return $subclass->_concrete_get();
}


1;


=pod

=head1 NAME

UR::Singleton - Abstract class for implementing singleton objects

=head1 SYNOPSIS

  package MyApp::SomeClass;
  use UR;
  class MyApp::SomeClass {
      is => 'UR::Singleton',
      has => [
          foo => { is => 'Number' },
      ]
  };

  $obj = MyApp::SomeClass->get();
  $obj->foo(1);

=head1 DESCRIPTION

This class provides the infrastructure for singleton classes.  Singletons
are classes of which there can only be one instance, and that instance's ID
is the class name.

If a class inherits from UR::Singleton, it overrides the default
implementation of C<get()> and C<is_loaded()> in UR::Object with code that
fabricates an appropriate object the first time it's needed.

Singletons are most often used as one of the parent classes for data sources
within a Namespace.  This makes it convienent to refer to them using only
their name, as in a class definition.

=head1 METHODS

=over 4

=item _singleton_object

  $obj = Class::Name->_singleton_object;

  $obj = $obj->_singleton_object;

Returns the object instance whether it is called as a class or object method.

=item _singleton_class_name

  $class_name = Class::Name->_singleton_class_name;

  $class_name = $obj->_singleton_class_name;

Returns the class name whether it is called as a class or object method.

=back

=head1 SEE ALSO

UR::Object

=cut
