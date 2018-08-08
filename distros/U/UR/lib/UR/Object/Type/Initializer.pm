# This line forces correct deployment by some tools.
package UR::Object::Type::Initializer;

package UR::Object::Type;

use strict;
use warnings;
require UR;

use UR::Util;

BEGIN {
    # Perl 5.10 did not require mro in order to call get_mro but it looks
    # like that was "fixed" in newer version.
    if ($^V ge v5.9.5) {
        eval "require mro";
    }
};

our $VERSION = "0.47"; # UR $VERSION;

use Carp ();
use Sub::Name ();
use Sub::Install ();

# keys are class property names (like er_role, is_final, etc) and values are
# the default value to use if it's not specified in the class definition
#
# For most classes, this kind of thing is handled by the default_value attribute on
# a class' property.  For bootstrapping reasons, the default values for the
# properties of UR::Object::Type' class need to be listed here as well.  If
# any of these change, or new default valued items are added, be sure to also
# update the class definition for UR::Object::Type (which really lives in UR.pm
# for the moment)
%UR::Object::Type::defaults = (
    er_role            => 'entity',
    is_final           => 0,
    is_singleton       => 0,
    is_transactional   => 1,
    is_mutable         => 1,
    is_many            => 0,
    is_abstract        => 0,
    subclassify_by_version => 0,
);

# All those same comments also apply to UR::Object::Property's properties
%UR::Object::Property::defaults = (
    is_optional      => 0,
    is_transient     => 0,
    is_constant      => 0,
    is_volatile      => 0,
    is_classwide    => 0,
    is_delegated     => 0,
    is_calculated    => 0,
    is_mutable       => undef,
    is_transactional => 1,
    is_many          => 0,
    is_numeric       => 0,
    is_specified_in_module_header => 0,
    is_deprecated    => 0,
    position_in_module_header => -1,
    doc_position    => -1,
    is_undocumented => 0,
);

@UR::Object::Type::meta_id_ref_shared_properties = (
    qw/
        is_optional
        is_transient
        is_constant
        is_volatile
        is_classwide
        is_transactional
        is_abstract
        is_concrete
        is_final
        is_many
        is_deprecated
        is_undocumented
    /
);

%UR::Object::Type::converse = (
    required => 'optional',
    abstract => 'concrete',
    one => 'many',
);

# These classes are used to define an object class.
# As such, they get special handling to bootstrap the system.

our %meta_classes = map { $_ => 1 }
    qw/
        UR::Object
        UR::Object::Type
        UR::Object::Property
    /;

our $bootstrapping = 1;
our @partially_defined_classes;

# When copying the object hash to create its db_committed, these keys should be removed because
# they contain things like coderefs
our @keys_to_delete_from_db_committed = qw( id db_committed _id_property_sorter get_composite_id_resolver get_composite_id_decomposer );

# Stages of Class Initialization
#
# define() is called to indicate the class structure (create() may also be called by the db sync command to make new classes)
#
# the parameters to define()/create() are normalized by _normalize_class_description()
#
# a basic functional class meta object is created by _define_minimal_class_from_normalized_class_description()
#
#  accessors are created
#
# if we're still bootstrapping:
#
#  the class is stashed in an array so the post-bootstrapping stages can be done in bulk
#
#  we exit define()
#
# if we're done bootstrapping:
#
# _inform_all_parent_classes_of_newly_loaded_subclass() sets up an internal map of known subclasses of each base class
#
# _complete_class_meta_object_definitions() decomposes the definition into normalized objects
#

sub __define__ {
    my $class = shift;
    my $desc = $class->_normalize_class_description(@_);

    my $class_name = $desc->{class_name} ||= (caller(0))[0];
    $desc->{class_name} = $class_name;

    my $self;

    my %params = $class->_construction_params_for_desc($desc);
    my $meta_class_name;
    if (%params) {
        $self = __PACKAGE__->__define__(%params);
        return unless $self;
        $meta_class_name = $params{class_name};
    }
    else {
        $meta_class_name = __PACKAGE__;
    }

    $self = $UR::Context::all_objects_loaded->{$meta_class_name}{$class_name};
    if ($self) {
        #$DB::single = 1;
        #Carp::cluck("Re-defining class $class_name?  Found $meta_class_name with id '$class_name'");
        return $self;
    }

    $self = $class->_make_minimal_class_from_normalized_class_description($desc);
    Carp::confess("Failed to define class $class_name!") unless $self;

    # we do this for define() but not create()
    my %db_committed = %$self;
    delete @db_committed{@keys_to_delete_from_db_committed};
    $self->{'db_committed'} = \%db_committed;

    $self->_initialize_accessors_and_inheritance
        or Carp::confess("Error initializing accessors for $class_name!");

    if ($bootstrapping) {
        push @partially_defined_classes, $self;
    }
    else {
        unless ($self->_inform_all_parent_classes_of_newly_loaded_subclass()) {
            Carp::confess(
                "Failed to link to parent classes to complete definition of class $class_name!"
                . $class->error_message
            );
        }
        unless ($self->_complete_class_meta_object_definitions()) {
            #$DB::single = 1;
            $self->_complete_class_meta_object_definitions();
            Carp::confess(
                "Failed to complete definition of class $class_name!"
                . $class->error_message
            );
        }
    }

    $self->_inform_roles_of_new_class();

    return $self;
}


sub create {
    # this is typically only used by code which intendes to autogenerate source code
    # it will lead to the writing of a Perl module upon commit.
    my $class = shift;
    my $desc = $class->_normalize_class_description(@_);

    my $class_name = $desc->{class_name} ||= (caller(0))[0];
    my $meta_class_name = $desc->{meta_class_name};

    no strict 'refs';
    unless (
        $meta_class_name eq __PACKAGE__
        or
        # in newer Perl interpreters the ->isa() call can return true
        # even if @ISA has been emptied (OS X) ???
        (scalar(@{$meta_class_name . '::ISA'}) and $meta_class_name->isa(__PACKAGE__))
    ) {
        if (__PACKAGE__->get(class_name => $meta_class_name)) {
            warn "class $meta_class_name already exists when creating class meta for $class_name?!";
        }
        else {
            __PACKAGE__->create(
                __PACKAGE__->_construction_params_for_desc($desc)
            );
        }
    }

    my $self = $class->_make_minimal_class_from_normalized_class_description($desc);
    Carp::confess("Failed to define class $class_name!") unless $self;

    $self->_initialize_accessors_and_inheritance
        or Carp::confess("Failed to define class $class_name!");

    $self->_inform_all_parent_classes_of_newly_loaded_subclass()
        or Carp::confess(
            "Failed to link to parent classes to complete definition of class $class_name!"
            . $class->error_message
        );

    $self->generated(0);

    $self->__signal_change__("create");

    return $self;
}

sub _preprocess_subclass_description {
    # allow a class to modify the description of any subclass before it instantiates
    # this filtering allows a base class to specify policy, add meta properties, etc.
    my ($self,$prev_desc) = @_;

    my $current_desc = $prev_desc;

    if (my $preprocessor = $self->subclass_description_preprocessor) {
        # the preprocessor must me a method name in the class being adjusted
        no strict 'refs';
        unless ($self->class_name->can($preprocessor)) {
            die "Class " . $self->class_name
                . " specifies a pre-processor for subclass descriptions "
                . $preprocessor . " which is not defined in the "
                . $self->class_name . " package!";
        }
        $current_desc = $self->class_name->$preprocessor($current_desc);
        $current_desc = $self->_normalize_class_description_impl(%$current_desc);
    }

    # only call it on the direct parent classes, let recursion walk the tree
    my @parent_class_names =
        grep { $_->can('__meta__') }
        $self->parent_class_names();

    for my $parent_class_name (@parent_class_names) {
        my $parent_class = $parent_class_name->__meta__;
        $current_desc = $parent_class->_preprocess_subclass_description($current_desc);
    }

    return $current_desc;
}

sub _construction_params_for_desc {
    my $class = shift;
    my $desc = shift;

    my $class_name = $desc->{class_name};
    my $meta_class_name = $desc->{meta_class_name};
    my @extended_metadata;
    if ($desc->{type_has}) {
        @extended_metadata = ( has => [ @{ $desc->{type_has} } ] );
    }

    if (
        $meta_class_name eq __PACKAGE__
    ) {
        if (@extended_metadata) {
            die "Cannot extend class metadata of $class_name because it is a class involved in UR bootstrapping.";
        }
        return();
    }
    else {
        if ($bootstrapping) {
            return (
                class_name => $meta_class_name,
                is => __PACKAGE__,
                @extended_metadata,
            );
        }
        else {
            my $parent_classes = $desc->{is};
            my @meta_parent_classes = map { $_ . '::Type' } @$parent_classes;
            for (@$parent_classes) {
                __PACKAGE__->use_module_with_namespace_constraints($_);
                eval {$_->class};
                if ($@) {
                    die "Error with parent class $_ when defining $class_name! $@";
                }
            }
            return (
                class_name => $meta_class_name,
                is => \@meta_parent_classes,
                @extended_metadata,
            );
        }
    }

}



sub initialize_bootstrap_classes
{
    # This is called once at the end of compiling the UR module set to handle
    # classes which did incomplete initialization while bootstrapping.
    # Until bootstrapping occurs is done,
    my $class = shift;

    for my $class_meta (@partially_defined_classes) {
        unless ($class_meta->_inform_all_parent_classes_of_newly_loaded_subclass) {
            my $class_name = $class_meta->{class_name};
            Carp::confess (
                "Failed to complete inheritance linkage definition of class $class_name!"
                . $class_meta->error_message
            );
        }

    }
    while (my $class_meta = shift @partially_defined_classes) {
        unless ($class_meta->_complete_class_meta_object_definitions()) {
            my $class_name = $class_meta->{class_name};
            Carp::confess(
                "Failed to complete definition of class $class_name!"
                . $class_meta->error_message
            );
        }
    }
    $bootstrapping = 0;

    # It should be safe to set up callbacks now.  register_callback() instead
    # of create() so a subsequent rollback won't remove the observer.
    UR::Observer->register_callback(
        subject_class_name => 'UR::Object::Property',
        subject_id => '',
        aspect => '',
        priority => 1,
        note => '',
        once => 0,
        callback => \&UR::Object::Type::_property_change_callback,
    );
}

sub _normalize_class_description {
    my $class = shift;
    my $desc = $class->_normalize_class_description_impl(@_);

    $class->compose_roles($desc) unless $bootstrapping;

    unless ($bootstrapping) {
        for my $parent_class_name (@{ $desc->{is} }) {
            my $parent_class = $parent_class_name->__meta__;
            $desc = $parent_class->_preprocess_subclass_description($desc);
        }
    }

    # we previously handled property meta extensions when normalizing the property
    # now we merely save unrecognized things
    # this is now done afterward so that parent classes can preprocess their subclasses descriptions before extending
    # normalize the data behind the property descriptions
    my @property_names = keys %{$desc->{has}};
    for my $property_name (@property_names) {
        Carp::croak("Invalid property name in class ".$desc->{class_name}.": '$property_name'")
            unless UR::Util::is_valid_property_name($property_name);

        my $pdesc = $desc->{has}->{$property_name};
        my $unknown_ma = delete $pdesc->{unrecognized_meta_attributes};
        next unless $unknown_ma;
        for my $name (keys %$unknown_ma) {
            if (exists $desc->{attributes_have}->{$name}) {
                $pdesc->{$name} = delete $unknown_ma->{$name};
            }
        }
        if (%$unknown_ma) {
            my $class_name = $desc->{class_name};
            my @unknown_ma = sort keys %$unknown_ma;
            Carp::confess("unknown meta-attributes present for $class_name $property_name: @unknown_ma\n");
        }
    }

    return $desc;
}

sub _canonicalize_class_params {
    my($params, $mappings) = @_;

    my %canon_params;

    for my $mapping ( @$mappings ) {
        my ($primary_field_name, @alternate_field_names) = @$mapping;
        my @all_fields = ($primary_field_name, @alternate_field_names);
        my @values = grep { defined($_) } delete @$params{@all_fields};
        if (@values > 1) {
            Carp::confess(
                "Multiple values in for field "
                . join("/", @all_fields)
            );
        }
        elsif (@values == 1) {
            $canon_params{$primary_field_name} = $values[0];
        }
    }

    return %canon_params;
}

our @CLASS_DESCRIPTION_KEY_MAPPINGS_COMMON_TO_CLASSES_AND_ROLES = (
        [ roles                 => qw//],
        [ is_abstract           => qw/abstract/],
        [ is_final              => qw/final/],
        [ is_singleton          => qw//],
        [ is_transactional      => qw//],
        [ id_by                 => qw/id_properties/],
        [ has                   => qw/properties/],
        [ type_has              => qw//],
        [ attributes_have       => qw//],
        [ er_role               => qw/er_type/],
        [ doc                   => qw/description/],
        [ relationships         => qw//],
        [ constraints           => qw/unique_constraints/],
        [ namespace             => qw//],
        [ schema_name           => qw//],
        [ data_source_id        => qw/data_source instance/],
        [ select_hint            => qw/query_hint/],
        [ join_hint             => qw//],
        [ subclassify_by        => qw/sub_classification_property_name/],
        [ sub_classification_meta_class_name    => qw//],
        [ sub_classification_method_name        => qw//],
        [ first_sub_classification_method_name  => qw//],
        [ composite_id_separator                => qw//],
        [ generate               => qw//],
        [ generated              => qw//],
        [ subclass_description_preprocessor => qw//],
        [ id_generator           => qw/id_sequence_generator_name/],
        [ subclassify_by_version => qw//],
        [ meta_class_name        => qw//],
        [ valid_signals          => qw//],
);

my @CLASS_DESCRIPTION_KEY_MAPPINGS = (
        @CLASS_DESCRIPTION_KEY_MAPPINGS_COMMON_TO_CLASSES_AND_ROLES,
        [ class_name            => qw//],
        [ type_name             => qw/english_name/],
        [ is                    => qw/inheritance extends isa is_a/],
        [ table_name            => qw/sql dsmap/],
);

sub _normalize_class_description_impl {
    my $class = shift;
    my %old_class = @_;

    if (exists $old_class{extra}) {
        %old_class = (%{delete $old_class{extra}}, %old_class);
    }

    my $class_name = delete $old_class{class_name};

    my %new_class = (
        class_name      => $class_name,
        is_singleton    => $UR::Object::Type::defaults{'is_singleton'},
        is_final        => $UR::Object::Type::defaults{'is_final'},
        is_abstract     => $UR::Object::Type::defaults{'is_abstract'},
        _canonicalize_class_params(\%old_class, \@CLASS_DESCRIPTION_KEY_MAPPINGS),
    );

    if (my $pp = $new_class{subclass_description_preprocessor}) {
        if (!ref($pp)) {
            unless ($pp =~ /::/) {
                # a method name, not fully qualified
                $new_class{subclass_description_preprocessor} =
                    $new_class{class_name}
                        . '::'
                            . $new_class{subclass_description_preprocessor};
            } else {
                $new_class{subclass_description_preprocessor} = $pp;
            }
        }
        elsif (ref($pp) ne 'CODE') {
            die "unexpected " . ref($pp) . " reference for subclass_description_preprocessor for $class_name!";
        }
    }

    unless ($new_class{er_role}) {
        $new_class{er_role} = $UR::Object::Type::defaults{'er_role'};
    }

    my @crap = qw/source/;
    delete @old_class{@crap};

    if ($class_name =~ /^(.*?)::/) {
        $new_class{namespace} = $1;
    }
    else {
        $new_class{namespace} = $new_class{class_name};
    }

    if (not exists $new_class{is_transactional}
        and not $meta_classes{$class_name}
    ) {
        $new_class{is_transactional} = $UR::Object::Type::defaults{'is_transactional'};
    }

    unless ($new_class{is}) {
        no warnings;
        no strict 'refs';
        if (my @isa = @{ $class_name . "::ISA" }) {
            $new_class{is} = \@isa;
        }
    }

    unless ($new_class{is}) {
        if ($new_class{table_name}) {
            $new_class{is} = ['UR::Entity']
        }
        else {
            $new_class{is} = ['UR::Object']
        }
    }

    unless ($new_class{'doc'}) {
        $new_class{'doc'} = undef;
    }

    foreach my $key ( qw(valid_signals roles) ) {
        unless (UR::Util::ensure_arrayref(\%new_class, $key)) {
            Carp::croak("The '$key' metadata for class $class_name must be an arrayref");
        }
    }

    # Later code expects these to be listrefs
    for my $field (qw/is id_by has relationships constraints/) {
        _massage_field_into_arrayref(\%new_class, $field);
    }


    # These may have been found and moved over.  Restore.
    $old_class{has}             = delete $new_class{has};
    $old_class{attributes_have} = delete $new_class{attributes_have};

    # Install structures to track fully formatted property data.
    my $instance_properties = $new_class{has} = {};
    my $meta_properties     = $new_class{attributes_have} = {};

    # The id might be a single value, or not specified at all.
    my $id_properties;
    if (not exists $new_class{id_by}) {
        if ($new_class{is}) {
            $id_properties = $new_class{id_by} = [];
        }
        else {
            $id_properties = $new_class{id_by} = [ id => { is_optional => 0 } ];
        }
    }
    elsif ( (not ref($new_class{id_by})) or (ref($new_class{id_by}) ne 'ARRAY') ) {
        $id_properties = $new_class{id_by} = [ $new_class{id_by} ];
    }
    else {
        $id_properties = $new_class{id_by};
    }

    _normalize_id_property_data(\%old_class, \%new_class);

    if (@$id_properties > 1
        and grep {$_ eq 'id'} @$id_properties)
    {
        Carp::croak("Cannot initialize class $class_name: "
                    . "Cannot have an ID property named 'id' when the class has multiple ID properties ("
                    . join(', ', map { "'$_'" } @$id_properties)
                    . ")");
    }

    _process_class_definition_property_keys(\%old_class, \%new_class);

    # NOT ENABLED YET
    if (0) {
        # done processing direct properties of this process
        # extend %$instance_properties with properties of the parent classes
        my @parent_class_names = @{ $new_class{is} };
        for my $parent_class_name (@parent_class_names) {
            my $parent_class_meta = $parent_class_name->__meta__;
            die "no meta for $parent_class_name while initializing $class_name?" unless $parent_class_meta;
            my $parent_normalized_properties = $parent_class_meta->{has};
            for my $parent_property_name (keys %$parent_normalized_properties) {
                my $parent_property_data = $parent_normalized_properties->{$parent_property_name};
                my $inherited_copy = $instance_properties->{$parent_property_name};
                unless ($inherited_copy) {
                    $inherited_copy = UR::Util::deep_copy($parent_property_data);
                }
                $inherited_copy->{class_name} = $class_name;
                my $override = $inherited_copy->{overrides_class_names} ||= [];
                push @$override, $parent_property_data->{class_name};
            }
        }
    }

    if (($new_class{data_source_id} and not ref($new_class{data_source_id})) and not $new_class{schema_name}) {
        my $s = $new_class{data_source_id};
        $s =~ s/^.*::DataSource:://;
        $new_class{schema_name} = $s;
    }

    if (%old_class) {
        # this should have all been deleted above
        # we actually process it later, since these may be related to parent classes extending
        # the class definition
        $new_class{extra} = \%old_class;
    };

    # ensure parent classes are loaded
    unless ($bootstrapping) {
        my @base_classes = map { ref($_) ? @$_ : $_ } $new_class{is};
        for my $parent_class_name (@base_classes) {
            # ensure the parent classes are fully processed
            no warnings;
            unless ($parent_class_name->can("__meta__")) {
                __PACKAGE__->use_module_with_namespace_constraints($parent_class_name);
                Carp::croak("Class $class_name cannot initialize because of errors using parent class $parent_class_name: $@") if $@;
            }
            unless ($parent_class_name->can("__meta__")) {
                if ($ENV{'HARNESS_ACTIVE'}) {
                    Carp::confess("Class $class_name cannot initialize because of errors using parent class $parent_class_name.  Failed to find static method '__meta__' on $parent_class_name.  Does class $parent_class_name exist, and is it loaded?\n  The entire list of base classes was ".join(', ', @base_classes));
                }
                Carp::croak("Class $class_name cannot initialize because of errors using parent class $parent_class_name.  Failed to find static method '__meta__' on $parent_class_name.  Does class $parent_class_name exist, and is it loaded?");
            }
            my $parent_class = $parent_class_name->__meta__;
            unless ($parent_class) {
                Carp::carp("No class metadata object for $parent_class_name");
                next;
            }

            # the the parent classes indicate version, if needed
            if ($parent_class->{'subclassify_by_version'} and not $parent_class_name =~ /::Ghost/) {
                unless ($class_name =~ /^${parent_class_name}::V\d+/) {
                    my $ns = $parent_class_name;
                    $ns =~ s/::.*//;
                    my $version;
                    if ($ns and $ns->can("component_version")) {
                        $version = $ns->component_version($class);
                    }
                    unless ($version) {
                        $version = '1';
                    }
                    $parent_class_name = $parent_class_name . '::V' . $version;
                    eval "use $parent_class_name";
                    Carp::confess("Error using versioned module $parent_class_name!:\n$@") if $@;
                    redo;
                }
            }
        }
        $new_class{is} = \@base_classes;
    }

    # allow parent classes to adjust the description in systematic ways
    my @additional_property_meta_attributes;
    unless ($bootstrapping) {
        for my $parent_class_name (@{ $new_class{is} }) {
            my $parent_class = $parent_class_name->__meta__;
            if (my $parent_meta_properties = $parent_class->{attributes_have}) {
                push @additional_property_meta_attributes, %$parent_meta_properties;
            }
        }
    }

    __PACKAGE__->_normalize_property_descriptions_during_normalize_class_description(\%new_class);

    unless ($bootstrapping) {
        %$meta_properties = (%$meta_properties, @additional_property_meta_attributes);

        # Inheriting from an abstract class that subclasses with a subclassify_by means that
        # this class' property named by that subclassify_by is actually a constant equal to this
        # class' class name
        PARENT_CLASS:
        foreach my $parent_class_name ( @{ $new_class{'is'} }) {
            my $parent_class_meta = $parent_class_name->__meta__();
            foreach my $ancestor_class_meta ( $parent_class_meta->all_class_metas ) {
                if (my $subclassify_by = $ancestor_class_meta->subclassify_by) {
                    if (not $instance_properties->{$subclassify_by}) {
                        my %old_property = (
                            property_name => $subclassify_by,
                            default_value => $class_name,
                            is_constant => 1,
                            is_classwide => 1,
                            is_specified_in_module_header => 0,
                            column_name => '',
                            implied_by => $parent_class_meta->class_name . '::subclassify_by',
                        );
                        my %new_property = $class->_normalize_property_description1($subclassify_by, \%old_property, \%new_class);
                        my %new_property2 = $class->_normalize_property_description2(\%new_property, \%new_class);
                        $instance_properties->{$subclassify_by} = \%new_property2;
                        last PARENT_CLASS;
                    }
                }
            }
        }
    }

    my $meta_class_name = __PACKAGE__->_resolve_meta_class_name_for_class_name($class_name);
    $new_class{meta_class_name} ||= $meta_class_name;
    return \%new_class;
}

# Transform the id properties into a list of raw ids,
# and move the property definitions into "id_implied"
# where present so they can be processed below.
sub _normalize_id_property_data {
    my($old_class_desc, $new_class_desc) = @_;

    my $id_properties = $new_class_desc->{id_by};
    my $property_rank = 0;
    my @replacement;
    my $pos = 0;

    for(my $n = 0; $n < @$id_properties; $n++) {
        my $name = $id_properties->[$n];

        my $data = $id_properties->[$n+1];
        if (ref($data)) {
            $old_class_desc->{id_implied}->{$name} ||= $data;
            if (my $obj_ids = $data->{id_by}) {
                push @replacement, (ref($obj_ids) ? @$obj_ids : ($obj_ids));
            }
            else {
                push @replacement, $name;
            }
            $n++;
        }
        else {
            $old_class_desc->{id_implied}->{$name} ||= {};
            push @replacement, $name;
        }
        $old_class_desc->{id_implied}->{$name}->{'position_in_module_header'} = $pos++;
    }
    @$id_properties = @replacement;
}

# Given several different kinds of input, convert it into an arrayref
sub _massage_field_into_arrayref {
    my($class_desc, $field_name) = @_;

    my $value = $class_desc->{$field_name};
    my $reftype = ref $value;
    if (! exists $class_desc->{$field_name}) {
        $class_desc->{$field_name} = [];

    } elsif (! $reftype) {
        # It's a plain string, wrap it in an arrayref
        $class_desc->{$field_name} = [ $value ];

    } elsif ($reftype eq 'HASH') {
        # Later code expects it to be a listref - convert it
        $class_desc->{$field_name} = [ %$value ];

    } elsif ($reftype ne 'ARRAY') {
        my $class_name = $class_desc->{class_name};
        Carp::croak "$class_name cannot initialize because its $field_name section is not a string, arrayref or hashref";

    }
}

sub _normalize_property_descriptions_during_normalize_class_description {
    my($class, $new_class) = @_;

    my $instance_properties = $new_class->{has};

    # normalize the data behind the property descriptions
    my @property_names = keys %$instance_properties;
    for my $property_name (@property_names) {
        my %old_property = %{ $instance_properties->{$property_name} };
        my %new_property = $class->_normalize_property_description1($property_name, \%old_property, $new_class);
        %new_property = $class->_normalize_property_description2(\%new_property, $new_class);
        $instance_properties->{$property_name} = \%new_property;
    }

    # Find 'via' properties where the to is '-filter' and rewrite them to
    # copy some attributes from the source property
    # This feels like a hack, but it makes other parts of the system easier by
    # not having to deal with -filter
    foreach my $property_name ( @property_names ) {
        my $property_data = $instance_properties->{$property_name};
        if ($property_data->{'to'} && $property_data->{'to'} eq '-filter') {
            my $via = $property_data->{'via'};
            my $via_property_data = $instance_properties->{$via};
            unless ($via_property_data) {
                my $class_name = $new_class->{class_name};
                Carp::croak "Cannot initialize class $class_name: Property '$property_name' filters '$via', but there is no property '$via'.";
            }

            $property_data->{'data_type'} = $via_property_data->{'data_type'};
            $property_data->{'reverse_as'} = $via_property_data->{'reverse_as'};
            if ($via_property_data->{'where'}) {
                unshift @{$property_data->{'where'}}, @{$via_property_data->{'where'}};
            }
        }
    }

    # Catch a mistake in the class definition where a property is 'via'
    # something, and its 'to' is the same as the via's reverse_as.  This
    # ends up being a circular definition and generates junk SQL
    foreach my $property_name ( @property_names ) {
        my $property_data = $instance_properties->{$property_name};
        my $via = $property_data->{'via'};
        my $to  = $property_data->{'to'};
        if (defined($via) and defined($to)) {
            my $via_property_data = $instance_properties->{$via};
            next unless ($via_property_data and $via_property_data->{'reverse_as'});
            if ($via_property_data->{'reverse_as'} eq $to) {
                my $class_name = $new_class->{class_name};
                Carp::croak("Cannot initialize class $class_name: Property '$property_name' defines "
                            . "an incompatible relationship.  Its 'to' is the same as reverse_as for property '$via'");
            }
        }
    }
}

sub _process_class_definition_property_keys {
    my($old_class, $new_class) = @_;

    my($class_name, $instance_properties, $meta_properties) = @$new_class{'class_name', 'has','attributes_have'};
    $class_name ||= $new_class->{role_name};  # This is used by role construction, too

    # Flatten and format the property list(s) in the class description.
    # NOTE: we normalize the details at the end of normalizing the class description.
    my @keys = _class_definition_property_keys_in_processing_order($old_class);
    foreach my $key ( @keys ) {
        # parse the key to see if we're looking at instance or meta attributes,
        # and take the extra words as additional attribute meta-data.
        my @added_property_meta;
        my $properties;
        if ($key =~ /has/) {
            @added_property_meta =
                grep { $_ ne 'has' } split(/[_-]/,$key);
            $properties = $instance_properties;
        }
        elsif ($key =~ /attributes_have/) {
            @added_property_meta =
                grep { $_ ne 'attributes' and $_ ne 'have' } split(/[_-]/,$key);
            $properties = $meta_properties;
        }
        elsif ($key eq 'id_implied') {
            # these are additions to the regular "has" list from complex identity properties
            $properties = $instance_properties;
        }
        else {
            die "Odd key $key?";
        }
        @added_property_meta = map { 'is_' . $_ => 1 } @added_property_meta;

        # the property data can be a string, array, or hash as they come in
        # convert string, hash and () into an array
        my $property_data = delete $old_class->{$key};

        my @tmp;
        if (!ref($property_data)) {
            if (defined($property_data)) {
                @tmp  = split(/\s+/, $property_data);
            }
            else {
                @tmp = ();
            }
        }
        elsif (ref($property_data) eq 'HASH') {
            @tmp = map {
                    ($_ => $property_data->{$_})
                } sort keys %$property_data;
        }
        elsif (ref($property_data) eq 'ARRAY') {
            @tmp = @$property_data;
        }
        else {
            die "Unrecognized data $property_data appearing as property list!";
        }

        # process the array of property specs
        my $pos = 0;
        while (my $name = shift @tmp) {
            my $params;
            if (ref($tmp[0])) {
                $params = shift @tmp;
                unless (ref($params) eq 'HASH') {
                    my $seen_type = ref($params);
                    Carp::confess("class $class_name property $name has a $seen_type reference instead of a hashref describing its meta-attributes!");
                }
                %$params = (@added_property_meta, %$params) if @added_property_meta;
            }
            else {
                $params = { @added_property_meta };
            }

            unless (exists $params->{'position_in_module_header'}) {
                $params->{'position_in_module_header'} = $pos++;
            }
            unless (exists $params->{is_specified_in_module_header}) {
                $params->{is_specified_in_module_header} = $class_name . '::' . $key;
            }

            # Indirect properties can mention the same property name more than once.  To
            # avoid stomping over existing property data with this other property data,
            # merge the new info into the existing hash.  Otherwise, the new property name
            # gets an empty hash of info
            if ($properties->{$name}) {
                # this property already exists, but is also implied by some other property which added it to the end of the listed
                # extend the existing definition
                foreach my $key ( keys %$params ) {
                    next if ($key eq 'is_specified_in_module_header' || $key eq 'position_in_module_header');
                    # once a property gets set to is_optional => 0, it stays there, even if it's later set to 1
                    next if ($key eq 'is_optional'
                             and
                             exists($properties->{$name}->{'is_optional'})
                             and
                             defined($properties->{$name}->{'is_optional'})
                             and
                             $properties->{$name}->{'is_optional'} == 0);
                    $properties->{$name}->{$key} = $params->{$key};
                }
                $params = $properties->{$name};
            } else {
                $properties->{$name} = $params;
            }

            # a single calculate_from can be a simple string, convert to a listref
            if (my $calculate_from = $params->{'calculate_from'}) {
                $params->{'calculate_from'} = [ $calculate_from ] unless (ref($calculate_from) eq 'ARRAY');
            }

            if (my $id_by = $params->{id_by}) {
                $id_by = [ $id_by ] unless ref($id_by) eq 'ARRAY';
                my @id_by_names;
                while (@$id_by) {
                    my $id_name = shift @$id_by;
                    my $params2;
                    if (ref($id_by->[0])) {
                        $params2 = shift @$id_by;
                    }
                    else {
                        $params2 = {};
                    }
                    for my $p (@UR::Object::Type::meta_id_ref_shared_properties) {
                        if (exists $params->{$p}) {
                            $params2->{$p} = $params->{$p};
                        }
                    }
                    $params2->{implied_by} = $name;
                    $params2->{is_specified_in_module_header} = 0;

                    push @id_by_names, $id_name;
                    push @tmp, $id_name, $params2;
                }
                $params->{id_by} = \@id_by_names;
            }

            if (my $id_class_by = $params->{'id_class_by'}) {
                if (ref $id_class_by) {
                    Carp::croak("Cannot initialize class $class_name: "
                                . "Property $name has an 'id_class_by' that is not a plain string");
                }
                push @tmp, $id_class_by, { implied_by => $name, is_specified_in_module_header => 0 };
            }

        } # next property in group

        # id-by properties' metadata can influence the id-ed-by property metadata
        for my $pdata (values %$properties) {
            next unless $pdata->{id_by};
            for my $id_property (@{ $pdata->{id_by} }) {
                my $id_pdata = $properties->{$id_property};
                for my $p (@UR::Object::Type::meta_id_ref_shared_properties) {
                    if (exists $id_pdata->{$p} xor exists $pdata->{$p}) {
                        # if one or the other specifies a value, copy it to the one that's missing
                        $id_pdata->{$p} = $pdata->{$p} = $id_pdata->{$p} || $pdata->{$p};
                    } elsif (!exists $id_pdata->{$p} and !exists $pdata->{$p} and exists $UR::Object::Property::defaults{$p}) {
                        # if neither has a value, use the default for both
                        $id_pdata->{$p} = $pdata->{$p} = $UR::Object::Property::defaults{$p};
                    }
                }
            }
        }

    }
}

sub compose_roles {
    my($class, $desc) = @_;

    UR::Role::Prototype->_apply_roles_to_class_desc($desc);
    $class->_normalize_property_descriptions_during_normalize_class_description($desc);
}

# Return the order to process the has, has_optional, has_constant, etc keys
sub _class_definition_property_keys_in_processing_order {
    my $class_hashref = shift;

    my @order;

    # we want to hit 'id_implied' first to preserve position_ and is_specified_ keys
    push(@order, 'id_implied') if exists $class_hashref->{id_implied};

    # 'has' next so is_optional can get set to 0 in case the same property also appears in has_optional
    push(@order, 'has') if exists $class_hashref->{has};

    # everything else
    push @order, grep { /has_|attributes_have/ } keys %$class_hashref;

    return @order;
}



sub _normalize_property_description1 {
    my $class = shift;
    my $property_name = shift;
    my $property_data = shift;
    my $class_data = shift || $class;
    my $class_name = $class_data->{class_name};
    my %old_property = %$property_data;
    my %new_class = %$class_data;

    if (exists $old_property{unrecognized_meta_attributes}) {
        %old_property = (%{delete $old_property{unrecognized_meta_attributes}}, %old_property);
    }

    delete $old_property{source};

    if ($old_property{implied_by} and $old_property{implied_by} eq $property_name) {
        $class->warning_message("Cleaning up odd self-referential 'implied_by' on $class_name $property_name");
        delete $old_property{implied_by};
    }

    # Only 1 of is_abstract, is_concrete or is_final may be set
    {
        no warnings 'uninitialized';
        my $modifier_sum = $old_property{is_abstract}
            + $old_property{is_concrete}
            + $old_property{is_final};

        if ($modifier_sum > 1) {
            Carp::confess("abstract/concrete/final are mutually exclusive.  Error in class definition for $class_name property $property_name!");
        } elsif ($modifier_sum == 0) {
            $old_property{is_concrete} = 1;
        }
    }

    my %new_property = (
        class_name => $class_name,
        property_name => $property_name,
    );

    for my $mapping (
        [ property_type                   => qw/resolution/],
        [ class_name                      => qw//],
        [ property_name                   => qw//],
        [ column_name                     => qw/sql/],
        [ constraint_name                 => qw//],
        [ data_length                     => qw/len/],
        [ data_type                       => qw/type is isa is_a/],
        [ calculated_default              => qw//],
        [ default_value                   => qw/default value/],
        [ valid_values                    => qw//],
        [ example_values                  => qw//],
        [ doc                             => qw/description/],
        [ is_optional                     => qw/is_nullable nullable optional/],
        [ is_transient                    => qw//],
        [ is_volatile                     => qw//],
        [ is_constant                     => qw//],
        [ is_classwide                    => qw/is_class_wide/],
        [ is_delegated                    => qw//],
        [ is_calculated                   => qw//],
        [ is_mutable                      => qw//],
        [ is_transactional                => qw//],
        [ is_abstract                     => qw//],
        [ is_concrete                     => qw//],
        [ is_final                        => qw//],
        [ is_many                         => qw//],
        [ is_deprecated                   => qw//],
        [ is_undocumented                 => qw//],
        [ is_numeric                      => qw//],
        [ is_id                           => qw//],
        [ id_by                           => qw//],
        [ id_class_by                     => qw//],
        [ specify_by                      => qw//],
        [ order_by                        => qw//],
        [ access_as                       => qw//],
        [ via                             => qw//],
        [ to                              => qw//],
        [ where                           => qw/restrict filter/],
        [ implied_by                      => qw//],
        [ calculate                       => qw//],
        [ calculate_from                  => qw//],
        [ calculate_perl                  => qw/calc_perl/],
        [ calculate_sql                   => qw/calc_sql/],
        [ calculate_js                    => qw//],
        [ reverse_as                      => qw/reverse_id_by im_its/],
        [ is_legacy_eav                   => qw//],
        [ is_dimension                    => qw//],
        [ is_specified_in_module_header   => qw//],
        [ position_in_module_header       => qw//],
        [ singular_name                   => qw//],
        [ plural_name                     => qw//],
    ) {
        my $primary_field_name = $mapping->[0];

        my $found_key;
        foreach my $key ( @$mapping ) {
            if (exists $old_property{$key}) {
                if ($found_key) {
                    my @keys = grep { exists $old_property{$_} }  @$mapping;
                    Carp::croak("Invalid class definition for $class_name in property '$property_name'.  The keys "
                                . join(', ',$found_key,@keys) . " are all synonyms for $primary_field_name");
                }
                $found_key = $key;
            }
        }

        if ($found_key) {
            $new_property{$primary_field_name} = delete $old_property{$found_key};
        } elsif (exists $UR::Object::Property::defaults{$primary_field_name}) {
            $new_property{$primary_field_name} = $UR::Object::Property::defaults{$primary_field_name};
        }
    }

    if (my $data = delete $old_property{delegate}) {
        if ($data->{via} =~ /^eav_/ and $data->{to} eq 'value') {
            $new_property{is_legacy_eav} = 1;
        }
        else {
            die "Odd delegation for $property_name: "
                . Data::Dumper::Dumper($data);
        }
    }

    if ($new_property{default_value} && $new_property{calculated_default}) {
        die qq(Can't initialize class $class_name: Property '$new_property{property_name}' has both default_value and calculated_default specified.);
    }

    if ($new_property{calculated_default}) {
        if ($new_property{calculated_default} eq 1) {
            $new_property{calculated_default} = '__default_' . $new_property{property_name} . '__';
        }

        my $ref = ref $new_property{calculated_default};
        if ($ref and $ref ne 'CODE') {
            die qq(Can't initialize class $class_name: Property '$new_property{property_name}' has calculated_default specified as a $ref ref but it must be a method name or coderef.);
        }

        unless ($ref) {
            my $method = $class_name->can($new_property{calculated_default});
            unless ($method) {
                die qq(Can't initialize class $class_name: Property '$new_property{property_name}' has calculated_default specified as '$new_property{calculated_default}' but method does not exist.);
            }
            $new_property{calculated_default} = $method;
        }
    }

    if ($new_property{id_by} && $new_property{reverse_as}) {
        die qq(Can't initialize class $class_name: Property '$new_property{property_name}' has both id_by and reverse_as specified.);
    }

    if ($new_property{data_type}) {
        if (my (undef, $length) = $new_property{data_type} =~ m/(\s*)\((\d+)\)$/) {
            $new_property{data_length} = $length;
        }
        if ($new_property{data_type} =~ m/[^\w:]/
            and
            (!ref($new_property{data_type}) or !$new_property{data_type}->isa('UR::Role::Param'))
        ) {
            Carp::croak("Can't initialize class $class_name: Property '" . $new_property{property_name}
                        . "' has metadata for is/data_type that does not look like a class name ($new_property{data_type})");
        }
    }

    if (%old_property) {
        $new_property{unrecognized_meta_attributes} = \%old_property;
        %new_property = (%old_property, %new_property);
    }

    return %new_property;
}

sub _normalize_property_description2 {
    my $class = shift;
    my $property_data = shift;
    my $class_data = shift || $class;

    my $property_name = $property_data->{property_name};
    my $class_name = $property_data->{class_name};

    my %new_property = %$property_data;
    my %new_class = %$class_data;

    if (grep { $_ ne 'is_calculated' && $_ ne 'calculated_default' && /calc/ } keys %new_property) {
        $new_property{is_calculated} = 1;
    }

    if ($new_property{via}
        || $new_property{to}
        || $new_property{id_by}
        || $new_property{reverse_as}
    ) {
        $new_property{is_delegated} = 1;
        if (defined $new_property{via} and not defined $new_property{to}) {
            $new_property{to} = $property_name;
        }
    }

    if (!defined($new_property{is_mutable})) {
        if ($new_property{is_delegated}
               or
             (defined $class_data->{'subclassify_by'} and $class_data->{'subclassify_by'} eq $property_name)
        ) {
            $new_property{is_mutable} = 0;
        }
        else {
            $new_property{is_mutable} = 1;
        }
    }

    # For classes that have (or pretend to have) tables, the Property objects
    # should get their column_name property automatically filled in
    my $the_data_source;
    if (ref($new_class{'data_source_id'}) eq 'HASH') {
        # This is an inline-defined data source
        $the_data_source = $new_class{'data_source_id'}->{'is'};
    } elsif ($new_class{'data_source_id'}) {
        $the_data_source = $new_class{'data_source_id'};
        # using local() here to save $@ doesn't work.  You end up with the
        # error "Unknown error" if one of the parent classes of the data source has
        # some kind of problem
        my $dollarat = $@;
        $@ = '';
        $the_data_source = UR::DataSource->get($the_data_source) || eval { $the_data_source->get() };
        unless ($the_data_source) {
            my $error = "Can't resolve data source from value '"
                        . $new_class{'data_source_id'}
                        . "' in class definition for $class_name";
            if ($@) {
                $error .= "\n$@";
            }
            Carp::croak($error);
        }
        $@ = $dollarat;
    }
    # UR::DataSource::File-backed classes don't have table_names, but for querying/saving to
    # work property, their properties still have to have column_name filled in
    if (($new_class{table_name} or ($the_data_source and ($the_data_source->initializer_should_create_column_name_for_class_properties())))
        and not exists($new_property{column_name})    # They didn't supply a column_name
        and not $new_property{is_transient}
        and not $new_property{is_delegated}
        and not $new_property{is_calculated}
        and not $new_property{is_legacy_eav}
    ) {
        $new_property{column_name} = $new_property{property_name};
        if ($the_data_source and $the_data_source->table_and_column_names_are_upper_case) {
            $new_property{column_name} = uc($new_property{column_name});
        }
    }

    if ($new_property{order_by} and not $new_property{is_many}) {
        die "Cannot use order_by except on is_many properties!";
    }

    if ($new_property{specify_by} and not $new_property{is_many}) {
        die "Cannot use specify_by except on is_many properties!";
    }

    if ($new_property{implied_by} and $new_property{implied_by} eq $property_name) {
        $class->warnings_message("New data has odd self-referential 'implied_by' on $class_name $property_name!");
        delete $new_property{implied_by};
    }

    return %new_property;
}


sub _make_minimal_class_from_normalized_class_description {
    my $class = shift;
    my $desc = shift;

    my $class_name = $desc->{class_name};
    unless ($class_name) {
        Carp::confess("No class name specified?");
    }

    my $meta_class_name = $desc->{meta_class_name};
    die unless $meta_class_name;
    if ($meta_class_name ne __PACKAGE__) {
        unless (
            $meta_class_name->isa(__PACKAGE__)
        ) {
            warn "Bogus meta class $meta_class_name doesn't inherit from UR::Object::Type?"
        }
    }

    # only do this when the classes match
    # when they do not match, the super-class has already called this by delegating to the correct subclass
    $class_name::VERSION = 2.0; # No BumpVersion

    my $self =  bless { id => $class_name, %$desc }, $meta_class_name;

    $UR::Context::all_objects_loaded->{$meta_class_name}{$class_name} = $self;
    my $full_name = join( '::', $class_name, '__meta__' );
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => '__meta__',
        code => Sub::Name::subname $full_name => sub {$self},
    });

    return $self;
}

sub _initialize_accessors_and_inheritance {
    my $self = shift;

    $self->initialize_direct_accessors;

    my $class_name = $self->{class_name};

    my @is = @{ $self->{is} };
    unless (@is) {
        @is = ('UR::ModuleBase')
    }
    eval "\@${class_name}::ISA = (" . join(',', map { "'$_'" } @is) . ")\n";
    Carp::croak("Can't initialize \@ISA for class_name '$class_name': $@\nMaybe the class_name or one of the parent classes are not valid class names") if $@;

    my $namespace_mro;
    my $namespace_name = $self->{namespace};
    if (
        !$bootstrapping
        && !$class_name->isa('UR::Namespace')
        && $namespace_name
        && $namespace_name->isa('UR::Namespace')
        && $namespace_name->can('get')
        && (my $namespace = $namespace_name->get())
    ) {
        $namespace_mro = $namespace->method_resolution_order;
    }

    if ($^V lt v5.9.5 && $namespace_mro && $namespace_mro eq 'c3') {
        warn "C3 method resolution order is not supported on Perl < 5.9.5. Reverting $namespace_name namespace to DFS.";
        my $namespace = $namespace_name->get();
        $namespace_mro = $namespace->method_resolution_order('dfs');
    }

    if ($^V ge v5.9.5 && $namespace_mro && mro::get_mro($class_name) ne $namespace_mro) {
        mro::set_mro($class_name, $namespace_mro);
    }

    return $self;
}

our %_init_subclasses_loaded;
sub subclasses_loaded {
    return @{ $_init_subclasses_loaded{shift->class_name}};
}

our %_inform_all_parent_classes_of_newly_loaded_subclass;
sub _inform_all_parent_classes_of_newly_loaded_subclass {
    my $self = shift;
    my $class_name = $self->class_name;

    Carp::confess("re-initializing class $class_name") if $_inform_all_parent_classes_of_newly_loaded_subclass{$class_name};
    $_inform_all_parent_classes_of_newly_loaded_subclass{$class_name} = 1;

    no strict 'refs';
    no warnings;
    my @parent_classes = @{ $class_name . "::ISA" };
    for my $parent_class (@parent_classes) {
        unless ($parent_class->can("id")) {
            __PACKAGE__->use_module_with_namespace_constraints($parent_class);
            if ($@) {
                die "Failed to find parent_class $parent_class for $class_name!";
            }
        }
    }

    my @i = sort $class_name->inheritance;
    $_init_subclasses_loaded{$class_name} ||= [];
    my $last_parent_class = "";
    for my $parent_class (@i) {
        next if $parent_class eq $last_parent_class;

        $last_parent_class = $parent_class;
        $_init_subclasses_loaded{$parent_class} ||= [];
        push @{ $_init_subclasses_loaded{$parent_class} }, $class_name;
        push @{ $parent_class . "::_init_subclasses_loaded" }, $class_name;

        # any index on a parent class must move to the child class
        # if the child class were loaded before the index is made, it is pushed down at index creation time
        if (my $parent_index_hashrefs = $UR::Object::Index::all_by_class_name_and_property_name{$parent_class}) {
            #print "PUSHING INDEXES FOR $parent_class to $class_name\n";
            for my $parent_property (keys %$parent_index_hashrefs) {
                my $parent_indexes = $parent_index_hashrefs->{$parent_property};
                my $indexes = $UR::Object::Index::all_by_class_name_and_property_name{$class_name}{$parent_property} ||= [];
                push @$indexes, @$parent_indexes;
            }
        }
    }

    return 1;
}

sub _inform_roles_of_new_class {
    my $self = shift;

    foreach my $role_obj ( @{ $self->{roles} } ) {
        my $package = $role_obj->role_name;
        next unless my $import = $package->can('__import__');
        $import->($package, $self);
    }
}

sub _complete_class_meta_object_definitions {
    my $self = shift;

    # track related objects
    my @subordinate_objects;

    # grab some data from the object
    my $class_name = $self->{class_name};
    my $table_name = $self->{table_name};

    # decompose the embedded complex data structures into normalized objects
    my $inheritance = $self->{is};
    my $properties = $self->{has};
    my $relationships = $self->{relationships} || [];
    my $constraints = $self->{constraints};
    my $data_source = $self->{'data_source_id'};

    my $id_properties = $self->{id_by};
    my %id_property_rank;
    for (my $i = '0 but true'; $i < @$id_properties; $i++) {
        $id_property_rank{$id_properties->[$i]} = $i;
    }

    # mark id/non-id properites
    foreach my $pinfo ( values %$properties ) {
        $pinfo->{'is_id'} = $id_property_rank{$pinfo->{'property_name'}};
    }

    # handle inheritance
    unless ($class_name eq "UR::Object") {
        no strict 'refs';

        # sanity check
        my @expected = @$inheritance;
        my @actual =  @{ $class_name . "::ISA" };

        if (@actual and "@actual" ne "@expected") {
            Carp::confess("for $class_name: expected '@expected' actual '@actual'\n");
        }

        # set
        @{ $class_name . "::ISA" } = @$inheritance;
    }

    if (not $data_source and $class_name->can("__load__")) {
        # $data_source = UR::DataSource::Default->__define__;
        $data_source = $self->{data_source_id} = $self->{db_committed}->{data_source_id} = 'UR::DataSource::Default';
    }

    # Create inline data source
    if ($data_source and ref($data_source) eq 'HASH') {
        $self->{'__inline_data_source_data'} = $data_source;
        my $ds_class = $data_source->{'is'};
        my $inline_ds = $ds_class->create_from_inline_class_data($self, $data_source);
        $self->{'data_source_id'} = $self->{'db_committed'}->{'data_source_id'} = $inline_ds->id;
    }

    
    if ($self->{'data_source_id'} and !defined($self->{table_name})) {
        my $data_source_obj = UR::DataSource->get($self->{'data_source_id'}) || eval { $self->{'data_source_id'}->get() };
        if ($data_source_obj and $data_source_obj->initializer_should_create_column_name_for_class_properties() ) {
            $self->{table_name} = '__default__';
        }
    }

    for my $parent_class_name (@$inheritance) {
        my $parent_class = $parent_class_name->__meta__;
        unless ($parent_class) {
            #$DB::single = 1;
            $parent_class = $parent_class_name->__meta__;
            $self->error_message("Failed to find parent class $parent_class_name\n");
            return;
        }

        # These class meta values get propogated from parent to child
        foreach my $inh_property ( qw(schema_name data_source_id) ) {
            if (not defined ($self->$inh_property)) {
                if (my $inh_value = $parent_class->$inh_property) {
                    $self->{$inh_property} = $self->{'db_committed'}->{$inh_property} = $inh_value;
                }
            }
        }

        # For classes with no data source, the default for id_generator is -urinternal
        # For classes with a data source, autogenerate_new_object_id_for_class_name_and_rule gets called
        # on that data source which can use id_generator as it sees fit
        if (! defined $self->{id_generator}) {
            my $id_generator;
            if ($self->{data_source_id}) {
                if ($parent_class->data_source_id
                    and
                    $parent_class->data_source_id eq $self->data_source_id
                ) {
                    $id_generator = $parent_class->id_generator;
                }
            } else {
                $id_generator = $parent_class->id_generator;
            }
            $self->{id_generator} = $self->{'db_committed'}->{id_generator} = $id_generator;
        }


        # If a parent is declared as a singleton, we are too.
        # This only works for abstract singletons.
        if ($parent_class->is_singleton and not $self->is_singleton) {
            $self->is_singleton($parent_class->is_singleton);
        }
    }

    # when we "have" an object reference, add it to the list of old-style references
    # also ensure the old-style property definition is complete
    for my $pinfo (grep { $_->{id_by} } values %$properties) {
        push @$relationships, $pinfo->{property_name}, $pinfo;

        my $id_properties = $pinfo->{id_by};
        my $r_class_name = $pinfo->{data_type};
        unless($r_class_name) {
            die sprintf("Object accessor property definition for %s::%s has an 'id_by' but no 'data_type'",
                                  $pinfo->{'class_name'}, $pinfo->{'property_name'});
        }
        my $r_class;
        my @r_id_properties;

        for (my $n=0; $n<@$id_properties; $n++) {
            my $id_property_name = $id_properties->[$n];
            my $id_property_detail = $properties->{$id_property_name};
            unless ($id_property_detail) {
                #$DB::single = 1;
                1;
            }

            # No data_type specified, first try parent classes for the same property name
            # and use their type
            if (!$bootstrapping and !exists($id_property_detail->{data_type})) {
                if (my $inh_prop = ($self->ancestry_property_metas(property_name => $id_property_name))[0]) {
                    $id_property_detail->{data_type} = $inh_prop->data_type;
                }
            }

            # Didn't find one - use the data type of the ID property(s) in the class we point to
            unless ($id_property_detail->{data_type}) {
                unless ($r_class) {
                    # FIXME - it'd be nice if we didn't have to load the remote class here, and
                    # instead put off loading until it's necessary
                    $r_class ||= UR::Object::Type->get($r_class_name);
                    unless ($r_class) {
                        Carp::confess("Unable to load $r_class_name while defining relationship ".$pinfo->{'property_name'}. " in class $class_name");
                    }
                    @r_id_properties = $r_class->id_property_names;
                }
                my ($r_property) =
                    map {
                        my $r_class_ancestor = UR::Object::Type->get($_);
                        my $data = $r_class_ancestor->{has}{$r_id_properties[$n]};
                        ($data ? ($data) : ());
                    }
                    ($r_class_name, $r_class_name->__meta__->ancestry_class_names);
                unless ($r_property) {
                    #$DB::single = 1;
                    my $property_name = $pinfo->{'property_name'};
                    if (@$id_properties != @r_id_properties) {
                        Carp::croak("Can't resolve relationship for class $class_name property '$property_name': "
                                    . "id_by metadata has " . scalar(@$id_properties) . " items, but remote class "
                                    . "$r_class_name only has " . scalar(@r_id_properties) . " ID properties\n");
                    } else {
                        my $r_id_property = $r_id_properties[$n] ? "'$r_id_properties[$n]'" : '(undef)';
                        Carp::croak("Can't resolve relationship for class $class_name property '$property_name': "
                                    . "Class $r_class_name does not have an ID property named $r_id_property, "
                                    . "which would be linked to the local property '".$id_properties->[$n]."'\n");
                    }
                }
                $id_property_detail->{data_type} = $r_property->{data_type};
            }
        }
        next;
    }

    # make old-style (bc4nf) property objects in the default way
    my %property_objects;

    for my $pinfo (values %$properties) {
        my $property_name       = $pinfo->{property_name};
        my $property_subclass   = $pinfo->{property_subclass};

        # Acme::Employee::Attribute::Name is a bc6nf attribute
        # extends Acme::Employee::Attribute
        # extends UR::Object::Attribute
        # extends UR::Object
        my @words = map { ucfirst($_) } split(/_/,$property_name);
        #@words = $self->namespace->get_vocabulary->convert_to_title_case(@words);
        my $bridge_class_name =
            $class_name
            . "::Attribute::"
            . join('', @words);

        # Acme::Employee::Attribute::Name::Type is both the class definition for the bridge,
        # and also the attribute/property metadata for
        my $property_meta_class_name = $bridge_class_name . "::Type";

        # define a new class for the above, inheriting from UR::Object::Property
        # all of the "attributes_have" get put into the class definition
        # call the constructor below on that new class
        #UR::Object::Type->__define__(
        ##    class_name => $property_meta_class_name,
        #    is => 'UR::Object::Property', # TODO: go through the inheritance
        #    has => [
        #        @{ $class_name->__meta__->{attributes_have} }
        #    ]
        #)

        my ($singular_name,$plural_name);
        unless ($pinfo->{plural_name} and $pinfo->{singular_name}) {
            require Lingua::EN::Inflect;
            if ($pinfo->{is_many}) {
                $plural_name = $pinfo->{plural_name} ||= $pinfo->{property_name};
                $pinfo->{singular_name} = Lingua::EN::Inflect::PL_V($plural_name);
            }
            else {
                $singular_name = $pinfo->{singular_name} ||= $pinfo->{property_name};
                $pinfo->{plural_name} = Lingua::EN::Inflect::PL($singular_name);
            }
        }

        my $property_object = UR::Object::Property->__define__(%$pinfo, id => $class_name . "\t" . $property_name);

        unless ($property_object) {
            $self->error_message("Error creating property $property_name for class " . $self->class_name . ": " . $class_name->error_message);
            for $property_object (@subordinate_objects) { $property_object->unload }
            $self->unload;
            return;
        }

        $property_objects{$property_name} =  $property_object;
        push @subordinate_objects, $property_object;
    }

    if ($constraints) {
        my $property_rule_template = UR::BoolExpr::Template->resolve('UR::Object::Property','class_name','property_name');

        my $n = 1;
        for my $unique_set (sort { $a->{sql} cmp $b->{sql} } @$constraints) {
            my ($name,$properties,$group,$sql);
            if (ref($unique_set) eq "HASH") {
                $name = $unique_set->{name};
                $properties = $unique_set->{properties};
                $sql = $unique_set->{sql};
                $name ||= $sql;
            }
            else {
                $properties = @$unique_set;
                $name = '(unnamed)';
                $n++;
            }
            for my $property_name (sort @$properties) {
                my $prop_rule = $property_rule_template->get_rule_for_values($class_name,$property_name);
                my $property = $UR::Context::current->get_objects_for_class_and_rule('UR::Object::Property', $prop_rule);
                unless ($property) {
                    Carp::croak("Constraint '$name' on class $class_name requires unknown property '$property_name'");
                }
            }
        }
    }

    for my $obj ($self,@subordinate_objects) {
        #use Data::Dumper;
        no strict;
        my %db_committed = %$obj;
        delete @db_committed{@keys_to_delete_from_db_committed};
        $obj->{'db_committed'} = \%db_committed;

    };

    unless ($self->generate) {
        $self->error_message("Error generating class " . $self->class_name . " as part of creation : " . $self->error_message);
        for my $property_object (@subordinate_objects) { $property_object->unload }
        $self->unload;
        return;
    }

    if (my $extra = $self->{extra}) {
        $self->_apply_extra_attrs_to_class_or_role($extra);
    }

    $self->__signal_change__("load");


    my @i = $class_name->inheritance;

    for my $parent_class_name (@i) {
        if ($parent_class_name->can('__signal_observers__')) {
            $parent_class_name->__signal_observers__('subclass_loaded', $class_name);
        }
    }

    # The inheritance method is high overhead because of the number of times it is called.
    # Cache on a per-class basis.
    if (grep { $_ eq '' } @i) {
        print "$class_name! @{ $self->{is} }";
        $class_name->inheritance;
    }
    Carp::confess("Odd inheritance @i for $class_name") unless $class_name->isa('UR::Object');
    my $src1 = " return shift->SUPER::inheritance(\@_) if ( (ref(\$_[0])||\$_[0]) ne '$class_name');  return (" . join(", ", map { "'$_'" } (@i)) . ")";
    my $src2 = qq|sub ${class_name}::inheritance { $src1 }|;
    eval $src2  unless $class_name eq 'UR::Object';
    die $@ if $@;

    $self->{'_property_meta_for_name'} = \%property_objects;

    # return the new class object
    return $self;
}

sub _apply_extra_attrs_to_class_or_role {
    my($self, $extra) = @_;

    if ($extra) {
        # some class characteristics may be only present in subclasses of UR::Object
        # we handle these at this point, since the above is needed for bootstrapping
        my %still_not_found;
        for my $key (sort keys %$extra) {
            if ($self->can($key)) {
                $self->$key($extra->{$key});
            }
            else {
                $still_not_found{$key} = $extra->{$key};
            }
        }
        if (%still_not_found) {
            my $kind = $self->isa('UR::Object::Type')
                        ? 'Class'
                        : 'Role';
            my $name = $self->id;

            $DB::single = 1;
            Carp::croak("Bad $kind defninition for $name.  Unrecognized properties:\n\t"
                            . join("\n\t", join(' => ', map { ($_, $still_not_found{$_}) } keys %still_not_found)));
        }
    }


}

# write the module from the existing data in the class object
sub generate {
    my $self = shift;
    return 1 if $self->{'generated'};

    #my %params = @_;   # Doesn't seem to be used below...


    # The follwing code will override a lot intentionally.
    # Supress the warning messages.
    no warnings;

    # the class that this object represents
    # the class that we're going to generate
    # the "new class"
    my $class_name = $self->class_name;

    # this is done earlier in the class definition process in _make_minimal_class_from_normalized_class_description()
    my $full_name = join( '::', $class_name, '__meta__' );
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => '__meta__',
        code => Sub::Name::subname $full_name => sub {$self},
    });

    my @parent_class_names = $self->parent_class_names;

    do {
        no strict 'refs';
        if (@{ $class_name . '::ISA' }) {
            #print "already have isa for class_name $class_name: " . join(",",@{ $class_name . '::ISA' }) . "\n";
        }
        else {
            no strict 'refs';
            @{ $class_name . '::ISA' } = @parent_class_names;
            #print "setting isa for class_name $class_name: " . join(",",@{ $class_name . '::ISA' }) . "\n";
        };
    };


    my ($props, $cols) = ([], []);  # for _all_properties_columns()
    $self->{_all_properties_columns} = [$props, $cols];

    my $id_props = [];              # for _all_id_properties()
    $self->{_all_id_properties} = $id_props;

    # build the supplemental classes
    for my $parent_class_name (@parent_class_names) {
        next if $parent_class_name eq "UR::Object";

        if ($parent_class_name eq $class_name) {
            Carp::confess("$class_name has parent class list which includes itself?: @parent_class_names\n");
        }

        my $parent_class_meta = UR::Object::Type->get(class_name => $parent_class_name);

        unless ($parent_class_meta) {
            #$DB::single = 1;
            $parent_class_meta = UR::Object::Type->get(class_name => $parent_class_name);
            Carp::confess("Cannot generate $class_name: Failed to find class meta-data for base class $parent_class_name.");
        }

        unless ($parent_class_meta->generated()) {
            $parent_class_meta->generate();
        }

        unless ($parent_class_meta->{_all_properties_columns}) {
            Carp::confess("No _all_properties_columns for $parent_class_name?");
        }

        # inherit properties and columns
        my ($p, $c) = @{ $parent_class_meta->{_all_properties_columns} };
        push @$props, @$p if $p;
        push @$cols, @$c if $c;
        my $id_p = $parent_class_meta->{_all_id_properties};
        push @$id_props, @$id_p if $id_p;
    }


    # set up accessors/mutators for properties
    my @property_objects =
        UR::Object::Property->get(class_name => $self->class_name);

    my @id_property_objects = $self->direct_id_property_metas;
    my %id_property;
    for my $ipo (@id_property_objects) {
        $id_property{$ipo->property_name} = 1;
    }

    if (@id_property_objects) {
        $id_props = [];
        for my $ipo (@id_property_objects) {
            push @$id_props, $ipo->property_name;
        }
    }

    my $has_table;
    my @parent_classes = map { UR::Object::Type->get(class_name => $_) } @parent_class_names;
    for my $co ($self, @parent_classes) {
        if ($co->table_name) {
            $has_table = 1;
            last;
        }
    }

    my $data_source_obj = $self->data_source;
    my $columns_are_upper_case;
    if ($data_source_obj) {
        $columns_are_upper_case = $data_source_obj->table_and_column_names_are_upper_case;
    }

    my @sort_list = map { [$_->property_name, $_] } @property_objects;
    for my $sorted_item ( sort { $a->[0] cmp $b->[0] } @sort_list ) {
        my $property_object = $sorted_item->[1];
        if ($property_object->column_name) {
            push @$props, $property_object->property_name;
            push @$cols, $columns_are_upper_case ? uc($property_object->column_name) : $property_object->column_name;
        }
    }

    # set the flag to prevent this from occurring multiple times.
    $self->generated(1);

    # read in filesystem package if there is one
    #$self->use_filesystem_package($class_name);

    # Let each class in the inheritance hierarchy do any initialization
    # required for this class.  Note that the _init_subclass method does
    # not call SUPER::, but relies on this code to find its parents.  This
    # is the only way around a sparsely-filled multiple inheritance tree.

    # TODO: Replace with $class_name->EVERY::LAST::_init_subclass()

    #unless (
    #    $bootstrapping
    #    and
    #    $UR::Object::_init_subclass->{$class_name}
    #)
    {
        my @inheritance = $class_name->inheritance;
        my %done;
        for my $parent (reverse @inheritance) {
            my $initializer = $parent->can("_init_subclass");
            next unless $initializer;
            next if $done{$initializer};
            $initializer->($class_name,$class_name)
                    or die "Parent class $parent failed to initialize subclass "
                        . "$class_name :" . $parent->error_message;
            $done{$initializer} = 1;
        }
    }

    unless ($class_name->isa("UR::Object")) {
        print Data::Dumper::Dumper('@C::ISA',\@C::ISA,'@B::ISA',\@B::ISA);
    }

    # ensure the class is generated
    die "Error in module for $class_name.  Resulting class does not appear to be generated!" unless $self->generated;

    # ensure the class inherits from UR::Object
    die "$class_name does not inherit from UR::Object!" unless $class_name->isa("UR::Object");

    return 1;
}


1;


