package UR::Object::Command::Crud;

use strict;
use warnings 'FATAL';

use UR::Object::Command::Create;
use UR::Object::Command::Copy;
use UR::Object::Command::Delete;
use UR::Object::Command::Update;
use UR::Object::Command::UpdateTree;
use UR::Object::Command::UpdateIsMany;
use UR::Object::Command::CrudUtil;
use Lingua::EN::Inflect;
use List::MoreUtils;
use Sub::Install;
use UR::Object::Command::List;

class UR::Object::Command::Crud {
    id_by => {
        target_class => { is => 'Text' },
    },
    has => {
        namespace => { is => 'Text', },
        target_name => { is => 'Text', },
        target_name_pl => { is => 'Text', },
        sub_command_configs => { is => 'HASH', default_value => {}, },
    },
    has_calculated => {
        target_name_ub => {
            calculate_from => [qw/ target_name /],
            calculate => q( $target_name =~ s/ /_/g; $target_name; ),
        },
        target_name_ub_pl => {
            calculate_from => [qw/ target_name_pl /],
            calculate => q( $target_name_pl =~ s/ /_/g; $target_name_pl; ),
        },
    },
    has_transient_optional => {
        namespace_sub_command_classes => {
            is => 'Text',
            is_many => 1,
        },
        namespace_sub_command_names => {
            is => 'Text',
            is_many => 1,
        },
    },
    doc => 'Dynamically build CRUD commands',
};

sub buildable_sub_command_names { (qw/ copy create delete list update /) }
sub sub_command_class_name_for {
    join('::', $_[0]->namespace, join('', map { ucfirst } split(/\s+/, $_[1])));
}

sub sub_command_config_for {
    my ($self, $name) = @_;

    $self->fatal_message('No sub command name given to get config!') if not $name;

    my $sub_command_configs = $self->sub_command_configs;
    return if !exists $sub_command_configs->{$name};

    if ( ref($sub_command_configs->{$name}) ne 'HASH' ) {
        $self->fatal_message('Invalid sub_command_config for %s: %s', $name, Data::Dumper::Dumper($sub_command_configs->{$name}));
    }

    %{$sub_command_configs->{$name}}; # copy hash
}

sub create_command_subclasses {
    my ($class, %params) = @_;

    $class->fatal_message('No target_class given!') if not $params{target_class};

    my $self = $class->create(%params);
    return if not $self;

    $self->namespace( $self->target_class.'::Command' ) if not $self->namespace;
    $self->_resolve_target_names;

    my @errors = $self->__errors__;
    $self->fatal_message( join("\n", map { $_->__display_name__ } @errors) ) if @errors;

    $self->_build_command_tree;
    $self->_get_current_namespace_sub_commands_and_names;

    $self->_build_copy_command;
    $self->_build_create_command;
    $self->_build_list_command;
    $self->_build_update_command;
    $self->_build_delete_command;
    $self->_set_namespace_sub_commands_and_names;

    $self;
}

sub _get_current_namespace_sub_commands_and_names {
    my $self = shift;
    $self->namespace_sub_command_classes([ $self->namespace->sub_command_classes ]);
    $self->namespace_sub_command_names([ $self->namespace->sub_command_names ]);
}

sub _add_to_namespace_sub_commands_and_names {
    my ($self, $name) = @_;
    $self->namespace_sub_command_names([ $self->namespace_sub_command_names, $name ]);
    $self->namespace_sub_command_classes([ $self->namespace_sub_command_classes, $self->sub_command_class_name_for($name) ]);
}

sub _set_namespace_sub_commands_and_names {
    my $self = shift;

    my @sub_command_classes = sort { $a cmp $b } List::MoreUtils::uniq $self->namespace_sub_command_classes;
    Sub::Install::reinstall_sub({
        code => sub{ @sub_command_classes },
        into => $self->namespace,
        as => 'sub_command_classes',
        });

    my @sub_command_names = sort { $a cmp $b } List::MoreUtils::uniq $self->namespace_sub_command_names;
    Sub::Install::reinstall_sub({
        code => sub{ @sub_command_names },
        into => $self->namespace,
        as => 'sub_command_names',
        });
}

sub _resolve_target_names {
    my $self = shift;

    if ( !$self->target_name ) {
        $self->target_name( join(' ', map { lc(UR::Value::Text->get($_)->to_camel) } split('::', $self->target_class)) );
    }

    if ( !$self->target_name_pl ) {
        Lingua::EN::Inflect::classical(persons => 1);
        $self->target_name_pl( Lingua::EN::Inflect::PL($self->target_name) );
    }
}

sub _build_command_tree {
    my $self = shift;

    return if UR::Object::Type->get($self->namespace);

    UR::Object::Type->define(
        class_name => $self->namespace,
        is => 'Command::Tree',
        doc => 'work with '.$self->target_name_pl,
    );

    for my $property (qw/ namespace target_class target_name target_name_pl target_name_ub target_name_ub_pl /) {
        Sub::Install::install_sub({
            code => sub{ $self->$property },
            into => $self->namespace,
            as => $property,
            });
    }
}

sub _build_list_command {
    my $self = shift;

    my $list_command_class_name = $self->sub_command_class_name_for('list');
    return if UR::Object::Type->get($list_command_class_name); # Do not recreate...

    my %config = $self->sub_command_config_for('list');
    return if exists $config{skip}; # Do not create if told not too...

    my @has =  (
        subject_class_name  => {
            is_constant => 1,
            value => $self->target_class,
        },
    );

    my $show = delete $config{show};
    if ( $show ) {
        $self->fatal_message('Invalid config for LIST `show` => %s', Data::Dumper::Dumper($show)) if ref $show;
        push @has, show => { value => $show, };
    }

    my $order_by = delete $config{order_by};
    if ( $order_by ) {
        $self->fatal_message('Invalid config for LIST `order_by` => %s', Data::Dumper::Dumper($order_by)) if ref $order_by;
        push @has, order_by => { value => $order_by, };
    }

    $self->fatal_message('Unknown config for LIST: %s', Data::Dumper::Dumper(\%config)) if %config;

    UR::Object::Type->define(
        class_name => $list_command_class_name,
        is => 'UR::Object::Command::List',
        has => \@has,
    );

    Sub::Install::install_sub({
        code => sub{ $self->target_name_pl },
        into => $list_command_class_name,
        as => 'help_brief',
        });

    $self->_add_to_namespace_sub_commands_and_names('list');
}

sub _build_create_command {
    my $self = shift;

    my $create_command_class_name = $self->sub_command_class_name_for('create');
    return if UR::Object::Type->get($create_command_class_name); # Do not recreate...

    my %config = $self->sub_command_config_for('create');
    return if exists $config{skip}; # Do not create if told not too...

    my @exclude;
    if ( exists $config{exclude} ) {
       @exclude = @{delete $config{exclude}};
    }

    $self->fatal_message('Unknown config for CREATE: %s', Data::Dumper::Dumper(\%config)) if %config;

    my $target_meta = $self->target_class->__meta__;
    my %properties;
    for my $target_property ( $target_meta->property_metas ) {
        my $property_name = $target_property->property_name;

        next if grep { $property_name eq $_ } @exclude;
        next if $target_property->class_name eq 'UR::Object';
        next if $property_name =~ /^_/;
        next if grep { $target_property->$_ } (qw/ is_calculated is_constant is_transient /);
        next if $target_property->is_id and ($property_name eq 'id' or $property_name =~ /_id$/);
        next if grep { not $target_property->$_ } (qw/ is_mutable /);
        next if $target_property->is_many and $target_property->is_delegated and not $target_property->via; # direct relationship

        my %property = (
            property_name => $property_name,
            data_type => $target_property->data_type,
            is_many => $target_property->is_many,
            is_optional => $target_property->is_optional,
            valid_values => $target_property->valid_values,
            default_value => $target_property->default_value,
            doc => $target_property->doc,
        );

        if ( $property_name =~ s/_id(s)?$// ) {
            $property_name .= $1 if $1;
            my $object_meta = $target_meta->property_meta_for_name($property_name);
            if ( $object_meta and  not grep { $object_meta->$_ } (qw/ is_calculated is_constant is_transient id_class_by /) ) {
                $property{property_name} = $property_name;
                $property{data_type} = $object_meta->data_type;
                $property{doc} = $object_meta->doc if $object_meta->doc;
            }
        }

        $properties{$property{property_name}} = \%property;
    }

    $self->fatal_message('No properties found for target class %s', $self->target_class) if not %properties;

    my $create_meta = UR::Object::Type->define(
        class_name => $create_command_class_name,
        is => 'UR::Object::Command::Create',
        has => \%properties,
        has_constant_transient => {
            namespace => { value => $self->namespace, },
            target_class_properties => { value => [ keys %properties ], },
        },
        doc => 'create '.$self->target_name_pl,
    );

    $self->_add_to_namespace_sub_commands_and_names('create');
}

sub _build_copy_command {
    my $self = shift;

    my $copy_command_class_name = $self->sub_command_class_name_for('copy');
    return if UR::Object::Type->get($copy_command_class_name);
    
    my %config = $self->sub_command_config_for('copy');
    return if exists $config{skip}; # Do not create if told not too...

    UR::Object::Type->define(
        class_name => $copy_command_class_name,
        is => 'UR::Object::Command::Copy',
        doc => sprintf('copy a %s', $self->target_name),
        has => {
            source => {
                is => $self->target_class,
                shell_args_position => 1,
                doc => sprintf('The source %s to copy.', $self->target_name),
            },
        },
    );

    $self->_add_to_namespace_sub_commands_and_names('copy');
}

sub _build_update_command {
    my $self = shift;

    my %config = $self->sub_command_config_for('update');
    return if exists $config{skip}; # Do not create if told not too...

    # Config
    # target meta and properties
    my $target_meta = $self->target_class->__meta__;
    my @properties = $target_meta->property_metas;

    # exclude these properties
    my @exclude;
    if ( exists $config{exclude} ) {
       @exclude = @{delete $config{exclude}};
    }

    # only if null
    my %only_if_null;
    if ( my $only_if_null = delete $config{only_if_null} ) {
        my $ref = ref $only_if_null;
        if ( $only_if_null eq 1 ) {
            %only_if_null = map { $_->property_name => 1 } @properties;
        }
        elsif ( not $ref ) {
            Carp::confess("Unknown 'only_if_null' config: $only_if_null");
        }
        else {
            %only_if_null = map { $_ => 1 } map { s/_id$//; $_; } ( $ref eq 'ARRAY' ? @$only_if_null : keys %$only_if_null )
        }
    }

    $self->fatal_message('Unknown config for UPDATE: %s', Data::Dumper::Dumper(\%config)) if %config;

    # Update Tree
    my $update_command_class_name = $self->sub_command_class_name_for('update');
    my $update_meta = UR::Object::Type->get($update_command_class_name);

    my (@update_sub_commands, @update_sub_command_names);
    if ( not $update_meta ) {
        UR::Object::Type->define(
            class_name => $update_command_class_name,
            is => 'UR::Object::Command::UpdateTree',
            doc => 'properties on '.$self->target_name_pl,
        );
    }
    else { # update command tree exists
        @update_sub_commands = $update_command_class_name->sub_command_classes;
        @update_sub_command_names = $update_command_class_name->sub_command_names;
    }

    # Properties: make a command for each
    my %properties_seen;
    PROPERTY: for my $target_property ( $target_meta->property_metas ) {
        my $property_name = $target_property->property_name;
        next if grep { $property_name eq $_ } @update_sub_command_names;
        next if List::MoreUtils::any { $property_name eq $_ } @exclude;

        next if $target_property->class_name eq 'UR::Object';
        next if $property_name =~ /^_/;
        next if grep { $target_property->$_ } (qw/ is_id is_calculated is_constant is_transient /);
        next if grep { not $target_property->$_ } (qw/ is_mutable /);
        next if $target_property->is_many and $target_property->is_delegated and not $target_property->via; # direct relationship

        my %property = (
            name => $target_property->singular_name,
            name_pl => $target_property->plural_name,
            is_many => $target_property->is_many,
            data_type => $target_property->data_type,
            doc => $target_property->doc,
        );
        $property{valid_values} = $target_property->valid_values if defined $target_property->valid_values;
        $property{only_if_null} = ( exists $only_if_null{$property_name} ) ? 1 : 0;

        if ( $property_name =~ s/_id(s)?$// ) {
            $property_name .= $1 if $1;
            my $object_meta = $target_meta->property_meta_for_name($property_name);
            if ( $object_meta ) {
                next if grep { $object_meta->$_ } (qw/ is_calculated is_constant is_transient id_class_by /);
                $property{name} = $object_meta->singular_name;
                $property{name_pl} = $object_meta->plural_name;
                $property{is_optional} = $object_meta->is_optional;
                $property{data_type} = $object_meta->data_type;
            }
        }
        next if $properties_seen{$property_name};
        $properties_seen{$property_name} = 1;

        my $update_sub_command;
        if ( $property{is_many} ) {
            $update_sub_command = $self->_build_update_is_many_property_sub_commands(\%property);
        }
        else {
            $update_sub_command = $self->_build_update_property_sub_command(\%property);
        }
        push @update_sub_commands, $update_sub_command if $update_sub_command;
    }

    Sub::Install::reinstall_sub({
        code => sub{ @update_sub_commands },
        into => $update_command_class_name,
        as => 'sub_command_classes',
        });

    $self->_add_to_namespace_sub_commands_and_names('update');
}

sub _build_update_property_sub_command {
    my ($self, $property) = @_;

    my $update_property_class_name = join('::', $self->sub_command_class_name_for('update'), join('', map { ucfirst } split('_', $property->{name})));
    return if UR::Object::Type->get($update_property_class_name);

    UR::Object::Type->define(
        class_name => $update_property_class_name,
        is => 'UR::Object::Command::Update',
        has => {
            $self->target_name_ub_pl => {
                is => $self->target_class,
                is_many => 1,
                shell_args_position => 1,
                doc => ucfirst($self->target_name_pl).' to update, resolved via query string.',
            },
            value => {
                is => $property->{data_type},
                valid_values => $property->{valid_values},
                doc => sprintf('New `%s` (%s) of the %s.', $property->{name}, $property->{data_type}, $self->target_name_pl),
            },
        },
        has_constant_transient => {
            namespace => { value => $self->namespace, },
            property_name => { value => $property->{name}, },
            only_if_null => { value => $property->{only_if_null}, },
        },
        doc => sprintf('update %s %s%s', $self->target_name_pl, $property->{name}, ( $property->{only_if_null} ? ' [only if null]' : '' )),
    );

    $update_property_class_name;
}

sub _build_update_is_many_property_sub_commands {
    my ($self, $property) = @_;

    my $tree_class_name = join('::', $self->namespace, 'Update', join('', map { ucfirst } split('_', $property->{name_pl})));
    UR::Object::Type->define(
        class_name => $tree_class_name,
        is => 'Command::Tree',
        doc => 'add/remove '.$property->{name_pl},
    );

    my @update_sub_command_class_names;
    Sub::Install::reinstall_sub({
        code => sub{ @update_sub_command_class_names },
        into => $tree_class_name,
        as => 'sub_command_classes',
        });

    for my $function (qw/ add remove /) {
        my $sub_command_class_name = join('::', $tree_class_name, ucfirst($function));
        push @update_sub_command_class_names, $sub_command_class_name;
        UR::Object::Type->define(
            class_name => $sub_command_class_name,
            is => 'UR::Object::Command::UpdateIsMany',
            has => {
                $self->target_name_ub_pl => {
                    is => $self->target_class,
                    is_many => 1,
                    shell_args_position => 1,
                    doc => sprintf('%s to update %s, resolved via query string.', ucfirst($self->target_name_pl), $property->{name_pl}),
                },
                'values' => => {
                    is => $property->{data_type},
                    is_many => 1,
                    valid_values => $property->{valid_values},
                    doc => sprintf('%s (%s) to %s %s %s.', ucfirst($property->{name_pl}), $property->{data_type}, $function, ( $function eq 'add' ? 'to' : 'from' ), $self->target_name_pl),
                },
            },
            has_constant_transient => {
                namespace => { value => $self->namespace, },
                property_function => { value => join('_', $function, $property->{name}), },
            },
            doc => sprintf('%s to %s', $property->{name_pl}, $self->target_name_pl),
        );
    }

    $tree_class_name;
}

sub _build_delete_command {
    my $self = shift;

    my $delete_command_class_name = $self->sub_command_class_name_for('delete');
    return if UR::Object::Type->get($delete_command_class_name);

    my %config = $self->sub_command_config_for('delete');
    return if exists $config{skip}; # Do not create if told not too...

    $self->fatal_message('Unknown config for DELETE: %s', Data::Dumper::Dumper(\%config)) if %config;

    UR::Object::Type->define(
        class_name => $delete_command_class_name,
        is => 'UR::Object::Command::Delete',
        has => {
            $self->target_name_ub => {
                is => $self->target_class,
                shell_args_position => 1,
                require_user_verify => 1,
                doc => ucfirst($self->target_name).' to delete, resolved via query string.',
            },
        },
        has_constant_transient => {
            namespace => { value => $self->namespace, },
        },
        doc => sprintf('delete %s', Lingua::EN::Inflect::A($self->target_name)),
    );

    $self->_add_to_namespace_sub_commands_and_names('delete');
}

1;
