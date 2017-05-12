package VCS::CMSynergy::Users;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

=head1 NAME

VCS::CMSynergy::Users - Perl interface to Synergy user administration

=head1 SYNOPSIS

  use VCS::CMSynergy::Users;

  $hash_ref = $ccm->users;
  $ccm->users(\%user_roles);
  $ccm->add_user($user, @roles);
  $ccm->delete_user($user);
  @roles = $ccm->get_roles($user);
  $ccm->add_roles($user, @roles);
  $ccm->delete_roles($user, @roles);

=head1 DESCRIPTION

NOTE: This interface is subject to change.

  use VCS::CMSynergy;
  use VCS::CMSynergy::Users;

  my $ccm = VCS::CMSynergy->new(database => "/ccmdb/test/tut62/db");

  $ccm->add_user('jluser', qw(developer build_mgr));

=head1 METHODS

=cut

package VCS::CMSynergy;

use strict;
use warnings;
use File::Temp qw(tempfile);

use Type::Params qw( validate );
use Types::Standard qw( Optional HashRef );
use Tie::CPHash;

=head2 users

  $hash_ref = $ccm->users;
  $ccm->users($hash_ref);

The first form gets the table of users and their roles as a hash ref.
The keys are the user names and the values are array refs containing
the user's roles, e.g.

  $hash_ref = {
    'jluser'    => [ qw(developer) ],
    'psizzle'   => [ qw(developer build_mgr) ],
    ...
    };

You need not be in the I<ccm_admin> role to use this form
(because it is I<not> implemented via B<ccm users>).

The second form replaces the existing table of users and their roles
with the contents of C<$hashref>. Duplicate roles will be removed
from C<$hashref>'s values before writing back the table.
You must be in the B<ccm_admin> role to use this form.

All operations try to preserve the order of roles (L<add_roles> appends
the roles that are actually new for the user). This mostly matters for
the role listed first for a user, as Synergy uses this as default
role for the user's session when the user calls B<ccm start> without
the B<-r> option.

Newer version of Synergy treat user names case insensitively.
Hence the value returned by L</users> is actually a C<Tie::CPHash>,
a case insensitive, but case preserving hash table.

Note that the roundtrip

  $ccm->users($ccm->users);

always results in a functionally equivalent users table. The order
of user lines may have changed, though.

Note: For typical Synergy administrator usage
it is usually more convenient to use one of the methods below.

=cut

sub users
{
    my $self = shift;
    my ($users) = validate(\@_, Optional[HashRef]);

    # NOTE: For getting the list of users we use
    # "ccm attr -show users base-1:model:base" because every role can do that -
    # whereas "ccm users" requires the ccm_admin role.
    # Apparently this is not necessary for Synergy >= 7.2 (web mode):
    # anybody can run "ccm users -export FILE".
    unless ($users)
    {
        my $text = $self->get_attribute(users => $self->base_model);
        return unless defined $text;
        
        $users = {};
        tie %$users, 'Tie::CPHash';

        foreach (split(/\n/, $text))
        {
            next if /^#/;
            my ($user, $roles) = /^ \s* user \s+ (\S+) \s* = \s* (.*) ;/x;
            next unless defined $user;
            $users->{$user} = [ split(" ", $roles) ];
        }

        return $users;
    }

    my $text = "";
    while (my ($user, $roles) = each %$users)
    {
        return $self->set_error("illegal value for user `$user' (array ref expected)")
            unless ref $roles eq "ARRAY";
        return $self->set_error("no roles defined for user `$user'")
            unless @$roles;

        # remove duplicates
        my %seen;
        $text .= "user $user = " . join(" ", grep { !$seen{$_}++ } @$roles) . ";\n";
    }

    my ($rc, $out, $err);
    if ($self->version >= 7.2)          # web mode
    {
        my $tempfile = $self->_text_to_tempfile($text) or return;

        # NOTE: On Cygwin we must convert $tempfile to a native Windows
        # pathname as we are passing it to a native Windows program.
        $tempfile = _fullwin32path($tempfile) if $^O eq 'cygwin';

        ($rc, $out, $err) = $self->ccm(qw/users -import/, $tempfile);
    }
    else
    {
        ($rc, $out, $err) = $self->ccm_with_text_editor($text, qw(users));
    }
    return $self->set_error($err || $out) unless $rc == 0;
    return $users;
}

=head2 add_user

  $ccm->add_user($user, @roles);

Adds the user with the given roles.
If the user already exists her roles will be reset to the ones given.

=cut

sub add_user
{
    my ($self, $user, @roles) = @_;

    my $users = $self->users;
    return unless $users;

    $users->{$user} = \@roles;

    $self->users($users);
}

=head2 delete_user

  $ccm->delete_user($user);

Deletes the user. It is no error if the user doesn't exist.

=cut

sub delete_user
{
    my ($self, $user) = @_;

    my $users = $self->users;
    return unless $users;

    delete $users->{$user};

    $self->users($users);
}

=head2 add_roles

  $ccm->add_roles($user, @roles);

Grants the given roles to the user. It is no error if the user
already has some of the given roles.

=cut

sub add_roles
{
    my ($self, $user, @roles) = @_;

    my $users = $self->users;
    return unless $users;

    return $self->set_error("user `$user' doesn't exist")
        unless $users->{$user};

    push @{ $users->{$user} }, @roles;

    $self->users($users);
}

=head2 delete_roles

  $ccm->delete_roles($user, @roles);

Revokes the given roles from the user. It is no error if the
user doesn't have any of the given rules.

If there are no roles left, also deletes the user.

=cut

sub delete_roles
{
    my ($self, $user, @roles) = @_;

    my $users = $self->users;
    return unless $users;

    return $self->set_error("user `$user' doesn't exist")
        unless exists $users->{$user};

    # NOTE: try to preserve the order of the remaining roles
    my %del;
    @del{@roles} = ();
    my @new_roles = grep { !exists $del{$_} } @{ $users->{$user} };
    if (@new_roles)
    {
        $users->{$user} = \@new_roles;
    }
    else
    {
        delete $users->{$user};
    }

    $self->users($users);
}

=head2 get_roles

  @roles = $ccm->get_roles($user);

Returns the roles for the user. Returns an empty list
if the user doesn't exist.

=cut

sub get_roles
{
    my ($self, $user) = @_;

    my $users = $self->users;
    return unless $users;

    my $roles = $users->{$user};
    return $roles ? @$roles : ();
}

=head1 SEE ALSO

L<VCS::CMSynergy>
L<VCS::CMSynergy::Object>,
L<VCS::CMSynergy::Client>,

=head1 AUTHORS

Roderich Schupp, argumentum GmbH <schupp@argumentum.de>

=cut

1;
