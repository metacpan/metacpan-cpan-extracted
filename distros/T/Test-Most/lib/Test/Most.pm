package Test::Most;

use warnings;
use strict;

use Test::Most::Exception 'throw_failure';

# XXX don't use 'base' as it can override signal handlers
use Test::Builder::Module;
our ( @ISA, @EXPORT, $DATA_DUMPER_NAMES_INSTALLED );
my $HAVE_TIME_HIRES;

BEGIN {

    require Test::More;
    if (Test::More->can('TB_PROVIDER_META')) {
        Test::More->import(import => [ '!explain' ]);
    }
    else {
        # There's some strange fiddling around with import(), so this allows us to
        # be nicely backwards compatible to earlier versions of Test::More.
        @Test::More::EXPORT = grep { $_ ne 'explain' } @Test::More::EXPORT;
        Test::More->import;
    }

    eval "use Time::HiRes";
    $HAVE_TIME_HIRES = 1 unless $@;
}

use Test::Builder;
my $OK_FUNC;
BEGIN {
    $OK_FUNC = \&Test::Builder::ok;
}

our $VERSION = '0.37';
$VERSION = eval $VERSION;

BEGIN {
    @ISA    = qw(Test::Builder::Module);
    @EXPORT = (
        Test::More->can('TB_PROVIDER_META')
            ? grep { $_ ne 'TODO' } keys( %{Test::More->TB_PROVIDER_META->{attrs}})
            : @Test::More::EXPORT,
        qw<
            $TODO
            all_done
            bail_on_fail
            die_on_fail
            explain
            always_explain
            last_test_failed
            restore_fail
            set_failure_handler
            show
            always_show
        >
    );
}

sub import {
    my $bail_set = 0;

    my %modules_to_load = map { $_ => 1 } qw/
        Test::Differences
        Test::Exception
        Test::Deep
        Test::Warn
    /;
    warnings->import;
    strict->import;
    eval "use Data::Dumper::Names 0.03";
    $DATA_DUMPER_NAMES_INSTALLED = !$@;

    if ( $ENV{BAIL_ON_FAIL} ) {
        $bail_set = 1;
        bail_on_fail();
    }
    if ( !$bail_set and $ENV{DIE_ON_FAIL} ) {
        die_on_fail();
    }
    for my $i ( 0 .. $#_ ) {
        if ( 'bail' eq $_[$i] ) {
            splice @_, $i, 1;
            bail_on_fail();
            $bail_set = 1;
            last;
        }
    }
    my $caller = caller;
    for my $i ( 0 .. $#_ ) {
        if ( 'timeit' eq $_[$i] ) {
            splice @_, $i, 1;
            no strict;
            *{"${caller}::timeit"} = \&timeit;
            last;
        }
    }

    my %exclude_symbol;
    my $i = 0;

    foreach my $do_not_import_by_default (qw/blessed reftype/) {
        if ( grep { $_ eq $do_not_import_by_default } @_ ) {
            @_ = grep { $_ ne $do_not_import_by_default } @_;
        }
        else {
            $exclude_symbol{$do_not_import_by_default} = 1;
        }
    }

    while ($i < @_) {
        if ( !$bail_set and ( 'die' eq $_[$i] ) ) {
            splice @_, $i, 1;
            die_on_fail();
            $i = 0;
            next;
        }
        if ( $_[$i] =~ /^-(.*)/ ) {
            my $module = $1;
            splice @_, $i, 1;
            unless (exists $modules_to_load{$module}) {
                require Carp;
                Carp::croak("Cannot remove non-existent Test::Module ($module)");
            }
            delete $modules_to_load{$module};
            $i = 0;
            next;
        }
        if ( $_[$i] =~ /^!(.*)/ ) {
            splice @_, $i, 1;
            $exclude_symbol{$1} = 1;
            $i = 0;
            next;
        }
        if ( 'defer_plan' eq $_[$i] ) {
            require Carp;
            Carp::carp(<<'END') unless $ENV{DO_NOT_WARN_ON_DEFER_PLAN};
defer_plan() is deprecated and will be removed in a future release of
Test::Most. It's functionality is provided by Test::More's done_testing(),
first added in 2009 (0.88).
END
            splice @_, $i, 1;

            my $builder = Test::Builder->new;

            # XXX I don't like setting this directly, but
            # Test::Builder::has_plan isn't public
            $builder->{Have_Plan}               = 1;
            $builder->{TEST_MOST_deferred_plan} = 1;
            $builder->{TEST_MOST_all_done}      = 0;
            $i = 0;
            next;
        }
        $i++;
    }
    foreach my $module (keys %modules_to_load) {
        eval "use $module";

        if ( my $error = $@) {
            require Carp;
            Carp::croak($error);
        }
        no strict 'refs';
        # Note: export_to_level would be better here.
        push @EXPORT => grep { !$exclude_symbol{$_} } @{"${module}::EXPORT"};
    }

    # 'magic' goto to avoid updating the callstack
    goto &Test::Builder::Module::import;
}

sub explain {
    _explain(\&Test::More::note, @_);
}


sub timeit(&;$) {
    my ( $code, $message ) = @_;
    unless($HAVE_TIME_HIRES) {
        Test::Most::diag("timeit: Time::HiRes not installed");
        $code->();
    }
    if ( !$message ) {
        my ( $package, $filename, $line ) = caller;
        $message = "$filename line $line";
    }
    my $start = [Time::HiRes::gettimeofday()];
    $code->();
    explain(
        sprintf "$message: took %s seconds" => Time::HiRes::tv_interval($start) );
}

sub always_explain {
    _explain(\&Test::More::diag, @_);
}

sub _explain {
    my $diag = shift;
    no warnings 'once';
    $diag->(
        map {
            ref $_
              ? do {
                require Data::Dumper;
                local $Data::Dumper::Indent   = 1;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Terse    = 1;
                Data::Dumper::Dumper($_);
              }
              : $_
          } @_
    );
}

sub show {
    _show(\&Test::More::note, @_);
}

sub always_show {
    _show(\&Test::More::diag, @_);
}

sub _show {
    unless ( $DATA_DUMPER_NAMES_INSTALLED ) {
        require Carp;
	Carp::carp("Data::Dumper::Names 0.03 not found.  Use explain() instead of show()");
        goto &_explain;
    }
    my $diag = shift;
    no warnings 'once';
    local $Data::Dumper::Indent         = 1;
    local $Data::Dumper::Sortkeys       = 1;
    local $Data::Dumper::Names::UpLevel = $Data::Dumper::Names::UpLevel + 2;
    $diag->(Data::Dumper::Names::Dumper(@_));
}

sub die_on_fail {
    set_failure_handler( sub { throw_failure } );
}

sub bail_on_fail {
    set_failure_handler(
        sub { Test::More::BAIL_OUT("Test failed.  BAIL OUT!.\n") } );
}

sub restore_fail {
    no warnings 'redefine';
    *Test::Builder::ok = $OK_FUNC;
}

sub all_done {
   my $builder = Test::Builder->new;
   if ($builder->{TEST_MOST_deferred_plan}) {
       $builder->{TEST_MOST_all_done} = 1;
       $builder->expected_tests(@_ ? $_[0] : $builder->current_test);
   }
}


sub set_failure_handler {
    my $action = shift;
    no warnings 'redefine';
    Test::Builder->new->{TEST_MOST_failure_action} = $action; # for DESTROY
    *Test::Builder::ok = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $builder = $_[0];
        if ( $builder->{TEST_MOST_test_failed} ) {
            $builder->{TEST_MOST_test_failed} = 0;
            $action->($builder);
        }
        $builder->{TEST_MOST_test_failed} = 0;
        my $result = $OK_FUNC->(@_);
        $builder->{TEST_MOST_test_failed} = !( $builder->summary )[-1];
        return $result;
    };
}

{
    no warnings 'redefine';
    my $orig_destroy = Test::Builder->can('DESTROY');

    # we need this because if the failure is on the final test, we won't have
    # a subsequent test triggering the behavior.
    *Test::Builder::DESTROY = sub {
        my $builder = $_[0];
        if ( $builder->{TEST_MOST_test_failed} ) {
            ( $builder->{TEST_MOST_failure_action} || sub {} )->();
        }
        $orig_destroy->(@_) if $orig_destroy;
    };
}

sub _deferred_plan_handler {
   my $builder = Test::Builder->new;
   if ($builder->{TEST_MOST_deferred_plan} and !$builder->{TEST_MOST_all_done})
   {
       $builder->expected_tests($builder->current_test + 1);
   }
}

# This should work because the END block defined by Test::Builder should be
# guaranteed to be run before t one, since we use'd Test::Builder way up top.
# The other two alternatives would be either to replace Test::Builder::_ending
# similar to how we did Test::Builder::ok, or to call Test::Builder::no_ending
# and basically rewrite _ending in our own image.  Neither is very palatable,
# considering _ending's initial underscore.

END {
   _deferred_plan_handler();
}

1;
__END__

=head1 NAME

Test::Most - Most commonly needed test functions and features.

=head1 VERSION

Version 0.34

=head1 SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use Test::Exception 0.88;
    use Test::Differences 0.500;
    use Test::Deep 0.106;
    use Test::Warn 0.11;
    use Test::More tests => 42;

You type this:

    use Test::Most tests => 42;

=head1 DESCRIPTION

L<Test::Most> exists to reduce boilerplate and to make your testing life
easier.  We provide "one stop shopping" for most commonly used testing
modules.  In fact, we often require the latest versions so that you get bug
fixes through L<Test::Most> and don't have to keep upgrading these modules
separately.

This module provides you with the most commonly used testing functions, along
with automatically turning on strict and warning and gives you a bit more
fine-grained control over your test suite.

    use Test::Most tests => 4, 'die';

    ok 1, 'Normal calls to ok() should succeed';
    is 2, 2, '... as should all passing tests';
    eq_or_diff [3], [4], '... but failing tests should die';
    ok 4, '... will never get to here';

As you can see, the C<eq_or_diff> test will fail.  Because 'die' is in the
import list, the test program will halt at that point.

If you do not want strict and warnings enabled, you must explicitly disable
them.  Thus, you must be explicit about what you want and no longer need to
worry about accidentally forgetting them.

    use Test::Most tests => 4;
    no strict;
    no warnings;

=head1 EXPORT

All functions from the following modules will automatically be exported into
your namespace:

=over 4

=item * L<Test::More>

=item * L<Test::Exception>

=item * L<Test::Differences>

=item * L<Test::Deep> 

=item * L<Test::Warn>

=back

Functions which are I<optionally> exported from any of those modules must be
referred to by their fully-qualified name:

  Test::Deep::render_stack( $var, $stack );

=head1 FUNCTIONS

Several other functions are also automatically exported:

=head2 C<die_on_fail>

 die_on_fail;
 is_deeply $foo, bar, '... we throw an exception if this fails';

This function, if called, will cause the test program to throw a
L<Test::Most::Exception>, effectively halting the test.

=head2 C<bail_on_fail>

 bail_on_fail;
 is_deeply $foo, bar, '... we bail out if this fails';

This function, if called, will cause the test suite to BAIL_OUT() if any
tests fail after it.

=head2 C<restore_fail>

 die_on_fail;
 is_deeply $foo, bar, '... we throw an exception if this fails';

 restore_fail;
 cmp_bag(\@got, \@bag, '... we will not throw an exception if this fails';

This restores the original test failure behavior, so subsequent tests will no
longer throw an exception or BAIL_OUT().

=head2 C<set_failure_handler>

If you prefer other behavior to 'die_on_fail' or 'bail_on_fail', you can
set your own failure handler:

 set_failure_handler( sub {
     my $builder = shift;
     if ( $builder && $builder->{Test_Results}[-1] =~ /critical/ ) {
        send_admin_email("critical failure in tests");
     }
 } );

It receives the C<< Test::Builder >> instance as its only argument.  

B<Important>:  Note that if the failing test is the very last test run, then
the C<$builder> will likely be undefined.  This is an unfortunate side effect
of how C<Test::Builder> has been designed.

=head2 C<explain>

Similar to C<note()>, the output will only be seen by the user by
using the C<-v> switch with C<prove> or reading the raw TAP.

Unlike C<note()>, any reference in the argument list is automatically expanded
using C<Data::Dumper>.  Thus, instead of this:

 my $self = Some::Object->new($id);
 use Data::Dumper;
 explain 'I was just created', Dumper($self);

You can now just do this:

 my $self = Some::Object->new($id);
 explain 'I was just created:  ', $self;

That output will look similar to:

 I was just created: bless( {
   'id' => 2,
   'stack' => []
 }, 'Some::Object' )

Note that the "dumpered" output has the C<Data::Dumper> variables
C<$Indent>, C<Sortkeys> and C<Terse> all set to the value of C<1> (one).  This
allows for a much cleaner diagnostic output and at the present time cannot be
overridden.

Note that Test::More's C<explain> acts differently.  This C<explain>
is equivalent to C<note explain> in Test::More.

=head2 C<show>

Experimental.  Just like C<explain>, but also tries to show you the lexical
variable names:

 my $var   = 3;
 my @array = qw/ foo bar /;
 show $var, \@array;
 __END__
 $var = 3;
 @array = [
     'foo',
     'bar'
 ];

It will show C<$VAR1>, C<$VAR2> ... C<$VAR_N> for every variable it cannot
figure out the variable name to:

 my @array = qw/ foo bar /;
 show @array;
 __END__
 $VAR1 = 'foo';
 $VAR2 = 'bar';

Note that this relies on L<Data::Dumper::Names> version 0.03 or greater.  If
this is not present, it will warn and call L<explain> instead.  Also, it can
only show the names for lexical variables.  Globals such as C<%ENV> or C<%@>
are not accessed via PadWalker and thus cannot be shown.  It would be nice to
find a workaround for this.

=head2 C<always_explain> and C<always_show>

These are identical to C<explain> and C<show>, but like L<Test::More>'s
C<diag> function, these will always emit output, regardless of whether or not
you're in verbose mode.

=head2 C<all_done>

B<DEPRECATED>.  Use the new C<done_testing()> (added in
L<Test::More|Test::More> since 0.87_01).  Instead. We're leaving this in here
for a long deprecation cycle.  After a while, we might even start warning.

If the plan is specified as C<defer_plan>, you may call C<&all_done> at the
end of the test with an optional test number.  This lets you set the plan
without knowing the plan before you run the tests.

If you call it without a test number, the tests will still fail if you don't
get to the end of the test.  This is useful if you don't want to specify a
plan but the tests exit unexpectedly.  For example, the following would
I<pass> with C<no_plan> but fails with C<all_done>.

 use Test::More 'defer_plan';
 ok 1;
 exit;
 ok 2;
 all_done;

See L<Deferred plans> for more information.

=head1 EXPORT ON DEMAND

The following will be exported only if requested:

=head2 C<timeit>

Prototype: C<timeit(&;$)>

This function will warn if C<Time::HiRes> is not installed. The test will
still be run, but no timing information will be displayed.

 use Test::Most 'timeit';
 timeit { is expensive_function(), $some_value, $message }
    "expensive_function()";
 timeit { is expensive_function(), $some_value, $message };

C<timeit> accepts a code reference and an optional message. After the test is
run, will C<explain> the time of the function using C<Time::HiRes>. If a
message is supplied, it will be formatted as:

  sprintf "$message: took %s seconds" => $time;

Otherwise, it will be formatted as:

  sprintf "$filename line $line: took %s seconds" => $time;

=head1 DIE OR BAIL ON FAIL

Sometimes you want your test suite to throw an exception or BAIL_OUT() if a
test fails.  In order to provide maximum flexibility, there are three ways to
accomplish each of these.

=head2 Import list

 use Test::Most 'die', tests => 7;
 use Test::Most qw< no_plan bail >;

If C<die> or C<bail> is anywhere in the import list, the test program/suite
will throw a C<Test::Most::Exception> or C<BAIL_OUT()> as appropriate the
first time a test fails.  Calling C<restore_fail> anywhere in the test program
will restore the original behavior (not throwing an exception or bailing out).

=head2 Functions

 use Test::Most 'no_plan';
 ok $bar, 'The test suite will continue if this passes';

 die_on_fail;
 is_deeply $foo, bar, '... we throw an exception if this fails';

 restore_fail;
 ok $baz, 'The test suite will continue if this passes';

The C<die_on_fail> and C<bail_on_fail> functions will automatically set the
desired behavior at runtime.

=head2 Environment variables

 DIE_ON_FAIL=1 prove t/
 BAIL_ON_FAIL=1 prove t/

If the C<DIE_ON_FAIL> or C<BAIL_ON_FAIL> environment variables are true, any
tests which use C<Test::Most> will throw an exception or call BAIL_OUT on test
failure.

=head1 MISCELLANEOUS

=head2 Moose

It used to be that this module would produce a warning when used with Moose:

    Prototype mismatch: sub main::blessed ($) vs none

This was because L<Test::Deep> exported a C<blessed()> function by default,
but its prototype did not match the L<Moose> version's prototype. We now
exclude the L<Test::Deep> version by default. If you need it, you can call the
fully-qualified version or request it on the command line:

    use Test::Most 'blessed';

Note that as of version C<0.34>, C<reftype> is also excluded from
C<Test::Deep>'s import list. This was causing issues with people trying to use
C<Scalar::Util>'s C<reftype> function.

=head2 Excluding Test Modules

Sometimes you want a exclude a particular test module.  For example,
L<Test::Deep>, when used with L<Moose>, produces the following warning:

    Prototype mismatch: sub main::blessed ($) vs none

You can exclude this with by adding the module to the import list with a '-'
symbol in front:

    use Test::Most tests => 42, '-Test::Deep';

See
L<https://rt.cpan.org/Ticket/Display.html?id=54362&results=e73ff63c5bf9ba0f796efdba5773cf3f>
for more information.

=head2 Excluding Test Symbols

Sometimes you don't want to exclude an entire test module, but just a
particular symbol that is causing issues You can exclude the symbol(s) in the
standard way, by specifying the symbol in the import list with a '!' in front:

    use Test::Most tests => 42, '!throws_ok';

=head2 Deferred plans

B<DEPRECATED> and will be removed in some future release of this module.
Using C<defer_plan> will C<carp()>. Use C<done_testing()> from L<Test::More>
instead.

 use Test::Most qw<defer_plan>;
 use My::Tests;
 my $test_count = My::Tests->run;
 all_done($test_count);

Sometimes it's difficult to know the plan up front, but you can calculate the
plan as your tests run.  As a result, you want to defer the plan until the end
of the test.  Typically, the best you can do is this:

 use Test::More 'no_plan';
 use My::Tests;
 My::Tests->run;

But when you do that, C<Test::Builder> merely asserts that the number of tests
you I<ran> is the number of tests.  Until now, there was no way of asserting
that the number of tests you I<expected> is the number of tests unless you do
so before any tests have run.  This fixes that problem.

=head2 One-stop shopping

We generally require the latest stable versions of various test modules.  Why?
Because they have bug fixes and new features.  You don't want to have to keep
remembering them, so periodically we'll release new versions of L<Test::Most>
just for bug fixes.

=head2 C<use ok>

We do not bundle L<Test::use::ok>, though it's been requested.  That's because
C<use_ok> is broken, but L<Test::use::ok> is also subtly broken (and a touch
harder to fix).  See L<http://use.perl.org/~Ovid/journal/39859> for more
information.

If you want to test if you can use a module, just use it.  If it fails, the
test will still fail and that's the desired result.

=head1 RATIONALE

People want more control over their test suites.  Sometimes when you see
hundreds of tests failing and whizzing by, you want the test suite to simply
halt on the first failure.  This module gives you that control.

As for the reasons for the four test modules chosen, I ran code over a local
copy of the CPAN to find the most commonly used testing modules.  Here's the
top twenty as of January 2010 (the numbers are different because we're now
counting distributions which use a given module rather than simply the number
of times a module is used).

    1   Test::More                          14111
    2   Test                                 1736
    3   Test::Exception                       744
    4   Test::Simple                          331
    5   Test::Pod                             328
    6   Test::Pod::Coverage                   274
    7   Test::Perl::Critic                    248
    8   Test::Base                            228
    9   Test::NoWarnings                      155
    10  Test::Distribution                    142
    11  Test::Kwalitee                        138
    12  Test::Deep                            128
    13  Test::Warn                            127
    14  Test::Differences                     102
    15  Test::Spelling                        101
    16  Test::MockObject                       87
    17  Test::Builder::Tester                  84
    18  Test::WWW::Mechanize::Catalyst         79
    19  Test::UseAllModules                    63
    20  Test::YAML::Meta                       61

L<Test::Most> is number 24 on that list, if you're curious.  See
L<http://blogs.perl.org/users/ovid/2010/01/most-popular-testing-modules---january-2010.html>.

The modules chosen seemed the best fit for what C<Test::Most> is trying to do.
As of 0.02, we've added L<Test::Warn> by request.  It's not in the top ten, but
it's a great and useful module.

=cut


=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-extended at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Most>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Most

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Most>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Most>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Most>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Most>

=back

=head1 TODO

=head2 Deferred plans

Sometimes you don't know the number of tests you will run when you use
C<Test::More>.  The C<plan()> function allows you to delay specifying the
plan, but you must still call it before the tests are run.  This is an error:

 use Test::More;

 my $tests = 0;
 foreach my $test (
     my $count = run($test); # assumes tests are being run
     $tests += $count;
 }
 plan($tests);

The way around this is typically to use 'no_plan' and when the tests are done,
C<Test::Builder> merely sets the plan to the number of tests run.  We'd like
for the programmer to specify this number instead of letting C<Test::Builder>
do it.  However, C<Test::Builder> internals are a bit difficult to work with,
so we're delaying this feature.

=head2 Cleaner skip()

 if ( $some_condition ) {
     skip $message, $num_tests;
 }
 else {
     # run those tests
 }

That would be cleaner and I might add it if enough people want it.

=head1 CAVEATS

Because of how Perl handles arguments, and because diagnostics are not really
part of the Test Anything Protocol, what actually happens internally is that
we note that a test has failed and we throw an exception or bail out as soon
as the I<next> test is called (but before it runs).  This means that its
arguments are automatically evaluated before we can take action:

 use Test::Most qw<no_plan die>;

 ok $foo, 'Die if this fails';
 ok factorial(123456),
   '... but wait a loooong time before you throw an exception';

=head1 ACKNOWLEDGEMENTS

Many thanks to C<perl-qa> for arguing about this so much that I just went
ahead and did it :)

Thanks to Aristotle for suggesting a better way to die or bailout.

Thanks to 'swillert' (L<http://use.perl.org/~swillert/>) for suggesting a
better implementation of my "dumper explain" idea
(L<http://use.perl.org/~Ovid/journal/37004>).

=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
