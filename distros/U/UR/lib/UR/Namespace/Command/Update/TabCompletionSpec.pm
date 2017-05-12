package UR::Namespace::Command::Update::TabCompletionSpec;

use strict;
use warnings;

use UR;
our $VERSION = "0.46"; # UR $VERSION;
use IO::File;
use POSIX qw(ENOENT);

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has => [
        classname => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'The base class to use as trunk of command tree, e.g. UR::Namespace::Command',
        },
        output => {
            is => 'Text',
            is_optional => 1,
            doc => 'Override output location of the opts spec file.',
        },
    ]
);


sub help_brief {
    "Creates a .opts file beside class/module passed as argument, e.g. UR::Namespace::Command.";
}

sub create {
    my $class = shift;

    my $bx = $class->define_boolexpr(@_);
    if($bx->specifies_value_for('classname') and !$bx->specifies_value_for('namespace_name')) {
        my $classname = $bx->value_for('classname');
        my($namespace) = ($classname =~ m/^(\w+)::/);
        $bx = $bx->add_filter(namespace_name => $namespace) if $namespace;
    }
    return $class->SUPER::create($bx);
}



sub is_sub_command_delegator { 0; }

sub execute {
    my $self = shift;
    my $class = $self->classname;

    my $req_exception = do {
        local $@;
        eval {
            require Getopt::Complete;
            require Getopt::Complete::Cache;
        };
        $@;
    };
    if ($req_exception) {
        die "Errors using Getopt::Complete.  Do you have Getopt::Complete installed?  If not try 'cpanm Getopt::Complete'";
    }

    my $use_exception = do {
        local $@;
        eval "use above '$class';";
        $@;
    };
    if ($use_exception) {
        $self->error_message("Unable to use above $class.\n$@");
        return;
    }

    (my $module_path) = Getopt::Complete::Cache->module_and_cache_paths_for_package($class, 1);
    my $cache_path = $module_path . ".opts";

    eval {
        my $rename_ok = rename($cache_path, "$cache_path.bak");
        if (!$rename_ok && $! != ENOENT) {
            die "failed to rename file: $!: $cache_path";
        }

        unless ($self->output) {
            $self->output($cache_path);
        }
        $self->status_message("Generating " . $self->output . " file for $class.");
        $self->status_message("This may take some time and may generate harmless warnings...");

        my $fh = IO::File->new($self->output, 'w')
            or die "Cannot create file at " . $self->output . "\n";

        my $src = Data::Dumper::Dumper($class->resolve_option_completion_spec());
        $src =~ s/^\$VAR1/\$$class\:\:OPTS_SPEC/;
        $fh->print($src);
    };

    if (-s $cache_path) {
        $self->status_message("\nOPTS_SPEC file created at $cache_path");
        unlink("$cache_path.bak")
            or $self->error_message("failed to remove backup file: $!");
    } else {
        if (-s "$cache_path.bak") {
            $self->error_message("$cache_path is 0 bytes, reverting to previous");
            rename("$cache_path.bak", $cache_path)
                or $self->error_message("failed to restore file: $!");
        } else {
            $self->error_message("$cache_path is 0 bytes and no backup exists, removing file");
            unlink($cache_path)
                or $self->error_message("failed to remove file: $!");
        }
    }
}

1;
