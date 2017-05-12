# Base class for Test::Mini test cases.
#
# @see Test::Mini::Runner
package Test::Mini::TestCase;
use strict;
use warnings;

use Test::Mini;
use Exception::Class;
use Test::Mini::Assertions;

# Constructor.
#
# @private
# @param [Hash] %args Initial state for the new instance.
# @option %args name The specific test this instance should run.
sub new {
    my ($class, %args) = @_;
    return bless { %args, passed => 0 }, $class;
}

# Test setup behavior, automatically invoked prior to each test.  Intended to
# be overridden by subclasses.
#
# @example
#   package TestSomething;
#   use base 'Test::Mini::TestCase';
#
#   use Something;
#
#   sub setup { $obj = Something->new(); }
#
#   sub test_can_foo {
#       assert_can($obj, 'foo');
#   }
#
# @see #teardown
sub setup {
    my ($self) = @_;
}

# Test teardown behavior, automatically invoked following each test.  Intended
# to be overridden by subclasses.
#
# @example
#   package Test;
#   use base 'Test::Mini::TestCase';
#
#   sub teardown { unlink 'foo.bar' }
#
#   sub test_touching_files {
#       `touch foo.bar`;
#       assert(-f 'foo.bar');
#   }
#
# @see #setup
sub teardown {
    my ($self) = @_;
}

# Runs the test specified at construction time.  This method is responsible
# for invoking the setup and teardown advice for the method, in addition to
# ensuring that any fatal errors encountered by the program are suitably
# handled.  Appropriate diagnostic information should be sent to the supplied
# +$runner+.
#
# @private
# @param [Test::Mini::Runner] $runner
# @return The number of assertions called by this test.
sub run {
    my ($self, $runner) = @_;
    my $e;
    my $test = $self->{name};

    eval {
        local $SIG{__DIE__} = sub {
            # Package declaration for isolating the callstack.
            # @api private
            package Test::Mini::SIGDIE;

            die $_[0] if UNIVERSAL::isa($_[0], 'Test::Mini::Exception');

            (my $msg = "@_") =~ s/ at .*? line \d+\.\n$//;
            my $error = Test::Mini::Exception->new(
                message        => "$msg\n",
                ignore_package => [qw/ Test::Mini::SIGDIE Carp /],
            );

            my $me = $error->trace->frame(0);
            if ($me->{subroutine} eq 'Test::Mini::TestCase::__ANON__') {
                $me->{subroutine} = 'die';
                $me->{args} = [ $msg ];
            }

            die $error;
        };

        $self->setup();
        $self->$test();
        $self->{passed} = 1;

        die 'No assertions called' unless count_assertions();
    };

    if ($e = Exception::Class->caught()) {
        $self->{passed} = 0;

        if ($e = Exception::Class->caught('Test::Mini::Exception::Skip')) {
            $runner->skip(ref $self, $test, $e);
        }
        elsif ($e = Exception::Class->caught('Test::Mini::Exception::Assert')) {
            $runner->fail(ref $self, $test, $e);
        }
        elsif ($e = Exception::Class->caught('Test::Mini::Exception')) {
            $runner->error(ref $self, $test, $e);
        }
    }

    eval {
        $self->teardown();
        $runner->pass(ref $self, $self->{name}) if $self->{passed};
    };
    if ($e = Exception::Class->caught()) {
        $runner->error(ref $self, $test, $e);
    }

    return reset_assertions();
}

1;
