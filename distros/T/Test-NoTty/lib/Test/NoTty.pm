#!perl

use strict;
use warnings;

package Test::NoTty;

use parent qw(Exporter);
use POSIX qw(setsid _exit WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG);

our @EXPORT = 'without_tty';
our $VERSION = '0.02';

sub without_tty(&@) {
    my ($code, @args) = @_;
    pipe my $reader, my $writer
        or die "Can't pipe: $!";

    # So, "how to detach from your controlling terminal" is a subset of the "how
    # to start a daemon" dance. In (reverse) you
    #
    # 2) Call setsid when your process is not a process group leader.
    #    This detaches you from any controlling terminal
    # 1) fork, as the child process won't be a process group leader.
    #    (Your parent might be, and certainly will be if run interactively)
    #
    # The fun and games ensues because the code needs to run in the child, but
    # really we'd like to fake it (as much as possible) that the code is running
    # in the parent.

    # I'm not quite sure if how we deal with this correctly. Of if we really
    # can. A child process is really supposed to call `exec` or `_exit`. But
    # there's a chance here that we want to have real output

    # Perl before v5.14 didn't automatically load this:
    require IO::File;
    STDOUT->flush;
    STDERR->flush;
    my $pid = fork;
    die "Couldn't fork: $!"
        unless defined $pid;

    unless ($pid) {
        # We are in the child

        # We use the pipe to send (and rethrow) any regular exception.
        # By implication, we can't deal with exception objects.
        close $reader;

        eval {
            die "setsid failed: $!"
                unless setsid;

            # Likewise, a limitation is that the only function return value we
            # can easily support is an integer process exit code:
            my $exitcode = $code->(@args);
            STDOUT->flush;
            STDERR->flush;
            _exit(defined $exitcode ? $exitcode : 0);
        };

        # If you get here it's an error:
        print $writer $@
            or warn "print to error message handle failed: $!";
        close $writer
            or warn "close error message handle failed: $!";
        STDOUT->flush;
        STDERR->flush;
        kill 'ABRT', $$;
    }
    # We are in the parent

    # Try very hard to relay signals to the child. For example, if it sleeps or
    # churns forever, we want ^C to interrupt it, not take us out but leave it
    # running in the background. This isn't foolproof, but seems better than
    # doing nothing:

    my @sigs = grep { !/^__/ && !/^CH?LD$/ } keys %SIG;
    local @SIG{@sigs};
    for my $sig (@sigs) {
        $SIG{$sig} = sub {
            kill $sig, $pid
                or warn "kill $sig $pid failed: $!";
        };
    }
    close $writer;

    # "Setup" done. Let's see what the child tried to tell us:
    waitpid $pid, 0
        or die "waitpid $pid, 0 failed: $!";
    local $/;
    my $error = <$reader>;
    die $error
        if length $error;

    # This is the common case:
    return WEXITSTATUS(${^CHILD_ERROR_NATIVE})
        if WIFEXITED(${^CHILD_ERROR_NATIVE});

    die "Code called by without_tty() died with signal " . WTERMSIG(${^CHILD_ERROR_NATIVE})
        if WTERMSIG(${^CHILD_ERROR_NATIVE});

    die "Code called by without_tty() exited with unknown status ${^CHILD_ERROR_NATIVE}";
}

1;

__END__

=head1 NAME

Test::NoTty

=head1 SYNOPSIS

    without_tty(sub {
        open my $fh, '+<', '/dev/tty'
            or die "Test this code path, even when run interactively";
        ...
    });

=head1 DESCRIPTION

Test your code that handles failure to open F</dev/tty>

On a *nix system the special file F</dev/tty> always exists, and opening it
gives you a(nother) file handle attached to your controlling terminal. This is
useful if you want direct user input, such as entering passwords or passphrases,
even if C<STDIN> or C<STDOUT> are redirected.

But what happens if your code is running non-interactively? Such as servers,
cron jobs, or just CPAN testers? F</dev/tty> still exists, but opening it will
fail. Your tests need to cover this case. But how do you test your tests as you
write them, when you're running them in a terminal session?

That's the purpose of this module. It encapsulates the complex setup dance
with C<fork>, C<setsid> I<etc>, to locally drop the controlling terminal, so
that you can interactively run code to test those code paths.

=head1 SUBROUTINES

The module provides a single function and is intended for test scripts, so
exports that function by default

=head2 without_tty I<sub> I<arguments ...>

C<without_tty> calls the passed-in subroutine with the optional list of
arguments, but in an environment without a controlling terminal, and hence
where attempting to open the character device file F</dev/tty> will fail.

(With caveats) it returns the result of the passed-in subroutine, or any
exception thrown.

C<without_tty> has the prototype C<&@> to permit it to take a bare block like
this:

    without_tty {
        open my $fh, '+<', '/dev/tty'
            or die "Test this path!";
        ...
    }

This is similar to other testing helper functions, such as C<exception> in
L<Test::Fatal>.

To drop the controlling terminal, the code needs to fork a child process
and then perform some system calls. Hence the subroutine is run in a forked
child, meaning

=over 4

=item *

Side effects "don't happen" in the parent - writes to structures passed in as
references get discarded, as do changes to global state. This is both for your
code B<and any code it calls>.

=item *

You can only return a single integer (it's the child process exit code)

=item *

Exceptions are always strings - any objects get stringified

=back

This B<is> restrictive, but it's this is about as good it's possible to get. The
code absolutely has to run in a forked child to be able to drop the controlling
terminal - everything else you get has to be rebuilt by some other emulation or
cheating.

C<without_tty> throws an exception if the child process dies with a signal.
(Don't write code that relies on this to trap signals - this is error handling)

The code attempts to propagate signals to the child, so that C<control-C>,
C<control-Z> and similar work somewhat as expected when tests are run
interactively, but this also is "best effort" and more intended as "fail less
ungracefully" than "rely on this and report bugs if it fails".

It means that you're using L<Test::More> and run tests (C<is>, C<like>, I<etc>)
in your subroutine, the test counter doesn't update "outside" in the parent,
and your test script will fail. The simple solution to this - update to

    use Test2::Bundle::More;
    use Test2::IPC;

and be happy. These modules have shipped with core since v5.26.0 and most CPAN
distributions already indirectly depend on them, so likely you already have it
installed and available even if you have to target unsupported Perl versions.

=head1 RATIONALE

At work our use case is testing our database code. Its configuration has
connection parameters (database, username, password, I<etc>). We'd like to be
able to run the same code

=over 4

=item *

In production, which will always need a password from the configuration

=item *

On a development system, running tests, using the local database password

=item *

On a development system, diagnosing problems, connecting to a read-only mirror,
when the B<self-same> code prompts us for the password (kept in a secure
password store)

=back

For this, we need a configuration that is capable of meaning "prompt the user
for the password", and we have implemented this by having a password of
C<undef>. For that case we open F</dev/tty>, turn of echoing, and read in
the password (just like C<ssh> clients, database CLI tools, I<etc>)

That's fine in development, but it would be easy to make a mistake in the
production configuration and accidentally hit the same code path. We want the
code to fail early and clearly, we need to write tests for that, and we need to
test those tests interactively. Hence we want a way to "run this block of code
as if it's non-interactive". Hence this module.

To keep things as simple as possible, the work code is structured to have just
the prompt code in a private method:

    sub _prompt {
        my ($log, $fail_no_tty, $prompt_message) = @_;
        confess('No parameters to _prompt may be empty')
            unless $log and length $fail_no_tty and length $prompt_message;

        my $dev_tty = '/dev/tty';
        my $tty_fh;
        unless (open $tty_fh, '+<', $dev_tty) {
            ... # error code (which dies)
        }
        ... # prompt code
        return $password;
    }

and B<that> is all that we test with this module - all the rest is regular
regression tests.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/test-notty

=head1 AUTHOR

Nicholas Clark - C<nick@ccl4.org>
