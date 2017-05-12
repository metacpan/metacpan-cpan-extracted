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


package ePortal::App::Organizer::Category;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ParentACL/;

    use ePortal::Utils;
    use ePortal::Global;
    use Error qw/:try/;
    use ePortal::Exception;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'Organizer';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{org_id} ||= {
            label => {rus => "Органайзер", eng => "Organizer"},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => sub {
                my $self = shift;
                my $m = $ePortal->Application('Organizer')->stOrganizers(writable=>1);
                my ($values, $labels) = $m->restore_all_hash();
                push @{$values}, undef;
                $labels->{undef} = '---';
                return ($values, $labels);
            }

        };
    $p{Attributes}{title} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    if ($self->org_id == 0) {
        throw ePortal::Exception::DataNotValid(
            -text => pick_lang(rus => "Не указан Органайзер", eng => "Unknown Organizer"));
    }

    return $self->SUPER::validate($beforeinsert);
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # parent_id cannot be 0, it may be NULL
    $p{org_id} = undef if exists $p{org_id} and $p{org_id} == 0;

    # default ORDER BY clause
    $p{order_by} = 'title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::App::Organizer::Organizer;
    $C->restore($self->org_id);
    return $C;
}##parent


############################################################################
sub delete  {   #04/07/03 1:29
############################################################################
    my $self = shift;

    my $id = $self->id;
    my $result = $self->SUPER::delete();

    if ($result) {
        $result += $self->dbh->do("UPDATE Notepad SET category_id=NULL WHERE category_id=?", undef, $id);
        $result += $self->dbh->do("UPDATE ToDo SET category_id=NULL WHERE category_id=?", undef, $id);
        $result += $self->dbh->do("UPDATE Contact SET category_id=NULL WHERE category_id=?", undef, $id);
    }
    return $result;
}##delete


1;
