package UR::Namespace::Command::Define::Db;

use warnings;
use strict;
use UR;
our $VERSION = "0.47"; # UR $VERSION;
use IO::File; # required to import symbols used below

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    has_input => [
        uri => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'a DBI connect string like dbi:mysql:someserver or user/passwd@dbi:Oracle:someserver~defaultns'
        },
        name => {
            is => 'Text',
            shell_args_position => 2,
            default_value => 'Db1',
            doc => "the name for this data source (used for class naming)",
        },
    ],
    has_output_optional => [
        _class_name=> {
            is => 'Text',
            calculate_from => ['name'],
            calculate => q|
                my $namespace = $self->namespace_name;
                my $dsid = $namespace . '::DataSource::' . $name;
                return $dsid
            |,
            doc => "The full class name to give this data source.",
        },
        _ds => {
            is_transient => 1,
        },
    ],
    doc => 'add a data source to the current namespace'
);

sub sub_command_sort_position { 2 }

sub help_synopsis {
    return <<'EOS'
ur define db dbi:SQLite:/some/file.db Db1

ur define db me@dbi:mysql:myserver MainDb

ur define db me@dbi:Oracle:someserver ProdDb
ur define db me@dbi:Oracle:someserver~schemaname BigDb 

ur define db me@dbi:Pg:prod  Db1
ur define db me@dbi:Pg:dev   Testing::Db1 # alternate for "Testing" (arbitrary) context
ur define db me@dbi:Pg:stage Staging::Db1 # alternate for "Staging" (arbitrary) context

EOS
}

sub data_source_module_pathname {
    my $self = shift;
    my $class_name = shift; 

    my $ns_path = $self->namespace_path;

    my @ds_parts = split(/::/, $class_name);
    shift @ds_parts;  # Get rid of the namespace name

    my $filename = pop @ds_parts;
    $filename .= '.pm';

    my $path = join('/', $ns_path, @ds_parts, $filename);
    return $path;
}

sub execute {
    my $self = shift;

    my $namespace = $self->namespace_name;
    unless ($namespace) {
        $self->error_message("This command must be run from a namespace directory.");
        return;
    }

    my $uri = $self->uri;
    my ($protocol,$driver,$login,$server,$owner) = ($uri =~ /^([^\:\W]+):(.*?):(.*@|)(.*?)(~.*|)$/);
    unless ($protocol) {
        $self->error_message("error parsing URI $uri\n" . 'expected dbi:$driver:$user@$server with optional trailing ~$namespace');
        return;
    }
    unless ($protocol eq 'dbi') {
        $self->error_message("currently only the 'dbi' protocol is supported with this command.  Other data sources must be hand-written.");
        return;
    }
    $login =~ s/\@$// if defined $login;
    $owner =~ s/^~// if defined $owner;
    $self->status_message("protocol: $protocol");
    $self->status_message("driver: $driver");
    $self->status_message("server: $server");
    my $password;
    if (defined $login) {
        if ($login =~ /\//) {
            ($login,$password) = split('/',$login);
        }
        $self->status_message("login: $login") if defined $login;
        $self->status_message("password: $password") if defined $password;
    }
    $self->status_message("owner: $owner") if defined $owner;

    # Force an autoload of the namespace module
    eval "use $namespace";
    if ($@) {
        $self->error_message("Can't load namespace $namespace: $@");
        return;
    }

    my $class_name = $self->namespace_name . '::DataSource::' . $self->name;
    $self->_class_name($class_name);
    my $c = eval { UR::DataSource->get($class_name) || $class_name->get() };
    if ($c) {
        $self->error_message("A data source named $class_name already exists\n");
        return;
    }

    my $src = "package $class_name;\nuse strict;\nuse warnings;\nuse $namespace;\n\n";
    $src .= "class $class_name {\n";

    my $parent_ds_class = 'UR::DataSource::' . $driver; #$self->_data_source_sub_class_name();
    $driver =~ s/mysql/MySQL/g;
    my @parent_classes = ( $parent_ds_class );
    push @parent_classes, 'UR::Singleton';
    $src .= sprintf("    is => [ '%s' ],\n", join("', '", @parent_classes));
    $src .= "};\n";

    my $module_body = $self->_resolve_module_body($class_name,$namespace,$driver,$server,$login);
    $src .= "\n$module_body\n1;\n";

    my $module_path = $self->data_source_module_pathname($class_name);
    my $fh = IO::File->new($module_path, O_WRONLY | O_CREAT | O_EXCL);
    unless ($fh) {
        $self->error_message("Can't open $module_path for writing: $!");
        return;
    }
    $fh->print($src);
    $fh->close();

    $self->status_message("A   $class_name (" . join(',', @parent_classes) . ")\n");

    #TODO: call a method on the datasource to init the new file
    my $method = '_post_module_written_' . lc($driver);
    $self->$method($module_path,$server);

    unless (UR::Object::Type->use_module_with_namespace_constraints($class_name)) {
    #if ($@) {
        $self->error_message("Error in module $class_name!?: $@");
        return;
    }
    my $ds = $class_name->get();
    unless ($ds) {
        $self->error_message("Failed to get data source for $class_name!");
        return;
    }       
    $self->_ds($ds);

    if ($self->_try_connect()) {
        return 1;
    } else {
        return;
    }
}
 
sub _resolve_module_body {
    my ($self,$class_name,$namespace,$driver,$server,$login,$owner) = @_;

    $owner ||= $login;

    my $src = <<EOS;
sub driver { '$driver' };

sub server { '$server' };

EOS

    # TODO: key this off of a property on the datasource
    # so datasource writers don't have to make a custom command here
    if ($driver ne 'SQLite') {
        $src .= "sub login { '$login' }\n";

        $src .= "sub auth { warn 'Set db password at ' . __LINE__ . ' in ' . __FILE__; return ''  }\n";

        $src .= "sub owner { '$owner' }\n";
    }

    return $src;
}

sub _post_module_written_sqlite {
    my ($self, $pathname, $server) = @_;

    # Create a new, empty DB if it dosen't exist yet
    IO::File->new($server, O_WRONLY | O_CREAT) unless (-f $server);
    $self->status_message("A   $server (empty database schema)");

    $pathname =~ s/\.pm$/.sqlite3/;
    unless ($pathname eq $server) {
        symlink ($server, $pathname) or die "no symline $pathname for $server! $!";
    }

    return 1;
}

sub _post_module_written_pg {
    my ($self, $pathname, $server) = @_;
    return 1;
}


sub _post_module_written_oracle {
    my ($self, $pathname, $server) = @_;
    return 1;
}

sub _post_module_written_mysql {
    my ($self, $pathname, $server) = @_;
    return 1;
}

sub _post_module_written_file {
    my ($self, $pathname, $server) = @_;
    return 1;
}

sub _post_module_written_filemux {
    my ($self, $pathname, $server) = @_;
    return 1;
}



sub _try_connect {
    my $self = shift;
    $self->status_message("    ...connecting...");

    my $ds = $self->_ds;
    my $dbh = $ds->get_default_handle();
    if ($dbh) {
        $self->status_message("    ....ok\n");
        return 1;
    } else {
        $self->error_message("    ERROR: " . $ds->error_message);
        return;
    }
}


1;

