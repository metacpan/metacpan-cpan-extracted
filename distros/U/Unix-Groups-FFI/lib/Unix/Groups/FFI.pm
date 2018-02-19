package Unix::Groups::FFI;

use strict;
use warnings;
use Carp 'croak';
use Errno qw(EINVAL ERANGE);
use Exporter 'import';
use FFI::Platypus;

use constant {
  MAX_NGROUPS_MAX => 65536,
  MAX_GETGROUPLIST_TRIES => 5,
  GETGROUPLIST_COUNT_LOW => 32,
  GETGROUPLIST_COUNT_HIGH => 256,
  GETGROUPLIST_COUNT_MAX => 65536,
};

our $VERSION = '0.002';

our @EXPORT_OK = qw(getgroups setgroups getgrouplist initgroups);

our @CARP_NOT = qw(FFI::Platypus);

my $ffi = FFI::Platypus->new(lib => [undef], ignore_not_found => 1);

$ffi->attach(getgroups => ['int', 'gid_t[]'] => 'int', sub {
  my ($xsub) = @_;
  my $count = $xsub->(0, []);
  croak "$!" if $count < 0;
  return () if $count == 0;
  my @groups = (0)x$count;
  my $rc = $xsub->($count, \@groups);
  if ($rc < 0 and $! == EINVAL) {
    @groups = (0)x(MAX_NGROUPS_MAX);
    $rc = $xsub->(MAX_NGROUPS_MAX, \@groups);
  }
  croak "$!" if $rc < 0;
  return @groups[0..$rc-1];
});

$ffi->attach(setgroups => ['size_t', 'gid_t[]'] => 'int', sub {
  my ($xsub, @groups) = @_;
  my $rc = $xsub->(scalar(@groups), \@groups);
  croak "$!" if $rc < 0;
  return 0;
});

$ffi->attach(getgrouplist => ['string', 'gid_t', 'gid_t[]', 'int*'] => 'int', sub {
  my ($xsub, $user, $group) = @_;
  $user = '' unless defined $user;
  my $gid = (getpwnam $user)[3];
  do { $! = EINVAL; croak "$!" } unless defined $gid;
  $group = $gid unless defined $group;
  my ($count, $last_count, @groups) = (1, 1, 0);
  my $rc = $xsub->($user, $group, \@groups, \$count);
  my $tries = 0;
  while ($rc < 0 and $tries++ < MAX_GETGROUPLIST_TRIES) {
    if ($count <= $last_count) {
      # count too small, but didn't get a larger one
      # some implementations short-circuit so we have to guess
      if ($last_count < GETGROUPLIST_COUNT_LOW) {
        $count = GETGROUPLIST_COUNT_LOW;
      } elsif ($last_count < GETGROUPLIST_COUNT_HIGH) {
        $count = GETGROUPLIST_COUNT_HIGH;
      } else {
        $count = GETGROUPLIST_COUNT_MAX;
      }
    }
    @groups = (0)x$count;
    $last_count = $count;
    $rc = $xsub->($user, $group, \@groups, \$count);
  }
  do { $! = ERANGE; croak "$!" } if $rc < 0;
  return @groups[0..$count-1];
});

$ffi->attach(initgroups => ['string', 'gid_t'] => 'int', sub {
  my ($xsub, $user, $group) = @_;
  $user = '' unless defined $user;
  my $gid = (getpwnam $user)[3];
  do { $! = EINVAL; croak "$!" } unless defined $gid;
  $group = $gid unless defined $group;
  my $rc = $xsub->($user, $group);
  croak "$!" if $rc < 0;
  return 0;
});

1;

=head1 NAME

Unix::Groups::FFI - Interface to Unix group syscalls

=head1 SYNOPSIS

  use Unix::Groups::FFI qw(getgroups setgroups getgrouplist initgroups);

  my @gids = getgroups;
  setgroups(@gids);
  my @gids = getgrouplist($username, $gid);
  initgroups($username, $gid);

=head1 DESCRIPTION

This module provides a L<FFI|FFI::Platypus> interface to several syscalls
related to Unix groups, including L<getgroups(2)>, L<setgroups(2)>,
L<getgrouplist(3)>, and L<initgroups(3)>. As such it will only work on
Unix-like operating systems.

=head1 FUNCTIONS

All functions are exported individually on demand. A function will not be
available for export if the system does not implement the corresponding
syscall.

=head2 getgroups

  my @gids = getgroups;

Returns the supplementary group IDs of the current process via L<getgroups(2)>.

=head2 setgroups

  setgroups(@gids);

Sets the supplementary group IDs for the current process via L<setgroups(2)>.
Attempting to set more than C<NGROUPS_MAX> groups (32 before Linux 2.6.4 or
65536 since Linux 2.6.4) will result in an C<EINVAL> error. Passing an empty
list of group IDs may result in unspecified behavior. The C<CAP_SETGID>
L<capability|capabilities(7)> or equivalent privilege is required.

=head2 getgrouplist

  my @gids = getgrouplist($username, $gid);
  my @gids = getgrouplist($username);

Returns the group IDs for all groups of which C<$username> is a member, also
including C<$gid> (without repetition), via L<getgrouplist(3)>. If C<$username>
does not exist on the system, an C<EINVAL> error will result.

As a special case, the primary group ID of C<$username> is included if C<$gid>
is not passed.

=head2 initgroups

  initgroups($username, $gid);
  initgroups($username);

Initializes the supplementary group access list for the current process to all
groups of which C<$username> is a member, also including C<$gid> (without
repetition), via L<initgroups(3)>. If C<$username> does not exist on the
system, an C<EINVAL> error will result. The C<CAP_SETGID>
L<capability|capabilities(7)> or equivalent privilege is required.

As a special case, the primary group ID of C<$username> is included if C<$gid>
is not passed.

=head1 ERROR HANDLING

All functions will throw an exception containing the syscall error message in
the event of an error. L<perlvar/"$!"> will also have been set by the syscall,
so you could check it after trapping the exception for finer exception
handling:

  use Unix::Groups::FFI 'setgroups';
  use Syntax::Keyword::Try;
  use Errno qw(EINVAL EPERM ENOMEM);

  try { setgroups((0)x2**16) }
  catch {
    if ($! == EINVAL) {
      die 'Tried to set too many groups';
    } elsif ($! == EPERM) {
      die 'Insufficient privileges to set groups';
    } elsif ($! == ENOMEM) {
      die 'Out of memory';
    } else {
      die $@;
    }
  }

See the documentation for each syscall for details on the possible error codes.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<POSIX>, L<credentials(7)>, L<capabilities(7)>
