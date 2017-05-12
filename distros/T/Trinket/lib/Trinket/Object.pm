###########################################################################
### Trinket::Object
###
### Base class for indexed persistent objects.
###
### $Id: Object.pm,v 1.3 2001/02/19 20:01:53 deus_x Exp $
###
### TODO:
### -- Implement support for data types (char is only type for now)
###     -- Use classes/modules to define datatypes
###     -- Fix use of data type modules in the case of per-object
###          properties.  (Broken right now)
###     -- Definable data types with different accessors,
###          index key generators
### -- More detailed introspection on properties
### -- Use hashes in BEGIN block property definitions versus arrays?
###     -- Use both for "backward" compatibility?
### -- Instead of per-instance accessor generation, generate them
###      per-class in import()
### -- Hooks in _get and _set to cooperate with any on-demand property
###      handling a Directory may implement
### -- Property visibility, read only flag.
### -- Data access levels, cooperate with ACLs
### -- Have get_* and set_* methods, implement index_* methods?
### -- Should something happen in DESTROY() ? (per warning)
###
###########################################################################

package Trinket::Object;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD %PROPERTIES);
use Carp qw( croak cluck );
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Object - Base class for persistent objects managed by
Trinket::Directory

=head1 SYNOPSYS

 {
   package TestObject;

   BEGIN
     {
       our $VERSION      = "0.0";
       our @ISA          = qw( Trinket::Object );
       our $DESCRIPTION  = 'Test object class';
       our %PROPERTIES   =
         (
           ### name => [ type, indexed, desc ]
           mung       => [ 'char', 1, 'Mung'     ],
           bar        => [ 'char', 1, 'Bar'      ],
           baz        => [ 'char', 0, 'Baz'      ],
         );
     }

   use Trinket::Object;
 }

 $obj = new TestObject({ mung => 'mung_value' });

 $obj->add_property( name => 'char', 0, 'The xzzxy property' );

 $obj->set_name('value');

 $obj->set(name=>'value');

 $obj->set(id=>'1',name=>'value',...);

 $val = $obj->get_name();

 $val = $obj->get('name');

 @vals = $obj->get('id','name');

 $obj->add_property(foo=>'char',0,'Foo property');

 $obj->remove_property('foo');

=head1 DESCRIPTION

Trinket::Object is the base class for all classes whose instances are
intended to be managed by Trinket::Directory.

This base class serves several purposes: A mechanism is specified by
which object data properties are described; accessor (get_*) and
mutator (set_*) methods are automatically generated; changes in
properties are tracked to facilitate object storage and indexing

The intent is to both serve as a convenient base class, as well as
provide means of interrogation to Trinket::Directory so that the
object can be managed transparently without any knowledge about the
directory in the object itself.  This should allow the object to be
managed by any directory.

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Exporter );
    $DESCRIPTION  = 'Base object class';
    %PROPERTIES   =
      (
       ### name => [ type, indexed, desc ]
       id         => [ 'char', 1, 'Object ID'      ],
#       name       => [ 'char', 1, 'Name'           ],
       class      => [ 'char', 1, 'Class'          ],
#       modified   => [ 'char', 1, 'Last modified'  ],
#       created    => [ 'char', 1, 'Created'        ],
#       author     => [ 'char', 1, 'Author'         ],
       directory  => [ 'ref',  0, 'Directory'      ],
      );
    @EXPORT =
      qw(
         &META_TYPES
         &META_PROP_TYPE
         &META_PROP_INDEXED
         &META_PROP_DESC
         &DIRTY_OLD_VALUE
         &DIRTY_NEW_VALUE
		 &OBJ_META_PROPS
		 &OBJ_PROPS
		 &PROP_VALUE
		 &PROP_DIRTY
		 &PROP_CLEAN_VALUE
        );
  }

# }}}

# {{{ EXPORTS

=head1 EXPORTS

=head2 CONSTANTS

=over 4

=item * META_TYPES - List of datatypes supported by object properties

=item * META_PROP_TYPE - Property metadata spec index to the data type
of the property.  See: add_property()

=item * META_PROP_INDEXED - Property metadata spec index to a 0/1 flag
indicating whether the property should be indexed.  See: add_property()

=item * META_PROP_DESC - Property metadata spec index to the text
description of the property.  See: add_property()

=item * DIRTY_OLD_VALUE - See:

=item * DIRTY_NEW_VALUE

=back

TODO

=cut

# }}}

# {{{ CONSTANTS

use constant META_PROP_TYPE			  => 0;
use constant META_PROP_TYPE_KEY		  => 'type';
use constant META_PROP_INDEXED		  => 1;
use constant META_PROP_INDEXED_KEY	  => 'indexed';
use constant META_PROP_DESC			  => 2;
use constant META_PROP_DESC_KEY		  => 'desc';
use constant META_PROP_MAP =>
  {
   META_PROP_TYPE_KEY    , META_PROP_TYPE,
   META_PROP_INDEXED_KEY , META_PROP_INDEXED,
   META_PROP_DESC_KEY    , META_PROP_DESC
  };
use constant META_PROP_INSTALLED => 3;

use constant DIRTY_OLD_VALUE     => 0;
use constant DIRTY_NEW_VALUE     => 1;

use constant OBJ_META_PROPS      => 0;
use constant OBJ_PROPS           => 1;

use constant PROP_VALUE          => 0;
use constant PROP_DIRTY          => 1;
use constant PROP_CLEAN_VALUE    => 2;

# }}}

use Trinket::DataType::default;
use Trinket::DataType::object;

# {{{ METHODS

=head1 METHODS

=over 4

=cut

# }}}

# {{{ new(): Object constructor

=item $obj = new Trinket::Object({prop1=>'val1'});

Object constructor, accepts a hashref of named properties with which to
initialize the object.  In initialization, the object's set methods
are called for each of initializing properties passed.  '

=cut

sub new
  {
    my $class = shift;

    my $self = [];
    $self->[OBJ_META_PROPS]  = {};
    $self->[OBJ_PROPS]       = {};

    bless($self, $class);
    $self->init(@_);
    return $self;
  }

# }}}
# {{{ init(): Object initializer

=item $obj->init({prop=>$value, prop2=>$value2, ...});

=item $obj->init(prop=>$value, prop2=>$value2, ...);

Object initializer, called by new() with the initializing parameters
sent to it.  In the base class, this initializer iterates through each
of the properties supplied and calls the appropriate mutator to set
the value.

This method never needs to be called directly, but it can
be overridden in subclasses.

=cut

sub init {
    no strict 'refs';
    my ($self) = shift;
	my %props;

	if (ref($_[0]) eq 'HASH') {
		### If a hashref is passed, convert to a straight hash.
		my $ref = shift;
		%props = %$ref;
	} else {
		### Otherwise, assume that this is a list to be used as hash.
		%props = @_;
	}

    my $mutator;
    foreach (keys %props) {
        $mutator = "set_$_";
        $self->$mutator($props{$_}) if (defined $props{$_});
	}
    $self->set_class( ref($self) );
  }

# }}}

# {{{ AUTOLOAD: Generate get_/set_ mutators to object properties.

=item AUTOLOAD

The C<AUTOLOAD> method of this class automatically generates mutator and
accessor methods on demand if they do not already exist.  These
methods each take the form of get_foo() and set_foo($value) where foo
is the name of an object property.  If a method matching this pattern
already exists, C<AUTOLOAD> will not be called, and will not overwrite
it.

=cut

sub AUTOLOAD
  {
    no strict 'refs';
    my $self = shift;
	
    ### Was it a get_... method?
    if ($AUTOLOAD =~ /.*::get_([\w_]+)/) {
        my $attr_name = $1;

		### Attempt to retrieve the metadata for this property
		my $prop_meta = $self->_get_prop_meta($attr_name);
		croak ("No such property '$attr_name' to get for $self")
		  if (!defined $prop_meta);
		
 		my ($prop_type, $prop_type_params) =
 		  split(/:/, $prop_meta->[META_PROP_TYPE]);
		my $pkg = "Trinket::DataType::$prop_type";
		eval "require $pkg";
		$pkg = 'Trinket::DataType::default' if ($@);

		($pkg)->install_methods($self, $attr_name);
		
		return ($pkg)->get($self, $attr_name, @_);
	}

    ### Was it a set_... method?
    if ($AUTOLOAD =~ /.*::set_([\w_]+)/) {
        my $attr_name = $1;

		### Attempt to retrieve the metadata for this property
		my $prop_meta = $self->_get_prop_meta($attr_name);
		croak ("No such property '$attr_name' to set for $self")
		  if (!defined $prop_meta);
	
 		my ($prop_type, $prop_type_params) =
 		  split(/:/, $prop_meta->[META_PROP_TYPE]);
		my $pkg = "Trinket::DataType::$prop_type";
		eval "require $pkg";
		$pkg = 'Trinket::DataType::default' if ($@);

		($pkg)->install_methods($self, $attr_name);

		return ($pkg)->set($self, $attr_name, @_);
	}

    croak("no such method: $AUTOLOAD");
  }

# }}}
# {{{ import()

=item import

The C<import> method of this base class facilitates the inheritance of
class metadata.  When a subclass is created, the list of properties
and other class definition data will be merged into the subclass' own
metadata. '

=cut

sub import {
    no strict; ### Wooo, scary scary.

    my ($self)  = shift;
    my $pkg = (caller())[0];

    ### Alias the metadata for the class subclassing Toybox::Component
    *PKG_PROPS   = *{"$pkg\::PROPERTIES"};

    ### Prepare some scratch variables for the inheritance
    my %props   = ();

	### Iterate through each of the class' superclasses
	foreach my $anc_pkg (_derive_ancestry($pkg)) {
		### Skip metadata inheritance if this is not a subclass
		next if (! UNIVERSAL::isa($anc_pkg, __PACKAGE__));
		
		### Alias the superclass' metadata
		*ANC_PROPS   = *{"$anc_pkg\::PROPERTIES"};
		
		### Inherit the metadata from this superclass
		$props{$_} = $ANC_PROPS{$_} foreach (keys %ANC_PROPS);
	}
	
	### Finalize the inheritance.  For the hash metadata, inherit those
	### values which are not already present in the class.
	foreach(keys %props)
	  { $PKG_PROPS{$_} = $props{$_} if (! defined $PKG_PROPS{$_}); }

# 	foreach my $name (keys %PKG_PROPS) {
# 		if ($PKG_PROPS{$name}->[META_PROP_INSTALLED]) {
# 			next;
# 		}
# 		$PKG_PROPS{$name}->[META_PROP_INSTALLED] = 1;
	
# 		warn("IMPORT INSTALLING $name");
# 		my $prop_meta = $PKG_PROPS{$name};

# 		if (!defined $prop_name) {
# 			die ("WHAT? $prop_name $pkg");
# 		}

# 		my ($prop_type, $prop_type_params) =
#  		  split(/:/, $prop_meta->[META_PROP_TYPE]);
# 		my $data_pkg = "Trinket::DataType::$prop_type";
# 		eval "require $data_pkg";
# 		$data_pkg = 'Trinket::DataType::default' if ($@);
		
# 		($data_pkg)->install_methods($pkg, $name);
# 	}
	
	### Finally, call on Exporter's original import
	__PACKAGE__->export_to_level(1, \@_);
}

# }}}
# {{{ set(): Object property mutator

=item $obj->set(name=>'value');

In addition to auto-generated property mutators, set() is a generic
mutator which can be used to set properties by name, and to set more
than one in a single method call.

Note that this method accesses object property data directly, and does
not call any overridden mutators in a subclass.  Because of this, this
method should only be used in overriding mutators and possibly object
directory data access backends.

=cut

sub set {
    my ($self, $name, $val) = @_;
		
	### Attempt to retrieve the metadata for this property
	my $prop_meta = $self->_get_prop_meta($name);
	if (!defined $prop_meta) {
		die "No such property '$name' to set for $self";
	} else {
		my ($prop_type, $prop_type_params) =
		  split(/:/, $prop_meta->[META_PROP_TYPE]);

		my $pkg = "Trinket::DataType::$prop_type";
		eval "require $pkg";
		if ($@) {
			$pkg = 'Trinket::DataType::default';
		}
		return ($pkg)->set(@_);
	}
}

# }}}
# {{{ get(): Object property accessor

=item $val = $obj->get('name');

In addition to auto-generated property accessors, get() is a generic
mutator which can be used to get properties by name, and to get more
than one in a single method call.

Note that this method accesses object property data directly, and does
not call any overridden accessors in a subclass.  Because of this,
this method should only be used in overriding accessors and possibly
object directory data access backends.

=cut

sub get {
    my ($self, $name) = @_;

	### Attempt to retrieve the metadata for this property
	my $prop_meta = $self->_get_prop_meta($name);
	if (!defined $prop_meta) {
		die "No such property '$name' to get for $self";
	} else {
		my ($prop_type, $prop_type_params) =
		  split(/:/, $prop_meta->[META_PROP_TYPE]);

		my $pkg = "Trinket::DataType::$prop_type";
		eval "require $pkg";
		if ($@) {
			$pkg = 'Trinket::DataType::default';
		}
		return ($pkg)->get(@_);
	}
}

# }}}

# {{{ has_property(): Test for property availability

=item $obj->has_property('name')

Tests whether an object has a given property.

=cut

sub has_property {
	my ($self, $name) = @_;

	### Attempt to retrieve the metadata for this property
	my $prop_meta = $self->_get_prop_meta($name);
	if (!defined $prop_meta) {
		return undef;
	} else {
		return 1;
	}
}

# }}}
# {{{ type_property(): Get a property's type

=item $obj->type_property('name')

Query the data type for a given property

=cut

sub type_property {
	my ($self, $name) = @_;

	### Attempt to retrieve the metadata for this property
	my $prop_meta = $self->_get_prop_meta($name);
	if (!defined $prop_meta) {
		return undef;
	} else {
		my ($prop_type, $prop_type_params);
		if ($prop_meta->[META_PROP_TYPE] =~ /([^:]+):(.*)/) {
			$prop_type        = $1;
			$prop_type_params = $2;
		} else {
			$prop_type        = $prop_meta->[META_PROP_TYPE];
			$prop_type_params = undef;
		}		

		return $prop_type, $prop_type_params;
	}
}

# }}}
# {{{ describe_property(): Get a property's type

=item $obj->describe_property('name')

Query the data type for a given property

=cut

sub describe_property {
	my ($self, $name) = @_;

	### Attempt to retrieve the metadata for this property
	my $prop_meta = $self->_get_prop_meta($name);
	if (!defined $prop_meta) {
		return undef;
	} else {
		return $prop_meta->[META_PROP_DESC];
	}
}

# }}}
# {{{ add_property(): Add a property to the object

=item $obj->add_property(name=>'type',0,'Description');

Add a property to the object.  The new property will be available to
get and set methods, and will be handled by the object directory.

The metadata supplied are the property name, whether the property
should be indexed (0/1), and a description of the property.

=cut

sub add_property
  {
    my ($self, $name, $type, $indexed, $desc) = @_;

    my $prop_spec = [];
    $prop_spec->[META_PROP_TYPE]    = $type;
    $prop_spec->[META_PROP_INDEXED] = $indexed;
    $prop_spec->[META_PROP_DESC]    = $desc;
		
	my ($prop_type, $prop_type_params) = split(/:/, $type);
	my $pkg = "Trinket::DataType::$prop_type";
	eval "require $pkg";
	$pkg = 'Trinket::DataType::default' if ($@);
	($pkg)->install_methods($self, $name);
	
    return $self->_set_prop_meta($name => $prop_spec);
  }

# }}}
# {{{ remove_property(): Delete a property from the object

=item $obj->remove_property('prop_name');

Remove a named property from the object.  After deletion, it will no
longer be recognized as a property to set or get, and will not be used
by the object directory in any operations.

=cut

sub remove_property
  {
    my ($self, $name, $meta) = @_;

    ### Delete the property data from the object
    delete $self->[OBJ_PROPS]->{$name};

	my $prop_meta = $self->_get_prop_meta($name);
	my ($prop_type, $prop_type_params) =
	  split(/:/, $prop_meta->[META_PROP_TYPE]);
	my $pkg = "Trinket::DataType::$prop_type";
	eval "require $pkg";
	$pkg = 'Trinket::DataType::default' if ($@);
	($pkg)->uninstall_methods($self, $name);
	
    ### Delete the property metadata from the object
    return $self->_set_prop_meta($name => undef);
  }

# }}}
# {{{ list_properties(): List property names in the object.

=item $obj->list_properties();

Return a list of properties in the object.

=cut

sub list_properties
  {
    my ($self) = @_;

    my @props = ();
    {
      no strict 'refs';
      my $pkg = ref($self);
      foreach (keys %{"$pkg\::PROPERTIES"})
        { push @props, $_; }
    }
    foreach (keys %{$self->[OBJ_META_PROPS]})
      { push @props, $_; }

    return @props;
  }

# }}}
# {{{ list_indices(): List property names in the object.

=item $obj->list_indices();

Return a list of indexed properties in the object.

=cut

sub list_indices
  {
    my ($self) = @_;

    my @indices = ();
    my $props = $self->[OBJ_PROPS];
    my ($name, $prop, $prop_meta);
    while (($name, $prop) = each %{$props})
      {
        $prop_meta = $self->_get_prop_meta($name);
        push @indices if ($prop_meta->[META_PROP_INDEXED]);
      }

    return @indices;
  }

# }}}

# {{{ _find_dirty(): Find dirty indexed properties, return old/new values

sub _find_dirty
  {
    my $self = shift;

    my (%dirty_props, $name, $prop, $prop_meta);
    my $props = $self->[OBJ_PROPS];
    while (($name, $prop) = each %{$props})
      {
        $prop_meta = $self->_get_prop_meta($name);
        if ($prop->[PROP_DIRTY])
          {
            $dirty_props{$name} = [ $prop->[PROP_CLEAN_VALUE],
                                    $prop->[PROP_VALUE] ];
          }
      }

    return \%dirty_props;
  }

# }}}
# {{{ _find_dirty_indices(): Find dirty indexed properties, return old/new values

sub _find_dirty_indices {
    my $self = shift;

    my (%dirty_props, $name, $prop, $prop_meta);
    my $props = $self->[OBJ_PROPS];
    while (($name, $prop) = each %{$props}) {
        $prop_meta = $self->_get_prop_meta($name);
        if ($prop_meta->[META_PROP_INDEXED]) {
			if ($prop->[PROP_DIRTY]) {
				$dirty_props{$name} = [ $prop->[PROP_CLEAN_VALUE],
										$prop->[PROP_VALUE] ];
			}
		}
	}
	
    return \%dirty_props;
}

# }}}
# {{{ _clean_all(): Mark all dirty properties as clean.

sub _clean_all
  {
    my $self = shift;

    my (%dirty_props);
    my $props = $self->[OBJ_PROPS];
    while (my($name, $prop) = each %{$props})
      { $prop->[PROP_DIRTY] = 0; }

    return \%dirty_props;
  }

# }}}
# {{{ _dirty_all(): Mark all dirty properties as clean.

sub _dirty_all {
    my $self = shift;
	
    my (%dirty_props);
    my $props = $self->[OBJ_PROPS];
    while (my($name, $prop) = each %{$props}) {
		$prop->[PROP_DIRTY] = 1;
	}
	
    return \%dirty_props;
}

# }}}

# {{{ _set_prop_meta(): Set the metadata for a named property

sub _set_prop_meta
  {
    my ($self, $name, $meta) = @_;

    if (defined $meta)
      { return $self->[OBJ_META_PROPS]->{$name} = $meta; }
    else
      {
        delete $self->[OBJ_META_PROPS]->{$name};
        return undef;
      }
  }

# }}}
# {{{ _get_prop_meta(): Get the metadata for a named property

sub _get_prop_meta {
	no strict 'refs';
    my ($self, $name) = @_;
	
    ### Attempt to retrieve the metadata for this property
    my $pkg = ref($self);
    my $prop_meta;

	$prop_meta = $self->[OBJ_META_PROPS]->{$name} ||
		  (${"$pkg\::PROPERTIES"}{$name});
	
	### Convert hash-style definition into array-style
	### TODO: Need to cache this!
	if (ref($prop_meta) eq "HASH") {
		my $new_prop_meta = [];
		my $prop_map = META_PROP_MAP;
		foreach my $map_name ( keys %{$prop_map} ) {
			$new_prop_meta->[$prop_map->{$map_name}] = $prop_meta->{$map_name};
		}
		
		$prop_meta = $new_prop_meta;
		
		if (defined $self->[OBJ_META_PROPS]->{$name}) {
			$self->[OBJ_META_PROPS]->{$name} = $prop_meta;
		} elsif (defined ${"$pkg\::PROPERTIES"}{$name}) {
			${"$pkg\::PROPERTIES"}{$name} = $prop_meta;
		}
	}

    return $prop_meta;
}

# }}}
# {{{ _derive_ancestry(): Derive the class ancestry for an object or class

sub _derive_ancestry
  {
    my $obj  = shift;
    my $anc  = shift || {};

    my $class = (ref($obj)) ? ref($obj) : $obj;

    my @isa = eval('@'.$class.'::ISA');

    ### Iterate through each class in the ancestry and mark it,
    ### then derive ancestry for each class in the ancestry
    $anc->{$class}++;
    foreach (@isa)
      { _derive_ancestry($_, $anc); }

    ### Return the list of ancestors for this class.
    return keys %$anc;
  }

# }}}

# {{{ DESTROY

sub DESTROY
  {
    ## no-op to pacify warnings
  }

# }}}

# {{{ End POD

=back

=head1 AUTHOR

Maintained by Leslie Michael Orchard <F<deus_x@pobox.com>>

=head1 COPYRIGHT

Copyright (c) 2000, Leslie Michael Orchard.  All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# }}}

1;
__END__

