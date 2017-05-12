package Test::SetupTeardown;

use strict;
use warnings;

use Test::Builder;
use Try::Tiny;

our $VERSION = 0.004;

sub new {
    my ($class, %routines) = @_;
    my $self = \%routines;
    bless $self, $class;
    $self->{begin}->() if $self->{begin};
    return $self;
}

# interrupting e.g. prove with C-c bypasses the DESTROY method, so
# trap SIGINT.  just die()-ing does not seem to work -- I just get
# bin/perl t/whatever.t.  exit(1) seems to work better.  in any case I
# don't see any output anywhere so *shrug*

sub handler {
    my $sig = shift;
    print "Test::SetupTeardown caught signal $sig, aborting\n";
    exit 1;
}

use sigtrap handler => \&handler, qw/normal-signals untrapped/;

sub run_test {
    my ($self, $description, $coderef) = @_;
    my $exception_while_running_block;

    if ($ENV{TEST_ST_ONLY}
        and $ENV{TEST_ST_ONLY} ne $description) {
        # TEST_ST_ONLY is set for another test case
        return;
    }

    Test::Builder->new->note($description);

    # Run setup() routine before each test
    $self->{setup}->() if $self->{setup};

    try {
        # Catch all exceptions thrown by the block, to be rethrown
        # later after the teardown has had a chance to run
        $coderef->();
    } catch {
        # Stash this for now
        $exception_while_running_block = $_;
    };

    # Run teardown routine after each test
    $self->{teardown}->() if $self->{teardown};

    if ($exception_while_running_block) {
        # The teardown has run now, rethrow the exception
        die $exception_while_running_block;
    }
}

sub DESTROY {
    my $self = shift;
    try {
        $self->{end}->() if $self->{end};
    } catch {
        # an exception from end() won't bubble up from DESTROY,
        # so at least we should warn
        warn $_;
    };
}

1;
__END__
=pod

=head1 NAME

Test::SetupTeardown -- Tiny Test::More-compatible module to group tests in clean environments

=head1 SYNOPSIS

  use Test::SetupTeardown;
  
  my $schema;
  my (undef, $temp_file_name) = tempfile();

  sub begin {
      say "We're about to start testing!";
  }
  
  sub setup {
      $schema = My::DBIC::Schema->connect("dbi:SQLite:$temp_file_name");
      $schema->deploy;
  }
  
  sub teardown {
      unlink $temp_file_name;
  }

  sub end {
      say "We're done testing now.";
  } 
  
  my $environment = Test::SetupTeardown->new(begin => \&begin,
                                             setup => \&setup,
                                             teardown => \&teardown,
                                             end => \&end);
  
  $environment->run_test('reticulating splines', sub {
      my $spline = My::Spline->new(prereticulated => 0);
      can_ok($spline, 'reticulate');
      $spline->reticulate;
      ok($spline->is_reticulated, q{... and reticulation state is toggled});
                         });
  
  $environment->run_test(...);

=head1 DESCRIPTION

This module provides very simple support for xUnit-style C<setup> and
C<teardown> methods.  It is intended for developers who want to ensure
their testing environment is in a known state before running their
tests, and is left in a known state after.

A similar feature is provided in L<Test::Class>, but this is
instance-based instead of class-based.  You can easily make this
closer to classes with a little work though.

=head1 METHODS

=head2 new

  my $environment = Test::SetupTeardown->new(setup => CODEREF,
                                             teardown => CODEREF);

The constructor for L<Test::SetupTeardown>.

All of the C<begin>, C<setup>, C<teardown>, C<end> arguments are
optional (although if you leave them all out, all you've accomplished
is adding a header to your tests).

The C<begin> callback runs immediately before C<new> returns.

The C<end> callback is run by the environment object's C<DESTROY>
method.  A signal handler tries to ensure that if the tests are
interrupted by a signal, the C<DESTROY> method still runs (it normally
wouldn't).

Support for C<begin> and C<end> was added in version 0.004.  Versions
before this will simply ignore unknown callbacks.

=head2 run_test

  $environment->run_test('reticulating splines',
                         sub { ok(...); ... });

This method runs the C<setup> callback, then the tests, then the
C<teardown> callback.  If an exception is thrown in the coderef, it is
caught by C<run_test>, then the C<teardown> runs, then the exception
is thrown again (otherwise you'd get all green on your test report
since the flow would proceed to the C<done_testing;> at the end of
your test file).

No arguments are passed to either the C<setup>, C<teardown> or test
callbacks.  Perl supports closures so this has not been a problem so
far (although it might become one).

The description is displayed before the test results with
L<Test::Builder>'s C<note()> method.

A specific test run can be selected through the environment variable
C<TEST_ST_ONLY>, e.g.:

  TEST_ST_ONLY='reticulating splines' prove -lrvm t/

This will cause all test cases not called "reticulating splines" to be
completely skipped.  They will not count against the test plan, so if
you're using this feature, be sure to use no plan and call
C<done_testing> instead.

=head1 BUGS AND LIMITATIONS

Currently there is no simple way, short of editing your tests, to
leave traces of your environment when tests have failed so you can go
all forensic on your SQLite database and determine what went wrong.

=head1 SEE ALSO

L<Test::More>

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013, 2017 SFR

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
