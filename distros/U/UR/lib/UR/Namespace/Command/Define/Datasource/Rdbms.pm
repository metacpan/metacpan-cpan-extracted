package UR::Namespace::Command::Define::Datasource::Rdbms;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

use IO::File;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Define::Datasource',
    has => [
                server => {
                    is => 'String',
                    doc => '"server" attribute for this data source, such as a database name',
                    is_optional => 1,
                },
                nosingleton => {
                    is => 'Boolean',
                    doc => 'Created data source should not inherit from UR::Singleton (defalt is that it will)',
                    default_value => 0,
                },
           ],
           is_abstract => 1,
);

sub help_description {
   "Define a UR datasource connected to a relational database through UR::DataSource::RDBMS and DBI";
}


sub execute {
    my $self = shift;

    my $namespace = $self->namespace_name;
    unless ($namespace) {
        $self->error_message("This command must be run from a namespace directory.");
        return;
    }

    unless ($self->__dsname || $self->__dsid) {
        $self->error_message("Either --dsname or --dsid is required");
        return;
    }

    # Force an autoload of the namespace module
    #my $ret = above::use_package($namespace);
    eval "use $namespace";
    if ($@) {
        $self->error_message("Can't load namespace $namespace: $@");
        return;
    }

    unless (defined $self->server) {
        $self->server($self->dsname);
    }
      
    my $ds_id = $self->dsid;

    my $c = eval { UR::DataSource->get($ds_id) || $ds_id->get() };
    if ($c) {
        $self->error_message("A data source named $ds_id already exists\n");
        return;
    }

    my $src = $self->_resolve_module_header($ds_id,$namespace);

    my($class_definition,$parent_classes) = $self->_resolve_class_definition_source();
    $src .= $class_definition;

    my $module_body = $self->_resolve_module_body();
    $src .= "\n$module_body\n1;\n";

    my $module_path = $self->data_source_module_pathname();
    my $fh = IO::File->new($module_path, O_WRONLY | O_CREAT | O_EXCL);
    unless ($fh) {
        $self->error_message("Can't open $module_path for writing: $!");
        return;
    }

    $fh->print($src);
    $fh->close();

    $self->status_message("A   $ds_id (" . join(',', @$parent_classes) . ")\n");

    $self->_post_module_written();

    if ($self->_try_connect()) {
        return 1;
    } else {
        return;
    }
}
 


sub _resolve_module_header {
    my($self,$ds_id, $namespace) = @_;

    return "package $ds_id;\n\nuse strict;\nuse warnings;\n\nuse $namespace;\n\n";
}

# Subclasses can override this to have something happen after the module
# is written, but before we try connecting to the DS
sub _post_module_written {
    return 1;
}


# Subclasses must override this to indicate what abstract DS class they should
# inherit from
sub _data_source_sub_class_name {
    my $self = shift;
    my $class = ref($self);
    die "Class $class didn't implement _data_source_sub_class_name";
}


sub _resolve_class_definition_source {
    my $self = shift;
 
    my $ds_id = $self->dsid;

    my $parent_ds_class = $self->_data_source_sub_class_name();
    my $src = "class $ds_id {\n";

    my @parent_classes = ( $parent_ds_class );
    if (! $self->nosingleton) {
        push @parent_classes, 'UR::Singleton';
    }

    $src .= sprintf("    is => [ '%s' ],\n", join("', '", @parent_classes));

    $src .= "};\n";

    return($src,\@parent_classes);
}


    
sub _resolve_module_body {
    my $self = shift;

    my $server = $self->server;
    my $src = "sub server { '$server' }\n";

    return $src;
}



sub _try_connect {
    my $self = shift;

    $self->status_message("    ...connecting...");

    my $ds_id = $self->dsid;
    my $dbh = $ds_id->get_default_handle();
    if ($dbh) {
        $self->status_message("    ....ok\n");
        return 1;
    } else {
        $self->error_message("    ERROR: " . $ds_id->error_message);
        return;
    }
}



1;

