#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------


package ePortal::App::Organizer::Organizer;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ExtendedACL/;

    use ePortal::Utils;
    use ePortal::Global;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'Organizer';
    $p{drop_admin_priv} = 1;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{private} ||= {
            dtype => 'YesNo',
            label => {rus => 'Личный', eng => 'Private'},
            };
    $p{Attributes}{title} ||= {};
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{xacl_write} ||= {};
    $p{Attributes}{xacl_admin} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    # Private attribute cannot be undef
    $self->Private(0) if ! defined $self->Private;

    return $self->SUPER::validate($beforeinsert);
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # default ORDER BY clause
    $p{order_by} = 'title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
# Who can create an Organizer
############################################################################
sub xacl_check_insert   {   #03/05/03 2:55
############################################################################
    my $self = shift;

    if ($self->Private) {
        return $ePortal->username ne '';
    } else {
        return $ePortal->Application('Organizer')->xacl_check_public_org;
    }
}##xacl_check_insert


############################################################################
sub xacl_check_admin    {   #04/15/03 8:41
############################################################################
    my $self = shift;

    if ($self->check_id) { # existing Organizer
        return $self->SUPER::xacl_check_admin('xacl_admin');
    } else {
        # Is the user may create new Organizer then he may change acces rights
        return $ePortal->Application('Organizer')->xacl_check_public_org;
    }
}##xacl_check_update

############################################################################
sub delete  {   #04/09/03 11:12
############################################################################
    my $self = shift;

    my $id = $self->id;
    my $result = $self->SUPER::delete;  # will throw on ACL violation

    if ( $result ) {
        foreach my $table (qw/Notepad Category Calendar ToDo Anniversary Contact/) {
            $result += $self->dbh->do("DELETE FROM $table WHERE org_id=?", undef, $id);
        }
    }
    return $result;
}##delete

1;
