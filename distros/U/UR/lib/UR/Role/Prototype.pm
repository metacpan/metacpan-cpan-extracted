package UR::Role::Prototype;

use strict;
use warnings;

use UR;
use UR::Object::Type::InternalAPI;
use UR::Util;
use UR::AttributeHandlers;

use Sub::Name qw();
use Sub::Install qw();
use List::MoreUtils qw(any);
use Carp;
our @CARP_NOT = qw(UR::Object::Type);

our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Role::Prototype',
    doc => 'Object representing a role',
    id_by => 'role_name',
    has => [
        id_by       => { is => 'ARRAY', doc => 'List of ID properties and their definitions' },
        role_name   => { is => 'Text', doc => 'Package name identifying the role' },
        class_names => { is => 'Text', is_many => 1, doc => 'Class names composing this role' },
        methods     => { is => 'HASH', doc => 'Map of method names and coderefs', default => {} },
        overloads   => { is => 'HASH', doc => 'Map of overload keys and coderefs', default => {} },
        has         => { is => 'ARRAY', doc => 'List of properties and their definitions' },
        roles       => { is => 'ARRAY', doc => 'List of other role names composed into this role', default => [] },
        requires    => { is => 'ARRAY', doc => 'List of properties required of consuming classes', default => [] },
        attributes_have => { is => 'HASH', doc => 'Meta-attributes for properites' },
        excludes    => { is => 'ARRAY', doc => 'List of Role names that cannot compose with this role', default => [] },
        method_modifiers => { is => 'UR::Role::MethodModifier',
                              is_many => 1,
                              doc => q(List of 'before', 'after' and 'around' method modifiers),
                              reverse_as => 'role'
                            },
        map { $_ => _get_property_desc_from_ur_object_type($_) }
                                meta_properties_to_compose_into_classes(),
    ],
    is_transactional => 0,
);

sub property_data {
    my($self, $property_name) = @_;
    return $self->has->{$property_name};
}

sub has_property_names {
    my $self = shift;
    return keys %{ $self->has };
}

sub id_by_property_names {
    my $self = shift;
    return @{ $self->id_by };
}

sub method_names {
    my $self = shift;
    return keys %{ $self->methods };
}

sub meta_properties_to_compose_into_classes {
    return qw( is_abstract is_final is_singleton doc
               composite_id_separator id_generator valid_signals 
               subclassify_by subclass_description_preprocessor sub_classification_method_name
               sub_classification_meta_class_name
               schema_name data_source_id table_name select_hint join_hint );
}

sub define {
    my $class = shift;
    my $desc = $class->_normalize_role_description(@_);

    unless ($desc->{role_name}) {
        Carp::croak(q('role_name' is a required parameter for defining a role));
    }

    my $methods = _introspect_methods($desc->{role_name});
    my $overloads = _introspect_overloads($desc->{role_name});

    my $extra = delete $desc->{extra};
    my $role = UR::Role::Prototype->__define__(%$desc, methods => $methods, overloads => $overloads);

    if ($extra and %$extra) {
        $role->UR::Object::Type::_apply_extra_attrs_to_class_or_role($extra);
    }

    $role->_inject_instance_constructor_into_namespace();

    return $role;
}

our @ROLE_DESCRIPTION_KEY_MAPPINGS = (
    @UR::Object::Type::CLASS_DESCRIPTION_KEY_MAPPINGS_COMMON_TO_CLASSES_AND_ROLES,
    [ role_name             => qw// ],
    [ methods               => qw// ],
    [ requires              => qw// ],
    [ excludes              => qw// ],
);

sub _normalize_role_description {
    my $class = shift;
    my $old_role = { @_ };

    my $role_name = delete $old_role->{role_name};

    my $new_role = {
        role_name => $role_name,
        has => {},
        attributes_have => {},
        UR::Object::Type::_canonicalize_class_params($old_role, \@ROLE_DESCRIPTION_KEY_MAPPINGS),
    };

    # The above call to _canonicalize_class_params removed recognized keys.  Anything
    # left over wasn't recognized
    $new_role->{extra} = $old_role;

    foreach my $key (qw( requires excludes ) ) {
        unless (UR::Util::ensure_arrayref($new_role, $key)) {
            Carp::croak("The '$key' metadata for role $role_name must be an arrayref");
        }
    }

    # UR::Object::Type::_normalize_class_description_impl() copies these over before
    # processing the properties.  We need to, too
    @$old_role{'has', 'attributes_have'} = @$new_role{'has','attributes_have'};
    @$new_role{'has','attributes_have'} = ( {}, {} );
    UR::Object::Type::_massage_field_into_arrayref($new_role, 'id_by');
    UR::Object::Type::_normalize_id_property_data($old_role, $new_role);
    UR::Object::Type::_process_class_definition_property_keys($old_role, $new_role);
    _complete_property_descriptions($new_role);

    return $new_role;
}

sub _complete_property_descriptions {
    my $role_desc = shift;

    # stole from UR::Object::Type::_normalize_class_description_impl()
    my $properties = $role_desc->{has};
    foreach my $property_name ( keys %$properties ) {
        my $old_property = $properties->{$property_name};
        my %new_property = UR::Object::Type->_normalize_property_description1($property_name, $old_property, $role_desc);
        delete $new_property{class_name};  # above normalizer fills this in as undef
        $properties->{$property_name} = \%new_property;
    }
}

my %property_definition_key_to_method_name = (
    is => 'data_type',
    len => 'data_length',
);

sub _get_property_desc_from_ur_object_type {
    my $property_name = shift;

    my $prop_meta = UR::Object::Property->get(class_name => 'UR::Object::Type', property_name => $property_name);
    Carp::croak("Couldn't get UR::Object::Type property meta for $property_name") unless $prop_meta;

    # These properties' definition key is the same as the method name
    my %definition = map { $_ => $prop_meta->$_ }
                     grep { defined $prop_meta->$_ }
                     qw( is_many is_optional is_transient is_mutable default_value doc );

    # These have a translation
    while(my($key, $method) = each(%property_definition_key_to_method_name)) {
        $definition{$key} = $prop_meta->$method;
    }

    # For any UR::Object::Type properties that are required or have a default value,
    # those don't apply to Roles
    $definition{is_optional} = 1;
    delete $definition{default_value};

    return \%definition;
}

{
    my @overload_ops;
    sub _all_overload_ops {
        @overload_ops = map { split /\s+/ } values(%overload::ops) unless @overload_ops;
        @overload_ops;
    }
}

my @DONT_EXPORT_THESE_SUBS_TO_CLASSES = qw(__import__ FETCH_CODE_ATTRIBUTES MODIFY_CODE_ATTRIBUTES MODIFY_SCALAR_ATTRIBUTES before after around);
sub _introspect_methods {
    my $role_name = shift;

    my $subs = UR::Util::coderefs_for_package($role_name);
    delete @$subs{@DONT_EXPORT_THESE_SUBS_TO_CLASSES};  # don't allow __import__ to be exported to a class's namespace
    delete @$subs{ map { "($_" } ( _all_overload_ops, ')', '(' ) };
    return $subs;
}

sub _introspect_overloads {
    my $role_name = shift;

    return {} unless overload::Overloaded($role_name);

    my %overloads;
    my $stash = do {
        no strict 'refs';
        \%{$role_name . '::'};
    };
    foreach my $op ( _all_overload_ops ) {
        my $op_key = $op eq 'fallback' ? ')' : $op;
        my $overloaded = $stash->{'(' . $op_key};

        if ($overloaded) {
            my $subref = *{$overloaded}{CODE};
            $overloads{$op} = $subref eq \&overload::nil
                                ? ${*{$overloaded}{SCALAR}} # overridden with string method name
                                : $subref; # overridden with a subref
        }
    }
    return \%overloads;
}

# Called by UR::Object::Type::Initializer::compose_roles to apply a role name
# to a partially constructed class description
sub _apply_roles_to_class_desc {
    my($class, $desc) = @_;
    if (ref($class) or ref($desc) ne 'HASH') {
        Carp::croak('_apply_roles_to_class_desc() must be called as a class method on a basic class description');
    }

    _validate_class_method_overrides_consumed_roles($desc);
    return unless ($desc->{roles} and @{ $desc->{roles} });
    my @role_objs = _role_prototypes_with_params_for_class_desc($desc);

    _validate_role_exclusions($desc, @role_objs);
    _validate_role_requirements($desc, @role_objs);
    _validate_class_desc_overrides($desc, @role_objs);

    my $id_property_names_to_add = _collect_id_property_names_from_roles($desc, @role_objs);
    my $properties_to_add = _collect_properties_from_roles($desc, @role_objs);
    my $meta_properties_to_add = _collect_meta_properties_from_roles($desc, @role_objs);
    my $overloads_to_add = _collect_overloads_from_roles($desc, @role_objs);
    my $method_modifiers_to_add = _collect_method_modifiers_from_roles($desc, @role_objs);

    _save_role_instances_to_class_desc($desc, @role_objs);
    _assert_all_role_params_are_bound_to_values($desc, @role_objs);
    do { $_->prototype->add_class_name($desc->{class_name}) } foreach @role_objs;

    UR::Role::Param->replace_unbound_params_in_struct_with_values(
            [ $id_property_names_to_add, $properties_to_add, $meta_properties_to_add, $overloads_to_add ],
            @role_objs);

    _import_methods_from_roles_into_namespace($desc->{class_name}, \@role_objs);
    _apply_overloads_to_namespace($desc->{class_name}, $overloads_to_add);
    _apply_method_modifiers_to_namespace($desc, $method_modifiers_to_add);

    _merge_role_meta_properties_into_class_desc($desc, $meta_properties_to_add);
    _merge_role_id_property_names_into_class_desc($desc, $id_property_names_to_add);
    _merge_role_properties_into_class_desc($desc, $properties_to_add);
}

sub _save_role_instances_to_class_desc {
    my($desc, @role_prototypes) = @_;

    my $class_name = $desc->{class_name};
    my @instances = map { $_->instantiate_role_instance($class_name) }
                    @role_prototypes;
    $desc->{roles} = \@instances;
}

sub _assert_all_role_params_are_bound_to_values {
    my($desc, @role_instances) = @_;

    foreach my $instance ( @role_instances ) {
        my $role_name = $instance->role_name;
        my %expected_params = map { $_ => 1 }
                              UR::Role::Param->param_names_for_role($role_name);
        my $got_params = $instance->role_params;
        if (my @missing = grep { ! exists($got_params->{$_}) } keys %expected_params) {
            Carp::croak("Role $role_name expects values for these params: ",join(', ', @missing));
        }
        if (my @extra = grep { ! exists($expected_params{$_}) } keys %$got_params) {
            Carp::croak("Role $role_name does not recognize these params: ",join(', ', @extra));
        }
    }
}


sub _merge_role_meta_properties_into_class_desc {
    my($desc, $meta_properties_to_add) = @_;

    my $valid_signals = delete $meta_properties_to_add->{valid_signals};
    my @meta_prop_names = keys %$meta_properties_to_add;
    @$desc{@meta_prop_names} = @$meta_properties_to_add{@meta_prop_names};
    if ($valid_signals) {
        push @{$desc->{valid_signals}}, @$valid_signals;
    };
}

sub _merge_role_properties_into_class_desc {
    my($desc, $properties_to_add) = @_;

    my @property_names = keys %$properties_to_add;
     @{$desc->{has}}{@property_names} = @$properties_to_add{@property_names};
}

sub _merge_role_id_property_names_into_class_desc {
    my($desc, $id_properties_to_add) = @_;

    push @{$desc->{id_by}}, @$id_properties_to_add;
}

sub _role_prototypes_with_params_for_class_desc {
    my $desc = shift;

    my @role_prototypes;
    foreach my $role_name ( @{ $desc->{roles} } ) {
        my $role;
        my $exception = do {
            local $@;
            $role = eval { $role_name->__role__ };
            $@;
        };
        unless ($role) {
            my $class_name = $desc->{class_name};
            Carp::croak("Cannot apply role $role_name to class $class_name: $exception");
        }
        push @role_prototypes, $role;
    }
    return @role_prototypes;
}

sub _collect_id_property_names_from_roles {
    my($desc, @role_objs) = @_;

    my %class_id_by_properties = map { $_ => 1 } @{ $desc->{id_by} };
    my %class_property_is_id_by = map { $_ => $class_id_by_properties{$_} }
                                  keys %{ $desc->{has} };

    my @property_names_to_add;
    foreach my $role ( @role_objs ) {
        my @role_id_property_names = $role->id_by_property_names;

        my @conflict = grep { exists($class_property_is_id_by{$_}) and ! $class_property_is_id_by{$_} }
                       @role_id_property_names;
        if (@conflict) {
            Carp::croak(sprintf(q(Cannot compose role %s: Property '%s' was declared as a normal property in class %s, but as an ID property in the role),
                                $role->role_name,
                                join(q(', '), @conflict),
                                $desc->{class_name},
                        ));
        }
        push @property_names_to_add, @role_id_property_names;
    }
    return \@property_names_to_add;
}

sub _collect_properties_from_roles {
    my($desc, @role_objs) = @_;

    my $properties_from_class = $desc->{has};

    my(%properties_to_add, %source_for_properties_to_add);
    foreach my $role ( @role_objs ) {
        my @role_property_names = $role->has_property_names;
        foreach my $property_name ( @role_property_names ) {
            my $prop_definition = $role->property_data($property_name);
            if (my $conflict = $source_for_properties_to_add{$property_name}) {
                Carp::croak(sprintf(q(Cannot compose role %s: Property '%s' conflicts with property in role %s),
                                    $role->role_name, $property_name, $conflict));
            }

            $source_for_properties_to_add{$property_name} = $role->role_name;

            next if exists $properties_from_class->{$property_name};

            $properties_to_add{$property_name} = $prop_definition;
        }
    }
    return UR::Util::deep_copy(\%properties_to_add);
}

sub _collect_overloads_from_roles {
    my($desc, @role_objs) = @_;

    my $overloads_from_class = _introspect_overloads($desc->{class_name});

    my(%overloads_to_add, %source_for_overloads_to_add);
    my $fallback_validator = _create_fallback_validator();

    foreach my $role ( @role_objs ) {
        my $role_name = $role->role_name;
        my $overloads_this_role = $role->overloads;

        $fallback_validator->($role_name, $overloads_this_role->{fallback});
        while( my($op, $impl) = each(%$overloads_this_role)) {
            next if ($op eq 'fallback');
            if (my $conflict = $source_for_overloads_to_add{$op}) {
                Carp::croak("Cannot compose role $role_name: Overload '$op' conflicts with overload in role $conflict");
            }
            $source_for_overloads_to_add{$op} = $role_name;

            next if exists $overloads_from_class->{$op};

            $overloads_to_add{$op} = $impl;
        }
    }

    my $fallback = $fallback_validator->();
    $overloads_to_add{fallback} = $fallback if defined $fallback;
    return \%overloads_to_add;
}

sub _collect_method_modifiers_from_roles {
    my($desc, @role_objs) = @_;

    my $class_name = $desc->{class_name};
    my @all_modifiers = map { $_->method_modifiers } @role_objs;

    my $isa = join('::', $class_name, 'ISA');
    no strict 'refs';
    local @$isa = (@$isa, @{$desc->{is}});
    use strict 'refs';

    foreach my $mod ( @all_modifiers ) {
        unless ($class_name->can($mod->name)) {
            my $role_name = $mod->role->role_name;
            my $type = $mod->type;
            my $subname = $mod->name;
            Carp::croak(qq(Cannot compose role $role_name: Cannot apply '$type' method modifier: Method "$subname" not found via class $class_name));
        }
    }
    return \@all_modifiers;
}

sub _create_fallback_validator {
    my($fallback, $fallback_set_in);

    return sub {
        unless (@_) {
            # no args, return current value
            return $fallback;
        }

        my($role_name, $value) = @_;
        if (defined($value) and !defined($fallback)) {
            $fallback = $value;
            $fallback_set_in = $role_name;
            return 1;
        }
        return 1 unless (defined($fallback) and defined ($value));
        return 1 unless ($fallback xor $value);

        Carp::croak(sprintf(q(Cannot compose role %s: fallback value '%s' conflicts with fallback value '%s' in role %s),
                                $role_name,
                                $value ? $value : defined($value) ? 'FALSE' : 'UNDEF',
                                $fallback ? $fallback : defined($fallback) ? 'FALSE' : 'UNDEF',
                                $fallback_set_in));
    };
}


sub _collect_meta_properties_from_roles {
    my($desc, @role_objs) = @_;

    my(%meta_properties_to_add, %source_for_meta_properties_to_add);
    foreach my $role ( @role_objs ) {
        foreach my $meta_prop_name ( $role->meta_properties_to_compose_into_classes ) {
            next if (defined $desc->{$meta_prop_name} and $meta_prop_name ne 'valid_signals');
            next unless defined $role->$meta_prop_name;

            if ($meta_prop_name ne 'valid_signals') {
                if (exists $meta_properties_to_add{$meta_prop_name}) {
                    Carp::croak(sprintf(q(Cannot compose role %s: Meta property '%s' conflicts with meta property from role %s),
                                        $role->role_name,
                                        $meta_prop_name,
                                        $source_for_meta_properties_to_add{$meta_prop_name}));
                }
                $meta_properties_to_add{$meta_prop_name} = $role->$meta_prop_name;
                $source_for_meta_properties_to_add{$meta_prop_name} = $role->role_name;
            } else {
                $meta_properties_to_add{valid_signals} ||= [];
                push @{ $meta_properties_to_add{valid_signals} }, @{ $role->valid_signals };
            }
        }
    }
    return UR::Util::deep_copy(\%meta_properties_to_add);
}

sub _validate_role_requirements {
    my($desc, @role_objs) = @_;

    my $class_name = $desc->{class_name};
    my %found_properties_and_methods = map { $_ => 1 } keys %{ $desc->{has} };

    foreach my $role ( @role_objs ) {
        foreach my $requirement ( @{ $role->requires } ) {
            unless ($found_properties_and_methods{ $requirement }
                        ||= _class_desc_lineage_has_method_or_property($desc, $requirement))
            {
                my $role_name = $role->role_name;
                Carp::croak("Cannot compose role $role_name: missing required property or method '$requirement'");
            }
        }

        # Properties and methods from this role can satisfy requirements for later roles
        foreach my $name ( $role->has_property_names, $role->method_names ) {
            $found_properties_and_methods{$name} = 1;
        }
    }

    return 1;
}

sub _validate_role_exclusions {
    my($desc, @role_objs) = @_;

    my %role_names = map { $_ => $_ } @{ $desc->{roles} };
    foreach my $role ( @role_objs ) {

        my @conflicts = grep { defined }
                            @role_names{ @{ $role->excludes } };
        if (@conflicts) {
            my $class_name = $desc->{class_name};
            my $plural = @conflicts > 1 ? 's' : '';
            Carp::croak(sprintf('Cannot compose role%s %s into class %s: Role %s excludes %s',
                                $plural,
                                join(', ', @conflicts),
                                $desc->{class_name},
                                $role->role_name,
                                $plural ? 'them' : 'it'));
        }
    }
    return 1;
}

sub _validate_class_method_overrides_consumed_roles {
    my $desc = shift;

    my $class_name = $desc->{class_name};
    my %this_class_role_names = $desc->{roles}
                                ? map { ref($_) ? ($_->role_name => 1) : ($_ => 1) }
                                    @{$desc->{roles}}
                                : ();
    my $this_class_methods = UR::Util::coderefs_for_package($class_name);
    while (my($method_name, $subref) = each %$this_class_methods) {
        my @overrides = UR::AttributeHandlers::get_overrides_for_coderef($subref);
        next unless (@overrides);

        my @missing_role_names = grep { ! exists $this_class_role_names{$_} }
                                 @overrides;
        if (@missing_role_names) {
            Carp::croak("Class method '$method_name' declares Overrides for roles the class does not consume: "
                        . join(', ', @missing_role_names));
        }
    }
    return 1;
}

sub _validate_class_desc_overrides {
    my($desc, @roles) = @_;

    my $class_name = $desc->{class_name};
    my %this_class_methods = map { %{ UR::Util::coderefs_for_package($_) } }
                                (@{$desc->{is}}, $class_name);

    my %overridden_methods_by_role;
    foreach my $method_name ( keys %this_class_methods ) {
        if (my @role_names = UR::AttributeHandlers::get_overrides_for_coderef($this_class_methods{$method_name})) {
            foreach my $role_name ( @role_names ) {
                $overridden_methods_by_role{$role_name} ||= [];
                push @{$overridden_methods_by_role{$role_name}}, $method_name;
            }
        }
    }

    foreach my $role ( @roles ) {
        my $role_name = $role->role_name;
        my $this_role_methods = $role->methods;
        my @this_role_method_names = keys( %$this_role_methods );

        my %method_is_overridden;
        my @conflict_methods = grep { ! ($method_is_overridden{$_} ||= _coderef_overrides_package($this_class_methods{$_}, $role_name)) }
                               grep { exists $this_class_methods{$_} }
                                   @this_role_method_names;
        if (@conflict_methods) {
            my $plural = scalar(@conflict_methods) > 1 ? 's' : '';
            my $conflicts = scalar(@conflict_methods) > 1 ? 'conflict' : 'conflicts';

            my %conflicting_sources;
            CONFLICTING_METHOD_NAME:
            foreach my $conflicting_method_name ( @conflict_methods ) {
                foreach my $source_class_name ( $class_name, @{$desc->{is}} ) {
                    if ($source_class_name->can($conflicting_method_name)) {
                        $conflicting_sources{$conflicting_method_name} = $source_class_name;
                        next CONFLICTING_METHOD_NAME;
                    }
                }
                $conflicting_sources{$conflicting_method_name} = '<unknown>';
            }
            Carp::croak("Cannot compose role $role_name: "
                        . "Method name${plural} $conflicts with class $class_name:\n"
                        . join("\n", map { sprintf("\t%s (from %s)\n", $_, $conflicting_sources{$_}) }
                                        keys %conflicting_sources)
                        . "Did you forget to add the 'Overrides' attribute?");
        }

        my @missing_methods = grep { ! exists $this_role_methods->{$_} and ! exists $role->has->{$_} }
                              @{$overridden_methods_by_role{$role_name}};
        if (@missing_methods) {
            my $plural = scalar(@missing_methods) > 1 ? 's' : '';
            my $method_list = join(q(', '), @missing_methods);
            Carp::croak("Cannot compose role $role_name: "
                        . "Class method${plural} '$method_list' declares it Overrides non-existant method in the role.");
        }
    }

    return 1;
}

sub _class_desc_lineage_has_method_or_property {
    my($desc, $requirement) = @_;

    my $class_name = $desc->{class_name};
    if (my $can = $class_name->can($requirement)) {
        return $can;
    }

    my @is = @{ $desc->{is} };
    my %seen;
    while(my $parent = shift @is) {
        next if $seen{$parent}++;

        if (my $can = $parent->can($requirement)) {
            return $can;
        }

        my $parent_meta = $parent->__meta__;
        if (my $prop_meta = $parent_meta->property($requirement)) {
            return $prop_meta;
        }
    }
    return;
}

sub _import_methods_from_roles_into_namespace {
    my($class_name, $roles) = @_;

    my $this_class_methods = UR::Util::coderefs_for_package($class_name);

    my(%all_imported_methods, %method_sources);
    foreach my $role ( @$roles ) {
        my $this_role_methods = $role->methods;
        my @this_role_method_names = keys( %$this_role_methods );

        my @conflicting = grep { ! exists($this_class_methods->{$_}) }  # not a conflict if the class overrides
                          grep { exists $all_imported_methods{$_} }
                          @this_role_method_names;

        if (@conflicting) {
            my $plural = scalar(@conflicting) > 1 ? 's' : '';
            my $conflicts = scalar(@conflicting) > 1 ? 'conflict' : 'conflicts';
            Carp::croak('Cannot compose role ' . $role->role_name
                        . ": method${plural} $conflicts with those defined in other roles\n\t"
                        . join("\n\t", join('::', map { ( $method_sources{$_}, $_ ) } @conflicting)));
        }

        @method_sources{ @this_role_method_names } = ($role->role_name) x @this_role_method_names;
        @all_imported_methods{ @this_role_method_names } = @$this_role_methods{ @this_role_method_names };
    }

    delete @all_imported_methods{ keys %$this_class_methods };  # Don't import roles' methods already defined on the class
    foreach my $name ( keys %all_imported_methods ) {
        Sub::Install::install_sub({
            code => $all_imported_methods{$name},
            as => $name,
            into => $class_name,
        });
    }
}

sub _coderef_overrides_package {
    my($coderef, $package) = @_;

    my @overrides = UR::AttributeHandlers::get_overrides_for_coderef($coderef);
    return any { $_ eq $package } @overrides;
}

sub _apply_overloads_to_namespace {
    my($class_name, $overloads) = @_;

    my(%cooked_overloads);
    while( my($op, $impl) = each %$overloads) {
        $cooked_overloads{$op} = ref $impl
                                    ? sprintf(q($overloads->{'%s'}), $op)
                                    : qq('$impl');
    }

    my $string = "package $class_name;\n"
                 . 'use overload '
                 . join(",\n\t", map { sprintf(q('%s' => %s), $_, $cooked_overloads{$_}) } keys %cooked_overloads)
                 . ';';

    my $exception;
    do {
        local $@;
        eval $string;
        $exception = $@;
    };

    if ($exception) {
        Carp::croak("Failed to apply overloads to package $class_name: $exception");
    }
    return 1;
}

sub _apply_method_modifiers_to_namespace {
    my($desc, $modifiers_list) = @_;

    my $class_name = $desc->{class_name};

    my $isa = join('::', $class_name, 'ISA');
    no strict 'refs';
    local @$isa = (@$isa, @{$desc->{is}});
    use strict 'refs';

    foreach my $mod ( @$modifiers_list ) {
        $mod->apply_to_package($class_name);
    }
    1;
}

sub _define_role {
    my($role_name, $func, @params) = @_;

    if (defined($func) and $func eq "role" and @params > 1 and $role_name ne "UR::Role") {
        my @role_params;
        if (@params == 2 and ref($params[1]) eq 'HASH') {
            @role_params = %{ $params[1] };
        }
        elsif (@params == 2 and ref($params[1]) eq 'ARRAY') {
            @role_params = @{ $params[1] };
        }
        else {
            @role_params = @params[1..$#params];
        }
        my $role = UR::Role->define(role_name => $role_name, @role_params);
        unless ($role) {
            Carp::croak "error defining role $role_name!";
        }
        return sub { $role_name };
    } else {
        return;
    }
}

sub _inject_instance_constructor_into_namespace {
    my $self = shift;

    my $package = $self->role_name;
    my $full_name = join('::', $package, 'create');
    my $sub = Sub::Name::subname $full_name => sub {
        my($class, %params) = @_;
        return UR::Role::PrototypeWithParams->create(prototype => $self, role_params => \%params);
    };
    Sub::Install::reinstall_sub({
        into => $package,
        as => 'create',
        code => $sub,
    });

    Sub::Install::reinstall_sub({
        into => $package,
        as => '__role__',
        code => sub { $package->create() },
    });
}

1;

__END__

=pod

=head1 NAME

UR::Role::Prototype - Implementation for defining and composing roles

=head1 DESCRIPTION

Basic info about using roles is described in the documentation for L<UR::Role>.

When a role is defined using the C<role> keyword, it creates a L<UR::Role::Prototype>
instance.  Role prototypes represent an uncomposed role.  They have most of the
same properties as L<UR::Object::Type> instances.

=head2 Methods

=over 4

=item property_data($property_name)

Returns a hashref of property data about the named property.

=item has_property_names()

Returns a list of all the properties named in the role's C<has>.

=item id_by_property_names()

Returns a list of all the properties named in the roles's C<id_by>.

=item method_names()

Returns a list of all the function names in the role's namespace.

=item define(%role_definition)

Define a role and return the role prototype.

=item role_name()

Return the name of the role.

=item class_names()

Returns a list of the names of the classes composing this role.

=item requires()

Returns an arrayref of strings.  These strings must exist in composing classes,
either as properties or methods.

=item excludes()

Returns an arrayref of role names that may not be composed with this role.

=back

=head2 Role namespace methods

When a role is defined, these methods are injected into the role's namespace

=over 4

=item create(%params)

Return a L<UR::Role::PrototypeWithParams> object representing this role with
a set of params immediately before it is composed into a class.  See the
section on Parameterized Roles in L<UR::Role>.

=item __role__()

Calls the above C<create()> method with no arguments.  This is used by the
role composition mechanism to trigger autoloading the role's module when role
names are given as strings in a class definition.

=back

=head1 SEE ALSO

L<UR>, L<UR::Object::Type::Initializer>, L<UR::Role::Instance>, L<UR::Role::PrototypeWithParams>

=cut
