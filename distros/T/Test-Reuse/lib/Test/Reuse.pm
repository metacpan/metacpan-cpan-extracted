package Test::Reuse;

=head1 NAME

Test::Reuse - Reusable Test::More tests in classes

=head1 DESCRIPTION

Test::Reuse was created for the sole purpose of writing really easy-to-use, reusable tests. You can create tests in a class, C<use> your class name in the test (which will also deploy all L<Test::More> features for you), then you can use specific tests from that class. You can also pass arguments to these tests.

=head1 SYNOPSIS

OK, say we have the very same test running in several different tests. You don't want to just keep copy and pasting that code because it clutters up space when it doesn't need to. So we start by writing the test class to where our reusable tests will be imported from.

    package MyTestClass;
    
    use Test::Reuse;

    subtest 'is_it_ok' => sub {
        my $test = shift;
        
        for (@_) {
            ok $_, "$_ seems just fine!";
        }
    };

The C<subtest> method in class that uses C<Test::Reuse> actually stores the tests that are reusable. It won't actually run a subtest. The first argument will always be the test class name. In this instance it is MyTestClass.
Now let's write the actual test.

    #!perl
    
    use MyTestClass;
    
    use_test 'is_it_ok', qw<1 2 3 4 0 5>;
    
    runtests();

That's it. We use C<use_test> followed by the subtest name. You can supply optional arguments afterwards if you like. Remember to always call C<runtests> when you're done, which is identical to C<done_testing>.
In the above example it will loop through all of numbers in the array we provided and will obviously fail on the fifth argument (the 0).
You can also run C<use_test> within the test class to control the flow a bit more.

    package MyTestClass;
    
    use Test::Reuse;

    subtest 'is_it_ok' => sub {
        my $test = shift;
        
        if (@_) {
            for (@_) {
                ok $_, "$_ seems just fine!";
            }
        }
        else {
            use_test 'show_problem', 'No arguments for is_it_ok';
        }
    };

    subtest 'show_problem' => sub {
        my ($test, $text) = @_;
        note "Woops!: ${text}";
    };
    
=cut

use warnings;
use strict;
use base 'Test::More';

$Test::Reuse::subtests = {};
$Test::Reuse::base = "";
$Test::Reuse::VERSION = '0.001';

sub import {
    my $class  = shift;
    my $caller = caller(1);
    $Test::Reuse::base = caller;
    distribute($caller)
        unless $Test::Reuse::base->can('ok');
}

sub distribute {
    my $caller = shift;
    my $base   = $Test::Reuse::base;
    {
        no strict 'refs';
        for my $method (keys %{"Test::More::"}) {
            *{"${caller}::${method}"} = *{"Test::More::${method}"}
                unless substr($method, 0, 1) eq '_' or $method eq uc($method);
            *{"${base}::${method}"} = *{"Test::More::${method}"}
                unless substr($method, 0, 1) eq '_' or $method eq uc($method) or $method eq 'subtest';
        }
        *{"${caller}::use_test"} = \&use_test;
        *{"${caller}::runtests"} = *{"Test::More::done_testing"};
        *{"${base}::use_test"} = \&use_test;
        *{"${base}::subtest"} = \&subtest;
    }
} 

sub subtest {
    my ($name, $code) = @_;
    $Test::Reuse::subtests->{$name} = $code;
}

sub use_test {
    my $base = $Test::Reuse::base;
    my $test = shift;
    __PACKAGE__->note("Can't use test '$test'. It's not included by $base")
        if !$Test::Reuse::subtests->{$test};
    $Test::Reuse::subtests->{$test}->($base, @_) if $Test::Reuse::subtests->{$test};
}

=head1 METHODS

Test::Reuse uses all the methods from L<Test::More>, but there are a couple that are used just in this module.

=head2 use_test

Calls a test from the test class. They must be defined in the test class using C<subtest>

    use_test 'method_name', qw<optional arguments here>;
    use_test 'my_test';

=head2 subtest

Technically this works exactly the same as Test::More's subtest in your test file, but in the test class it simply defines a reusable test.

    subtest 'reusable_test_name' => sub {
        my $test_class = shift;
        
        note "Running from ${test_class}";
    };

=head2 runtests

I don't like the way C<done_testing> looks, so swapped it for C<runtests>. But you are welcome to use either one in your code. This MUST be run at the bottom of your normal test file (.t), or it will freak out. Which is pretty normal if you don't declare a plan.

=head1 LIMITATIONS

This module is still new, so there are plenty. The main one at the moment being that you can only C<use> ONE reusable test class per test. It really sucks, I know. In the future I would love to be able to reuse tests from multiple classes, but at the moment it only works with one.

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself, because Perl is awesome, and so are you for using it.

=cut

1;
