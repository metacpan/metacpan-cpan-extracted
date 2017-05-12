package Command::Shell;
use strict;
use warnings;
use Command::V2;

class Command::Shell {
    is => 'Command::V2',
    is_abstract => 1,
    subclassify_by => "_shell_command_subclass", 
    has_input => [
        delegate_type   => { is => 'Text', shell_args_position => 1,
                            doc => 'the class name of the command to be executed' },

        argv            => { is => 'Text', is_many => 1, is_optional => 1, shell_args_position => 2, 
                            doc => 'list of command-line arguments to be translated into parameters' },
    ],
    has_transient => [
        delegate        => { is => 'Command',
                            doc => 'the command which this adaptor wraps' },
        _shell_command_subclass => {    calculate_from => ['delegate_type'], 
                                        calculate => 
                                            sub {
                                                my $delegate_type = shift; 
                                                my $subclass = $delegate_type . "::Shell";
                                                eval "$subclass->class";
                                                if ($@) {
                                                    my $new_subclass = UR::Object::Type->define(
                                                        class_name => $subclass,
                                                        is => __PACKAGE__
                                                    );
                                                    die "Failed to fabricate subclass $subclass!" unless $new_subclass;
                                                }
                                                return $subclass;
                                            }, 
                                    },
    ],
    has_output => [
        exit_code =>    => { is => 'Number',
                            doc => 'the exit code to be returned to the shell', }
    ],
    doc => 'an adaptor to create and run commands as specified from a standard command-line shell (bash)'
};

sub help_synopsis {
    return <<EOS

    In the "foo" executable:

    #!/usr/bin/env perl
    use Foo;
    exit Command::Shell->run("Foo",@ARGV);

    The run() static method will construct the appropriate Command::Shell object, have it build its delegate,
    run the delegate's execution method in an in-memory transaction sandbox, and capture an exit code.

    If the correct environment variables are set, it will respond to a bash tab-completion request, such that
    the "foo" script can be used as a self-completer.

EOS

}

sub run {
    my $class = shift;
    my $delegate_type = shift;
    my @argv = @_;
    my $cmd = $class->create(delegate_type => $delegate_type, argv => \@argv);
    #print STDERR "created $cmd\n";
    $cmd->execute;
    my $exit_code = $cmd->exit_code;
    $cmd->delete;
    return $exit_code;
}

sub execute {
    my $self = shift;
    my $delegate_type = $self->delegate_type;
    eval "use above '$delegate_type'";
    if ($@) {
        my $t = UR::Object::Type->get($delegate_type);
        unless ($t) {
            die "Failure to use delegate class $delegate_type!:\n$@";
        }
    }
    my @argv = $self->argv;

    my $exit_code = $delegate_type->_cmdline_run(@argv);
    $self->exit_code($exit_code);
    return 1;
}

# TODO: migrate all methods in Command::V2 which live in the Command::Dispatch::Shell module to this package
# Methods which address $self to get to shell-specific things still call $self
# Methods which address $self to get to the underlying command should instead call $self->delegate

1;

