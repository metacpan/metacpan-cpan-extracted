package UR::Object::Property;
use warnings;
use strict;

require UR;

use Lingua::EN::Inflect;
use Class::AutoloadCAN;

our $VERSION = "0.47"; # UR $VERSION;
our @CARP_NOT = qw( UR::DataSource::RDBMS UR::Object::Type );

# class_meta and r_class_meta duplicate the functionality if two properties of the same name,
# but these are faster
sub class_meta {
    return shift->{'class_name'}->class->__meta__;
}

sub r_class_meta {
    return shift->{'data_type'}->class->__meta__;
}


sub is_direct {
    my $self = shift;
    if ($self->is_calculated or $self->is_constant or $self->is_many or $self->via) {
        return 0;
    }
    return 1;
}

sub is_numeric {
    my $self = shift;
    unless (defined($self->{'_is_numeric'})) {
        my $class = $self->_data_type_as_class_name;
        unless ($class) {
            return;
        }
        $self->{'_is_numeric'} = $class->isa("UR::Value::Number");
    }
    return $self->{'_is_numeric'};
}

sub is_text {
    my $self = shift;
    unless (defined($self->{'_is_text'})) {
        my $class = $self->_data_type_as_class_name;
        unless ($class) {
            return;
        }
        $self->{'_is_text'} = $class->isa("UR::Value::Text");
    }
    return $self->{'_is_text'};
}

sub is_valid_storage_for_value {
    my($self, $value) = @_;

    my $data_class_name = $self->_data_type_as_class_name;
    return 1 if ($value->isa($data_class_name));

    if ($data_class_name->isa('UR::Value') ) {
        my @underlying_types = $data_class_name->underlying_data_types;
        foreach my $underlying_type ( @underlying_types ) {
            return 1 if ($value->isa($underlying_type));
        }
    }
    return 0;
}

sub alias_for {
    my $self = shift;

    if ($self->{'via'} and $self->{'to'} and $self->{'via'} eq '__self__') {
        return $self->{'to'};
    } else {
        return $self->{'property_name'};
    }
}

sub _convert_data_type_for_source_class_to_final_class {
    my ($class, $foreign_class, $source_class) = @_;

    $foreign_class ||= '';

    # TODO: allowing "is => 'Text'" instead of is => 'UR::Value::Text' is syntactic sugar
    # We should have an is_primitive flag set on these so we do efficient work.

    my ($ns) = ($source_class =~ /^([^:]+)::/);
    if ($ns and not $ns->isa("UR::Namespace")) {
        $ns = undef;
    }

    my $final_class;
    if ($foreign_class) {
        if ($foreign_class->can('__meta__')) {
            $final_class = $foreign_class;
        }
        else {
            my ($ns_value_class, $ur_value_class);

            if ($ns
                and $ns ne 'UR' and $ns ne 'URT'
                and $ns->can("get")
            ) {
                $ns_value_class = $ns . '::Value::' . $foreign_class;
                if ($ns_value_class->can('__meta__')) {
                    $final_class = $ns_value_class;
                }
            }

            if (!$final_class) {
                $ur_value_class = 'UR::Value::' . $foreign_class;
                my $normalized_ur_value_class = 'UR::Value::' . ucfirst(lc($foreign_class));
                if ($normalized_ur_value_class->can('__meta__')) {
                    $final_class = $normalized_ur_value_class;

                } elsif ($ur_value_class->can('__meta__')) {
                    $final_class = $ur_value_class;
                }
            }
        }
    }

    if (!$final_class) {
        if (Class::Autouse->class_exists($foreign_class)) {
            return $foreign_class;
        }
        elsif ($foreign_class =~ /::/) {
            return $foreign_class;
        }
        else {
            local $@;
            eval "use $foreign_class;";
            if (!$@) {
                return $foreign_class;
            }
            
            if (!$ns or $ns->get()->allow_sloppy_primitives) {
                # no colons, and no namespace: no choice but to assume it's a sloppy primitive
                return 'UR::Value::SloppyPrimitive';      
            }
            else {
                Carp::confess("Failed to find a ${ns}::Value::* or UR::Value::* module for primitive type $foreign_class!");
            }
        }
    }

    return $final_class;
}

sub _data_type_as_class_name {
    my $self = $_[0];
    return $self->{_data_type_as_class_name} ||= do {
        my $source_class = $self->class_name;
        #this is so NUMBER -> Number
        my $foreign_class = $self->data_type;

        
        if (not $foreign_class) {
            if ($self->via or $self->to) {
                my @joins = UR::Object::Join->resolve_chain(
                    $self->class_name,
                    $self->property_name,
                    $self->property_name,
                );
                $foreign_class = $joins[-1]->foreign_class;
            }
        }

        __PACKAGE__->_convert_data_type_for_source_class_to_final_class($foreign_class, $source_class);
    };
}

# TODO: this is a method on the data source which takes a given property.
# Returns the table and column for this property.
# If this particular property doesn't have a column_name, and it
# overrides a property defined on a parent class, then walk up the
# inheritance and find the right one
sub table_and_column_name_for_property {
    my $self = shift;

    # Shortcut - this property has a column_name, so the class should have the right
    # table_name
    if ($self->column_name) {
        return ($self->class_name->__meta__->table_name, $self->column_name);
    }

    my $property_name = $self->property_name;
    my @class_metas = $self->class_meta->parent_class_metas;

    my %seen;
    while (@class_metas) {
        my $class_meta = shift @class_metas;
        next if ($seen{$class_meta}++);

        my $p = $class_meta->property_meta_for_name($property_name);
        next unless $p;

        if ($p->column_name && $class_meta->table_name) {
            return ($class_meta->table_name, $p->column_name);
        }

        push @class_metas, $class_meta->parent_class_metas;
    }

    # This property has no column anywhere in the class' inheritance
    return;
}


# Return true if resolution of this property involves an ID property of
# any class.
sub _involves_id_property {
    my $self = shift;

    my $is_id = $self->is_id;
    return 1 if defined($is_id);

    if ($self->id_by) {
        my $class_meta = $self->class_meta;
        my $id_by_list = $self->id_by;
        foreach my $id_by ( @$id_by_list ) {
            my $id_by_meta = $class_meta->property_meta_for_name($id_by);
            return 1 if ($id_by_meta and $id_by_meta->_involves_id_property);
        }
    }

    if ($self->via) {
        my $via_meta = $self->via_property_meta;
        return 1 if ($via_meta and $via_meta ne $self and $via_meta->_involves_id_property);

        if ($self->to) {
            my $to_meta = $self->to_property_meta;
            return 1 if ($to_meta and $to_meta->_involves_id_property);

            if ($self->where) {
                unless ($to_meta) {
                    Carp::confess("Property '" . $self->property_name . "' of class " . $self->class_name
                                . " has 'to' metadata that does not resolve to a known property.");
                }
                my $other_class_meta = $to_meta->class_meta;
                my $where = $self->where;
                for (my $i = 0; $i < @$where; $i += 2) {
                    my $where_meta = $other_class_meta->property_meta_for_name($where->[$i]);
                    return 1 if ($where_meta and $where_meta->_involves_id_property);
                }
            }
        }
    }
    return 0;
}


# For via/to delegated properties, return the property meta in the same
# class this property delegates through
sub via_property_meta {
    my $self = shift;

    return unless ($self->is_delegated and $self->via);
    my $class_meta = $self->class_meta;
    return $class_meta->property_meta_for_name($self->via);
}

sub final_property_meta {
    my $self = shift;

    my $closure;
    $closure = sub { 
        return unless defined $_[0];
        if ($_[0]->is_delegated and $_[0]->via) {
            if ($_[0]->to) {
                return $closure->($_[0]->to_property_meta);
            } else {
                return $closure->($_[0]->via_property_meta);
            }
        } else {
            return $_[0];
        }
    };
    my $final = $closure->($self);

    return if !defined $final || $final->id eq $self->id;
    return $final;
}

# For via/to delegated properties, return the property meta on the foreign
# class that this property delegates to
sub to_property_meta {
    my $self = shift;

    return unless ($self->is_delegated && $self->to);

    my $via_meta = $self->via_property_meta();
    return unless $via_meta;

    my $remote_class = $via_meta->data_type;
#    unless ($remote_class) {
#        # Can we guess what the data type is for multiply indirect properties?
#        if ($via_meta->to) {
#            my $to_property_meta = $via_meta->to_property_meta;
#            $remote_class = $to_property_meta->data_type if ($to_property_meta);
#        }
#    }
    return unless $remote_class;
    my $remote_class_meta = UR::Object::Type->get($remote_class);
    return unless $remote_class_meta;

    return $remote_class_meta->property_meta_for_name($self->to);
}


sub get_property_name_pairs_for_join {
    my ($self) = @_;
    unless ($self->{'_get_property_name_pairs_for_join'}) {
        my @linkage = $self->_get_direct_join_linkage();
        unless (@linkage) {
            Carp::croak("Cannot resolve underlying property joins for property '"
                            . $self->property_name . "' of class "
                            . $self->class_name
                            . ": Couldn't determine which properties link to the remote class");
        }
        my @results;
        if ($self->reverse_as) {
            @results = map { [ $_->[1] => $_->[0] ] } @linkage;
        } else {
            @results = map { [ $_->[0] => $_->[1] ] } @linkage;
        }
        $self->{'_get_property_name_pairs_for_join'} = \@results;
    }
    return @{$self->{'_get_property_name_pairs_for_join'}};
}

sub _get_direct_join_linkage {
    my ($self) = @_;
    my @retval;
    if (my $id_by = $self->id_by) {
        my $r_class_meta = $self->r_class_meta;
        unless ($r_class_meta) {
            Carp::croak("Property '" . $self->property_name . "' of class '" . $self->class_name . "' "
                        . "has data_type '" . $self->data_type ."' with no class metadata");
        }

        my @my_id_by = @{ $self->id_by };
        my @their_id_by = @{ $r_class_meta->{'id_by'} };
        if (! @their_id_by
            or
            (@my_id_by == 1 and @their_id_by > 1)
        ) {
            @their_id_by = ( 'id' );
        }

        unless (@my_id_by == @their_id_by) {
            Carp::croak("Property '" . $self->property_name . "' of class '" . $self->class_name . "' "
                        . "has " . scalar(@my_id_by) . " id_by elements, while its data_type ("
                        . $self->data_type .") has " . scalar(@their_id_by));
        }

        for (my $i = 0; $i < @my_id_by; $i++) {
            push @retval, [ $my_id_by[$i], $their_id_by[$i] ];
        }

    }
    elsif (my $reverse_as = $self->reverse_as) {
        my $r_class_name = $self->data_type;
        @retval = 
            $r_class_name->__meta__->property_meta_for_name($reverse_as)->_get_direct_join_linkage();
    }
    return @retval;
}

sub _resolve_join_chain {
    my $self = shift;
    return UR::Object::Join->resolve_chain(
        $self->class_name,
        $self->property_name,
    );
}

sub label_text {
    # The name of the property in friendly terms.
    my ($self,$obj) = @_;
    my $property_name = $self->property_name;
    my @words = App::Vocabulary->filter_vocabulary(map { ucfirst(lc($_)) } split(/\s+/,$property_name));
    my $label = join(" ", @words);
    return $label;
}

# This gets around the need to make a custom property subclass
# when a class has an attributes_have specification.

# This primary example of this in base infrastructure is that
# all Commands have is_input, is_output and is_param attributes.

# Note: it's too permissive and will make an accessor for any hash key.
# The updated code should not do this.

sub CAN {
    my ($thisclass, $method, $self) = @_;
    if (ref($self)) {
        my $accessor_key = '_' . $method . "_accessor";
        if (my $method = $self->{$accessor_key}) {
            return $method;
        }
        if ($self->class_name->__meta__->{attributes_have}
            and
            exists $self->class_name->__meta__->{attributes_have}{$method}
        ) {
            return $self->{$accessor_key} = sub {
                return $_[0]->{$method};
            }
        }
    }
    return;
}


1;

=pod

=head1 NAME

UR::Object::Property - Class representing metadata about a class property

=head1 SYNOPSIS

  my $prop = UR::Object::Property->get(class_name => 'Some::Class', property_name => 'foo');

  my $class_meta = Some::Class->__meta__;
  my $prop2 = $class_meta->property_meta_for_name('foo');

  # Print out the meta-property name and its value of $prop2
  print map { " $_ : ".$prop2->$_ }
        qw(class_name property_name data_type default_value);

=head1 DESCRIPTION

Instances of this class represent properties of classes.  For every item
mentioned in the 'has' or 'id_by' section of a class definition become Property
objects.  

=head1 INHERITANCE

UR::Object::Property is a subclass of L<UR::Object>

=head1 PROPERTY TYPES

For this class definition:
  class Some::Class {
      has => [
          other_id => { is => 'Text' },
          other    => { is => 'Some::Other', id_by => 'foo_id' },
          bar      => { via => 'other', to => 'bar' },
          foos     => { is => 'Some::Foo', reverse_as => 'some', is_many => 1 },
          uc_other_id => { calculate_from => 'other_id',
                           calculate_perl => 'uc($other_id)' },
      ],
  };
      
Properties generally fall in to one of these categories:

=over 4

=item regular property

A regular property of a class holds a single scalar.  In this case,
'other_id' is a regular property.

=item object accessor

An object accessor property returns objects of some class.  The properties
of this class must link in some way with all the ID properties of the remote
class (the 'is' declaration).  'other' is an object accessor property.  This
is how one-to-one relationships are implemented.

=item via property

When a class has some object accessor property, and it is helpful for an
object to assume the value of the remote class's properties, you can set
up a 'via' property.  In the example above, an object of this class 
gets the value of its 'bar' property via the 'other' object it's linked
to, from that object's 'bar' property.

=item reverse as or is many property

This is how one-to-many relationships are implemented.  In this case, 
the Some::Foo class must have an object accessor property called 'some',
and the 'foos' property will return a list of all the Some::Foo objects
where their 'some' property would have returned that object.

=item calculated property

A calculated property doesn't store its data directly in the object, but 
when its accessor is called, the calculation code is executed.

=back

=head1 PROPERTIES

Each property has a method of the same name

=head2 Direct Properties

=over 4

=item class_name => Text

The name of the class this Property is attached to

=item property_name => Text

The name of the property.  The pair of class_name and property name are
the ID properties of UR::Object::Property

=item column_name => Text

If the class is backed by a database table, then the column this property's 
data comes from is stored here

=item data_type => Text

The type of data stored in this property.  Corresponds to the 'is' part of
a class's property definition.

=item data_length => Number

The maximum size of data stored in this property

=item default_value

For is_optional properties, the default value given when an object is created
and this property is not assigned a value.

=item valid_values => ARRAY

A listref of enumerated values this property may be set to

=item doc => Text

A place for documentation about this property

=item is_id => Boolean

Indicates whether this is an ID property of the class

=item is_optional => Boolean

Indicates whether this is property may have the value undef when the object
is created

=item is_transient => Boolean

Indicates whether this is property is transient?

=item is_constant => Boolean

Indicates whether this property can be changed after the object is created.

=item is_mutable => Boolean

Indicates this property can be changed via its accessor.  Properties cannot
be both constant and mutable

=item is_volatile => Boolean

Indicates this property can be changed by a mechanism other than its normal
accessor method.  Signals are not emitted even when it does change via
its normal accessor method.

=item is_classwide => Boolean

Indicates this property's storage is shared among all instances of the class.
When the value is changed for one instance, that change is effective for all
instances.

=item is_delegated => Boolean

Indicates that the value for this property is not stored in the object
directly, but is delegated to another object or class.

=item is_calculated => Boolean

Indicates that the value for this property is not a part of the object'd
data directly, but is calculated in some way.

=item is_transactional => Boolean

Indicates the changes to the value of this property is tracked by a Context's
transaction and can be rolled back if necessary.

=item is_abstract => Boolean

Indicates this property exists in a base class, but must be overridden in
a derived class.

=item is_concrete => Boolean

Antonym for is_abstract.  Properties cannot be both is_abstract and is_concrete,

=item is_final => Boolean

Indicates this property cannot be overridden in a derived class.

=item is_deprecated => Boolean

Indicates this property's use is deprecated.  It has no effect in the use
of the property in any way, but is useful in documentation.

=item implied_by => Text

If this property is created as a result of another property's existence,
implied_by is the name of that other property.  This can happen in the
case where an object accessor property is defined

  has => [ 
      foo => { is => 'Some::Other', id_by => 'foo_id' },
  ],

Here, the 'foo' property requires another property called 'foo_id', which
is not explicitly declared.  In this case, the Property named foo_id will
have its implied_by set to 'foo'.

=item id_by => ARRAY

In the case of an object accessor property, this is the list of properties in
this class that link to the ID properties in the remote class.

=item reverse_as => Text

Defines the linking property name in the remote class in the case of an
is_many relationship

=item via => Text

For a via-type property, indicates which object accessor to go through.

=item to => Text

For a via-type property, indicates the property name in the remote class to
get its value from.  The default value is the same as property_name

=item where => ARRAY

Supplies additional filters for indirect properties.  For example:

  foos => { is => 'Some::Foo', reverse_as => 'some', is_many => 1 },
  blue_foos => { via => 'foos', where => [ color => 'blue' ] },

Would create a property 'blue_foos' which returns only the related
Some::Foo objects that have 'blue' color.

=item calculate_from => ARRAY

For calculated properties, this is a list of other property names the
calculation is based on

=item calculate_perl => Text

For calculated properties, a string containing Perl code.  Any properties
mentioned in calculate_from will exist in the code's scope at run time
as scalars of the same name.

=item class_meta => UR::Object::Type

Returns the class metaobject of the class this property belongs to

=back

=head1 METHODS

=over 4

=item via_property_meta

For via/to delegated properties, return the property meta in the same
class this property delegates through

=item to_property_meta

For via/to delegated properties, return the property meta on the foreign
class that this property delegates to

=back

=head1 SEE ALSO

UR::Object::Type, UR::Object::Type::Initializer, UR::Object

=cut
