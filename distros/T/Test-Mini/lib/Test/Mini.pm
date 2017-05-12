# Lightweight xUnit Testing for Perl.
#
# Test::Mini is a light, spry testing framework built to bring the familiarity
# of an xUnit testing framework to Perl as a first-class citizen.  Based
# initially on Ryan Davis' minitest, it provides a not only a simple way to
# write and run tests, but the necessary infrastructure for more expressive
# test fromeworks to be written.
#
# Since example code speaks louder than words:
#
#   package t::Test
#   use base 'Test::Mini::TestCase';
#   use strict;
#   use warnings;
#
#   # This will run before each test
#   sub setup { ... }
#
#   # This will run after each test
#   sub teardown { ... }
#
#   sub test_something {
#       my $self = shift;
#       $self->assert(1); # Assertions come from Test::Mini::Assertions
#   }
#
#   # Assertions can also be imported...
#   use Test::Mini::Assertions;
#
#   sub helper { return 1 }
#
#   sub test_something_else {
#       assert(helper());
#   }
#
# Like any traditional xUnit framework, any method whose name begins with
# 'test' will be automatically run.  If you've declared 'setup' or 'teardown'
# methods, they will be run before or after each test.
#
# @see http://blog.zenspider.com/minitest
# @see Test::Mini::Runner
# @author Pieter van de Bruggen <pvande@cpan.org>
package Test::Mini;
use strict;
use warnings;
use 5.008;

use version 0.77; our $VERSION = qv("v1.1.3");

# @scope class
# @return [Class] The test runner class to use.
sub runner_class { 'Test::Mini::Runner' }

END {
    $| = 1;
    return if $?;

    unless ($ENV{TEST_MINI_NO_AUTORUN}) {
        my $class = __PACKAGE__->runner_class;
        eval "require $class;";

        $? = $class->new()->run();
    }
}

1;
