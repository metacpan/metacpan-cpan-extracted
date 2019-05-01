package Unix::Pledge;

use strict;

require Exporter;

our @ISA = qw{Exporter};
our @EXPORT = qw{pledge unveil};

our $VERSION = '0.006';

require XSLoader;
XSLoader::load('Unix::Pledge', $VERSION);

1;
__END__

=head1 NAME

Unix::Pledge - restrict system operations

=head1 SYNOPSIS

  use Unix::Pledge;

  # ...
  # Program initializtion, open files, drop privileges, fork, etc
  # ...

  # Now that we're initialized, limit our process to reading our .profile
  unveil("$ENV{HOME}/.profile", "r");
  unveil; # To ensure unveil can no longer be called
  pledge("stdio rpath"); # ... which this does also

  # Reading user's .profile works as expected
  open(my $fd, "<", "$ENV{HOME}/.profile");
  while(<$fd>) {
    print $_;
  }

  # Trying to open outside whitelisted path fails with file not found
  open($fd, "<", "/etc/passwd") or warn $!;

  # Trying to write will cause SIGABRT
  open($fd, ">", "$ENV{HOME}/.profile");

  # Abort trap (core dumped)

=head1 DESCRIPTION

The current process is forced into a restricted-service operating mode.
A few subsets are available, roughly described as computation, memory
management, read-write operations on file descriptors, opening of files,
networking.  In general, these modes were selected by studying the
operation of many programs using libc and other such interfaces, and
setting promises or paths.

Requires that the kernel supports the L<pledge(2)> and L<unveil(2)>
system calls, which as of this writing are only available in OpenBSD.

There are two types of restriction which can be made: Restrict the set
of system calls which can be made with L</pledge> or the files which
can be accessed with L</unveil>.

=head1 pledge

The pledge function takes one or two parameters: C<promises> and
optionally C<execpromises>.

Both parameters are space-delimited strings listing modes of operation
which represent system calls that a process is asserting are the only
calls that it will make from then on. C<promises> lists the modes this
process will adhere to while C<execpromises> lists the modes that
will be adhered to after calling L<exec>.

To set C<execpromises> only, C<promises> can be passed as undef or the
empty string. A detailed description of which calls are restricted by
which modes is available in the L<pledge(2)> manpage.

Process violations of the previously "pledged" modes will result in
the process being forcibly terminated via SIGABRT, which under normal
circumstances will dump perl's core as it quits.  In this way pledge
serves as a capabilities framework like capsicum, systrace, AppArmor,
etc.  The difference is that pledge aims to be very easy to use for
the typical developer to sandbox their process.

Note that restrictions are one way only: you can only increase the
restrictions on your process, not relax them.

Also note that if either list of promises includes C<error> then
further attempts to raise privileges will fail silently and illegal
system calls will fail rather than abort.

=head1 unveil

The unveil function takes two parameters - a directory/file path and
access mode - or none. After it has been called with no parameters
further calls to unveil will fail.

Each successive call to unveil adds a path which this process is
permitted to access. Any attempt to access a file not previously
unveiled will fail.

Full details on the difference between naming files and directories,
and their access modes are in the L<unveil(2)> manpage.

Note that, on OpenBSD at least, the kernel associates the unveiling
with the file itself not the textual path, so unveiled files which are
subsequently renamed or removed will be "lost". OpenBSD's manpage
recommends only unveiling directories.

=head2 ERRORS

Unix::Pledge will croak on any errors.

=head2 EXPORT

The L</pledge> and L</unveil> functions are exported by default.

=head1 SEE ALSO

For detailed information on pledge and unveil, their parameters and errors, please see the
OpenBSD L<pledge(2)|http://www.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man2/pledge.2>
and L<unveil(2)|http://www.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man2/unveil.2>
man pages.

L<Github repo|https://github.com/rfarr/Unix-Pledge>

=head1 AUTHOR

Richard Farr C<< <richard@nxbit.io> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Richard Farr

This module is licensed under the same terms as Perl itself.

=cut
