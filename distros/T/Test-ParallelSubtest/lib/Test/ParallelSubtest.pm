package Test::ParallelSubtest;
use strict;
use warnings;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

use Test::Builder::Module;
our @ISA    = qw(Test::Builder::Module);
our @EXPORT = qw(bg_subtest_wait bg_subtest max_parallel);

our @_kids;
our $_i_am_a_child = 0;

our $MaxParallel = 4;

use Carp;
use Sub::Prepend ();
use TAP::Parser;
use Test::Builder;
use Test::ParallelSubtest::Capture;

Test::Builder->new->can('subtest') or croak
                      "Need a version of Test::Builder with subtest support";

END { bg_subtest_wait() if @_kids }

Sub::Prepend::prepend(
    'Test::Builder::done_testing' => \&bg_subtest_wait
);
Sub::Prepend::prepend(
    'Test::Builder::subtest' => sub {
        # Wait for kids just before entering a subtest.
        bg_subtest_wait();

        # Wait for kids just before leaving a subtest.
        my $subtests = $_[2];
        $_[2] = sub {
            $subtests->();
            bg_subtest_wait();
        };
    }
);

sub import_extra {
    my ($class, $list) = @_;

    my @other;
    while (@$list >= 2) {
        my $item = shift @$list;
        if ($item eq 'max_parallel') {
            max_parallel(shift @$list);
        }
        else {
            push @other, $item;
        }
    }

    @$list = @other;

    return;
}

sub max_parallel (;$) {
    my $new_value = shift;

    my $old_value = $MaxParallel;
    if (defined $new_value) {
        $new_value =~ /^[0-9]+\z/ or croak "non-numeric max_parallel value";
        $MaxParallel = $new_value;
    }

    return $old_value;
}

sub bg_subtest ($&) {
    my ($name, $subtests) = @_;

    $_i_am_a_child and croak "bg_subtest() called from a child process";

    my $tb = Test::Builder->new;

    if ($MaxParallel < 1) {
        # We've been told not to fork.
        return $tb->subtest($name, $subtests);
    }

    while (@_kids >= $MaxParallel) {
        _wait_for_next_kid();
    }

    my ($read_pipe, $write_pipe, $pid) = _pipe_and_fork();

    if (!defined $pid) {
        # Can't fork, fall back to a subtest() call.
        return $tb->subtest($name, $subtests);
    }

    my $out_fh  = $tb->output;
    my $fail_fh = $tb->failure_output;
    my $todo_fh = $tb->todo_output;

    if ($pid) {
        # parent
        close $write_pipe;
        my @caller = caller();
        push @_kids, {
            Pid      => $pid,
            Ppid     => $$,
            Pipe     => $read_pipe,
            Out      => [$out_fh, $fail_fh, $todo_fh],
            TestName => $name,
            Caller   => "$caller[1] line $caller[2]",
        };
        return;
    }
    else {
        # child
        close $read_pipe;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        _child($write_pipe, $name, $subtests);
    }
}

sub _child {
    my ($write_pipe, $name, $subtests) = @_;

    $_i_am_a_child = 1;

    # Capture the outputs of the subtest as strings.
    my $outer_out  = '';
    my $outer_fail = '';
    my $outer_todo = '';
    my $tb = Test::Builder->new;
    $tb->output(\$outer_out);
    $tb->failure_output(\$outer_fail);
    $tb->todo_output(\$outer_todo);

    # Capture the outputs of tests within the subtest for replay
    # in the parent.
    my $capture = Test::ParallelSubtest::Capture->new;

    $tb->subtest($name, sub {
        $capture->install($tb);
        $subtests->();
    });

    # Pass all the captured output to the parent process.
    _len_prefixed_writes($write_pipe,
        \$outer_out, \$outer_fail, \$outer_todo, $capture->as_string_ref
    );

    close $write_pipe;

    no warnings 'redefine';
    *Test::Builder::DESTROY = sub {}; # For T::B fork in subtest bug
    exit(0);
}

sub bg_subtest_wait {
    return if $_i_am_a_child;
    
    _wait_for_next_kid() while @_kids;
}

sub _pipe_and_fork {
    my ($read_pipe, $write_pipe, $pid);

    while (1) {
        my $pipe_ok = pipe $read_pipe, $write_pipe;
        if ($pipe_ok) {
            $pid = fork;
            if (defined $pid) {
                return ($read_pipe, $write_pipe, $pid);
            }
        }

        if (@_kids) {
            # The pipe or fork failure could be due to a resource limit,
            # reap a kid and try again.
            _wait_for_next_kid();
        }
        else {
            # No kids and pipe+fork won't work, give up.
            return;
        }
    }
}

sub _wait_for_next_kid {
    my $kid = shift @_kids;

    return unless $kid and $kid->{Ppid} == $$;

    my $tb = Test::Builder->new;
    my ($out_dest, $fail_dest, $todo_dest) = @{ $kid->{Out} };

    my ($outer_out, $outer_fail, $outer_todo, $inner_capture)
                                      = _len_prefixed_reads($kid->{Pipe}, 4);

    waitpid $kid->{Pid}, 0; # Don't let zombies build up.

    if (!defined $outer_out) {
        my $name = "failed child process for '$kid->{TestName}'";
        _run_test_from_kid_in_parent(0, $name, undef, undef, <<END);
ERROR: bg_subtest "$kid->{TestName}" ($kid->{Caller}) aborted:
       Lost contact with the child process.
END
        return;
    }

    my ($ok, $name, $todo, $skip) = _parse_outer_output_line($$outer_out);

    if (!defined $ok) {
        $name = "parse child output for '$kid->{TestName}'";
        _run_test_from_kid_in_parent(0, $name, undef, undef, <<END);
ERROR: bg_subtest "$kid->{TestName}" ($kid->{Caller}) aborted:
       Parsing failure in Test::ParallelSubtest - cannot parse:
       [$$outer_out]
END
        return;
    }

    if (defined $todo and $Test::Builder::VERSION >= 0.95_02) {
        # Recent Test::Builder redirects the fail output to the todo
        # output for a todo subtest.
        $fail_dest = $todo_dest;
    }

    my $cap = Test::ParallelSubtest::Capture->new($inner_capture);
    if ( ! $cap->replay_writes($out_dest, $fail_dest, $todo_dest) ) {
        $name = "garbled child output for '$name'";
        _run_test_from_kid_in_parent(0, $name, undef, undef, <<END);
ERROR: bg_subtest "$name" ($kid->{Caller}) aborted:
       Garbled captured output from the child process
END
        return;
    }

    _run_test_from_kid_in_parent($ok, $name, $todo, $skip);

    print $fail_dest $$outer_fail;
    print $todo_dest $$outer_todo;
}

sub _run_test_from_kid_in_parent {
    my ($ok, $name, $todo, $skip, $internal_failure) = @_;

    no warnings 'redefine';
    local *Test::Builder::todo    = sub { $todo };
    local *Test::Builder::in_todo = sub { defined $todo };

    my $tb = Test::Builder->new;
    
    if ($internal_failure) {
        $tb->ok($ok, $name);
        $tb->diag($internal_failure);
    }
    elsif (defined $skip) {
        $tb->skip($skip);
    }
    else {
        _ok_without_diag_output($tb, $ok, $name);
    }
}

sub _ok_without_diag_output {
    my ($tb, $pass, $name) = @_;

    my $discard = '';
    my $save_fail = $tb->failure_output;
    my $save_todo = $tb->todo_output;
    $tb->failure_output(\$discard);
    $tb->todo_output(\$discard);

    $tb->ok($pass, $name);

    $tb->todo_output($save_todo);
    $tb->failure_output($save_fail);
}

sub _parse_outer_output_line {
    my $output = shift;

    while ($output =~ s/^(\s*#\s*.*\n)//) {
        _print_to(Test::Builder->new->output, $1);
    }
    $output =~ s/^\s*//; # it may have been generated within a subtest

    my $parser = TAP::Parser->new( { tap => $output } ) or return;
    my $result = $parser->next or return;
    $result->is_test or return;

    my $ok = $result->is_actual_ok;
    my $name = $result->description;
    $name =~ s/- //;
    $name =~ s/\\#/#/g;
    my $todo = $result->has_todo ? $result->explanation : undef;
    my $skip = $result->has_skip ? $result->explanation : undef;

    return ($ok, $name, $todo, $skip);
}

sub _len_prefixed_writes {
    my ($fh, @data) = @_;

    print $fh map { pack('N', length $$_) . $$_ } @data;
}

sub _len_prefixed_reads {
    my ($fh, $count) = @_;

    my @results;
    while ($count--) {
        my $lenbuf = '';
        read $fh, $lenbuf, 4 or return;
        length($lenbuf) == 4 or return;
        my $wantlen = unpack 'N', $lenbuf;

        my $buf = '';
        if ($wantlen) {
            read $fh, $buf, $wantlen or return;
            length($buf) == $wantlen or return;
        }
        push @results, \$buf;
    }

    return @results;
}

sub _print_to {
    my ($dest, $msg) = @_;

    if (ref $dest =~ /^SCALAR/) {
        $$dest .= $msg;
    } else {
        print {$dest} $msg;
    }
}

1;

__END__

=head1 NAME

Test::ParallelSubtest - fork subtests to run in parallel

=head1 SYNOPSIS

  use Test::More tests => 2;
  use Test::ParallelSubtest max_parallel => 8;

  bg_subtest test_one => sub {
      # tests here run in a sub-process
  };

  bg_subtest test_two => sub {
      # tests here run in another sub-process
  };

=head1 DESCRIPTION

This module allows a test script to run subtests (see L<Test::More/subtest>)
in the background, using a forked sub-processes for each subtest.  Several
background subtests can be run in parallel, saving time.  Particularly handy
if you have lots of tests that sleep for a second or two.

Background subtest output is buffered and merged, so that output from
different child processes doesn't get mixed up.  A test script using
bg_subtest() should produce exactly the same results as it would if the
bg_subtest() calls were replaced with subtest() calls, subject to a few
L</LIMITATIONS>.

=head1 FUNCTIONS

The following functions are exported by default.

=over

=item B<bg_subtest>

    bg_subtest $name => \&code;

As L<Test::More/subtest>, except that the subtest is run in the background
in a forked sub-process.  The test script's execution continues immediately,
while the child process runs the subtest.  The results of the background
subtest will be captured in the child process, and later passed to the
parent process and merged.

If the fork() system call is not available then bg_subtest() just does a
regular subtest().

=item B<bg_subtest_wait>

Waits for all currently running bg_subtest child processes to complete, and
merges the child process output and test results into the parent process.

There is an implicit call to bg_subtest_wait() each time any of the following
occur:

=over

=item

execution enters or leaves a subtest()

=item

done_testing() is called, see L<Test::More/done_testing>

=item

execution reaches the end of the test script

=back

You do not normally need to call bg_subtest_wait() manually, but see
L</LIMITATIONS> below for why you might want to.

=item B<max_parallel>

    my $old_max_parallel = max_parallel 8;

Gets (and optionally sets) the maximum number of background subtests that
will be run in parallel.  The default is 4.

If called without arguments, max_parallel() just returns the current value.

If an argument is passed it becomes the new value.  The old value is returned.

If the parallel subtest limit is set to 0 then subtests will not be run
in sub-processes and bg_subtest() will act just like subtest().

The limit can also be accessed directly as
B<$Test::ParallelSubtest::MaxParallel>, which allows you to localize a change:

   {
      # Lots of parallelism for this next bit.
      local $Test::ParallelSubtest::MaxParallel = 20;

      #...
   }

The parallel subtest limit can be set when B<Test::ParallelSubtest> is
imported:

   use Test::ParallelSubtest max_parallel => 10;

=back

=head1 LIMITATIONS

=head2 bg_subtest return value doesn't indicate pass/fail

The return value of subtest() tells you whether or not the subtest passed,
but bg_subtest() can't do that because it returns before the subtest is
complete.

bg_subtest() returns false when it launches the subtest in a child
process.

=head2 bg_subtest side effects are lost

Because bg_subtest() runs your code in a forked sub-process, any side effects
of the code will not be visible in the parent process or other bg_subtest
child processes.

Note however that you should not B<rely> on bg_subtest() side effects being
lost, since bg_subtest() reverts to running the subtest in the parent process
if fork() is not working.

=head2 parent tests may complete before bg_subtests started earlier

If you run tests in the parent process while background subtests are running,
then the parent process tests will take effect first.  For example, consider
the test script:

   subtest foo => sub {
       plan tests => 1;
       ok 1, 'foo inner';
   };
   ok 1 'bar';

   # prints:
   #      1..1
   #      ok 1 - foo inner
   #  ok 1 - foo
   #  ok 2 - bar

On the other hand, the equivalent bg_subtest script:

   bg_subtest foo => sub {
       plan tests => 1;
       ok 1, 'foo inner';
   };
   ok 1 'bar';

   # prints:
   #  ok 1 - bar
   #      1..1
   #      ok 1 - foo inner
   #  ok 2 - foo

This happens because the 'bar' test runs in the parent process before the
parent merges the results of the background subtest.  Out of order test
results can be prevented by adding bg_subtest_wait() calls to the test
script.

=head1 AUTHOR

Nick Cleaton, E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Nick Cleaton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
