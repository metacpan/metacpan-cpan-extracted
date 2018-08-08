package UR::Context::Root;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Context::Root',
    is => ['UR::Singleton', 'UR::Context'],
    is_abstract => 1,
    is_transactional => 1,
    doc => 'A base level context, representing the committed state of datasources external to the application.',
);

# this is called automatically by UR.pm at the end of the module
my $initialized = 0;
sub _initialize_for_current_process {
    my $class = shift;
    if ($initialized) {
        die "Attempt to re-initialize the current process?";
    }
    my $context_singleton_class = $ENV{UR_CONTEXT_ROOT} ||= 'UR::Context::DefaultRoot';
    $class->set_current($context_singleton_class);
}

sub name {
    my $class = shift->_singleton_class_name;
    my ($name) = ($class =~ /^\w+?\:\:\w+?\:\:(\w+)$/);
    die "failed to parse name from $class!" unless $name;
    return lc($name);
}

sub get_current {
    #shift->_initialize_for_current_process() unless $initialized;
    #eval "sub get_current { \$ENV{UR_CONTEXT_ROOT} }";
    return $ENV{UR_CONTEXT_ROOT};
}

sub set_current {
    my $class = shift;
    my $value = shift;
    
    return $value if $value eq $ENV{UR_CONTEXT_ROOT};
    
    $ENV{UR_CONTEXT_ROOT} = $value;
    
    #print "base context set to $value\n";    
    #print Carp::longmess();
    
    eval {
        local $SIG{__DIE__};
        local $SIG{__WARN__};
        $ENV{UR_CONTEXT_ROOT}->class;
    };
    
    if ($@) {
        die "The context at application initialization is set to "
            . $ENV{UR_CONTEXT_ROOT} . ".\n"
            . "This failed to compile:\n$@"
    }
    
    unless ($ENV{UR_CONTEXT_ROOT}->isa("UR::Context")) {
        die "The context at application initialization is set to "
            . $ENV{UR_CONTEXT_ROOT} . ".\n"
            . "This does not inherit from UR::Context."
    }
    
    unless ($ENV{UR_CONTEXT_ROOT}->__meta__) {
        die "The context at application initialization is set to "
            . $ENV{UR_CONTEXT_ROOT} . ".\n"
            . "This is not defined with UR::Object::Type metadata!"
    }

    # Initialize the bottom of the transaction stack
    if (@UR::Context::Transaction::open_transaction_stack > 1) {
        die "Cannot change the base context once transactions are in progress!"            
    }        

    return $value;
}

sub access_level {
    my $self = shift->_singleton_object;
    return "???";
}

# sub has_changes { return }

1;

