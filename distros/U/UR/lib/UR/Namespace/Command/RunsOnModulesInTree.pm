
# Abstract base command for commands which run on all or part of a class tree.

package UR::Namespace::Command::RunsOnModulesInTree;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has => [
        classes_or_modules => {
            is_many => 1,
            is_optional => 1,
            shell_args_position => 99
        }
    ]
);


sub is_abstract
{
    my $self = shift;
    my $class = ref($self) || $self;
    return 1 if $class eq __PACKAGE__;
    return;
}

sub _help_detail_footer
{
    my $text =
    return <<EOS
This command requires that the current working directory be under a namespace module.

If no modules or class names are specified as parameters, it runs on all modules in the namespace.

If modules or class names ARE listed, it will operate only on those.

Words containing double-colons will be interpreted as absolute class names.

All other words will be interpreted as relative file paths to modules.
EOS
}



sub execute
{
    my $self = shift;

    my $params = shift;

    my $namespace = $self->namespace_name;
    unless ($namespace) {
        die "This command can only be run from a directory tree under a UR namespace module.\n";
    }

    my @subject_list = $self->classes_or_modules;

    if ($self->can("for_each_class_object") ne __PACKAGE__->can("for_each_class_object")) {

        my @classes = $self->_class_objects_in_tree(@subject_list);

        unless ($self->before(\@classes)) {
            print STDERR "Terminating.\n";
            return;
        }
        for my $class (@classes) {
            unless ($self->for_each_class_object($class)) {
                print STDERR "Terminating...\n";
                return;
            }
        }
    }
    elsif ($self->can("for_each_class_name") ne __PACKAGE__->can("for_each_class_name")) {
        my @class_names = $self->_class_names_in_tree(@subject_list);
        unless ($self->before(\@class_names)) {
            print STDERR "Terminating.\n";
            return;
        }
        for my $class (@class_names) {
            unless ($self->for_each_class_name($class)) {
                print STDERR "Terminating...\n";
                return;
            }
        }
    }
    elsif ($self->can("for_each_module_file") ne __PACKAGE__->can("for_each_module_file")) {
        my @modules = $self->_modules_in_tree(@subject_list);
        unless ($self->before(\@modules)) {
            print STDERR "Terminating.\n";
            return;
        }
        for my $module (@modules) {
            unless ($self->for_each_module_file($module)) {
                print STDERR "Terminating...\n";
                return;
            }
        }
    }
    elsif ($self->can("for_each_module_file_in_parallel") ne __PACKAGE__->can("for_each_module_file_in_parallel")) {
        my @modules = $self->_modules_in_tree(@subject_list);
        unless ($self->before(\@modules)) {
            print STDERR "Terminating.\n";
            return;
        }
        my $bucket_count = 10;
        my @buckets;
        my %child_processes;
        for my $bucket_number (0..$bucket_count-1) {
            $buckets[$bucket_number] ||= [];
        }
        while (@modules) {
            for my $bucket_number (0..$bucket_count-1) {
                my $module = shift @modules;
                last if not $module;
                push @{ $buckets[$bucket_number] }, $module;
            }
        }

        for my $bucket (@buckets) {
            my $child_pid = fork();
            if ($child_pid) {
                # the parent process continues forking...
                $child_processes{$child_pid} = 1;
            }
            else {
                # the child process does handles its bucket
                for my $module (@$bucket) {
                    unless ($self->for_each_module_file_in_parallel($module)) {
                        exit 1;
                    }
                }
                # and then exits quietly
                exit 0;
            }
        }
        #$DB::single = 1;
        while (keys %child_processes) {
            my $child_pid = wait();
            if ($child_pid == -1) {
                print "lost children? " . join(" ", keys %child_processes);
            }
            delete $child_processes{$child_pid};
        }
    }
    else {
        die "$self does not implement: for_each_[class_object|class_name|module_file]!";
    }

    unless ($self->after()) {
        print STDERR "Terminating.\n";
        return;
    }

    return 1;
}

sub before {
    return 1;
}

sub for_each_module_file {
    die "The for_each_module_file method is not defined by/in " . shift;
}


sub for_each_class_name {
    die "The for_each_class_name method is not defined by/in " . shift;
}

sub for_each_class_object {
    Carp::confess "The for_each_class_object method is not defined by/in " . shift;
}

sub after {
    return 1;
}

sub loop_methods
{
    my $self = shift;
    my @methods;
    for my $method (qw/
        for_each_class_object
        for_each_class_name
        for_each_module_file
        for_each_module_file_in_parallel
    /) {
        no warnings;
        if ($self->can($method) ne __PACKAGE__->can($method)) {
            push @methods, $method;
        }
    }
    return @methods;
}

sub shell_args_description
{
    my $self = shift;

    my @loop_methods = $self->loop_methods;
    my $takes_classes = 1 if grep { /class/ } @loop_methods;
    my $takes_modules = 1 if grep { /modul/ } @loop_methods;

    my $text;
    if ($takes_classes and $takes_modules) {
        $text = "[CLASS|MODULE] [CLASS|MODULE] ...";
    }
    elsif ($takes_classes) {
        $text = "[CLASS] [CLASS]..";
    }
    elsif ($takes_modules) {
        $text = "[MODULE] [MODULE] ...";
    }
    else {
        $text = "<module broken!>";
    }

    $text .= " " . $self->SUPER::shell_args_description(@_);

    if ($self->is_sub_command_delegator) {
        my @names = $self->sub_command_names;
        return "[" . join("|",@names) . "] $text"
    }
    return $text;
}


1;
