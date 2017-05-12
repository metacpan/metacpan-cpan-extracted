#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
# ACL (Access Control List) support for ThePersistent classes.
# For ACL to work the following attributes must exists:
#   owner varchar(64)
#   acl varchar(4000)
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::ExtendedACL - Extended Access Control Lists base
class for persistent objects.

=head1 SYNOPSIS

B<ePortal::ThePersistent::ExtendedACL> implements extended processing of ACL
based on SQL queries.

Two attributes are mandatory for C<ePortal::ThePersistent::ExtendedACL>:

 uid - user name of object owner
 xacl_read - read access to the object


=head1 METHODS

=cut

package ePortal::ThePersistent::ExtendedACL;
    use base qw/ePortal::ThePersistent::ACL/;
    our $VERSION = '4.5';

    use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang

    use Params::Validate qw/:types/;
    use Error qw/:try/;
    use ePortal::Exception;



=head2 initialize()

Overloaded method. Adds ACL specific attributes C<uid> and C<xacl_read> to
the object.

Additional parameters:

=over 4

=item * xacl_uid_field

Redefine standard C<uid> attribute name to something another.

=item * xacl_read_field

Redefine standard C<xacl_read> attribute name to something another.

=back

=cut

############################################################################
sub initialize  {   #04/25/02 10:29
############################################################################
    my ($self, %p) = @_;

    # save for future some special field names
    foreach (qw/ xacl_uid_field xacl_read_field /) {
        $self->{$_} = $p{$_};
        delete $p{$_};
    }

    # Add mandatory ExtendedACL attributes
    $p{Attributes}{xacl_read}  ||= {};
    $p{Attributes}{uid}{dtype} ||= 'VarChar';
    $p{Attributes}{uid}{maxlength} ||= 64;
    $p{Attributes}{uid}{label} ||= {rus => 'Владелец', eng => 'Owner'};

    # Call SUPER initialization function. No additional parameters!
    $self->SUPER::initialize(%p);
}##initialize



=head2 xacl_where()

Construct SQL WHERE clause based on C<uid> and C<xacl_read> fields.

=cut

############################################################################
sub xacl_where  {   #11/05/02 4:31
############################################################################
    my $self;

    $self = shift @_ if (ref($_[0]));
    my $xacl_field = shift || 'xacl_read';
    my $uid_field = shift || 'uid';
    my ($XACL_WHERE, @BINDS);

    if ($self and $self->{xacl_uid_field}) {
        $uid_field = $self->{xacl_uid_field};
    }
    if ($self and $self->{xacl_read_field}) {
        $xacl_field = $self->{xacl_read_field};
    }

    my $username = $ePortal->username;
    if ($ePortal->isAdmin and !$self->{drop_admin_priv}) {
        # no restrictions for Admin
    } elsif ($username eq '') {
        # restrictions for anonyous user
        $XACL_WHERE = "($xacl_field='everyone')";
    } else {
        my @groups = $ePortal->user->member_of;
        my $groups_placeholder = join(',', map('?', @groups));
        $XACL_WHERE = "(($xacl_field='everyone') OR ($xacl_field='registered') OR
            ($xacl_field='uid:$username') OR ($xacl_field='owner' AND $uid_field=?)";
        push @BINDS, $username;
        if (@groups) {
            $XACL_WHERE .= " OR ($xacl_field in ($groups_placeholder))";
            push @BINDS, map("gid:$_", @groups);
        }
        $XACL_WHERE .= ')';
    }

    return ($XACL_WHERE, @BINDS);
}##xacl_where




=head2 xacl_check_read()

Dummy function. Returns True. Read access is restricted in SQL WHERE
clause.

=cut

############################################################################
sub xacl_check_read {   #04/16/03 3:20
############################################################################
    my $self = shift;
    1;
}##xacl_check_read




=head2 restore_where()

Adds some WHERE conditions to comply with ACL.

=cut

############################################################################
sub restore_where   {   #09/05/01 4:42
############################################################################
    my ($self, %p) = @_;

    my ($xacl_where, @xacl_binds) = $self->xacl_where;
    $self->add_where( \%p, $xacl_where, @xacl_binds);

    return $self->SUPER::restore_where(%p);
}##restore_where


1;


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
