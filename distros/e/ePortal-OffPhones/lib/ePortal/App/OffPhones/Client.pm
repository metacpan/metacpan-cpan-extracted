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


package ePortal::App::OffPhones::Client;
	use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = '4.2';

	use ePortal::Global;
	use ePortal::Utils;
	use ePortal::HTML::Tree;

	my $MAX_PHONES_PER_CLIENT = 32;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'OffPhones';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{dept_id} ||= {
            label => {rus => "Подразделение", eng => "Department"},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => sub { my $parent = shift->parent;
                my (@values, %labels);

                # Top level
                push @values, 0;
                $labels{0} = pick_lang(rus => "-Телефоны-", eng => "-Phones-");

                # A level before
                if ($parent) {
                    my $subparent = $parent->parent;
                    if ($subparent) {
                        push @values, $subparent->id;
                        $labels{ $subparent->id } = $subparent->Title;
                    }
                }

                # Current level
                if ($parent) {
                    push @values, $parent->id;
                    $labels{ $parent->id } = '== '.$parent->Title . ' ==';
                }

                # Children departments
                if ($parent) {
                    my $children = $parent->children;
                    while($children->restore_next) {
                        push @values, $children->id;
                        $labels{ $children->id } = $children->Title;
                    }
                } else {    # I'm at top of the tree
                    my $dpt = new ePortal::App::OffPhones::Department;
                    $dpt->restore_where(parent_id=>0);
                    while($dpt->restore_next) {
                        push @values, $dpt->id;
                        $labels{ $dpt->id } = $dpt->Title;
                    }
                }

                return (\@values, \%labels);
            },
        };
    $p{Attributes}{title} ||= {
            label => {rus => 'Ф.И.О.', eng => 'Person Name'},
        };
    $p{Attributes}{position} ||= {
            label => {rus => 'Должность', eng => 'Position'},
        };
    $p{Attributes}{rank} ||= {
            label => {rus => 'Приоритет (1-выс...9-низ)', eng => 'Rank'},
            dtype => 'Number',
            size  => 2,
            maxlength => 2,
            default => 5,
        };
    $p{Attributes}{memos} ||= {
            label => {rus => "Персональные примечани ", eng => "Personal memo"},
            type => "Transient",
            dtype => 'Varchar',
        };
    $p{Attributes}{ts} ||= {};

    $self->SUPER::initialize(%p);

    for (1..$MAX_PHONES_PER_CLIENT) {
		$self->_add_phone_attribute($_);
	}
}##initialize


############################################################################
# Function: _add_phone_attribute
# Description: Add Transient attributes for PhoneNumber,PhoneType
# Parameters: Attribute number
#
############################################################################
sub _add_phone_attribute	{	#04/11/02 10:56
############################################################################
	my $self = shift;
	my $counter = shift;

	die if ! $counter;
	return if $self->attribute("phone_type$counter");

	$self->add_attribute("phone_type$counter" => {
				label => pick_lang(rus => "Тип номера", eng => "Phone type"),
				type => "Transient",
				dtype => 'Number',
				fieldtype => 'popup_menu',
				popup_menu => sub { my $o = new ePortal::App::OffPhones::PhoneType;
					return $o->restore_all_hash('id','title',undef,'title');
				}
			});
	$self->add_attribute("phone_number$counter" => {
				label => pick_lang(rus => "Номер", eng => "Number"),
				type => "Transient",
				dtype => 'VarChar',
				size  => 12}
				);
}##_add_phone_attribute


############################################################################
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	if ( ! $self->Title and ! $self->Position) {
		return pick_lang(rus => "Не указано наименование", eng => 'No name');
	}

	undef;
}##validate



############################################################################
sub restore_where	{	#12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

	$p{order_by} = 'rank,title' if not defined $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where



############################################################################
sub children	{	#04/09/02 1:30
############################################################################
	my $self = shift;
	my $phone = new ePortal::App::OffPhones::Phone;
	$phone->restore_where( client_id => $self->id);
	return $phone;
}##children


############################################################################
sub parent	{	#04/09/02 2:12
############################################################################
	my $self = shift;
	my $dpt = new ePortal::App::OffPhones::Department;
	if ($dpt->restore($self->dept_id)) {
		return $dpt;
	} else {
		return undef;
	}
}##parent


############################################################################
# Function: Phones
# Description:
# Parameters:
# Returns: Array of phones
# ( [type, number, type_id, format_string], ... )
#
############################################################################
sub Phones	{	#04/09/02 2:30
############################################################################
	my $self = shift;
	my $id = $self->id;
	my @phones;
	return () if $id == 0;

    my $obj = new ePortal::ThePersistent::Support(SQL => "SELECT
			t.id, t.title, pt.Title as PhoneType, pt.Format, t.client_id, t.type_id
		FROM Phone t, PhoneType pt
		WHERE t.type_id = pt.id AND t.client_id = $id
		ORDER BY PhoneType, t.title
        ", DBISource => 'OffPhones');
	$obj->restore_all();
	while($obj->restore_next) {
		push @phones, [$obj->PhoneType, $obj->Title, $obj->type_id, $obj->Format];
	}

	return @phones;
}##initialize



############################################################################
# Function: restore_next
# Description: Fill out a list of phones for current client
# Parameters:
# Returns:
#
############################################################################
sub restore_next	{	#04/10/02 10:54
############################################################################
	my $self = shift;
	my $result = $self->SUPER::restore_next(@_);

	# clear data
#	foreach my $counter (1..$MAX_PHONES_PER_CLIENT) {
#		$self->value("phone_type$counter", undef);
#		$self->value("phone_number$counter", undef);
#	}

    # Return if not found
	return $result if ! $result;

	# load fresh info
	my @phones = $self->Phones;
	foreach my $counter (1..$MAX_PHONES_PER_CLIENT) {
		my $item = $phones[$counter-1];
		next if ! $item;
		$self->value("phone_type$counter", $item->[2]);
		$self->value("phone_number$counter", $item->[1]);
	}


	#load memos
	if ($ePortal->username) {
		my $pm = new ePortal::App::OffPhones::PhoneMemo;
		$pm->restore_where(client_id => $self->id, user_name => $ePortal->username);
		while($pm->restore_next) {
			$self->memos( $self->memos . $pm->title . ' ');
        }
    }

	return $result;
}##restore_next



############################################################################
# Function: htmlSave
# Description:
# Parameters:
# Returns:
#
############################################################################
sub htmlSave	{	#04/10/02 11:01
############################################################################
	my $self = shift;
	my %ARGS = @_;

	my @phones;
	foreach my $counter (1..$MAX_PHONES_PER_CLIENT) {
		$ARGS{"phone_number$counter"} =~ tr/-\., //d;
		push @phones, [ $ARGS{"phone_type$counter"}, $ARGS{"phone_number$counter"}]
			if ($ARGS{"phone_type$counter"} and $ARGS{"phone_number$counter"});
		delete $ARGS{"phone_type$counter"};
		delete $ARGS{"phone_number$counter"};
	}

	my $result = $self->SUPER::htmlSave(%ARGS);
	return $result if ! $result;

	# Iterate with saved phones and remove some
	my $ph = new ePortal::App::OffPhones::Phone;
	$ph->restore_where(client_id => $self->id);
	while($ph->restore_next) {
		my $found = 0;
		foreach my $counter (1.. scalar(@phones)+1) {
			if ($phones[$counter-1]->[0] == $ph->type_id() and $phones[$counter-1]->[1] eq $ph->Title()) {
				$phones[$counter-1] = [];
				$found = 1;
            }
		}
		$ph->delete if not $found;
	}

	# add missing
	foreach my $counter (1..scalar(@phones)+1) {
		if ($phones[$counter-1]->[0] and $phones[$counter-1]->[1]) {
			$ph->clear;
			$ph->type_id($phones[$counter-1]->[0]);
			$ph->Title($phones[$counter-1]->[1]);
			$ph->Client_id($self->id);
			$ph->insert;
		}
	}

	return $result;
}##htmlSave

############################################################################
sub delete	{	#04/23/02 9:54
############################################################################
	my $self = shift;

    my $dbh = $self->dbh;
	$dbh->do("DELETE FROM PhoneMemo where private=1 AND client_id=?", undef, $self->id);
	$dbh->do("DELETE FROM Phone where client_id=?", undef, $self->id);

	$self->SUPER::delete;
}##delete


1;

