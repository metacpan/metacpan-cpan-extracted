package Test::Kantan;
use 5.010_001;
use strict;
use warnings;

our $VERSION = "0.40";

use parent qw(Exporter);

use Try::Tiny;

use Test::Kantan::State;
use Test::Kantan::Builder;
use Test::Kantan::Caller;
use Test::Kantan::Suite;
use Test::Kantan::Expect;

use Test::Deep::NoTest qw(ignore);
use Module::Spy 0.03 qw(spy_on);

our @EXPORT = (
    qw(Feature Scenario Given When Then),
    qw(subtest done_testing setup teardown),
    qw(describe context it),
    qw(before_each after_each),
    qw(expect ok diag ignore spy_on),
    qw(skip_all),
);

my $HAS_DEVEL_CODEOBSERVER = !$ENV{KANTAN_NOOBSERVER} && eval "use Devel::CodeObserver 0.11; 1;";

our $Level = 0;

if (Test::Builder->can('new')) {
    # Replace some Test::Builder methods with mine.

    no warnings 'redefine';

    *Test::Builder::ok = sub {
        my ($self, $ok, $msg) = @_;
        Test::Kantan->builder->ok(
            value => $ok,
            message => $msg,
            caller => Test::Kantan::Caller->new(
                $Test::Builder::Level
            ),
        );
    };

    *Test::Builder::subtest = sub {
        my $self = shift;
        goto \&Test::Kantan::subtest;
    };

    *Test::Builder::diag = sub {
        my ($self, $message) = @_;

        Test::Kantan->builder->diag(
            message => $message,
            cutoff  => 1024,
            caller  => Test::Kantan::Caller->new($Test::Builder::Level),
        );
    };

    *Test::Builder::note = sub {
        my ($self, $message) = @_;

        Test::Kantan->builder->diag(
            message => $message,
            cutoff  => 1024,
            caller  => Test::Kantan::Caller->new($Test::Builder::Level),
        );
    };

    *Test::Builder::done_testing = sub {
        my ($self, $message) = @_;

        Test::Kantan->builder->done_testing()
    };
}

our $BUILDER = Test::Kantan::Builder->new();
sub builder { $BUILDER }

# -------------------------------------------------------------------------
# DSL functions

our $CURRENT = our $ROOT = Test::Kantan::Suite->new(root => 1, title => 'Root');
our $FINISHED;
our $RAN_TEST;

sub skip_all {
    my ($reason) = @_;
    $reason //= '';
    print "1..0 # SKIP ${reason}\n";
    exit 0;
}

sub setup(&) {
    my ($code) = @_;
    $CURRENT->add_trigger('setup' => $code);
}
sub before_each { goto \&setup }

sub teardown(&) {
    my ($code) = @_;
    $CURRENT->add_trigger('teardown' => $code);
}
sub after_each { goto \&teardown }

sub _step {
    my ($tag, $title) = @_;
    @_==2 or Carp::confess "Invalid arguments";

    my $last_state = $CURRENT->{last_state};
    $CURRENT->{last_state} = $tag;
    if ($last_state && $last_state eq $tag) {
        $tag = 'And';
    }
    builder->reporter->step(sprintf("%5s %s", $tag, $title));
}

sub Given { _step('Given', @_) }
sub When  { _step('When', @_) }
sub Then  { _step('Then', @_) }

sub _suite {
    my ($env_key, $tag, $title, $code) = @_;

    if (defined($env_key)) {
        my $filter = $ENV{$env_key};
        if (defined($filter) && length($filter) > 0 && $title !~ /$filter/) {
            builder->reporter->step("SKIP: ${title}");
            return;
        }
    }

    my $suite = Test::Kantan::Suite->new(
        title   => $title,
        parent  => $CURRENT,
    );
    {
        local $CURRENT = $suite;
        builder->subtest(
            title => defined($tag) ? "${tag} ${title}" : $title,
            code  => $code,
            suite => $suite,
        );
    }
    $RAN_TEST++;
}

sub Feature  { _suite('KANTAN_FILTER_FEATURE',  'Feature', @_) }
sub Scenario { _suite('KANTAN_FILTER_SCENARIO', 'Scenario', @_) }

# Test::More compat
sub subtest  { _suite('KANTAN_FILTER_SUBTEST', undef, @_) }

# BDD compat
sub describe { _suite(     undef, undef, @_) }
sub context  { _suite(     undef, undef, @_) }
sub it       { _suite(     undef, undef, @_) }

sub expect {
    my $stuff = shift;
    Test::Kantan::Expect->new(
        stuff   => $stuff,
        builder => Test::Kantan->builder
    );
}

sub ok(&) {
    my $code = shift;

    if ($HAS_DEVEL_CODEOBSERVER) {
        state $observer = Devel::CodeObserver->new();
        my ($retval, $result) = $observer->call($code);

        my $builder = Test::Kantan->builder;
        $builder->ok(
            value       => $retval,
            caller      => Test::Kantan::Caller->new(
                $Test::Kantan::Level
            ),
        );
        for my $pair (@{$result->dump_pairs}) {
            my ($code, $dump) = @$pair;

            $builder->diag(
                message => sprintf("%s => %s", $code, $dump),
                caller  => Test::Kantan::Caller->new(
                    $Test::Kantan::Level
                ),
                cutoff  => $builder->reporter->cutoff,
            );
        }
        return !!$retval;
    } else {
        my $retval = $code->();
        my $builder = Test::Kantan->builder;
        $builder->ok(
            value       => $retval,
            caller      => Test::Kantan::Caller->new(
                $Test::Kantan::Level
            ),
        );
    }
}

sub diag {
    my ($msg, $cutoff) = @_;

    Test::Kantan->builder->diag(
        message => $msg,
        cutoff  => $cutoff,
        caller  => Test::Kantan::Caller->new(
            $Test::Kantan::Level
        ),
    );
}

sub done_testing {
    builder->done_testing
}

END {
    if ($RAN_TEST) {
        unless (builder->finished) {
            die "You need to call `done_testing` before exit";
        }
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Test::Kantan - simple, flexible, fun "Testing framework"

=head1 SYNOPSIS

  use Test::Kantan;

  describe 'String', sub {
    describe 'index', sub {
      it 'should return -1 when the value is not matched', sub {
        expect(index("abc", 'x'))->to_be(-1);
        expect(index("abc", 'a'))->to_be(0);
      };
    };
  };

  done_testing;

=head1 DESCRIPTION

Test::Kantan is a behavior-driven development framework for testing Perl 5 code.
It has a clean, obvious syntax so that you can easily write tests.

=head1 CURRENT STATUS

Unstable. I will change the API without notice.

=head1 Interfaces

There is 3 types for describing test cases.

=head2 BDD style

RSpec/Jasmine like BDD style function names are available.

  describe 'String', sub {
    before_each { ... };
    describe 'index', sub {
      it 'should return -1 when the value is not matched', sub {
        expect(index("abc", 'x'))->to_be(-1);
        expect(index("abc", 'a'))->to_be(0);
      };
    };
  };

  done_testing;

=head2 Given-When-Then style

There is the Given-When-Then style functions.
It's really useful for describing real complex problems.

  Scenario 'String', sub {
    setup { ... };

    Feature 'Get the index from the code', sub {
      Given 'the string';
      my $str = 'abc';

      When 'get the index for "a"';
      my $i = index($str, 'a');

      Then 'the return value is 0';
      expect($i)->to_be(0);
    };
  };

  done_testing;

=head2 Plain old Test::More style

  subtest 'String', sub {
    setup { ... };

    subtest 'index', sub {
      expect(index("abc", 'x'))->to_be(-1);
      expect(index("abc", 'a'))->to_be(0);
    };
  };

  done_testing;

=head1 Assertions

Here is 2 type assertions.

=head2 C<ok()>

    ok { 1 };

There is the C<ok> function. It takes one code block. The code returns true value if the test case was passed, false otherwise.

C<ok()> returns the value what returned by the code.

=head2 C<expect()>

    expect($x)->to_be_true;

Here is the C<expect> function like RSpec/Jasmine. For more details, please look L<Test::Kantan::Expect>.

=head1 Utility functions

=head2 C< diag($message) >

You can show the diagnostic message with C< diag() > function.
Diagnostic message would not print if whole test cases in the subtest were passed.

It means, you can call diag() without worries about the messages is a obstacle.

=head2 C<ignore()>

The same as L<Test::Deep::NoTest>'s one. See also L<Test::Deep/ignore()>

=head2 C<spy_on()>

The same as L<"spy_on()" in Module::Spy|Module::Spy/my-spy-spy_on-class-object-method>

=head2 C<skip_all()>

Skips all of the tests that are in the hereafter.

=head1 Hooks

=head2 C<setup()>

    setup { do_something() };

C<setup> blocks are run before each example C<setup> blocks are run once before all of the examples in a group.

=head2 C<teardown()>

    teardown { do_something() };

C<teardown> blocks are run after each example C<teardown> blocks are run once after all of the examples in a group.

=head2 C<before_each()>

Alias of C<setup()>.

=head2 C<after_each>

Alias of C<teardown()>.

=head1 ENVIRONMENT VARIABLES

=over 4

=item KANTAN_REPORTER

You can specify the reporter class by KANTAN_REPORTER environment variable.

    KANTAN_REPORTER=TAP perl -Ilib t/01_simple.t

=item KANTAN_CUTOFF

Kantan cut the diagnostic message by 80 bytes by default.
If you want to change this value, you can set by KANTAN_CUTOFF.

    KANTAN_CUTOFF=10000 perl -Ilib t/01_simple.t

=back

=head1 Tips

=head2 How do I suppress output from Log::Minimal?

Log::Minimal outputs logs to STDERR by default.

    $Log::Minimal::PRINT = sub {
        my ( $time, $type, $message, $trace,$raw_message) = @_;
        local $Test::Kantan::Level = $Test::Kantan::Level + 3;
        Test::Kantan::diag("$time [$type] $message at $trace", 1024);
    };

=head1 How do I use the testing library based on Test::Builder?

Test::Kantan replace some methods in Test::Builder.
You can use the library based on Test::Builder with Test::Kantan :)

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

moznion

Kuniwak

=cut

