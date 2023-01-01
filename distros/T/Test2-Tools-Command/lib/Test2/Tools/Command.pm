# -*- Perl -*-
#
# run simple unix commands for expected results given particular inputs

package Test2::Tools::Command;
our $VERSION = '0.11';

use 5.10.0;
use strict;
use warnings;
use File::chdir;    # $CWD
use IPC::Open3 'open3';
use Symbol 'gensym';
use Test2::API 'context';

use base 'Exporter';
our @EXPORT = qw(command);

our @command;         # prefixed on each run, followed by any ->{args}
our $timeout = 30;    # seconds, for alarm()

sub command ($) {
    local $CWD = $_[0]->{chdir} if defined $_[0]->{chdir};
    local @ENV{ keys %{ $_[0]->{env} } } = values %{ $_[0]->{env} };

    # what to run, and possibly also a string to include in the test name
    my @cmd = ( @command, exists $_[0]->{args} ? @{ $_[0]->{args} } : () );

    my ( $stdout, $stderr );
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm( $_[0]->{timeout} || $timeout );

        my $pid = open3( my $in, my $out, my $err = gensym, @cmd );
        if ( defined $_[0]->{binmode} ) {
            for my $fh ( $in, $out, $err ) { binmode $fh, $_[0]->{binmode} }
        }
        if ( exists $_[0]->{stdin} ) {
            print $in $_[0]->{stdin};
            close $in;
        }
        # this may be bad if the utility produces too much output
        $stdout = do { local $/; readline $out };
        $stderr = do { local $/; readline $err };
        waitpid $pid, 0;
        alarm 0;
        1;
    } or die $@;
    my $orig_status = $?;
    # the exit status is broken out into a hashref for exact tests on
    # the various components of the 16-bit word (an alternative might be
    # to mangle it into a number like the shell does)
    my $status = {
        code   => $? >> 8,
        signal => $? & 127,
        iscore => $? & 128 ? 1 : 0
    };
    # the munge are for when the code or signal vary (for portability or
    # for reasons out of your control) and you only want to know if the
    # value was 0 or not. lots of CPAN Tester systems did not set the
    # iscore flag following a CORE::dump by a test program...
    $status->{code}   = $status->{code}   ? 1 : 0 if $_[0]->{munge_status};
    $status->{signal} = $status->{signal} ? 1 : 0 if $_[0]->{munge_signal};

    # default exit status word is 0, but need it in hashref form
    if ( exists $_[0]->{status} ) {
        if ( !defined $_[0]->{status} ) {
            $_[0]->{status} = { code => 0, signal => 0, iscore => 0 };
        } elsif ( ref $_[0]->{status} eq '' ) {
            $_[0]->{status} = { code => $_[0]->{status}, signal => 0, iscore => 0 };
        }
        # assume that ->{status} is a hashref
    } else {
        $_[0]->{status} = { code => 0, signal => 0, iscore => 0 };
    }

    my ( $ctx, $name, $result ) = ( context(), $_[0]->{name} // "@cmd", 1 );

    if (    $_[0]->{status}{code} == $status->{code}
        and $_[0]->{status}{signal} == $status->{signal}
        and $_[0]->{status}{iscore} == $status->{iscore} ) {
        $ctx->pass("exit - $name");
    } else {
        $ctx->fail(
            "exit - $name",
            sprintf(
                "code\t%d\tsignal\t%d\tiscore\t%d want",
                $_[0]->{status}{code},
                $_[0]->{status}{signal},
                $_[0]->{status}{iscore}
            ),
            sprintf(
                "code\t%d\tsignal\t%d\tiscore\t%d got",
                $status->{code}, $status->{signal}, $status->{iscore}
            )
        );
        $result = 0;
    }
    # qr// or assume it's a string
    if ( defined $_[0]->{stdout} and ref $_[0]->{stdout} eq 'Regexp' ) {
        if ( $stdout =~ m/$_[0]->{stdout}/ ) {
            $ctx->pass("stdout - $name");
        } else {
            $ctx->fail( "stdout - $name", "expected match on $_[0]->{stdout}" );
            $result = 0;
        }
    } else {
        my $want = $_[0]->{stdout} // '';
        if ( $stdout eq $want ) {
            $ctx->pass("stdout - $name");
        } else {
            $ctx->fail( "stdout - $name", "expected equality with q{$want}" );
            $result = 0;
        }
    }
    if ( defined $_[0]->{stderr} and ref $_[0]->{stderr} eq 'Regexp' ) {
        if ( $stderr =~ m/$_[0]->{stderr}/ ) {
            $ctx->pass("stderr - $name");
        } else {
            $ctx->fail( "stderr - $name", "expected match on $_[0]->{stderr}" );
            $result = 0;
        }
    } else {
        my $want = $_[0]->{stderr} // '';
        if ( $stderr eq $want ) {
            $ctx->pass("stderr - $name");
        } else {
            $ctx->fail( "stderr - $name", "expected equality with q{$want}" );
            $result = 0;
        }
    }
    $ctx->release;
    return $result, $orig_status, \$stdout, \$stderr;
}

1;
__END__

=head1 NAME

Test2::Tools::Command - test simple unix commands

=head1 SYNOPSIS

  use Test2::Tools::Command;

  # test some typical unix tools; implicit checks are that status
  # is 0, and that stdout and stderr are the empty string, unless
  # otherwise specified
  command { args => [ 'true'        ] };
  command { args => [ 'false'       ], status => 1 };
  command { args => [ 'echo', 'foo' ], stdout => "foo\n" };

  # subsequent args are prefixed with this
  local @Test2::Tools::Command::command = ( 'perl', '-E' );

  # return values and a variety of the options available
  my ($result, $exit_status, $stdout_ref, $stderr_ref) =
   command { args    => [ q{say "out";warn "err";kill TERM => $$} ],
             chdir   => '/some/dir',
             env     => { API_KEY => 42 },
             stdin   => "printed to program\n",
             stdout  => qr/out/,
             stderr  => qr/err/,
             status  => { code => 0, signal => 15, iscore => 0 },
             timeout => 7 };

=head1 DESCRIPTION

This module tests that commands given particular arguments result in
particular outputs by way of the exit status word, standard output, and
standard error. Various parameters to the B<command> function alter
exactly how this is done, in addition to variables that can be set.

The commands are expected to be simple, for example filters that maybe
accept standard input and respond with some but not too much output.
Interactive or otherwise complicated commands will need some other
module such as L<Expect> to test them, as will programs that generate
too much output.

=head1 VARIABLES

These are not exported.

=over 4

=item B<@command>

Custom command to prefix any commands run by B<command> with, for
example to specify a test program that will be used in many
subsequent tests

  local @Test2::Tools::Command::command = ($^X, '--', 'bin/foo');
  command { args => [ 'bar', '-c', 'baz' ] };

will result in C<perl -- bin/foo bar -c baz> being run.

If I<chdir> is used, a command that uses a relative path may need to be
fully qualified, e.g. with C<rel2abs> of L<File::Spec::Functions>.

=item B<$timeout>

Seconds after which commands will be timed out via C<alarm> if a
I<timeout> is not given to B<command>. 30 by default.

=back

=head1 FUNCTIONS

B<command> is exported by default; this can be disabled by using this
module with an empty import list. The test keys are I<status>,
I<stdout>, and I<stderr>. The other keys influence how the command is
run or change test metadata.

=over 4

=item B<command> I<hashref>

Runs a command and executes one or more tests on the results, depending
on the contents of I<hashref>, which may contain:

=over 4

=item I<args> => I<arrayref>

List of arguments to run the command with. The argument list will be
prefixed by the B<@command> variable, if that is set.

=item I<binmode> => I<layer>

If set, I<layer> will be set on the filehandles wired to the command via
the C<binmode> function. See also L<open>.

=item I<chdir> => I<directory>

Attempt to C<chdir> into I<directory> or failing that will throw an
exception, by way of L<File::chdir>.

A command that uses a relative path may need to be fully qualified, e.g.
with C<rel2abs> of L<File::Spec::Functions>.

=item I<env> => I<hashref>

Set the environment for the command to include the keys and values
present in I<hashref>. This is additive only; environment variables that
must not be set must be deleted from C<%ENV>, or the command wrapped
with a command that can reset the environment, such as L<env(1)>.

=item I<name> => I<string>

Custom name for the tests. Otherwise, the full command executed is used
in the test name, which may not be ideal.

=item I<munge_signal> => I<boolean>

If the signal number of the 16-bit exit status word is not zero, the
signal will be munged to have the value C<1>.

=item I<munge_status> => I<boolean>

If the exit code of the 16-bit exit status word is not zero, the code
will be munged to have the value C<1>. Use this where the program being
tested is unpredictable as to what non-zero exit code it will use.

=item I<status> => I<code-or-hashref>

Expect the given value as the 16-bit exit status word. By default C<0>
for the exit code is assumed. This can be specified in two different
forms; the following two are equivalent:

  status => 42
  status => { code => 42, iscore => 0, signal => 0 }

Obviously the 16-bit exit status word is decomposed into a hash
reference. If the program is instead expected to exit by a SIGPIPE, one
might use:

  status => { code => 0, iscore => 0, signal => 13 }

See also I<munge_signal> and I<munge_status>.

=item I<stdin> => I<data>

If present, I<data> will be printed to the command and then standard
input will be closed. Otherwise, nothing is done with standard input.

=item I<stdout> => I<qr-or-string>

Expect that the standard output of the command exactly matches the given
string, or if the string is a C<qr//> regular expression, that the
output matches that expression.

=item I<stderr> => I<qr-or-string>

Expect that the standard err of the command exactly matches the given
string, or if the string is a C<qr//> regular expression, that the
stderr matches that expression.

=item I<timeout> => I<seconds>

Set a custom timeout for the C<alarm> call that wraps the command. The
variable B<$timeout> will be used if this is unset.

=back

B<command> returns a list consisting of the result of the tests, the
original 16-bit exit status word, and scalar references to strings
that contain the standard output and standard error of the test
program, if any.

  my ($result, $status, $out_ref, $err_ref) = command { ...

=back

=head1 BUGS

None known. There are probably portability problems if you stray from
the unix path.

=head1 SEE ALSO

L<Test2::Suite>

L<Expect> may be necessary to test complicated programs.

L<IPC::Open3> is used to run programs; this may run into portability
problems on systems that stray from the way of unix?

L<Test::UnixCmdWrap> is older and has similar functionality though
contains various warts such as being unable to run a command with the
sole argument of C<0>.

L<Test::UnixExit> has specific tests for the unix exit status word;
similar functionality is present in this module.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
