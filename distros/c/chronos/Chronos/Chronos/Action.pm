# $Id: Action.pm,v 1.2 2002/08/28 14:30:57 nomis80 Exp $
#
# Copyright (C) 2002  Linux Québec Technologies
#
# This file is part of Chronos.
#
# Chronos is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Chronos is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Chronos::Action;

# This class should be considered a pure virtual.

use strict;
use Apache::Constants qw(:common);

# Standard constructor. The 'parent' property contains the Chronos object.
sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    return bless { parent => shift }, $class;
}

# This should return a description of the action, but I don't think it works.
sub description {
    my $self = shift;
    my $text = $self->{parent}->gettext;
    return $text->{"action_$self->{name}"};
}

# Returns the object. Remember that the object is almost the same as the user,
# but it's completely different.
sub object {
    my $self = shift;
    # If no object is specified, the default object is the user itself.
    return $self->{parent}->{r}->param('object') || $self->{parent}->user;
}

# This method is the default authorization function. It bases it's decision on
# wether the action is read or write and wether the user has enough privileges
# to act on the object.
sub authorized {
    my $self   = shift;
    my $user   = $self->{parent}->user;
    my $object = $self->object;
    if ( not $object ) {
        # This should never happen but we never know. Computers are sometimes
        # non-deterministic.
        return 0;
    } elsif ( $user eq $object ) {
        # A user is always allowed to do anything to himself. What a relief!
        return 1;
    } else {
        # A user wants to act on someone else. Check if that user has enough
        # privileges to do so.
        my $dbh           = $self->{parent}->dbh;
        my $user_quoted   = $dbh->quote($user);
        my $object_quoted = $dbh->quote($object);
        if ( $self->type eq 'read' ) {
            # The user want to perform a read action on the object. This is
            # usually more restrictive than a read action.
            if (
                # The object is a public_readable object
                $dbh->selectrow_array(
"SELECT public_readable FROM user WHERE user = $object_quoted"
                ) eq 'Y'
                # ...or the object has specifically allowed the user to read
                # himself.
                or $dbh->selectrow_array(
"SELECT can_read FROM acl WHERE user = $user_quoted AND object = $object_quoted"
                ) eq 'Y'
              )
            {
                # The user is allowed.
                return 1;
            } else {
                # The user is not allowed.
                return 0;
            }
        } elsif ( $self->type eq 'write' ) {
            # Same thing for a write request, except that the columns are
            # different. Note that a user could have write access but not read
            # access. It is up to chronosadmin to set the column values
            # correctly so that this does not happen.
            if (
                $dbh->selectrow_array(
"SELECT public_writable FROM user WHERE user = $object_quoted"
                ) eq 'Y'
                or $dbh->selectrow_array(
"SELECT can_write FROM acl WHERE user = $user_quoted AND object = $object_quoted"
                ) eq 'Y'
              )
            {
                return 1;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
}

# An action is by default not a redirect action.
sub redirect {
    return 0;
}

# An action is by default not a freeform action.
sub freeform {
    return 0;
}

1;

# vim: set et ts=4 sw=4 ft=perl:
