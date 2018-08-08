package UR::Namespace::Command::Define::Class;
use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Namespace::Command::Define::Class {
    is => 'UR::Namespace::Command::Base',
    has => [
        names => {
            is_optional => 1,
            is_many => 1,
            shell_args_position => 1
        },
        extends => { doc => "The base class.  Defaults to UR::Object.", default_value => 'UR::Object' },
    ],
    doc => 'Add one or more classes to the current namespace'
};

sub sub_command_sort_position { 3 }

sub help_synopsis {
    return <<'EOS'

$ cd Acme

$ ur define class Animal Vegetable Mineral
A Acme::Animal
A Acme::Vegetable
A Acme::Mineral

$ ur define class Dog Cat Bird --extends Animal
A Acme::Dog
A Acme::Cat
A Acme::Bird

EOS
}

sub execute {
    my $self = shift;
    my @class_names = $self->names;
    unless (@class_names) {
        $self->error_message("No class name(s) provided!");
        return;
    }

    my $namespace = $self->namespace_name;
    my $is = $self->extends || 'UR::Object';
    my $parent_class_meta = UR::Object::Type->get($is);
    unless ($parent_class_meta) {
        unless ($self->extends =~ /^${namespace}::/) {
            $parent_class_meta = UR::Object::Type->get($namespace . '::' . $is);
            if ($parent_class_meta) {
                $is = $namespace . '::' . $is;
            }
        }
        unless ($parent_class_meta) {
            $self->error_message("Failed to find base class $is!");
            return;
        }
    }
    
    for my $class_name (@class_names) {
        unless ($class_name =~ /^${namespace}::/) {
            $class_name = $namespace . '::' . $class_name;
        }
        my $new_class = UR::Object::Type->create(
            class_name => $class_name,
            is => $is,
        );
        unless ($new_class) {
            $self->error_message("Failed to create class $class_name!: "
                . UR::Object::Type->error_message
            );
            return;
        }
        print "A   $class_name\n";
        $new_class->rewrite_module_header 
            or die "Failed to write class $class_name!: "
                . $new_class->error_message;
    }
    return 1;
}

1;

