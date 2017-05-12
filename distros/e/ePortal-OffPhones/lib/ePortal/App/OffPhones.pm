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


package ePortal::App::OffPhones;
    our $VERSION = '4.2';
    use base qw/ePortal::Application/;

    use Text::Wrap;

    # use system modules
    use ePortal::Global;
    use ePortal::ThePersistent::Support;

    # use internal Application modules
    use ePortal::App::OffPhones::Client;
    use ePortal::App::OffPhones::Department;
    use ePortal::App::OffPhones::Phone;
    use ePortal::App::OffPhones::PhoneMemo;
    use ePortal::App::OffPhones::PhoneType;
    use ePortal::App::OffPhones::PhoneMemo;
    use ePortal::App::OffPhones::SearchDialog;


############################################################################
sub initialize  {   #09/08/2003 10:10
############################################################################
    my ($self, %p) = @_;
    
    $p{Attributes}{xacl_write} = {
          label => {rus => 'Редактор Т.справочника', eng => 'Edit access'},
          fieldtype => 'xacl',
      };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub config_save {   #03/17/03 4:55
############################################################################
    my $self = shift;
    $self->SUPER::config_save;

    # Modify permissions for SquidAcnt Catalog item
    foreach my $nickname ('ePortal-OffPhones-phtype', 'ePortal-OffPhones-memos') {
        my $C = new ePortal::Catalog;
        if ($C->restore($nickname)) {
            $C->xacl_read( $self->xacl_write );
            $C->update;
        }
    }
}##config_save

# ------------------------------------------------------------------------
# Description: Returns ThePersistent object with single field ID of
# departments found
# Parameters: $what - what to find
#
############################################################################
sub stSearchDistinctDepartment  {   #04/05/02 9:38
############################################################################
    my $what = shift;
    $what =~ s/'/''/g;
    my $like = '%'.$what.'%';
    my $like_start = $what.'%';
    my $obj = new ePortal::ThePersistent::Support(SQL => 'SELECT distinct
            d.id
        FROM
            Department d,
            Client c,
            Phone ph
        left join PhoneMemo m on c.id=m.client_id and m.private=1 and m.user_name=?
        WHERE
            c.dept_id = d.id AND
            ph.client_id = c.id AND
            (   d.Title like ? OR       c.Title like ? OR
                c.Position like ? OR    m.Title like ? OR
                ph.title = ?
            )
            ', DBISource => 'OffPhones');

    $obj->restore_where(
            limit_rows => 10,
            bind => [$ePortal->username, $like, $like_start, $like, $like, $what]);
    return $obj;
}##stSearchDistinctDepartment




############################################################################
# Function: stClientsByDept
# Description: Clients to show for the department
# Parameters:
# Returns:
#
############################################################################
sub stClientsByDept {   #04/19/02 10:23
############################################################################
    my $dept_id = shift;

    my $obj = new ePortal::ThePersistent::Support(SQL => "SELECT
        c.id, c.position, c.title,
        p.id as phone_id, p.title as nNumber,
        pt.title as phone_type,
        pt.format,
        m.id as memo_id, m.title as phone_memo
    from Client c
        left join Phone p on c.id=p.client_id
        left join PhoneMemo m on c.id=m.client_id and
        m.private=1 and m.user_name=?
        left join PhoneType pt on p.type_id = pt.id
    where c.dept_id=?
    order by c.rank, c.position, c.title, c.id,
            phone_type, phone_id,
            phone_memo, memo_id
    ", DBISource => 'OffPhones');

    $obj->restore_where( bind => [$ePortal->username, $dept_id]);
    return $obj;
}##stClientsByDept


############################################################################
# Function: UserMemoCount
# Description: Number of memos from users
# Parameters:
# Returns:
#
############################################################################
sub UserMemoCount   {   #04/22/02 1:14
############################################################################
    my $tp = new ePortal::ThePersistent::Support(
        DBISource => 'OffPhones', Table => 'PhoneMemo' );
    return $tp->restore_where(count_rows => 1, where => 'private=0');
#    my $db = $ePortal->DBConnect('OffPhones');

#   return $db->selectrow_array("SELECT count(*) from PhoneMemo
#       WHERE private=0");
}##UserMemoCount


############################################################################
# Function: NiceFormat
# Description: Nively formats a phone number
# Parameters: number, format
############################################################################
sub NiceFormat  {   #04/15/02 11:26
############################################################################
    my $number = shift;
    my $format = shift;

    return $number if $format eq '';

    my @a_number = split('', $number);
    my @a_format = split('', $format);

    my @result = map {$_ eq '#' ? shift @a_number : $_} @a_format;
    return join('', @result) . join('', @a_number) ;
}##NiceFormat


############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;
    my $result = 0;

    my $tp = new ePortal::ThePersistent::Support(
        Attributes => { id => { }},
        DBISource => 'OffPhones',
        Table => 'PhoneMemo' );
    $tp->restore_where(where => 'private=1', user_name => $username);
    while($tp->restore_next) {
        $result += $tp->delete;
    }
    return $result;
}##onDeleteUser


1;
