package Test::Unix::User;

# Copyright (c) 2005 Nik Clayton
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

use warnings;
use strict;

use Test::Builder;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(user_ok homedir_ok);

my $Test = Test::Builder->new;

use User::pwent;
use File::stat;

my @USER_FIELDS = qw(name passwd uid gid change age quota
		     comment class gecos dir shell expire);
my %USER_FIELDS = map {$_ => 1} @USER_FIELDS;
my @HDIR_FIELDS = qw(name uid gid perm owner group);
my %HDIR_FIELDS = map {$_ => 1} @HDIR_FIELDS;

sub import {
  my($self) = shift;
  my $pack = caller;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, qw(user_ok homedir_ok));
}

=head1 NAME

Test::Unix::User - Test::Builder based tests for Unix users and home directories

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Test::Unix::User tests => 2;

    user_ok({ name => 'nik', uid => 1000, ... },
            "Verify nik's account");

    homedir_ok({ name => 'nik', perm => 0755, ... },
               "Verify nik's home directory");

Test::Unix::User B<automatically> exports C<user_ok()> and C<homedir_ok()> 
to make it easier to test whether or not the Unix users and home 
directories on the system have been correctly configured.

Test::Unix::User uses Test::Builder, so plays nicely with Test::Simple,
Test::More, and other Test::Builder based modules.

=head1 FUNCTIONS

=head2 user_ok($spec, [ $test_name ]);

user_ok() tests that an account exists that matches the given 
specification.

The specification is a hashref that consists of one or more keys.  Keys
are taken from the L<User::pwent> module, and are C<name>, C<passwd>, C<uid>,
C<gid>, C<change>, C<age>, C<quota>, C<comment>, C<class>, C<gecos>, 
C<dir>, C<shell>, and C<expire>.  Some of these may not be supported on
your platform.  See User::pwent for more details.

Each value associated with a key is the value that that entry is supposed
to have.

Only the C<name> key is mandatory, the others are optional.  If they are
not present in the specification then they are not checked.

The C<$test_name> is optional.  If it is not present then a sensible one
is generated following the form 

    Checking user '$user' ($key, $key, $key, ...)

=cut

sub user_ok {
  return unless _check_spec(@_);

  my($spec, $test_name) = @_;

  if(! defined $test_name) {
    $test_name = "Checking user '$spec->{name}'";
    $test_name .= ' (' . join(', ', sort keys %$spec) . ')';
  }

  my($u, @diag);

  $u = getpwnam($spec->{name});

  if(! defined $u) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    User '$spec->{name}' does not exist");
    return $ok;
  }

  foreach my $field (keys %$spec) {
    if(! exists $USER_FIELDS{$field}) {
      push @diag, "    Invalid field '$field' given";
      next;
    }

    if(! defined $spec->{$field} or $spec->{$field} =~ /^\s*$/) {
      push @diag, "    Empty field '$field' given";
      next;
    }

    if($u->$field ne $spec->{$field}) {
      push @diag, "    Field: $field\n";
      push @diag, "    expected: $spec->{$field}\n";
      push @diag, "         got: " . $u->$field . "\n";
    }
  }

  if(@diag) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag(@diag);
    return $ok;
  }

  return $Test->ok(1, $test_name);
}

=head2 homedir_ok($spec, [ $test_name ]);

C<homedir_ok()> checks that the home directory for a given user exists and
matches the specification.

The specification is a hashref that consists of one or more keys.  Valid
keys are C<name>, C<uid>, C<gid>, C<owner>, C<group>, and C<perm>.

The C<name> key is mandatory, the other keys are optional.  

The C<$test_name> is optional.  If it is not present then a sensible one
is generated following the form.

    Home directory for user '$user' ($key, $key, $key, ...)

Use C<uid> when you want to check the numeric user id assigned to the
directory, irrespective of the user name that is assigned to that uid.
Use C<owner> when you are interested in the name of the owner, without
being concerned about the numeric UID.  Use both of these together to
ensure that the UID and the owner name match.

C<gid> is to C<group> as C<uid> is to C<owner>.

=cut

sub homedir_ok {
  return unless _check_spec(@_);

  my($spec, $test_name) = @_;

  if(! defined $test_name) {
    $test_name = "Home directory for user '$spec->{name}'";
    $test_name .= ' (' . join(', ', sort keys %$spec) . ')';
  }

  my @diag;

  foreach my $field (keys %$spec) {
    if(! exists $HDIR_FIELDS{$field}) {
      push @diag, "    Invalid field '$field' given";
      delete $spec->{$field};
      next;
    }

    if(! defined $spec->{$field} or $spec->{$field} =~ /^\s*$/) {
      push @diag, "    Empty field '$field' given";
      delete $spec->{$field};
      next;
    }
  }
  
  my $u = getpwnam($spec->{name});

  if(! defined $u) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    User '$spec->{name}' does not exist");
    return $ok;
  }

  if(! -d $u->dir) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    Home directory '" . $u->dir . "' for '$spec->{name}' is not a directory");
    return $ok;
  }

  my $sb = stat($u->dir);

  foreach my $field (qw(uid gid)) {
    if(exists $spec->{$field}) {
      if($sb->$field != $spec->{$field}) {
        push @diag, "    Field: $field\n";
        push @diag, "    expected: $spec->{$field}\n";
        push @diag, "         got: " . $sb->$field . "\n";
      }
    }
  }

  if(exists $spec->{owner}) {
    my $owner = getpwuid($sb->uid)->name();
    if($spec->{owner} ne $owner) {
      push @diag, "    Field: owner\n";
      push @diag, "    expected: $spec->{owner}\n";
      push @diag, "         got: $owner\n";
    }
  }

  if(exists $spec->{group}) {
    my $group = getgrgid($sb->gid);
    if($spec->{group} ne $group) {
      push @diag, "    Field: group\n";
      push @diag, "    expected: $spec->{group}\n";
      push @diag, "         got: $group\n";
    }
  }

  if(exists $spec->{perm}) {
    if(($sb->mode & 07777) != $spec->{perm}) {
      push @diag, "    Field: perm\n";
      push @diag, sprintf("    expected: %04o\n", $spec->{perm});
      push @diag, sprintf("         got: %04o\n", $sb->mode & 07777);
    }
  }

  if(@diag) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag(@diag);
    return $ok;
  }

  return $Test->ok(1, $test_name);
}

sub _check_spec {
  my($spec, $test_name) = @_;
  my $sub = (caller(1))[3];

  $sub =~ s/Test::Unix::User:://;

  if(! defined $spec) {
    my $ok = $Test->ok(0, "$sub()");
    $Test->diag("    $sub() called with no arguments");
    return $ok;
  }

  if(ref($spec) ne 'HASH') {
    my $t = $test_name;
    $t = "$sub(...)" unless defined $t;
    my $ok = $Test->ok(0, $t);
    $Test->diag("    First argument to $sub() must be a hash ref");
    return $ok;
  }

  if(! exists $spec->{name} or 
     ! defined $spec->{name} or 
       $spec->{name} =~ /^\s*$/) {
    my $t = $test_name;
    $t = "$sub(...)" unless defined $t;
    my $ok = $Test->ok(0, $t);
    $Test->diag("    $sub() called with no user name");
    return $ok;
  }

  return 1;
}

1;

=head1 EXAMPLES

Verify that an account exists

    user_ok({ name => 'nik' }, "'nik' exists as a user");

Verify that the account exists, that it has a given UID, and 
that the home directory and shell match.  Omit the test name, 
rely on the default.

    user_ok({ name => 'nik', uid => 1001, dir => '/home/nik', 
	      shell => '/bin/sh');

Check that the home directory for 'nik' exists.  Use an automatically
generated test name.

    homedir_ok({ name => 'nik' });

Test that nik's home directory is owned by the 'nik' user, without
worrying what UID is assigned to that user.

    homedir_ok({ name => 'nik', owner => 'nik' });

Ensure that nik's home directory is owned by uid 1000, and that
uid 1000 maps back to the 'nik' user

    homedir_ok({ name => 'nik', uid => 1000, owner => 'nik');

Check the permissions on the home directory, and supply our own test
name.

    homedir_ok({ name => 'nik', perm => 0755 },
               "Nik's home directory is correctly set");

=head1 SEE ALSO

Test::Simple, Test::Builder, User::pwent.

=head1 AUTHOR

Nik Clayton, C<nik@FreeBSD.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-unix-user@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Unix-User>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 Nik Clayton
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut

1; # End of Test::Unix::User
