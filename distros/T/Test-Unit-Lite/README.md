# NAME

Test::Unit::Lite - Unit testing without external dependencies

# SYNOPSIS

Bundling the [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) as a part of package distribution:

    perl -MTest::Unit::Lite -e bundle

Running all test units:

    perl -MTest::Unit::Lite -e all_tests

Using as a replacement for Test::Unit:

    package FooBarTest;
    use Test::Unit::Lite;   # unnecessary if module isn't directly used
    use base 'Test::Unit::TestCase';

    sub new {
        my $self = shift()->SUPER::new(@_);
        # your state for fixture here
        return $self;
    }

    sub set_up {
        # provide fixture
    }
    sub tear_down {
        # clean up after test
    }
    sub test_foo {
        my $self = shift;
        my $obj = ClassUnderTest->new(...);
        $self->assert_not_null($obj);
        $self->assert_equals('expected result', $obj->foo);
        $self->assert(qr/pattern/, $obj->foobar);
    }
    sub test_bar {
        # test the bar feature
    }

# DESCRIPTION

This framework provides lighter version of [Test::Unit](http://search.cpan.org/perldoc?Test::Unit) framework.  It
implements some of the [Test::Unit](http://search.cpan.org/perldoc?Test::Unit) classes and methods needed to run test
units.  The [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) tries to be compatible with public API of
[Test::Unit](http://search.cpan.org/perldoc?Test::Unit). It doesn't implement all classes and methods at 100% and only
those necessary to run tests are available.

The [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) can be distributed as a part of package distribution,
so the package can be distributed without dependency on modules outside
standard Perl distribution.  The [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) is provided as a single
file.

## Bundling the [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) as a part of package distribution

The [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) framework can be bundled to the package distribution.
Then the [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) module is copied to the `inc` directory of the
source directory for the package distribution.

# FUNCTIONS

- bundle

Copies [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) modules into `inc` directory.  Creates missing
subdirectories if needed.  Silently overwrites previous module if was
existing.

- all\_tests

Creates new test runner for [Test::Unit::Lite::AllTests](http://search.cpan.org/perldoc?Test::Unit::Lite::AllTests) suite which searches
for test units in `t/tlib` directory.

# CLASSES

## [Test::Unit::TestCase](http://search.cpan.org/perldoc?Test::Unit::TestCase)

This is a base class for single unit test module.  The user's unit test
module can override the default methods that are simple stubs.

The MESSAGE argument is optional and is included to the default error message
when the assertion is false.

- new

The default constructor which just bless an empty anonymous hash reference.

- set\_up

This method is called at the start of each test unit processing.  It is empty
method and can be overridden in derived class.

- tear\_down

This method is called at the end of each test unit processing.  It is empty
method and can be overridden in derived class.

- list\_tests

Returns the list of test methods in this class and base classes.

- fail(\[MESSAGE\])

Immediate fail the test.

- assert(ARG \[, MESSAGE\])

Checks if ARG expression returns true value.

- assert\_null(ARG \[, MESSAGE\])
- assert\_not\_null(ARG \[, MESSAGE\])

Checks if ARG is defined or not defined.

- assert\_equals(ARG1, ARG2 \[, MESSAGE\])
- assert\_not\_equals(ARG1, ARG2 \[, MESSAGE\])

Checks if ARG1 and ARG2 are equals or not equals.  If ARG1 and ARG2 look like
numbers then they are compared with '==' operator, otherwise the string 'eq'
operator is used.

- assert\_num\_equals(ARG1, ARG2 \[, MESSAGE\])
- assert\_num\_not\_equals(ARG1, ARG2 \[, MESSAGE\])

Force numeric comparison.

- assert\_str\_equals(ARG1, ARG2 \[, MESSAGE\])
- assert\_str\_not\_equals(ARG1, ARG2 \[, MESSAGE\])

Force string comparison.

- assert(qr/PATTERN/, ARG \[, MESSAGE\])
- assert\_matches(qr/PATTERN/, ARG \[, MESSAGE\])
- assert\_does\_not\_match(qr/PATTERN/, ARG \[, MESSAGE\])

Checks if ARG matches PATTER regexp.

- assert\_deep\_equals(ARG1, ARG2 \[, MESSAGE\])
- assert\_deep\_not\_equals(ARG1, ARG2 \[, MESSAGE\])

Check if reference ARG1 is a deep copy of reference ARG2 or not.  The
references can be deep structure.  If they are different, the message will
display the place where they start differing.

## [Test::Unit::TestSuite](http://search.cpan.org/perldoc?Test::Unit::TestSuite)

This is a base class for test suite, which groups several test units.

- empty\_new(\[NAME\])

Creates a fresh suite with no tests.

- new(\[CLASS | TEST\])

Creates a test suite from unit test name or class.  If a test suite is
provided as the argument, it merely returns that suite.  If a test case is
provided, it extracts all test case methods (see
[Test::Unit::TestCase](http://search.cpan.org/perldoc?Test::Unit::TestCase)\->list\_test) from the test case into a new test suite.

- name

Contains the name of the current test suite.

- units

Contains the list of test units.

- add\_test(\[TEST\_CLASSNAME | TEST\_OBJECT\])

Adds the test object to a suite.

- count\_test\_cases

Returns the number of test cases in this suite.

- run

Runs the test suite and output the results as TAP report.

## [Test::Unit::TestRunner](http://search.cpan.org/perldoc?Test::Unit::TestRunner)

This is the test runner which outputs text report about finished test suite.

- new(\[$fh\_out \[, $fh\_err\]\])

The constructor for whole test framework.  Its optional parameters are
filehandles for standard output and error messages.

- fh\_out

Contains the filehandle for standard output.

- fh\_err

Contains the filehandle for error messages.

- suite

Contains the test suite object.

- print\_header

Called before running test suite.

- print\_error

Called after error was occurred on `set_up` or `tear_down` method.

- print\_failure

Called after test unit is failed.

- print\_pass

Called after test unit is passed.

- print\_footer

Called after running test suite.

- start(TEST\_SUITE)

Starts the test suite.

## [Test::Unit::Result](http://search.cpan.org/perldoc?Test::Unit::Result)

This object contains the results of test suite.

- new

Creates a new object.

- messages

Contains the array of result messages.  The single message is a hash which
contains:

    - test

    the test unit name,

    - type

    the type of message (PASS, ERROR, FAILURE),

    - message

    the text of message.

- errors

Contains the number of collected errors.

- failures

Contains the number of collected failures.

- passes

Contains the number of collected passes.

- add\_error(TEST, MESSAGE)

Adds an error to the report.

- add\_failure(TEST, MESSAGE)

Adds an failure to the report.

- add\_pass(TEST, MESSAGE)

Adds a pass to the report.

## [Test::Unit::HarnessUnit](http://search.cpan.org/perldoc?Test::Unit::HarnessUnit)

This is the test runner which outputs in the same format that
[Test::Harness](http://search.cpan.org/perldoc?Test::Harness) expects (Test Anything Protocol).  It is derived
from [Test::Unit::TestRunner](http://search.cpan.org/perldoc?Test::Unit::TestRunner).

## [Test::Unit::Debug](http://search.cpan.org/perldoc?Test::Unit::Debug)

The empty class which is provided for compatibility with original
[Test::Unit](http://search.cpan.org/perldoc?Test::Unit) framework.

## [Test::Unit::Lite::AllTests](http://search.cpan.org/perldoc?Test::Unit::Lite::AllTests)

The test suite which searches for test units in `t/tlib` directory.

# COMPATIBILITY

[Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) should be compatible with public API of [Test::Unit](http://search.cpan.org/perldoc?Test::Unit).
The [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) also has some known incompatibilities:

- The test methods are sorted alphabetically.
- It implements new assertion method: __assert\_deep\_not\_equals__.
- Does not support __ok__, __assert__(CODEREF, @ARGS) and __multi\_assert__.

`Test::Unit::Lite` is compatible with [Test::Assert](http://search.cpan.org/perldoc?Test::Assert) assertion functions.

# EXAMPLES

## t/tlib/SuccessTest.pm

This is the simple unit test module.

    package SuccessTest;

    use strict;
    use warnings;

    use base 'Test::Unit::TestCase';

    sub test_success {
      my $self = shift;
      $self->assert(1);
    }

    1;

## t/all\_tests.t

This is the test script for [Test::Harness](http://search.cpan.org/perldoc?Test::Harness) called with "make test".

    #!/usr/bin/perl

    use strict;
    use warnings;

    use File::Spec;
    use Cwd;

    BEGIN {
        unshift @INC, map { /(.*)/; $1 } split(/:/, $ENV{PERL5LIB}) if defined $ENV{PERL5LIB} and ${^TAINT};

        my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
        unshift @INC, File::Spec->catdir($cwd, 'inc');
        unshift @INC, File::Spec->catdir($cwd, 'lib');
    }

    use Test::Unit::Lite;

    local $SIG{__WARN__} = sub { require Carp; Carp::confess("Warning: $_[0]") };

    Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');

## t/test.pl

This is the optional script for calling test suite directly.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use File::Basename;
    use File::Spec;
    use Cwd;

    BEGIN {
        chdir dirname(__FILE__) or die "$!";
        chdir '..' or die "$!";

      unshift @INC, map { /(.*)/; $1 } split(/:/, $ENV{PERL5LIB}) if defined $ENV{PERL5LIB} and ${^TAINT};

        my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
        unshift @INC, File::Spec->catdir($cwd, 'inc');
        unshift @INC, File::Spec->catdir($cwd, 'lib');
    }

    use Test::Unit::Lite;

    local $SIG{__WARN__} = sub { require Carp; Carp::confess("Warning: $_[0]") };

    all_tests;

This is perl equivalent of shell command line:

    perl -Iinc -Ilib -MTest::Unit::Lite -w -e all_tests

# SEE ALSO

[Test::Unit](http://search.cpan.org/perldoc?Test::Unit), [Test::Assert](http://search.cpan.org/perldoc?Test::Assert).

# TESTS

The [Test::Unit::Lite](http://search.cpan.org/perldoc?Test::Unit::Lite) was tested as a [Test::Unit](http://search.cpan.org/perldoc?Test::Unit) replacement for following
distributions: [Test::C2FIT](http://search.cpan.org/perldoc?Test::C2FIT), [XAO::Base](http://search.cpan.org/perldoc?XAO::Base), [Exception::Base](http://search.cpan.org/perldoc?Exception::Base).

# BUGS

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/perl-Test-Unit-Lite/issues](https://github.com/dex4er/perl-Test-Unit-Lite/issues)

The code repository is available at
[http://github.com/dex4er/perl-Test-Unit-Lite](http://github.com/dex4er/perl-Test-Unit-Lite)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2007-2009, 2012 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See [http://www.perl.com/perl/misc/Artistic.html](http://www.perl.com/perl/misc/Artistic.html)
