package Command::SubCommandFactory;

use strict;
use warnings;
use UR;

class Command::SubCommandFactory {
    is => 'Command::Tree',
    is_abstract => 1,
    doc => 'Base class for commands that delegate to sub-commands that may need to be dynamically created',
};

sub _init_subclass {
    my $subclass = shift;
    my $meta = $subclass->__meta__;
    if (grep { $_ eq __PACKAGE__ } $meta->parent_class_names) {
        my $delegating_class_name = $subclass;
        eval "sub ${subclass}::_delegating_class_name { '$delegating_class_name' }";
    }

    return 1;
}

sub _build_sub_command_mapping {
    my ($class) = @_;

    unless ($class->can('_sub_commands_from')) {
        die "Class $class does not implement _sub_commands_from()!\n"
            . "This method should return the namespace to use a reference "
            . "for defining sub-commands."
    }
    my $ref_class = $class->_sub_commands_from;

    my @inheritance;
    if ($class->can('_sub_commands_inherit_from') and defined $class->_sub_commands_inherit_from) {
        @inheritance = $class->_sub_commands_inherit_from();
    }
    else {
        @inheritance = $class;
    }

    my $module = $ref_class;
    $module =~ s/::/\//g;
    $module .= '.pm';
    my $base_path = $INC{$module};
    unless ($base_path) {
        if (UR::Object::Type->get($ref_class)) {
            $base_path = $INC{$module};
        }
        unless ($base_path) {
           die "Failed to find the path for ref class $ref_class!"; 
        }
    }
    $base_path =~ s/$module//;

    my $ref_path = $ref_class;
    $ref_path =~ s/::/\//g;
    my $full_ref_path = $base_path . '/' . $ref_path;

    my @target_paths = glob("\Q$full_ref_path\E/*.pm");
    my @target_class_names;
    for my $target_path (@target_paths) { 
        my $target = $target_path;
        $target =~ s#\Q$base_path\E\/$ref_path/##;
        $target =~ s/\.pm//;

        my $target_base_class = $class->_target_base_class;
        my $target_class_name = $target_base_class . '::' . $target;  

        my $target_meta = UR::Object::Type->get($target_class_name);
        next unless $target_meta; 
        next unless $target_class_name->isa($target_base_class); 

        push @target_class_names, $target => $target_class_name; 
    }
    my %target_classes = @target_class_names;

    # Create a mapping of command names to command classes, and either find or
    # create those command classes
    my $mapping;
    for my $target (sort keys %target_classes) {
        my $target_class_name = $target_classes{$target};

        my $command_class_name = $class . '::' . $target; 
        my $command_module_name = $command_class_name;
        $command_module_name =~ s|::|/|g;
        $command_module_name .= '.pm';

        # If the command class already exists, load it. Otherwise, create one.
        if (grep { -e $_ . '/' . $command_module_name } @INC) {
            UR::Object::Type->get($command_class_name);
        }
        else {
            next if not $class->_build_sub_command($command_class_name, @inheritance);
        }

        # Created commands need to know where their parameters came from
        no warnings 'redefine';
        eval "sub ${command_class_name}::_target_class_name { '$target_class_name' }";
        use warnings;

        my $command_name = $class->_command_name_for_class_word($target);
        $mapping->{$command_name} = $command_class_name;
    }

    return $mapping;
}

sub _build_sub_command {
    my ($self, $class_name, @inheritance) = @_;
    class {$class_name} { 
        is => \@inheritance, 
        doc => '',
    };
    return $class_name;
}

sub _target_base_class { return $_[0]->_sub_commands_from; }
sub _target_class_name { undef }
sub _sub_commands_inherit_from { undef }

1;

