# -*- Perl -*-
#
# some utility routines for scripts

package Unix::ScriptUtil;
our $VERSION = '0.02';

use 5.10.0;
use strict;
use warnings;
use Carp qw(croak);
use POSIX qw(setsid);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK =
  qw(cd brun diropen fileopen pipe_close pipe_from pipe_to solitary timeout);

sub cd { chdir($_[0]) or croak("chdir $_[0] failed: $!") }
sub brun { system({ $_[0] } @_) == 0 or croak("system '@_' failed: $?") }

sub diropen {
    opendir(my $dh, $_[0]) or croak("opendir $_[0] failed: $!");
    return $dh;
}

# fileopen - kind of like what File::Open provides?
{
    # more or less stolen from fopen(3)
    my %fomap = (
        'r'  => '<',
        'w'  => '>',
        'r+' => '+<',
        'w+' => '+>',
        'a'  => '>>',
        'a+' => '+>>',
    );

    sub fileopen {
        my ($file, $how) = @_;
        my $way = $fomap{ $how // 'r' } // croak("unknown open method $how");
        open(my $fh, $way, $file) or croak("open $how '$file' failed: $!");
        return $fh;
    }
}

sub pipe_close {
    close($_[0]) or croak($! ? "close failed: $!" : "pipe command failed: $?");
}

# NOTE these next two may invoke sh in certain cases
sub pipe_from {
    open(my $fh, '-|', @_) or croak("exec '@_' failed: $!");
    return $fh;
}

sub pipe_to {
    open(my $fh, '|-', @_) or croak("exec '@_' failed: $!");
    return $fh;
}

# similar to disown (as seen in ZSH) but also with a chdir because where
# the process lives probably needs to be thought about (where *.core
# files may go, could be on a network mount, ...). the double-fork
# prevents the chdir/etc from altering the original process and should
# help disassociate things from any controlling terminal
sub solitary {
    my $dir = shift;
    my $pid = fork() // croak("fork failed: $!");    # child 1
    if ($pid == 0) {
        chdir($dir) or croak("chdir $dir failed: $!");
        open(*STDIN,  '<', '/dev/null') or croak("can read /dev/null: $!\n");
        open(*STDOUT, '>', '/dev/null') or croak("can write /dev/null: $!\n");
        my $pid = fork() // croak("fork failed: $!\n");    # child 2
        exit if $pid;                                      # child 1

        # NOTE beyond here original process will have no idea whether
        # the solitary process (child 2) fails any of these
        setsid() == -1 and die("setsid failed: $!\n");
        open(*STDERR, '>&', *STDOUT) or die("dup failed: $!\n");
        exec { $_[0] } @_;
        die("exec failed: $!\n");
    } else {
        wait();    # for child 1
        croak("child error: $?") if $? != 0;
    }
}

sub timeout {
    my ($duration, $fn) = @_;
    eval {
        local $SIG{ALRM} = sub { die("timeout\n") };
        alarm($duration);
        $fn->();
        alarm(0);
    };
    if ($@) {
        die unless $@ eq "timeout\n";
        croak($@);
    }
}

1;
__END__

=head1 NAME

Unix::ScriptUtil - some utility routines for scripts

=head1 SYNOPSIS

  use Unix::ScriptUtil
    qw(cd brun diropen fileopen
       pipe_close pipe_from pipe_to
       solitary timeout);

  cd '/some/dir';           # or croaks
  brun qw[some command];    # or croaks
  my $dh = diropen '.';     # or croaks
  my $fh = fileopen 'file'; # or croaks
  my $pf = pipe_from qw[some command]; # or croaks (maybe)
  my $pt = pipe_to   qw[some command]; # or croaks (maybe)

  solitary '/some/dir', qw[some command]; # or croaks (maybe)

  timeout 3, sub { brun qw[sleep 5] }; # croaks (or should)

=head1 DESCRIPTION

L<Unix::ScriptUtil> contains various utility functions to assist with
scripts; these may optionally be exported into the caller for easy use.
The functions tend to "do it or die" (in truth mostly B<croak>) to cut
down on boilerplate error handling.

Some effort is taken to avoid having calls route through the shell
though the B<pipe_from> and B<pipe_to> may call C<sh> under certain
circumstances.

=head1 FUNCTIONS

=over 4

=item B<cd> I<dir>

Like B<chdir> but calls B<croak> if that fails.

=item B<brun> I<command>, I<args ..>

Like B<system> but calls B<croak> if the exit status word is not C<0>.

=item B<diropen> I<directory>

Like B<opendir> but dies if the I<directory> cannot be opened. Returns a
directory handle.

=item B<fileopen> I<file>, I<mode>

Returns a filehandle to the I<file> or calls B<croak> if something went
awry. I<mode> is based on L<fopen(3)> and C<r> is the default, so

  fileopen($file, 'r'); # default, is like open(..., '<'
  fileopen($file, 'w'); # is like '>'
  fileopen($file, 'a'); # is like '>>'

and so forth are supported; see the source code for the exact list.
C<r+> is probably better than C<w+> unless you do want to clobber the
file first.

=item B<pipe_close> I<fh>

Wrapper around B<close> that checks C<$!> or C<$?> for where an error
may be hiding, and calls B<croak> if there is one.

=item B<pipe_from> I<command>, I<args ..>

Returns a filehandle (or B<croaks>) that can be used to read output from
the I<command>. Note that some error conditions will only be available
when the filehandle is closed, consider

  # fails on pipe_to()
  $fh = pipe_to "nosuchcommand.$$";

  # fails on close()
  $fh = pipe_to 'false';
  pipe_close $fh;

=item B<pipe_to> I<command>, I<args ..>

As previous only returns a filehandle that can be used to print output
to the input of the I<command>. Use something else if you need a
bi-directional pipe.

=item B<solitary> I<directory>, I<command>, I<args ..>

Forks the given I<command>, running it in the given I<directory> with a
new session (via L<setsid(2)>) and STDIN, STDOUT, and STDERR reopened to
C</dev/null>. Will B<croak> on various errors though various failure may
be hidden behind the double-fork and output reopens.

=item B<timeout> I<duration>, I<coderef>

A small wrapper around C<alarm>. Runs the given I<coderef> but throws an
error if the code takes longer than I<duration> to run. Will B<die> if
there is a non-timeout error. The I<coderef> should not directly or
indirectly mess around with the C<ALRM> signal handler.

=back

=head1 ENCODING

No particular encoding is assumed or enforced by this module. If
necessary use B<binmode> on the filehandles or the L<open> module to set
the desired encoding.

=head1 WHY NOT JUST WRITE A SHELL SCRIPT

C<tl;dr> if you catch yourself doing something complicated in a shell
script (like using logic, looping over data, etc) it's probably time to
use some other language.

  $ which bash
  which: bash: Command not found.

=head2 Silent Data Loss

  $ (echo data; echo -n loss) | while read line; do echo $line; done
  data
  $ 

there is the less buggy

  while IFS= read line || [ -n "$line" ]; do ...

but that is a verbose and slow way to say in Perl

  while (my $line = readline) { ...

=head2 Crouching TRS-80 Hidden Child Process

The shell will sometimes run code in some other process, so something
simple like setting a variable to use later

  $ x=FALSE; echo foo | while read line; do x=TRUE; done; echo $x         
  FALSE

confounds you (a prime motivator for this module).

=head2 POSIX Word Split Glob

The shell command

  foocmd $arg

may be totally unsafe due to the invisible POSIX split and then glob on
C<$arg> that is actually something like the following in Perl

  system 'foocmd', map { glob } split /[\n \t]/, $arg;

especially if a file path has a space in the name and C<rm -rf> is
the command.

A safer shell command might disable options processing, quote the
variable to turn off the word split glob fun, and could check for
errors,

  foocmd -- "$arg" "$and" "$another" || exit 1

which in this module could be written as

  brun qw[foocmd --], $arg, $and, $another;

or better yet

  brun qw[foocmd --], @args;

=head1 BUGS

Patches might best be applied towards:

L<https://github.com/thrig/Unix-ScriptUtil>

=head1 SEE ALSO

L<autodie> is another way to make calls always blow up.

B<fileopen> is probably very similar to L<File::Open>. See also
L<File::Slurper> for routines to get file contents into and out of perl
data structures. Also L<File::AtomicWrite> if you are worried about the
filesystem corrupting the data or want more atomicity when adjusting the
contents of files.

There exist various other IPC and system modules that may better suit
your needs, e.g. L<IPC::Run>, L<IPC::System::Simple>, etc.
L<Capture::Tiny> can be used to collect or hide output from programs.

Something like L<Parallel::PreFork> may be necessary if you want to keep
tabs on child processes, unlike the fire and forget B<solitary>.

L<Import::Into> or L<Import::Base> can cut down on script boilerplate
C<use> statements.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
