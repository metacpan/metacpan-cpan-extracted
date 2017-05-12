use strict;
use warnings;

package Test::Expectation;

our $VERSION = 0.06;

use Carp qw(croak);
use Test::More 'no_plan';
use Test::Expectation::Positive;
use Test::Expectation::Negative;

require Exporter;
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(it_should before_each after_each it_is_a);

our @Expectations;
our $Description = '';
our $BeforeEach = sub {};
our $AfterEach = sub {};

sub it_is_a {
    $Description = shift;
}

sub before_each {
    $BeforeEach = shift;
}

sub after_each {
    $AfterEach = shift;
}

sub it_should {
    my ($testName, $testRef) = @_;

    @Expectations = ();
    $BeforeEach->();

    $testRef->();

    $AfterEach->();

    foreach my $expectation (@Expectations) {
        my $testString = ($Description ? $Description . " " : 'it ') . "should $testName";

        if ($expectation->isMet()) {
            pass($testString);
        }
        else {
            fail($testString . ' (' . $expectation->failure . ')');
        }
    }

    @Expectations = ();
}

*UNIVERSAL::_bindExpectation = sub {
    my ($expectationType, $class, $method) = @_;

    my $expectation = $expectationType->new($class, $method);

    push(@Expectations, $expectation);
    return $expectation
};

*UNIVERSAL::expects = sub {
    UNIVERSAL::_bindExpectation('Test::Expectation::Positive', @_);
};

*UNIVERSAL::does_not_expect = sub {
    UNIVERSAL::_bindExpectation('Test::Expectation::Negative', @_);
};

1;

__END__

=head1 NAME

Test::Expectation - A Perl unit test framework based on Ruby's RSpec framework.

=head1 SYNOPSIS

 # our test class is...
 use Day;

 use Test::Expectation;

 # tell the framework what we're testing...
 it_is_a 'Day'

 my $today;

 # set up some code that will run before every test.
 before_each(sub {
     $today = Day->new();
 });

 # ... and some code that will run after each test.
 after_each(sub {
     $today->sunGoesDown;
 });

 # these are our tests.

 # this test will only pass if "length" calls the method "hours".
 it_should "have some hours in it", sub {
     Day->expects('hours');
     $day->length(); 
 };

 # this test will pass if "weather" calls clouds.
 # we will make "clouds" return "rain".
 it_should "have some weather", sub {
     Day->expects('clouds')->to_return('rain');

     is_deeply(
         $day->weather(),
         'rain'
         'the weather today will be rain'
     );
 };

 # this test will pass if either 'setDay' or
 # 'calculateSurroundingDays' calls the method 
 # tomorrow" with the parameter "wednesday".
 # we'll force "tomorrow" to return thursday.
 it_should "have a next day", sub {
     Day->expects('tomorrow')->with('wednesday')->to_return('thursday');

     $day->setDay('wednesday');
     $day->calculateSurroundingDays();
 };

=head1 DESCRIPTION

If you've never heard of Behavior Driven Development or Test Driven Development then you should probably learn about that first! Take a look at the "SEE ALSO" section for some useful links.

The way I like to think of Test Driven Development unit testing is like writing a TODO list for my code that also happens to test it as well. So I can put together my class, design it and it's internals in my Test::Expectation test and then write the code to make the tests pass. This should be done for each test.

This is a blatant copy of Ruby's RSpec framework. Having used that pretty frequently, when I moved from a Ruby project to a Perl one, it felt a bit dirty not writing RSpec tests. So I have quickly put together a framework that will act in a similar way to RSpec.

=head1 EXPORTED FUNCTIONS

 it_is_a(your class or whatever) - This sets the name of the class you are testing.

 it_should(expected behavior string, coderef) - This is your test. The block within will contain the expectations and some execution.

 before_each(some coderef) - Some code that will be executed before each "it_should" block.

 after_each(some coderef) - Some code that will be executed *after* each "it_should" block.

=head1 METHODS

 YourClass.expects(some method) - This method will be added to your class and will assert that the given method will be called somewhere in the "it_should" block. It returns an instance of Test::Expectation::Base.

 YourClass.does_not_expect(some method) - Same as "expects" but checks that your method is NOT called during the execution of your "it_should_ block.

Calling "expects" or "does_not_expect" will return an instance of Test::Expectation::Base. It has the following methods:

 with(arguments...) - Asserts that your method named in your "expects"/"does_not_expect" call will be called with the given arguments.

 to_return(some vaues...) - Ensures that *if* your method is called, it will return the list of values.

 to_raise(some error) - If your method is called, it will throw a given exception.

=head1 HOW IT WORKS

I've used some pretty cheeky hackery to shoe-horn methods in to your beautiful class. Your class will have new methods called "expect" and "does_not_expect". The argument you pass into those is the name of the method that is intended to be called (or explicitly NOT called) somewhere in your "it_should" block. It will return a child of Test::Expectation::Base.

The method you define in your "expect"/"does_not_expect" will be replaced with a fake one whose sole purpose is to ensure that the method is called. Optionally you can assert that the method should be called with some paramters (using "with") and that it should return some values (using "to_return").

Each assertion made with expects or does_not_expect will be a test. If the asseertions are not met during the "it_should" block, then the test will fail.

=head1 SEE ALSO

 - Project's GitHub page: http://github.com/moowahaha/p5-Test-Expectation/

 - RSpec: http://rspec.info/

 - Test::More: http://search.cpan.org/~mschwern/Test-Simple-0.92/lib/Test/More.pm

 - TDD (Test Driven Development): http://en.wikipedia.org/wiki/Test-driven_development

 - BDD (Behavior Driven Development): http://en.wikipedia.org/wiki/Behavior_Driven_Development

=head1 COPYRIGHT

Copyright 2009 by Stephen Hardisty <moowahaha@hotmail.com>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

