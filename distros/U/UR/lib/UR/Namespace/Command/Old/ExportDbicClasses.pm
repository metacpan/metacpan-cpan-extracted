package UR::Namespace::Command::Old::ExportDbicClasses;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::RunsOnModulesInTree',
    has => [
        bare_args => {
            is_optional => 1,
            is_many => 1,
            shell_args_position => 1
        }
    ]
);

sub help_brief {
    "Create or update a DBIx::Class class from an already existing UR class";
}

sub help_detail {
    return <<EOS;

Given one or more UR class names on the command line, this will create
or update a DBIx::Class class.  The files will appear under the DBIx directory
in the namespace.

EOS
}



sub x_execute {
    my $self = shift;
    my $params = shift;
    
#$DB::single = 1;
    unless ($self->bare_args) {
        $self->error_message("No class names were specified on the command line");
        $self->status_message($self->help_usage_complete_text,"\n");
        return;
    }

    my $namespace = $self->namespace_name;
    unless ($namespace) {
        $self->error_message("This command must be run from a namespace directory.");
        return;
    }

    eval "use $namespace";
    if ($@) {
        $self->error_message("Failed to load namespace $namespace");
        return;
    }

    foreach my $class_name ( $self->bare_args ) {
        my $class = UR::Object::Type->get(class_name => $class_name);

        unless ($class) {
            $self->error_message("Couldn't load class metadata for $class_name");
            next;
        }

        $class->dbic_rewrite_module_header();
    }
    return 1;
}


sub for_each_class_object {
    my($self,$class) = @_;

    return 1 unless ($class->table_name);  # Skip classes without tables

    $class->dbic_rewrite_module_header();
    return 1;
}


1;

