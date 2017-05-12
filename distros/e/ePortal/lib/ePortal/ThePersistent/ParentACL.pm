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

ePortal::ThePersistent::ParentACL - Extended Access Control Lists base
class for persistent objects based on parent object.

=head1 SYNOPSIS

B<ePortal::ThePersistent::ParentACL> implements Access Control Lists
(ACL) functions) for ThePersistent classes.

=over 4

=item *

Object is inaccessible if parent is not exists. This is VERY IMPORTANT.
Even Admin may not access this object. This is like constraint.

=item *

Object is C<readable> if parent too.

=item *

Object if C<modifiable> including ability to delete if parent allows
C<xacl_check_update()>

=item *

New object is allowed if parent allows C<xacl_check_children()> which check
by default C<xacl_check_update()>

=item *

Admin privileges is not a sense for C<ParentACL> package but defaults to
C<xacl_check_admin()> of the parent.

=back

=head1 METHODS

See
L<ePortal::ThePersistent::ExtendedACL|ePortal::ThePersistent::ExtendedACL>
for details.

=cut

package ePortal::ThePersistent::ParentACL;
    use base qw/ePortal::ThePersistent::ACL/;
    our $VERSION = '4.5';

    use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang

    use Params::Validate qw/:types/;
    use Error qw/:try/;




############################################################################
sub xacl_check  {   #11/05/02 4:31
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    my $parent = $self->parent;
    return 0 if ! $parent;

    return $parent->xacl_check($xacl_field);
}##xacl_check



############################################################################
sub restore_next    {   #10/19/01 10:35
############################################################################
    my $self = shift;

    # This object support ACL but via parent. It's not possible
    # to implement ACL checks in WHERE clause of SQL
    my $result = undef;
    while ($result = $self->SUPER::restore_next(@_)) {
        last if $self->xacl_check_read;
    }
    return $result;
}##restore_next


############################################################################
sub xacl_check_read   {   #02/26/03 9:01
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    my $parent = $self->parent;
    return 0 if ! $parent;

    return $parent->xacl_check_read($xacl_field);
}##xacl_check_read

############################################################################
sub xacl_check_update   {   #02/26/03 9:01
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    my $parent = $self->parent;
    return 0 if ! $parent;

    return $parent->xacl_check_update($xacl_field);
}##xacl_check_update

sub xacl_check_delete   { shift->xacl_check_update(@_); }

############################################################################
sub xacl_check_insert  {   #02/26/03 9:01
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    my $parent = $self->parent;
    return 0 if ! $parent;

    return $parent->xacl_check_children($xacl_field);
}##xacl_check_update


############################################################################
sub xacl_check_admin   {   #02/26/03 9:01
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    my $parent = $self->parent;
    return 0 if ! $parent;

    return $parent->xacl_check_admin($xacl_field);
}##xacl_check_admin


1;


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
