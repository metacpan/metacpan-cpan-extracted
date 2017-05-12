package Test::Unix::Group;

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
our @EXPORT = qw(group_ok);

my $Test = Test::Builder->new;

use User::pwent;
use User::grent;

my @GROUP_FIELDS = qw(name gid passwd members);
my %GROUP_FIELDS = map { $_ => 1 } @GROUP_FIELDS;

sub import {
  my($self) = shift;
  my $pack = caller;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, qw(group_ok));
}

=head1 NAME

Test::Unix::Group - Test::Builder based tests for Unix groups

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Test::Unix::Group tests => 4;

    group_ok({ name => 'wheel' }, "'wheel' must exist");
    group_ok({ name => 'wheel' }); # Auto-generate test name
    group_ok({ name => 'wheel',
               gid  => 0, }, "'wheel' must have gid 0");

    group_ok({ name => 'wheel', members => [qw(root nik)], }
             "'wheel' has the correct members");

Test::Unix::Group B<automatically> exports C<group_ok()> to make it
easier to test whether or not Unix groups have been correctly
configured.

Test::Unix::Group uses Test::Builder, so plays nicely with
Test::Simple, Test::More, and other Test::Builder based modules.

=head1 FUNCTIONS

=head2 group_ok($spec, [ $test_name ]);

group_ok() tests that a group exists and matches the given specification.

The specification is a hashref that consists of one or more keys.
Keys are taken from the L<User::grent> module, and are C<name>,
C<passwd>, C<gid>, and C<members>.  See L<User::grent> for more
details.

Each value associated with a key, except C<members>, is the value that
that entry is supposed to have.

C<members> behaves a little differently.  The C<members> key should
have an array ref as a value.  This array should contain the user
names of all the users who must be members of the group.  Note that
this is not an exclusive list, and allows for users other than those
in the list to be members of the group.  This is because it is not
practical to test all the accounts on the system to verify that they
are not members of the given group via their user account GID.

User accounts provided to the C<members> key are looked for in the
list of members explicitly listed in the group.  If they are not found
there then their account information is obtained and their account GID
is examined to see if they are members through that mechanism.

Only the C<name> key is mandatory, the others are optional.  If they
are not present in the specification then they are not checked.

The C<$test_name> is optional.  If it is not present then a sensible
one is generated following the form

    Checking group '$group' ($key, $key, $key, ...)

=cut

sub group_ok {
  my($spec, $test_name) = @_;

  if(! defined $spec) {
    my $ok = $Test->ok(0, "group_ok()");
    $Test->diag("    group_ok() called with no arguments");
    return $ok;
  }

  if(ref($spec) ne 'HASH') {
    my $ok = $Test->ok(0, 'group_ok()');
    $Test->diag("    First argument to group_ok() must be a hash ref");
    return $ok;
  }

  if(! exists $spec->{name} or 
     ! defined $spec->{name} or 
       $spec->{name} =~ /^\s*$/) {
    my $t = $test_name;
    $t = "group_ok(...)" unless defined $t;
    my $ok = $Test->ok(0, $t);
    $Test->diag("    group_ok() called with no group name");
    return $ok;
  }

  if(! defined $test_name) {
    $test_name = "Checking group '$spec->{name}'";
    $test_name .= ' (' . join(', ', sort keys %$spec) . ')';
  }

  my($g, @diag);

  $g = getgrnam($spec->{name});

  if(! defined $g) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    Group '$spec->{name}' does not exist");
    return $ok;
  }

  foreach my $field (keys %$spec) {
    if(! exists $GROUP_FIELDS{$field}) {
      push @diag, "    Invalid field '$field' given";
      next;
    }

    if(! defined $spec->{$field} or $spec->{$field} =~ /^\s*$/) {
      push @diag, "    Empty field '$field' given";
      next;
    }

    # All members in $spec->{members} must exist in the group, either
    # in the members returned by getgrnam(), or, if any are left over,
    # by checking each account's group membership.
    if($field eq 'members') {
      my %exp_members = map { $_ => 1 } @{$spec->{members}};

      delete $exp_members{$_} foreach @{$g->members};

      # Any members left?  If so, check their group ownership
      foreach my $name (sort keys %exp_members) {
	my $u = getpwnam($name);
	if(! defined $u) {
	  push @diag, "    You looked for user '$name' in group '$spec->{name}'\n";
	  push @diag, "    That account does not exist on this system";
	  next;
	}

	if($g->gid != $u->gid) {
	  push @diag, "    Field: members\n";
	  push @diag, "    expected: user '$name' with gid " . $g->gid . "\n";
	  push @diag, "         got: user '$name' with gid " . $u->gid . "\n";
	}
      }

      next;
    }

    if($spec->{$field} ne $g->$field) {
      push @diag, "    Field: $field\n";
      push @diag, "    expected: $spec->{$field}\n";
      push @diag, "         got: " . $g->$field . "\n";
      next;
    }
  }

  if(@diag) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag(@diag);
    return $ok;
  }

  return $Test->ok(1, $test_name);
}

=head1 EXAMPLES

Verify that a group exists.

    group_ok({ name => 'wheel' }, "Group 'wheel' exists");

Verify that a group exists with a given GID.  Omit the test name, rely
on the default.

    group_ok({ name => 'wheel', gid => 0 });

Verify that the group exists and contains at least the members
C<qw(root nik)>.

    group_ok({ name => 'wheel', members => [ qw(root nik) ] });

=head1 SEE ALSO

Test::Unix::User, Test::Simple, Test::Builder, User::grent.

=head1 AUTHOR

Nik Clayton, C<nik@FreeBSD.org>>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-unix-group@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Unix-Group>.
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

1; # End of Test::Unix::Group
