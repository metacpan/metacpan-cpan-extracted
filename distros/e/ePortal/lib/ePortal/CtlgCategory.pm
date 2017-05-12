#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software.
#
#----------------------------------------------------------------------------


package ePortal::CtlgCategory;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::ParentACL/;

    use ePortal::Utils;
    use ePortal::Global;
    use Params::Validate qw/:types/;
    use ePortal::Catalog;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{nickname} ||= {};
    $p{Attributes}{parent_id} ||= {
        dtype => 'Number',
        };
    $p{Attributes}{catnum} ||= {
        dtype => 'Number',
        default => 1,
        values => [1, 2, 3],
        };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    # Check title
    if ( $self->catnum < 1 or $self->catnum > 3 ) {
        return 'CATNUM field is out of range';
    }

    undef;
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # default ORDER BY clause
    $p{order_by} = 'parent_id,catnum,title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::Catalog;
    $C->restore($self->parent_id);
    return $C;
}##parent


############################################################################
sub delete  {   #02/09/2004 3:39
############################################################################
    my $self = shift;

    if ($self->xacl_check_delete and
        $self->catnum >= 1 and
        $self->catnum <= 3) {
        my $cn = $self->catnum;
        $self->dbh->do(
            "UPDATE CtlgItem SET Category$cn = null WHERE parent_id=? AND Category$cn=?",
            undef, $self->parent_id, $self->id);
    }

    return $self->SUPER::delete;
}##delete

1;
