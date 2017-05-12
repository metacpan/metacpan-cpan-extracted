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


package ePortal::epGroup;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Support/;
	use ePortal::Utils;
    use ePortal::Global;


############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{groupname} ||= {
        label => {rus => 'Наименование',eng => 'Name'},
        maxlength => 64,
        size => 20,             # size of <input type=text>
        };
    $p{Attributes}{groupdesc} ||= {
        label => {rus => 'Описание группы', eng => 'Description'},
        size  => 40,
        };
    $p{Attributes}{ext_group} ||= {
        dtype => 'YesNo',
        label => {rus => 'Внешняя группа', eng => 'External group'},
        };
    $p{Attributes}{hidden} ||= {
        dtype => 'YesNo',
        label => {rus => 'Скрытая', eng => 'Hidden'},
        };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Проверка данных перед сохранением объекта
# Parameters: not null - проверка перед insert
# Returns: Строку с описанием ошибки или undef;
#
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	# Простые проверки на наличие данных.
	unless ( $self->groupname) {
		return pick_lang(rus => "Не указано имя группы", eng => 'No group name');
	}

	undef;
}##validate


############################################################################
sub restore_where	{	#12/26/01 8:36
############################################################################
    my ($self, %p) = @_;

	if ($p{text}) {
		$p{where} .= ' AND ' if $p{where};
		$p{where} .= "(groupname like ? OR groupdesc like ?)";
		push @{$p{bind}}, '%' . $p{text} . '%';
		push @{$p{bind}}, '%' . $p{text} . '%';
    }
    delete $p{text};

    $p{order_by} = 'groupname' if not $p{order_by};

	$self->SUPER::restore_where(%p)
}##restore_where

############################################################################
# Function: restore
# Description:
# Parameters:
# Returns:
#
############################################################################
sub restore	{	#06/09/01 9:34
############################################################################
	my $self = shift;
	my $id = shift;

    my $result = $self->SUPER::restore($id);
    if (!$result) {
		$self->restore_where(where => 'groupname=?', bind => [$id]);
        $result = $self->restore_next();
	}
    if (ref ($self->{STH})) {
      $self->{STH}->finish;
      $self->{STH} = undef;
    }

    return $result;
}##restore

############################################################################
# Function: Overloaded function delete
# Description: Deletes all related records from UsrGrp table
#
############################################################################
sub delete	{	#06/19/01 2:19
############################################################################
	my $self = shift;
	my $groupname = $self->groupname;
    my $dbh = $self->dbh;

    my $result = 0;
    $result += $dbh->do("delete from epUsrGrp where groupname=?", undef, $groupname);
    $result += $ePortal->onDeleteGroup($groupname);
    $result += $self->SUPER::delete(@_);
    logline('warn', "Group $groupname deleted. Total objects deleted: $result");
	return $result;
}##delete

############################################################################
# Function: members
# Returns:
# 	array with names of members
#
############################################################################
sub members	{	#06/26/01 11:58
############################################################################
	my $self = shift;
    my $dbh = $self->dbh();

	my $sql = "SELECT username FROM epUsrGrp WHERE groupname=?";
	my $ary = $dbh->selectcol_arrayref($sql, undef, $self->groupname);

	$ary = [] if not defined $ary;

	return wantarray? @$ary : $ary;
}##members

############################################################################
sub ObjectDescription   {   #04/15/03 10:49
############################################################################
    my $self = shift;

    return pick_lang(rus => "Группа пользователей: ", eng => "Group of users: ") .
        $self->groupname;
}##ObjectDescription

1;

