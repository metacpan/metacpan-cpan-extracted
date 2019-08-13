# -*- Perl -*-
#
# Test::UnixCmdWrap - test unix commands with various assumptions

package Test::UnixCmdWrap;

use 5.24.0;
use warnings;
use Cwd qw(getcwd);
use Carp qw(croak);
use File::Spec::Functions qw(catfile);
use Moo;
use Test::Cmd ();
use Test::Differences qw(eq_or_diff);
use Test::More;
use Test::UnixExit qw(exit_is);

our $VERSION = '0.02';

has cmd => (
    is      => 'rwp',
    default => sub {
        # t/foo.t -> ./foo with restrictive sanity checks on what is
        # consided valid for a command name--"foo.sh" is not a valid
        # command name, get rid of that dangly thing at the end, or
        # manually supply your own Test::Cmd object. 38 characters is
        # the longest command name I can find on my OpenBSD 6.5 system
        if ($0 =~ m{^t/([A-Za-z0-9_][A-Za-z0-9_-]{0,127})\.t$}) {
            my $file = $1;
            return Test::Cmd->new(prog => catfile(getcwd(), $1), workdir => '');
        } else {
            croak "could not extract command name from $0";
        }
    },
);
has prog => (is => 'lazy',);

sub _build_prog { $_[0]->cmd->prog }

sub BUILD {
    my ($self, $args) = @_;
    if (exists $args->{cmd} and !ref $args->{cmd}) {
        # TODO may need to fully qualify this path depending on how that
        # interacts with chdir (or if the caller is making any of those)
        $self->_set_cmd(Test::Cmd->new(prog => $args->{cmd}, workdir => ''));
    }
}

sub run {
    my ($self, %p) = @_;

    $p{env} //= {};
    # no news is good news. and here is the default
    $p{status} //= 0;
    $p{stderr} //= qr/^$/;
    $p{stdout} //= qr/^$/;

    my $cmd  = $self->cmd;
    my $name = $cmd->prog . (exists $p{args} ? ' ' . $p{args} : '');

    local @ENV{ keys $p{env}->%* } = values $p{env}->%*;

    $cmd->run(map { exists $p{$_} ? ($_ => $p{$_}) : () } qw(args chdir stdin));

    # tests relative to the caller so the test failures don't point at
    # lines of this function
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    exit_is($?, $p{status}, "STATUS $name");
    # for some commands a regex suffices but for others want to compare
    # expected lines NOTE this is sloppy about trailing whitespace which
    # many but not all things may be forgiving of
    if (ref $p{stdout} eq 'ARRAY') {
        eq_or_diff([ map { s/\s+$//r } split $/, $cmd->stdout ],
            $p{stdout}, 'STDOUT ' . $name);
    } else {
        ok($cmd->stdout =~ m/$p{stdout}/, 'STDOUT ' . $name)
          or diag 'STDOUT ' . $cmd->stdout;
    }
    ok($cmd->stderr =~ m/$p{stderr}/, 'STDERR ' . $name)
      or diag 'STDERR ' . $cmd->stderr;

    # for when the caller needs to poke at the results for something not
    # covered by the above
    return $cmd;
}

1;
__END__

=head1 NAME

Test::UnixCmdWrap - test unix commands with various assumptions

=head1 SYNOPSIS

in C<./t/echo.t> and assuming that an C<./echo> exists...

  use Test::More;
  use Test::UnixCmdWrap;

  # create testor for ./echo
  my $echo = Test::UnixCmdWrap->new;

  # the program being tested
  $echo->prog;

  # tests stdout, and that there is no stderr, and that the exit
  # status word is 0
  $echo->run(
    args   => 'foo bar',
    stdout => qr/^foo bar$/,
  );

  # illustration of various possible parameters, and the array
  # test form for stdout
  $echo->run(
    chdir  => '/etc',
    env    => { PATH => '/foo', MANPATH => '/bar', },
    stdin  => 'some input',
    stdout => [ '' ],
    stderr => qr/^$/,
  );

  # custom 'cmd' constructor instead of the default
  Test::UnixCmdWrap->new( cmd => './script/echo' );
  # same, only being even more verbose
  Test::UnixCmdWrap->new( cmd =>
    Test::Cmd->new(prog => './script/echo', workdir => '')
  );

  done_testing();

=head1 DESCRIPTION

C<Test::UnixCmdWrap> wraps L<Test::Cmd> and provides automatic filename
detection of the program being tested, and tests the exit status word,
stdout, and stderr of each program run. Various other parameters can be
used to customize individual program runs.

These are very specific tests for unix commands that behave in specific
ways (known exit status word for given inputs, etc) so this module will
not suit more generic needs (which is what more generic modules like
L<Test::Cmd> are for).

=head1 ATTRIBUTES

=over 4

=item B<cmd>

Read-only attribute containing the L<Test::Cmd> object associated with
the command being tested. This is created by default from C<$0> on the
assumption that C<t/foo.t> contains tests for the program C<./foo>,
unless you specify otherwise when calling B<new>.

=item B<prog>

Read-only program name being tested. May or may not be a fully qualified
path to the program.

=back

=head1 METHODS

=over 4

=item B<new> [ I<cmd> => ... ]

Makes a new object. Supply a custom B<cmd> attribute if the default for
C<cmd> does not work for you.

=item B<run> ...

Runs the command. Various parameters can be added to adjust the inputs
to the command and expected results. By default the command is assumed
to exit with status code C<0>, and emit nothing to stdout, and nothing
to stderr. Parameters:

=over 4

=item I<chdir>

Optional directory to I<chdir> into prior to the test (passed to
L<Test::Cmd> as C<chdir> flag for B<run>).

=item I<env>

Optional hash reference with local elements to add to C<%ENV> during the
test. Other envrionment variables may need to be deleted from C<%ENV>
prior to the tests, this only adds.

=item I<status>

Optional unix exit status word, by default C<0>. See L<Test::UnixExit>
for the more complicated forms this value supports.

=item I<stderr>

Optional regular expression to check the standard error of the command
against, empty string by default.

=item I<stdin>

Optional input to pipe to the program.

=item I<stdout>

Optional regular expression or array reference to check the standard
output of the command against, empty string by default.

=back

B<run> returns the L<Test::Cmd> object, if subsequent tests need to do
more with that object. Each call to B<run> runs three tests, if you are
keeping track for B<done_testing>.

=back

=head1 BUGS

Patches might best be applied towards:

L<https://github.com/thrig/Test-UnixCmdWrap>

=head2 Known Issues

Need to standardize on whether the program name is always qualified or
not (complicated by the user possibly passing in a L<Test::Cmd> object
with something else set).

=head1 SEE ALSO

L<Test::Cmd>, L<Test::Differences>, L<Test::More>, L<Test::UnixExit>

https://github.com/thrig/scripts/

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
