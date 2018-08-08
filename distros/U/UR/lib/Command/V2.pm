package Command::V2;

use strict;
use warnings;

use UR;
use Data::Dumper;
use File::Basename;
use Getopt::Long;

use Command::View::DocMethods;
use Command::Dispatch::Shell;

our $VERSION = "0.47"; # UR $VERSION;

our $entry_point_class;
our $entry_point_bin;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => ['Command', 'Command::Common'],
    is_abstract => 1,
    subclass_description_preprocessor => 'Command::V2::_preprocess_subclass_description',
    attributes_have => [
        is_param            => { is => 'Boolean', is_optional => 1 },        
        is_input            => { is => 'Boolean', is_optional => 1 },
        is_output           => { is => 'Boolean', is_optional => 1 },
        shell_args_position => { is => 'Integer', is_optional => 1, 
                                doc => 'when set, this property is a positional argument when run from a shell' },
        completion_handler  => { is => 'MethodName', is_optional => 1,
                                doc => 'to supply auto-completions for this parameter, call this class method' },
        require_user_verify => { is => 'Boolean', is_optional => 1,
                                doc => 'when expanding user supplied values: 0 = never verify, 1 = always verify, undef = determine automatically', },        
    ],
    has_optional => [
        debug       => { is => 'Boolean', doc => 'enable debug messages' },
        is_executed => { is => 'Boolean' },
        result      => { is => 'Scalar', is_output => 1 },
        original_command_line => { is => 'String', doc => 'null-byte separated list of command and arguments when run via execute_with_shell_params_and_exit'},
        _total_command_count => { is => 'Integer', default => 0, is_transient => 1 },
        _command_errors => { 
            is => 'HASH',
            doc => 'Values can be an array ref is multiple errors occur during a command\'s execution',
            default => {},
            is_transient => 1,
        },
    ],
);

sub _is_hidden_in_docs { return; }

sub _preprocess_subclass_description {
    my ($class, $desc) = @_;
    while (my ($prop_name, $prop_desc) = each(%{ $desc->{has} })) {
        unless (
            $prop_desc->{'is_param'} 
            or $prop_desc->{'is_input'} 
            or $prop_desc->{'is_transient'}
            or $prop_desc->{'is_calculated'},
            or $prop_desc->{'is_output'} 
        ) {
            $prop_desc->{'is_param'} = 1;
        }
    }
    return $desc;
}

sub _init_subclass {
    # Each Command subclass has an automatic wrapper around execute().
    # This ensures it can be called as a class or instance method, 
    # and that proper handling occurs around it.
    my $subclass_name = $_[0];
    no strict;
    no warnings;
    if ($subclass_name->can('execute')) {
        # NOTE: manipulating %{ $subclass_name . '::' } directly causes ptkdb to segfault perl
        my $new_symbol = "${subclass_name}::_execute_body";
        my $old_symbol = "${subclass_name}::execute";
        *$new_symbol = *$old_symbol;
        undef *$old_symbol;
    }
    else {
        #print "no execute in $subclass_name\n";
    }

    if($subclass_name->can('shortcut')) {
        my $new_symbol = "${subclass_name}::_shortcut_body";
        my $old_symbol = "${subclass_name}::shortcut";
        *$new_symbol = *$old_symbol;
        undef *$old_symbol;
    }

    my @p = $subclass_name->__meta__->properties();
    my @e;
    for my $p (@p) {
        next if $p->property_name eq 'id';
        next if $p->class_name eq __PACKAGE__;
        next unless $p->class_name->isa('Command');
        unless ($p->is_input or $p->is_output or $p->is_param or $p->is_transient or $p->is_calculated) {
            my $modname = $subclass_name;
            $modname =~ s|::|/|g;
            $modname .= '.pm';
            push @e, $modname . " property " . $p->property_name . " must be input, output, param, transient, or calculated!";  
        }
    }
    if (@e) {
        for (@e) {
            $subclass_name->error_message($_); 
        }
        die "command classes like $subclass_name  have properties without is_input/output/param/transient/calculated set!";
    }

    return 1;
}

sub __errors__ {
    my ($self,@property_names) = @_;
    my @errors1 =($self->SUPER::__errors__);

    if ($self->is_executed) {
        return @errors1;
    }

    # for Commands which have not yet been executed, 
    # only consider errors on inputs or params

    my $meta = $self->__meta__;
    my @errors2;
    ERROR:
    for my $e (@errors1) {
        for my $p ($e->properties) {
            my $pm = $meta->property($p);
            if ($pm->is_input or $pm->is_param) {
                push @errors2, $e;
                next ERROR;
            }
        }
    }

    return @errors2;
}

# For compatability with Command::V1 callers
sub is_sub_command_delegator {
    return;
}

sub _wrapper_has {
    my ($class, $new_class_base) = @_;

    $new_class_base ||= __PACKAGE__;

    my $command_meta = $class->__meta__;
    my @properties = $command_meta->properties();
    
    my %has;
    for my $property (@properties) {
        my %desc;
        next unless $property->can("is_param") and $property->can("is_input") and $property->can("is_output");

        my $name = $property->property_name;

        next if $new_class_base->can($name);

        if ($property->is_param) {
            $desc{is_param} = 1;
        }
        elsif ($property->is_input) {
            $desc{is_input} = 1;
        }
        #elsif ($property->can("is_metric") and $property->is_metric) {
        #    $desc{is_metric} = 1;
        #}
        #elsif ($property->can("is_output") and $property->is_output) {
        #    $desc{is_output} = 1;
        #}
        else {
            next;
        }

        $has{$name} = \%desc;
        $desc{is} = $property->data_type;
        $desc{doc} = $property->doc;
        $desc{is_many} = $property->is_many;
        $desc{is_optional} = $property->is_optional;
    }

    return %has;
}

sub display_command_summary_report {
    my $self = shift;
    my $total_count = $self->_total_command_count;
    my %command_errors = %{$self->_command_errors};

    if (keys %command_errors) {
        $self->status_message("\n\nErrors Summary:");
        for my $key (keys %command_errors) {
            my $errors = $command_errors{$key};
            $errors = [$errors] unless (ref($errors) and ref($errors) eq 'ARRAY');
            my @errors = @{$errors};
            print "$key: \n";
            for my $error (@errors) {
                $error = $self->truncate_error_message($error);
                print "\t- $error\n";
            }
        }
    }

    if ($total_count > 1) {
        my $error_count = scalar(keys %command_errors);
        $self->status_message("\n\nCommand Summary:");
        $self->status_message(" Successful: " . ($total_count - $error_count));
        $self->status_message("     Errors: " . $error_count);
        $self->status_message("      Total: " . $total_count);
    }
}

sub append_error {
    my $self = shift;
    my $key = shift || die;
    my $error = shift || die;

    my $command_errors = $self->_command_errors;
    push @{$command_errors->{$key}}, $error;
    $self->_command_errors($command_errors);

    return 1;
}

sub truncate_error_message {
    my $self = shift;
    my $error = shift || die;

    # truncate errors so they are actually a summary
    ($error) = split("\n", $error);

    # meant to truncate a callstack as this is meant for user/high-level
    $error =~ s/\ at\ \/.*//;

    return $error;
}


1;

__END__

=pod

=head1 NAME

Command - base class for modules implementing the command pattern

=head1 SYNOPSIS

  use TopLevelNamespace;

  class TopLevelNamespace::SomeObj::Command {
    is => 'Command',
    has => [
        someobj => { is => 'TopLevelNamespace::SomeObj', id_by => 'some_obj_id' },
        verbose => { is => 'Boolean', is_optional => 1 },
    ],
  };

  sub execute {
      my $self = shift;
      if ($self->verbose) {
          print "Working on id ",$self->some_obj_id,"\n";
      }
      my $result = $someobj->do_something();
      if ($self->verbose) {
          print "Result was $result\n";
      }
      return $result;
  }

  sub help_brief {
      return 'Call do_something on a SomeObj instance';
  }
  sub help_synopsis {
      return 'cmd --some_obj_id 123 --verbose';
  }
  sub help_detail {
      return 'This command performs a FooBarBaz transform on a SomObj object instance by calling its do_something method.';
  }

  # Another part of the code
 
  my $cmd = TopLevelNamespace::SomeObj::Command->create(some_obj_id => $some_obj->id);
  $cmd->execute();

=head1 DESCRIPTION

The Command module is a base class for creating other command modules
implementing the Command Pattern.  These modules can be easily reused in
applications or loaded and executed dynamicaly in a command-line program.

Each Command subclass represents a reusable work unit.  The bulk of the
module's code will likely be in the execute() method.  execute() will
usually take only a single argument, an instance of the Command subclass.

=head1 Command-line use

Creating a top-level Command module called, say TopLevelNamespace::Command,
and a script called tln_cmd that looks like:

  #!/usr/bin/perl
  use TopLevelNamespace;
  TopLevelNamespace::Command->execute_with_shell_params_and_exit();

gives you an instant command-line tool as an interface to the hierarchy of
command modules at TopLevelNamespace::Command.  

For example:

  > tln_cmd foo bar --baz 1 --qux

will create an instance of TopLevelNamespace::Command::Foo::Bar (if that
class exists) with params baz => 1 and qux => 1, assumming qux is a boolean
property, call execute() on it, and translate the return value from execute()
into the appropriate notion of a shell return value, meaning that if
execute() returns true in the Perl sense, then the script returns 0 - true in
the shell sense.

The infrastructure takes care of turning the command line parameters into
parameters for create().  Params designated as is_optional are, of course,
optional and non-optional parameters that are missing will generate an error.

--help is an implicit param applicable to all Command modules.  It generates 
some hopefully useful text based on the documentation in the class definition
(the 'doc' attributes you can attach to a class and properties), and the
strings returned by help_detail(), help_brief() and help_synopsis().

=head1 TODO

This documentation needs to be fleshed out more.  There's a lot of special 
things you can do with Command modules that isn't mentioned here yet.

=cut



