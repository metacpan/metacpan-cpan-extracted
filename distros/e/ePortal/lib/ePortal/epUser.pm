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


package ePortal::epUser;
	use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = '4.5';

	use Carp;
	use ePortal::Global;
	use ePortal::Utils;

    use ePortal::Exception;
    use Error qw/:try/;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{username} ||= {
        label => {rus => 'Имя входа', eng => 'Login name'},
        maxlength => 64,
        size => 20,             # size of <input type=text>
    };
    $p{Attributes}{dn} ||= {
        label => 'LDAP DN', # LDAP returns DN that is different from username
        maxlength => 64,
    };
    $p{Attributes}{fullname} ||= {
        label => {rus => 'ФИО пользователя', eng => 'User name'},
        size  => 40,
        };
    $p{Attributes}{password} ||= {
        fieldtype => 'password',
        label => {rus => 'Пароль', eng => 'Password'},
        };
    $p{Attributes}{department} ||= {
        label => {rus => 'Подразделение', eng => 'Department'},
        size  => 40,
        };
    $p{Attributes}{title} ||= {
        label => {rus => 'Должность', eng => 'Job'},
        size  => 40,
        };
    $p{Attributes}{email} ||= {
        label => {rus => 'Адрес эл.почты', eng => 'e-mail'},
        };
    $p{Attributes}{enabled} ||= {};
    $p{Attributes}{last_checked} ||= {
        dtype => 'date',
        label => {rus => 'Дата проверки в LDAP', eng => 'Last validated'},
        };
    $p{Attributes}{last_login} ||= {
        dtype => 'datetime',
        label => {rus => 'Дата последней регистрации', eng => 'Last login time'},
        };
    $p{Attributes}{ext_user} ||= {
        dtype => 'YesNo',
        label => {rus => 'LDAP пользователь', eng => 'LDAP user'},
        };

    $self->SUPER::initialize( %p );
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
	unless ( $self->username ) {
        return pick_lang(rus => "Не указано имя входа для пользователя",
			eng => 'No login name');
	}

    # Check for duplicate
    my $cnt = $self->dbh->selectrow_array(
        "SELECT count(*) from epUser WHERE username=? AND id!=?", undef,
        $self->username, $self->id+0);
    if ($cnt) {
        return pick_lang(
            rus => "Такое имя уже используется",
            eng => 'Duplicate user name');
    }    

	undef;
}##validate


############################################################################
sub restore_where	{	#12/25/01 3:45
############################################################################
    my ($self, %p) = @_;

	if ($p{text}) {
		my $like = '%' . $p{text} . '%';
		$self->add_where( \%p, "username like ? OR fullname like ?", $like, $like);
    }
    delete $p{text};

    $p{order_by} = 'username' if not $p{order_by};
	$self->SUPER::restore_where(%p);
}##restore_where


=head2 restore()

Restore a user from DB. Look up by ID first, then by username and DN.

=cut

############################################################################
sub restore	{	#06/09/01 9:34
############################################################################
	my $self = shift;
	my $id = shift;

    my $result = $self->SUPER::restore($id);
    if (!$result) {
        $self->restore_where(where => 'username=?', bind => [$id]);
        $result = $self->restore_next();
    }
    if (!$result) {
        $self->restore_where(where => 'dn=?', bind => [$id]);
        $result = $self->restore_next();
    }

    if (ref ($self->{STH})) {
      $self->{STH}->finish;
      $self->{STH} = undef;
    }

    return $result;
}##restore


=head2 find_user()

The same functionality as C<restore()> but additionaly look for

 fullname like 'name%'

If unique fullname found then the user is restored.

=cut

############################################################################
sub find_user   {   #04/23/03 10:53
############################################################################
    my $self = shift;
    my $id = shift;

    # look up by ID, username, DN
    my $result = $self->restore($id);

    if (!$result) {
        $self->restore_where(where => 'fullname like ?', bind => [$id.'%']);
        if ($self->restore_next) {      # first match
            my $first_found_id = $self->id;
            if ($self->restore_next) {  # second match. Too many matches!!
                $self->clear;
            } else {                    # Good. Only 1 match. Restore it
                $result = $self->restore($first_found_id);
            }
        }
    }
    return $result;
}##find_user



############################################################################
# Function: Overloaded function delete
# Description: Deletes all related records from UsrGrp table
#
############################################################################
sub delete	{	#06/19/01 2:19
############################################################################
	my $self = shift;
	my $username = $self->username;
    my $dbh = $self->dbh;

    my $result = 0;
    $result += $dbh->do("delete from epUsrGrp where username=?", undef, $username);
    $result += $dbh->do("delete from PageView where pvtype='user' and uid=?", undef, $username);
    $result += $dbh->do("delete from UserConfig where username=?", undef, $username);
    $result += $ePortal->onDeleteUser($username);
    $result += $self->SUPER::delete(@_);
    logline('warn', "User $username deleted. Total objects deleted: $result");
	return $result;
}##delete

############################################################################
# Function: group_member
# Description: Checks for membership to the group
# Parameters: group name
# Returns: >0 - YES
#          undef - NO
############################################################################
sub group_member	{	#08/01/00 1:51
############################################################################
	my $self = shift;
	my $groupname = lc shift;

	if (not defined $self->{_groups}) {
		$self->{_groups} = $self->member_of;
	}

    # this is faster than grep
    foreach ( @{$self->{_groups}} ) {
        return 1 if $_ eq $groupname;
    }

    return undef;
}##group_member

############################################################################
# Function: ShortName
# Description:
# Parameters:
# Returns:
#
############################################################################
sub ShortName	{	#05/04/01 2:32
############################################################################
	my $self = shift;
	my $name = $self->FullName || $self->username;

    use locale;
	$name =~ s/^(\S+)\s+(\S)\S*\s+(\S)\S*/$1 $2. $3./;
	return $name;
}##ShortName

############################################################################
# Function: update_group_membership
# Description: Refreshes list of groups the user is member of
# Parameters:
# 	array or arrayref with names of groups
# Returns:
# 	1 on success
# 	undef on error
#
############################################################################
sub update_group_membership	{	#06/26/01 10:35
############################################################################
	my $self = shift;
	my (@params) = @_;

	# remove old group membership

    my $dbh = $self->dbh();
	my $sql = "DELETE FROM epUsrGrp WHERE username=?";
	if (! $dbh->do($sql, undef, $self->username)) {
		logline('error', "DBI error: $DBI::srrstr");
	}

	# Add new membership
	my $G = new ePortal::epGroup;
	my %groups_member= ();
	while(my $ary = shift @params) {
		# dereference $ary to array
		my @groups = ref($ary) eq 'ARRAY'? @$ary : ($ary);

		foreach my $group (@groups) {
			# check if already group member
			next if $groups_member{$group};

			# add membership
			if ($G->restore($group)) {
                $dbh->do("INSERT INTO epUsrGrp (username,groupname) VALUES(?,?)", undef,
                    $self->username, $group);
				$groups_member{$group} = 1;
			}
		}
	}

	delete $self->{_groups};
	1;
}##update_group_membership



############################################################################
# Function: groups
# Returns:
# 	array with names of groups the user is member
#
############################################################################
sub member_of	{	#06/26/01 11:58
############################################################################
	my $self = shift;
    my $dbh = $self->dbh();

	my $sql = "SELECT groupname FROM epUsrGrp WHERE username=?";
	my $ary = $dbh->selectcol_arrayref($sql, undef, $self->username);

	$ary = [] if not defined $ary;

	return wantarray? @$ary : $ary;
}##groups


############################################################################
# Function: not_member_of
# Parameters:
# 	arrays of groups names the user is not member of
# Returns:
# 	array or array ref
#
############################################################################
sub not_member_of	{	#06/26/01 12:07
############################################################################
	my $self = shift;
	my @member_of = $self->member_of;
	my @not_member_of;
    my $dbh = $self->dbh();

	my $sql = "SELECT groupname FROM epGroup ORDER BY groupname";
	my $ary = $dbh->selectcol_arrayref($sql);

	$ary = [] if not defined $ary;

	foreach $index (0.. scalar (@$ary)) {
		push @not_member_of, $ary->[$index]
			unless (grep ($_ eq $ary->[$index], @member_of));
	}

	return wantarray? @not_member_of : \@not_member_of;
}##not_member_of


############################################################################
# Function: add_groups
# Description: Add membership to groups
# Parameters:
# 	array of groups
# Returns:
#
############################################################################
sub add_groups	{	#06/26/01 1:50
############################################################################
	my $self = shift;
	my (@groups) = @_;

	my $G = new ePortal::epGroup;
    my $dbh = $ePortal->dbh;

	foreach my $group (@groups) {
		if ($G->restore($group)) {
            $dbh->do("INSERT IGNORE INTO epUsrGrp (username,groupname) VALUES(?,?)", undef,
                $self->username, $group);
		}
	}

	delete $self->{_groups};    # clear cache
	1;
}##add_groups


############################################################################
# Function: remove_groups
# Description: Remove membership from groups
# Parameters:
# 	arrays with groups names
# Returns:
#
############################################################################
sub remove_groups	{	#06/26/01 1:53
############################################################################
	my $self = shift;
	my (@groups) = @_;
    my $dbh = $ePortal->dbh;

	foreach my $group (@groups) {
        $dbh->do("DELETE FROM epUsrGrp WHERE username=? AND groupname=?", undef,
            $self->username, $group);
	}

	delete $self->{_groups};	# clear cache
	1;
}##remove_groups


############################################################################
sub ObjectDescription   {   #04/15/03 10:49
############################################################################
    my $self = shift;

    return pick_lang(rus => "Пользователь: ", eng => "User: ") .
        $self->username;
}##ObjectDescription


1;

