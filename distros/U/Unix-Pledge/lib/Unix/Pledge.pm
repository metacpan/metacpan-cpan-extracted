package Unix::Pledge;

use strict;

require Exporter;

our @ISA = qw{Exporter};
our @EXPORT = qw{pledge};

our $VERSION = '0.005';

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
  pledge("stdio rpath", ["/home/$ENV{USER}/.profile"]);

  # Reading user's .profile works as expected
  open(my $fd, "<", "/home/$ENV{USER}/.profile");
  while(<$fd>) {
    print $_;
  }
 
  # Trying to open outside whitelisted path fails with file not found
  open($fd, "<", "/etc/passwd") or warn $!;

  # Trying to write will cause SIGABRT
  open($fd, ">", "/home/$ENV{USER}/.profile");

  # Abort trap (core dumped)

=head1 DESCRIPTION
 
The current process is forced into a restricted-service operating mode.
A few subsets are available, roughly described as computation, memory
management, read-write operations on file descriptors, opening of files,
networking.  In general, these modes were selected by studying the
operation of many programs using libc and other such interfaces, and
setting promises or paths.

Requires that the kernel supports the C<pledge(2)> syscall, which as of this
writing is only available in OpenBSD.

B<NOTE:> As of OpenBSD 6.0 the "whitepaths" parameter is B<disabled> as its implementation is incomplete.

The pledge function takes two parameters: "promises" and "whitepaths".

"Promises" is a space delimited string of modes which the process is promising
that it will stick to from here on out.  "Whitepaths" is an optional array ref
parameter that is useful to further limit the process to operate under specific paths
only.  Paths that are not under the whitepath will return ENOENT if you attempt
to access them.

Process violations of the previously "pledged" modes will result in
your processing being forcibly terminated via SIGABRT.  In this
way pledge serves as a capabilities framework like capsicum, systrace,
AppArmor, etc.  The difference is that pledge aims to be very easy to use
for the typical developer to sandbox their process.

Note that restrictions are one way only: you can only increase the restrictions
on your process, not relax them.

=head2 ERRORS

Unix::Pledge will croak on any errors.

=head2 EXPORT

The C<pledge> function is exported by default.

=head1 SEE ALSO

For detailed information on pledge, its parameters and errors, please see the
L<OpenBSD pledge(2) man page|http://www.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man2/pledge.2?query=pledge>.

L<Github repo|https://github.com/rfarr/Unix-Pledge>


=head1 AUTHOR

Richard Farr C<< <richard@nxbit.io> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Richard Farr

This module is licensed under the same terms as Perl itself.

=cut
