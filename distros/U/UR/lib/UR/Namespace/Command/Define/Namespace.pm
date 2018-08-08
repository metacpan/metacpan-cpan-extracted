package UR::Namespace::Command::Define::Namespace;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;
use IO::File;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "Command",
    has => [
        nsname => {
            shell_args_position => 1,
            doc => 'The name of the namespace, and first "word" in all class names',
        },
    ],
    doc => 'create a new namespace tree and top-level module',
);

sub help_brief { "Used to define a new Namespace as part of starting a new project." }

sub sub_command_sort_position { 1 }

our $module_template=<<EOS;
package %s;
use warnings;
use strict;
use UR;

%s

1;
EOS

# FIXME This should be refactored at some point to act more like "update classes" in that it
# Creates a bunch of objects and them uses the change log to determine what is new and what 
# files to create/write
sub execute {
    my $self = shift;
    
    my $name = $self->nsname;
    
    if (-e $name . ".pm") {
        $self->error_message("Module ${name}.pm already exists!");
        return;
    }
    eval "package $name;";
    if ($@) {
        $self->error_message("Invalid package name $name: $@");
        return;
    }


    # Step 1 - Make a new Namespace
    my $namespace = UR::Object::Type->define(class_name => $name,
                                                is => ['UR::Namespace'],
                                                is_abstract => 0);
    my $namespace_src = $namespace->resolve_module_header_source;

    # Step 2 - Make an empty Vocabulary
    my $vocab_name = $name->get_vocabulary();
    my $vocab = UR::Object::Type->define(
        class_name => $vocab_name,
        is => 'UR::Vocabulary',
        is_abstract => 0,
    );
    my $vocab_src = $vocab->resolve_module_header_source();
    my $vocab_filename = $vocab->module_base_name();

    # write the namespace module
    $self->status_message("A   $name (UR::Namespace)\n");
    IO::File->new("$name.pm", 'w')->printf($module_template, $name, $namespace_src);

    # Write the vocbaulary module
    mkdir($name);
    IO::File->new($vocab_filename,'w')->printf($module_template, $vocab_name, $vocab_src);
    $self->status_message("A   $vocab_name (UR::Vocabulary)\n");

    # Step 3 - Make and write a new Meta DataSource module 
    # and also, the SQL source for a new, empty metadata DB
    my ($meta_datasource, $meta_db_file) = 
        UR::DataSource::Meta->generate_for_namespace($name);
    my $meta_datasource_name = $meta_datasource->id;
    $self->status_message("A   $meta_datasource_name (UR::DataSource::Meta)\n");
    $self->status_message("A   $meta_db_file (Metadata DB skeleton)");
    
    return 1; 
}

1;

