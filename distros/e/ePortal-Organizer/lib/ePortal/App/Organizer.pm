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


package ePortal::App::Organizer;
    our $VERSION = '4.2';

    use base qw/ePortal::Application/;
    use Params::Validate qw/:types/;
    use Error qw/:try/;

    # use system modules
    use ePortal::Global;
    use ePortal::Utils;

    # use internal Application modules
    use ePortal::App::Organizer::Organizer;
    use ePortal::App::Organizer::Category;
    use ePortal::App::Organizer::Anniversary;
    use ePortal::App::Organizer::Calendar;
    use ePortal::App::Organizer::ToDo;
    use ePortal::App::Organizer::Notepad;
    use ePortal::App::Organizer::Contact;



############################################################################
sub initialize  {   #09/08/2003 10:10
############################################################################
    my ($self, %p) = @_;
    
    $p{Attributes}{xacl_write} = {
          label => {rus => 'Создание общ.органайзеров', eng => 'Create public Organizers'},
          fieldtype => 'xacl',
      };

    $self->SUPER::initialize(%p);
}##initialize



#Access rights: Create new public organizers

############################################################################
sub xacl_check_public_org   {   #04/16/03 4:16
############################################################################
    my $self = shift;
    return $self->xacl_check('xacl_write');
}##xacl_check_public_org


############################################################################
sub AvailableOrganizers {   #02/19/03 4:09
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with(params => \@_,
        spec => {
            writable => { type => BOOLEAN, optional => 1},
        });

    my @available_organizers;
    my $A = new ePortal::App::Organizer::Organizer;
    $A->restore_all;
    while($A->restore_next) {
        next if $A->Private and ($A->uid ne $ePortal->username);
        next if $p{writable} and (! $A->xacl_check_update);
        push @available_organizers, $A->id;
    }
    push @available_organizers, 0 if @available_organizers==0;
    return @available_organizers;
}##AvailableOrganizers

############################################################################
# List of Organizers with additional info
############################################################################
sub stOrganizers  {   #02/11/03 1:02
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with(params => \@_,
        spec => {
            writable => { type => BOOLEAN, optional => 1},
        });

    my $st = new ePortal::ThePersistent::ExtendedACL(
        DBISource => 'Organizer',
        SQL => qq{SELECT Organizer.*
            FROM Organizer
        },
        xacl_uid_field => 'Organizer.uid',
        xacl_read_field => 'Organizer.xacl_read',
        GroupBy => "Organizer.id",
        OrderBy => 'Organizer.Title',
#        Attributes => {
#            LoadDate => {dtype => 'Date'}
#        },
        Where => "Organizer.id in (" . join(',', $self->AvailableOrganizers(writable=>$p{writable})) . ')',
        );
    return $st;
}##stOrganizers


############################################################################
sub DefaultPrivateOrganizerID   {   #03/11/03 10:50
############################################################################
    my $self = shift;
    my $username = shift || $ePortal->username;

    my $org_id = $self->dbh->selectrow_array(
        "SELECT id FROM Organizer WHERE private=1 and uid=?", undef, $username);

    if ( !$org_id) {
        throw ePortal::Exception::ObjectNotFound(
            -text => pick_lang(rus => "Личный органайзер не найден или не существует",
                    eng => "Default private organizer not found or not exists"));
    }
    return $org_id;
}##DefaultPrivateOrganizerID


############################################################################
# Delete personal data
############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;
    my $result = 0;

    my $tp = new ePortal::App::Organizer::Organizer();
    $tp->restore_where(where => 'Private=1', uid => $username);
    while($tp->restore_next) {
        $result += $tp->delete;
    }
    return $result;
}##onDeleteUser



1;
