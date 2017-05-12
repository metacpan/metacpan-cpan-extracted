package Command::Common;

use strict;
use warnings;

use UR;

# Once roles exist this should probably be a role.
class Command::Common {
    is_abstract => 1,
    valid_signals => [qw(error_die)],
};

sub create {
    my $class = shift;
    my ($rule,%extra) = $class->define_boolexpr(@_);
    my @params_list = $rule->params_list;
    my $self = $class->SUPER::create(@params_list, %extra);
    return unless $self;

    # set non-optional boolean flags to false.
    # TODO: rename that property meta method if it is not ONLY used for shell args
    for my $property_meta ($self->_shell_args_property_meta) {
        my $property_name = $property_meta->property_name;
        if (!$property_meta->is_optional and !defined($self->$property_name)) {
            if (defined $property_meta->data_type and $property_meta->data_type =~ /Boolean/i) {
                $self->$property_name(0);
            }
        }
    }

    return $self;
}

sub shortcut {
    my $self = shift;
    return unless $self->can('_shortcut_body');

    my $result = $self->_shortcut_body;
    $self->result($result);

    return $result;
}

sub execute {
    # This is a wrapper for real execute() calls.
    # All execute() methods are turned into _execute_body at class init,
    # so this will get direct control when execute() is called.
    my $self = shift;

    #TODO handle calls to SUPER::execute() from another execute().

    # handle calls as a class method
    my $was_called_as_class_method = 0;
    if (ref($self)) {
        if ($self->is_executed) {
            Carp::confess("Attempt to re-execute an already executed command.");
        }
    }
    else {
        # called as class method
        # auto-create an instance and execute it
        $self = $self->create(@_);
        return unless $self;
        $was_called_as_class_method = 1;
    }

    # handle __errors__ objects before execute
    if (my @problems = $self->__errors__) {
        for my $problem (@problems) {
            my @properties = $problem->properties;
            $self->error_message("Property " .
                                 join(',', map { "'$_'" } @properties) .
                                 ': ' . $problem->desc);
        }
        my $command_name = $self->command_name;
        $self->error_message("Please see '$command_name --help' for more information.");
        $self->delete() if $was_called_as_class_method;
        return;
    }

    my $result = eval { $self->_execute_body(@_); };
    my $error = $@;
    if ($error or not $result) {
        my %error_data;

        $error_data{die_message} = defined($error) ? $error:'';
        $error_data{error_message} = defined($self->error_message) ? $self->error_message:'';
        $error_data{error_package} = defined($self->error_package) ? $self->error_package:'';
        $error_data{error_file} = defined($self->error_file) ? $self->error_file:'';
        $error_data{error_subroutine} = defined($self->error_subroutine) ? $self->error_subroutine:'';
        $error_data{error_line} = defined($self->error_line) ? $self->error_line:'';
        $self->__signal_observers__('error_die', %error_data);
        die $error if $error;
    }

    $self->is_executed(1);
    $self->result($result);

    return $self if $was_called_as_class_method;
    return $result;
}

sub _execute_body {
    # default implementation in the base class

    # Override "execute" or "_execute_body" to implement the body of the command.
    # See above for details of internal implementation.

    my $self = shift;
    my $class = ref($self) || $self;
    if ($class eq __PACKAGE__) {
        die "The execute() method is not defined for $_[0]!";
    }
    return 1;
}

# Translates a true/false value from the command module's execute()
# from Perl (where positive means success), to shell (where 0 means success)
# Also, execute() could return a negative value; this is converted to
# positive and used as the shell exit code.  NOTE: This means execute()
# returning 0 and -1 mean the same thing
sub exit_code_for_return_value {
    my $self = shift;
    my $return_value = shift;
    if (! $return_value) {
        $return_value = 1;
    } elsif ($return_value < 0) {
        $return_value = 0 - $return_value;
    } else {
        $return_value = 0
    }
    return $return_value;
}
