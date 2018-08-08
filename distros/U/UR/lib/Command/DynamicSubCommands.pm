package Command::DynamicSubCommands;

use strict;
use warnings;
use UR;

class Command::DynamicSubCommands {
    is => 'Command',
    is_abstract => 1,
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

sub __extend_namespace__ {
    # auto generate sub-classes at the time of first reference
    my ($self,$ext) = @_;

    my $meta = $self->SUPER::__extend_namespace__($ext);
    return $meta if $meta;

    unless ($self->can('_sub_commands_from')) {
        die "Class " . $self->class . " does not implement _sub_commands_from()!\n"
            . "This method should return the namespace to use a reference "
            . "for defining sub-commands."
    }
    my $ref_class = $self->_sub_commands_from;
    my $target_class_name = join('::', $ref_class, $ext);
    my $target_class_meta = UR::Object::Type->get($target_class_name);
    if ($target_class_meta and $target_class_name->isa($ref_class)) {
        my $subclass_name = join('::', $self->class, $ext);
        my $subclass = $self->_build_sub_command($subclass_name, $self->class, $target_class_name);

        my $meta = $subclass->__meta__;
        return $meta;
    }

    return;
}

sub _build_all_sub_commands {
    my ($class) = @_;

    unless ($class->can('_sub_commands_from')) {
        die "Class $class does not implement _sub_commands_from()!\n"
            . "This method should return the namespace to use a reference "
            . "for defining sub-commands."
    }
    my $ref_class = $class->_sub_commands_from;

    my $delegating_class_name = $class;

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
        $target =~ s#$base_path\/$ref_path/##;
        $target =~ s/\.pm//;
        my $target_class_name = $ref_class . '::' . $target;
        my $target_meta = UR::Object::Type->get($target_class_name);
        next unless $target_meta;
        next unless $target_class_name->isa($ref_class);
        push @target_class_names, $target => $target_class_name;
    }
    my %target_classes = @target_class_names;

    my @subclasses;
    for my $target (sort keys %target_classes) {
        my $target_class_name = $target_classes{$target};
        my $class_name = $delegating_class_name . '::' . $target;

        # skip commands which have a module
        my $module_name = $class_name;
        $module_name =~ s|::|/|g;
        $module_name .= '.pm';

        if (my @matches = grep { -e $_ . '/' . $module_name } @INC) {
            my $c = UR::Object::Type->get($class_name);
            push @subclasses, $class_name;
            next;
        }

        my @new_class_names = $class->_build_sub_command($class_name,$delegating_class_name,$target_class_name);
        for my $new_class_name (@new_class_names) {
            eval "sub ${new_class_name}::_target_class_name { '$target_class_name' }";
            push @subclasses, $new_class_name;
        }
    }

    return @subclasses;
}

sub _build_sub_command {
    my ($self,$class_name,$delegating_class_name,$reference_class_name) = @_;
    class {$class_name} { 
        is => $delegating_class_name, 
        doc => '',
    };
    return $class_name;
}

sub sub_command_dirs {
    my $class = ref($_[0]) || $_[0];
    return ( $class eq $class->_delegating_class_name ? 1 : 0 );
}

sub sub_command_classes {
    my $class = shift;

    unless(exists $class->__meta__->{_sub_commands}) {
        my @subclasses = $class->_build_all_sub_commands;
        $class->__meta__->{_sub_commands} = \@subclasses;
    }

    return @{ $class->__meta__->{_sub_commands} };
}

sub _target_class_name { undef }

1;

=pod

=head1 NAME

Command::DynamicSubCommands - auto-generate sub-commands based on other classes

=head1 SYNOPSIS

 # given that these classes exist:
 #   Acme::Task::Foo
 #   Acme::Task::Bar
 
 # in Acme/Worker/Command/DoTask.pm:

    class Acme::Worker::Command::DoTask {
        is => 'Command::DynamicSubCommands',
        has => [
            param1 => { is => 'Text' },
            param2 => { is => 'Text' },
        ]
    };

    sub _sub_commands_from { 'Acme::Task' }

    sub execute {
        my $self = shift;
        print "this command " . ref($self) . " applies to " . $self->_target_class_name;
        return 1;
    }

 # the class above will discover them at compile, 
 # and auto-generate these subclasses of itself:
 #   Acme::Worker::Command::DoTask::Foo
 #   Acme::Worker::Command::DoTask::Bar
 
 # in the shell...
 #
 #   $ acme worker do-task
 #   foo
 #   bar
 #
 #   $ acme worker do-task foo --param1 aaa --param2 bbb 
 #   this command Acme::Worker::Command::DoTask::Foo applies to Acme::Task::Foo
 #
 #   $ acme worker do-task bar --param1 ccc --param2 ddd
 #   this command Acme::Worker::Command::DoTask::Bar applies to Acme::Task::Bar

=head1 DESCRIPTION

This module helps you avoid writing boilerplate commands.

When a command has a set of sub-commands which are meant to be derived from another 
group of classes, this module lets you auto-generate those sub-commands at run 
time.

=head1 REQUIRED ABSTRACT METHOD

=over 4

=item _sub_commands_from 

    $base_namespace = Acme::Order::Command->_sub_commands_from();
    # 'Acme::Task

    Returns the namespace from which target classes will be discovered, and
    sub-commands will be generated.

=back

=head1 PRIVATE API

=over 4

=item _target_class_name

    $c= Acme::Order::Command::Purchasing->_target_class_name;
    # 'Acme::Task::Foo'

    The name of some class under the _sub_commands_from() namespace.
    This value is set during execute, revealing which sub-command the caller is using. 

=back

=head1 OPTIONAL OVERRIDES

=over 4

=item _build_sub_commmand

    This can be overridden to customize the sub-command construction.
    By default, each target under _sub_commands_from will result in 
    a call to this method.  The default implementation is below:

    my $self = shift;
    my ($suggested_class_name,$delegator_class_name,$target_class_name) = @_;
    
    class {$suggested_class_name} { 
        is => $delegator_class_name, 
        sub_classify_by => 'class',
        has_constant => [
            _target_class_name => { value => $target_class_name },
        ]
    };

    return ($suggested_class_name);
    
    Note that the class in question may be on the filesystem, and not need
    to be created.  The return list can include more than one class name,
    or zero class names.

=item _build_all_sub_commands 

    This is called once for any class which inherits from Command::DynamicSubCommands.

    It generates the sub-commands as needed, and returns a list.

    By default it resolves the target classes, and calls  _build_sub_command

    It can be overridden to customize behavior, or filter results.  Be sure
    to call @cmds = $self->SUPER::_build_all_sub_commands() if you want 
    to get the default commands in addition to overriding.

=back 

The sub-commands need not be 1:1 with the target classes, though this is the default.

The sub-commands need not inherit from the Command::DynamicSubCommands base command
which generates them, though this is the default.


=cut

